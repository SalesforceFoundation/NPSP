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
* NOTE: This class handles both household naming for the Household__c object
* as well as for HH Account objects. 
*/
public without sharing class HH_HouseholdNaming {
      
    @future  
    public static void FutureUpdateNames(list<id> hhids){       
        //set our process control to avoid recursive updating on household records
        HH_ProcessControl.inFutureContext = true;
        
        //create a new instance of the HH_HouseholdNaming class -
        //and pass in our param
        //this is b/c of the public visibility
        HH_HouseholdNaming hn = new HH_HouseholdNaming();
        hn.UpdateNames(hhids);      
        HH_ProcessControl.inFutureContext = false;    
    }

    // we now want to always call UpdateNames() because it will set Number_Of_Household_Members__c, and
    // it will be responsible for only updating names if the advanced household naming is true.
    // so any code that used to check for advanced household naming should no longer do so,
    // (unless it is only for a naming scenario that would possibly change number of household members.)
    public void UpdateNames(list<id> hhids){
        
        //we need this turned on to prevent recursive triggering on household creation        
        HH_ProcessControl.inFutureContext = true;    
        
        //get all of the contacts and their associated households
        //return them in the order of household and then household naming order
        //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
        string strSoql = strContactSelectStmtAllNamingFields;
        string strHHId = UTIL_Namespace.StrTokenNSPrefix('HHId__c');
        strSoql += ' WHERE AccountId IN :hhids OR npo02__Household__c in :hhids ' +
            ' ORDER BY ' + strHHId + ', Primary_Contact__c DESC, npo02__Household_Naming_Order__c ASC NULLS LAST, CreatedDate ';     
        list<Contact> contactlist = Database.Query(strSoql); 
        
        list<SObject> listHHObj = [select Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c from npo02__Household__c where id IN : hhids];
        list<SObject> listHHAcct = [select Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c from Account where id IN : hhids];

        // handle two types of households by using an SObject    
        list<SObject> hhupdatelist = new list<SObject>();
        hhupdatelist.addAll(listHHObj);
        hhupdatelist.addAll(listHHAcct);        
        
        map<id, list<Contact>> hhIDContactMap = new map<id, list<Contact>>();
        
        //sort contacts by household
        for (Contact c : contactlist){          
            if(!hhIDContactMap.containskey(c.hhId__c)){
                hhIDContactMap.put(c.hhId__c, new list<Contact>{c});
            }
            else{
                list<Contact> clist = hhIDContactMap.get(c.hhId__c);
                clist.add(c);                
            }
        }
         
        npo02__Households_Settings__c hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();
               
        //loop through the households needing name changes, if necessary, make them.
        for (SObject h : hhupdatelist){    
            ID hhId = string.valueOf(h.get('Id'));
            list<Contact> listCon = hhIDContactMap.get(hhId);

            if (hs.npo02__Advanced_Household_Naming__c == true) {
	            string customnameparam = '';
	            if (h.get('npo02__SYSTEM_CUSTOM_NAMING__c') != null){
	                customnameparam = string.valueOf(h.get('npo02__SYSTEM_CUSTOM_NAMING__c'));
	            }            
	            
	            if (!customnameparam.contains('Name'))
	                h.put('Name', getHHName(listCon));
	            
	            if (!customnameparam.contains('Formal_Greeting__c'))
	                h.put('npo02__Formal_Greeting__c', getFormalName(listCon));
	
	            if (!customnameparam.contains('Informal_Greeting__c'))
	                h.put('npo02__Informal_Greeting__c', getInformalName(listCon));   
            }
                        
            // now we also store the number of members on the Household!
            h.put(UTIL_Namespace.StrTokenNSPrefix('Number_of_Household_Members__c'), listCon != null ? listCon.size() : 0);          
        } 
        
        if (!hhupdatelist.isEmpty()) {
        	//Database.SaveResult[] listSR = Database.update(hhupdatelist, false);
        	// all or nothing, so errors not lost
        	update hhupdatelist;
        }

        HH_ProcessControl.inFutureContext = false;    
    }
    
    
    // our cached copy of the Household Naming Settings
    private static Household_Naming_Settings__c hns {
        get {
            if (hns == null) hns = UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
            return hns;
        }
        set;
    }

    public static HH_INaming iNaming {
    	get {
    		if (iNaming == null) {                
		        string strClass = hns.Implementing_Class__c;  
		        if (strClass == null || strClass == '') strClass = 'HH_NameSpec';   
		        Type classType = Type.forName(strClass);
		        if (classType != null) {     
		            Object classInstance = classType.newInstance();
		            if (classInstance instanceof HH_INaming) {
		                iNaming = (HH_INaming)classInstance;
		            }
		        }
    		}
    		return iNaming;
    	}
    	set;
    }
    
    //get generic household name 
    public string getHHName(list<Contact> ContactList){        
        if (ContactList == null)
            ContactList = new list<Contact>();
    	list<Contact> listCon = new list<Contact>();
    	for (Contact con : ContactList) {
            if (con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Name'))
                listCon.add(con);	
    	}
        return iNaming.getHouseholdName(listCon);  
    }
/***********    	
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
                if((c.npo02__Naming_Exclusions__c == null || !c.npo02__Naming_Exclusions__c.contains('Name'))    
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
************/
    
    
    //just pile up first names for qualifying contacts
    public  string getInformalName(list<Contact> ContactList){
        if (ContactList == null)
            ContactList = new list<Contact>();
        list<Contact> listCon = new list<Contact>();
        for (Contact con : ContactList) {
            if (con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Informal_Greeting__c'))
                listCon.add(con);   
        }
        return iNaming.getHouseholdInformalGreeting(listCon);  
    }
/***********        
        string informalname = ''; 
       
        list<Contact> contactnames = new list<Contact>();
       
        integer i = 0;
        //remove any excluded contacts
        if (Contactlist != null){
        
        for (Contact c : ContactList){ 
            if(c.FirstName != null && (c.npo02__Naming_Exclusions__c == null || !c.npo02__Naming_Exclusions__c.contains('Informal_Greeting__c')))
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
*****/
    
    public  string getFormalName(list<Contact> ContactList){
        if (ContactList == null)
            ContactList = new list<Contact>();
        list<Contact> listCon = new list<Contact>();
        for (Contact con : ContactList) {
            if (con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Formal_Greeting__c'))
                listCon.add(con);   
        }
        return iNaming.getHouseholdFormalGreeting(listCon);  
    }

/***********        
        string formalname = ''; 
       
        list<Contact> contactnames = new list<Contact>();
       
        integer i = 0;
        
        if (Contactlist != null){
        //remove any excluded contacts
        for (Contact c : ContactList){ 
            if(c.npo02__Naming_Exclusions__c == null || !c.npo02__Naming_Exclusions__c.contains('Formal_Greeting__c'))
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
*****/
    
    //interface for the batch jobs on Refresh Household Naming
    public static void refreshAllHouseholdNaming(boolean isActivation) {                        
        // the household batch expects a list of Contact's with just Id, LastName, HHId__c available.
        string strSoql = 'SELECT Id, LastName, ' + UTIL_Namespace.StrTokenNSPrefix('HHId__c') + ' FROM Contact WHERE ' +
            UTIL_Namespace.StrTokenNSPrefix('HHId__c') + ' != NULL ';    
        HH_HouseholdNaming_BATCH batch = new HH_HouseholdNaming_BATCH(strSoql, isActivation);
        integer batchSize = 200;
        id batchProcessId = database.executeBatch(batch, batchSize);                 
    }

    private static list<string> listStrContactFields { 
        get {
            if (listStrContactFields == null) {
                Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Contact.fields.getMap().clone();
                // due to a Salesforce bug, we get these new fields if our caller is api 30 or greater,
                // but we will hit an error if we soql for them since we are api 28.
                // this workaround will no longer be needed when we move up to version 30 or greater.
                mapS.remove('mailingaddress');
                mapS.remove('otheraddress');
                listStrContactFields = new list<string>();
                listStrContactFields.addAll(mapS.keySet());                         
            }
            return listStrContactFields;
        }
        set;
    }    

    public string strContactSelectStmtAllNamingFields {
        get {
	        if (strContactSelectStmtAllNamingFields == null) {
		        //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
		        string strSoql = 'SELECT Id, HHId__c, npo02__Naming_Exclusions__c';
		        
		        set<string> setStrField = iNaming.setHousholdNameFieldsOnContact();
		        system.debug('****DJH setStrField: ' + setStrField);
		        for (string strF : setStrField) {
                    if (strF == 'Salutation') strF = 'toLabel(Salutation)';
                    strSoql += ', ' + strF;
		        }  
		        
		        /***********
		        for (string strF : listStrContactFields) {
		        	// only include Text, TextArea, and Picklist fields for custom household naming
		        	// also include a bunch of types needed by the ManageHouseholdUI code
		        	Schema.Displaytype dt = UTIL_Describe.getFieldDisplaytype('Contact', strF);
		        	if (dt == Schema.Displaytype.ID || 
                        dt == Schema.Displaytype.String || 
                        //dt == Schema.Displaytype.TextArea || //THESE EAT UP TOO MUCH HEAP SPACE!! 
                        dt == Schema.DisplayType.Picklist ||
                        dt == Schema.DisplayType.MultiPicklist ||  // needed for naming exclusions
                        dt == Schema.DisplayType.Integer ||
                        dt == Schema.DisplayType.Double ||   // needed for name order
                        dt == Schema.DisplayType.Date ||  // needed for CreatedDate
                        dt == Schema.DisplayType.DateTime ||
                        dt == Schema.DisplayType.Boolean || // needed for isAddressOverride
                        dt == Schema.DisplayType.Reference  // needed for HHId
                    ) {
			            if (strF == 'Salutation') strF = 'toLabel(Salutation)';
			            strSoql += strComma + strF;
			            strComma = ', ';
		        	}
		        }
		        **********/
		        
		        strSoql += ' FROM Contact ';
		        strContactSelectStmtAllNamingFields = strSoql;
	        }
	        return strContactSelectStmtAllNamingFields;
        }
        private set;        
    }    
   
    public static void handleHHNameUpdates(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
            
        list<SObject> listHHNew = newlist;
        list<SObject> listHHOld = oldlist;  
        map<ID, SObject> mapIdHHOld = new map<ID, SObject>(listHHOld);       
    
        npo02__Households_Settings__c hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        
        //updates household records to indicate where/if user changes to the household record are happening
        //and marks them as such so they won't be updated
        //need to use a process control class to avoid recursion when async updates occur
        //in non async updates, this won't fire again, so we don't need to worry
        if (!HH_ProcessControl.inFutureContext && 
            (triggerAction == TDTM_Runnable.Action.BeforeUpdate || triggerAction == TDTM_Runnable.Action.AfterUpdate)) {
            
            // no need to do any of this name checking if we aren't using auto household naming.
            // even though UpdateNames() keeps Number of Household Members updated, there is no need
            // to call it from here which is just trying to detect manual hh name changes.
            if (hs != null && hs.npo02__Advanced_Household_Naming__c == true ) {
                // AfterUpdate data
                list<id> hhlist = new list<id>();
                                       
                for (SObject h : listHHNew) {
                    string customname = '';
            
                    if (h.get('npo02__SYSTEM_CUSTOM_NAMING__c') == null)
                        customname = ';';                    
                    else  
                        customname = h.get('npo02__SYSTEM_CUSTOM_NAMING__c') + ';';
                
                    // BeforeUpdate data
                    list<string> customnamelist = new list<string>();
                    set<string> customnameset = new set<string>();
                    customnamelist = customname.split(';');
                    customnameset.addall(customnamelist);
                    
                    if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
                    	string hName = (string)h.get('Name');                
                        if (hName != null && hName != mapIdHHOld.get(h.id).get('Name') && !customnameset.contains('Name')) {
                            customname += 'Name' + ';';
                        } else if ((hName == null || hName == '' || hName == system.Label.npo02.NameReplacementText) && customnameset.contains('Name')) {
                            customname = customname.replace('Name;', ';');
                            h.put('Name', system.Label.npo02.NameReplacementText);
                        }
                
                        string informalGreeting = (string)h.get('npo02__Informal_Greeting__c');
                        if (informalGreeting != null && 
                            informalGreeting != mapIdHHOld.get(h.id).get('npo02__Informal_Greeting__c') && 
                            !customnameset.contains('Informal_Greeting__c')) {
                            customname += 'Informal_Greeting__c' + ';';
                        } else if ((informalGreeting == null || informalGreeting == '' || informalGreeting == system.Label.npo02.NameReplacementText) && 
                            customnameset.contains('Informal_Greeting__c')) {                
                            customname = customname.replace('Informal_Greeting__c;', ';');
                            h.put('npo02__Informal_Greeting__c', system.Label.npo02.NameReplacementText);
                        }
                
                        string formalGreeting = (string)h.get('npo02__Formal_Greeting__c');
                        if (formalGreeting != null && 
                            formalGreeting != mapIdHHOld.get(h.id).get('npo02__Formal_Greeting__c') && 
                            !customnameset.contains('Formal_Greeting__c')) {
                            customname += 'Formal_Greeting__c' + ';';
                        } else if ((formalGreeting == null || formalGreeting == '' || formalGreeting == system.Label.npo02.NameReplacementText) && 
                            customnameset.contains('Formal_Greeting__c')) {
                            customname = customname.replace('Formal_Greeting__c;', ';');
                            h.put('npo02__Formal_Greeting__c', system.Label.npo02.NameReplacementText);
                        }
                        h.put('npo02__SYSTEM_CUSTOM_NAMING__c', customname);
                    } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                        if (h.get('Name') == system.Label.npo02.NameReplacementText)
                           hhlist.add(h.id);
                        else if (h.get('npo02__Informal_Greeting__c') == system.Label.npo02.NameReplacementText)
                           hhlist.add(h.id);
                        else if (h.get('npo02__Formal_Greeting__c') == system.Label.npo02.NameReplacementText)
                            hhlist.add(h.id);       
                        else if (h.get('npo02__SYSTEM_CUSTOM_NAMING__c') != mapIdHHOld.get(h.id).get('npo02__SYSTEM_CUSTOM_NAMING__c'))
                            hhlist.add(h.id);                        
                        else if (h.getSObjectType() == Account.sObjectType && h.get('npe01__One2OneContact__c') != mapIdHHOld.get(h.id).get('npe01__One2OneContact__c'))
                            hhlist.add(h.id);                        
                    }
                }
                if (!hhlist.isEmpty()){
                    HH_HouseholdNaming hn = new HH_HouseholdNaming();
                    hn.UpdateNames(hhlist);
                }
            }
        } 
    
    }
   
}