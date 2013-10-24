/*
    Copyright (c) 2011, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2011 (2.3)
* @description Controls generation of household names for lists of households 
*/
global virtual without sharing class HH_HouseholdNaming {
      
    @future  
    global static void FutureUpdateNames(list<id> hhids){       
        //set our process control to avoid recursive updating on household records
        HH_ProcessControl.inFutureContext = true;
        
        //create a new instance of the HH_HouseholdNaming class -
        //and pass in our param
        //this is b/c of the global visibility
        HH_HouseholdNaming hn = new HH_HouseholdNaming();
        hn.UpdateNames(hhids);      
    }
    global virtual string getOtherName(list<Contact> ContactList){return null;}
    global virtual void UpdateNames(list<id> hhids){
        
        //we need this turned on to prevent recursive triggering on household creation        
        HH_ProcessControl.inFutureContext = true;    
        
        //get all of the contacts and their associated households
        //return them in the order of household and then household naming order
        list<Contact> contactlist = [select id, Firstname, toLabel(Salutation), LastName, npo02__Household__r.id, npo02__Naming_Exclusions__c from Contact where npo02__Household__c IN :hhids and npo02__Household__c != null ORDER BY npo02__Household__c,npo02__Household_Naming_Order__c ASC NULLS LAST ];
        list<npo02__Household__c> hhupdatelist = [select Name, npo02__SYSTEM_CUSTOM_NAMING__c from npo02__Household__c where id IN : hhids];
        
        map<id, list<Contact>> hhIDContactMap = new map<id, list<Contact>>();
        
        //sort contacts by household
        for (Contact c : contactlist){          
            if(!hhIDContactMap.containskey(c.npo02__household__r.id)){
                hhIDContactMap.put(c.npo02__household__r.id, new list<Contact>{c});
            }
            else{
                list<Contact> clist = hhIDContactMap.get(c.npo02__household__r.id);
                clist.add(c);                
            }
        }
                
        //loop through the households needing name changes, if necessary, make them.
        for (npo02__Household__c h : hhupdatelist){    
        
            string customnameparam = '';
            if (h.npo02__SYSTEM_CUSTOM_NAMING__c != null){
                customnameparam = h.npo02__SYSTEM_CUSTOM_NAMING__c;
            }            
            
            if (!customnameparam.contains('Name'))
                h.Name = getHHName(hhIDContactMap.get(h.id));   
            
            if (!customnameparam.contains('Formal_Greeting__c'))
                h.npo02__Formal_Greeting__c = getFormalName(hhIDContactMap.get(h.id));

            if (!customnameparam.contains('Informal_Greeting__c'))
                h.npo02__Informal_Greeting__c = getInformalName(hhIDContactMap.get(h.id));             
        } 
        
        if (!hhupdatelist.isEmpty()) Database.update(hhupdatelist, false);
    }
    
    //get generic household name 
    global virtual string getHHName(list<Contact> ContactList){
        string householdname = '';
        
        if(ContactList != null){
            //most of our records will be either one or two people per household, so we'll handle
            //those cases seperately, process medium size households, then
            //go on to larger
            //we need to keep the names in order so store them in a list, but also maintain a set to prevent duplicates
            set<string> contactlastnamesSet = new set<string>();
            list<string> contactlastnames = new list<string>(); 
             
            for (Contact c : ContactList){
                //add valid values to the contactnames and lastnames lists for processing if not already in the set
                if((c.npo02__Naming_Exclusions__c == null || !c.npo02__Naming_Exclusions__c.contains('Household__c.Name')) 
                    && !contactlastnamesSet.contains(c.LastName))
                {
                    contactlastnames.add(c.LastName);
                    contactlastnamesSet.add(c.LastName);
                }
            }
            
            //we lost our only contact - he/she's anonymous
            if (contactlastnames.isEmpty())
                householdname = system.label.npo02.HouseholdAnonymousName + ' ' + system.label.npo02.DefaultHouseholdName;
                    
            //standard hh naming
            else if (contactlastnames.size() > 0 && contactlastnames.size() < 10){          
                integer x = 0;
                for (string lastname : contactlastnames){
                    x++;
                    householdname += lastname;
                    
                    if (x < contactlastnames.size() - 1)
                        householdname += ', ';
                    else if (x == contactlastnames.size() - 1)
                        householdname += ' ' + system.label.npo02.HouseholdNameConnector + ' ';
                    else
                        householdname += ' ' + system.label.npo02.DefaultHouseholdName;                                
                }
            }
            
            //more than 10 DIFFERENT last names, default to family, it can be overwritten in this 
            //special case
            else{
               householdname = ContactList[0].LastName;
               householdname += ' ' + system.label.npo02.HouseholdNameConnector + ' ' + system.label.npo02.HouseholdNameOverrun + ' ' + system.label.npo02.DefaultHouseholdname;
            }
        }
        return householdname;
    }
    
    
    //just pile up first names for qualifying contacts
    global virtual string getInformalName(list<Contact> ContactList){
        string informalname = ''; 
       
        list<Contact> contactnames = new list<Contact>();
       
        integer i = 0;
        //remove any excluded contacts
        if (Contactlist != null){
        
        for (Contact c : ContactList){ 
            if(c.FirstName != null && (c.npo02__Naming_Exclusions__c == null || !c.npo02__Naming_Exclusions__c.contains('Household__c.npo02__Informal_Greeting__c')))
                contactnames.add(c);
        }
        
        integer listsize = 0;
        if (contactnames != null)
            listsize = contactnames.size();
        
        if (listsize == 0)
            informalname = system.label.npo02.HouseholdAnonymousGreeting;
        
        else if (listsize == 1)
            informalname = contactnames[0].FirstName;
        
        else if (listsize == 2)
            informalname = contactnames[0].FirstName + ' ' + system.label.npo02.HouseholdNameConnector + ' ' + contactnames[1].FirstName;
        
        //more than 2
        else{
            integer counter = 1;
            for (Contact c : contactnames){
                
                //we're at the first name in the group
                if (counter == 1)
                    informalname += c.FirstName;
                //if we're at the last name in the group
                else if (counter == contactnames.size())
                    informalname += ' ' + system.label.npo02.HouseholdNameConnector + ' ' + c.FirstName;
                //we're somewhere in the middle of the group
                else
                    informalname += ', ' + c.Firstname;
                
                counter++;
            }  
        }
        }
        return informalname;
    }
    
    global virtual string getFormalName(list<Contact> ContactList){
        string formalname = ''; 
       
        list<Contact> contactnames = new list<Contact>();
       
        integer i = 0;
        
        if (Contactlist != null){
        //remove any excluded contacts
        for (Contact c : ContactList){ 
            if(c.npo02__Naming_Exclusions__c == null || !c.npo02__Naming_Exclusions__c.contains('Household__c.npo02__Formal_Greeting__c'))
                contactnames.add(c);
        }
        
            //chuck all of the last names in a set, lets see how many different ones we have
        set<string> lastnamelist = new set<string>();
        for (Contact c : contactnames)
            lastnamelist.add(c.LastName);  
      
      
        //no non-excluded contact for this household
        if (contactnames.size() == 0){                        
            formalname += '-'; 
        }
        else if (contactnames.size() > 0 && contactnames.size() < 9){
            
            integer counter = 1;
            for(Contact c : contactnames){    
                
                if (c.Salutation != null)
                    formalname += c.Salutation;
                if (c.Salutation != null && c.FirstName != null) //correct spacing between names
                    formalname += ' ';
                if (c.FirstName != null)
                    formalname += c.FirstName;
                if (lastnamelist.size() != 1 && counter != contactnames.size())
                    formalname += ' ' + c.LastName;
                    
                //any first name before the last and next to last gets the
                //same treatment, a comma.
                if(counter < (contactnames.size() - 1))
                    formalname += ', ';
                else if (counter == (contactnames.size() - 1))
                    formalname += ' ' + system.label.npo02.HouseholdNameConnector + ' ';                          
                //add the family name     
                else
                    formalname += ' ' + c.LastName;
        
                counter++;
            }            
        }          
        
        //else we have 9 or more people
        else{        
            //some default name here        
            if (contactnames[0].Salutation != null)
                formalname += contactnames[0].Salutation + ' ';
            if (contactnames[0].FirstName != null)
                formalname += contactnames[0].FirstName + ' ';                    
            
            formalname += contactnames[0].LastName + ' ' + system.label.npo02.HouseholdNameConnector + ' ' + system.label.npo02.HouseholdNameOverrun;
        }
        }
        return formalname;  
    }
    
    //interface for the batch jobs on advanced greeting activation
    public void ActivateAdvancedGreetings(boolean isTest){
        
        //shamelessly borrowed from opprollups      
        integer batchSize = 200;
        
        //start the activation batch process, used only once, on initial click
        //to enable batch rollups
        HH_HouseholdNaming_BATCH batch = new HH_HouseholdNaming_BATCH('SELECT id, npo02__Household__r.id, ' + 
        'npo02__household__r.Name, npo02__Household__r.npo02__Informal_Greeting__c, npo02__Household__r.npo02__Formal_Greeting__c, ' +
        'npo02__household__r.npo02__SYSTEM_CUSTOM_NAMING__c, npo02__Naming_Exclusions__c,  Firstname, lastname, ' +
        'salutation ' +
        'FROM Contact where npo02__Household__c != null ' +
        (isTest ? ' and lastname=\'%LastName0%\' LIMIT 200' : '') + 
        '', true);
        id batchProcessId = database.executeBatch(batch, batchSize);                 
    }
    
}