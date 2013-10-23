/*
    Copyright (c) 2009, Salesforce.com Foundation
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
* @date 2011 (2.0)
* @description Handles creation, deleting and moving of Households between Contacts 
*/
global without sharing class HH_Households { 
    
    //One-to-One value for system processor field
    public static String ALL_PROCESSOR = 'All New or Edited Contacts';
    public static String ALL_INDIVIDUALS_PROCESSOR = 'All Individual Contacts';
    public static String NO_HOUSEHOLDS_PROCESSOR = 'No Contacts';
    
    public static Households_Settings__c householdsSettings;

    /// <name> HH_Households </name>
    /// <summary> Default Constructor </summary>
    public HH_Households(){}

    /// <name> triggerAction </name>
    /// <summary> contains possible actions for a trigger </summary>
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}

    //need a new constructor overload for updates that provides the maps as well, we can dump them
    //in as null values for inserts/deletes
    public HH_Households(Contact[] contacts, Contact[] oldContacts, triggerAction ta){
        //zoinks! call the newer version 
        this(contacts, oldContacts, ta, null, null);
    }
    
    /// <name> HH_Households </name>
    /// <summary> Overloads the HH_Households object constructor to handle Household processing </summary>
    /// <param name="households"> Household objects that are being triggered </param>
    /// <param name="oldHouseholds"> Household object values before trigger event </param>
    /// <param name="ta"> Trigger action that is occuring </param>
    public HH_Households(Contact[] contacts, Contact[] oldContacts, triggerAction ta, map<id, Contact> newcmap, map<id, Contact> oldcmap)
    {        
        Households_Settings__c currentHouseholdsSettings = getHouseholdsSettings();
        List<Contact> householdInserts = new List<Contact>();
        List<Contact> contactEvaluations = new List<Contact>();
        List<Contact> householdDeletes = new List<Contact>();
        list<id> householdnameupdates = new list<id>();        
        list<id> oldHouseholds = new list<id>();
        map<id, integer> oldHouseholdSize = new map<id, integer>();
        
        Set<Id> mergedWinningContact = new Set<Id>();
        
        
        //typically this is handled through the contact, but for old households
        //being updated, we need to get the list here
        list<id> blankHHDeletes = new list<id>();
     
        //if its an update, we need to get some data about their
        //old Household for processing
        if (ta==triggerAction.afterUpdate){
            
            for (Contact c : Contacts){
                
                if (oldcmap.get(c.id).Household__c != null){
                    oldHouseholds.add(oldcmap.get(c.id).Household__c);
                    system.debug('ID ADDED================' + oldcmap.get(c.id).Household__c);
                }
                
            }            
            
            AggregateResult[] ar = [select Household__c oldhh, count(id) membercount from Contact where Household__c IN :oldHouseholds group by Household__c];
            
            //create a map from the old household id and its size
            for (AggregateResult a : ar){
                system.debug('AR RESULTS=====ID: ' + (id)a.get('oldhh') + ' MEMBERCOUNT: ' + (integer)a.get('membercount'));
                oldHouseholdSize.put((id)a.get('oldhh'), (integer)a.get('membercount'));
            }
            
            //an agg query doesn't pick empty HHs, so if we have an ID, and no
            //HH in the ag, we know we have an empty hh
            for (id hhid : oldHouseholds){
                if (!oldHouseholdSize.containskey(hhid))
                   oldHouseholdSize.put(hhid, 0);               
            }            
        }
     
        Integer i = 0;
        for(Contact c : contacts) {
            //AFTER INSERT - NOTE: naming has to be handled inside othe household inserts, 
            //since we don't have the contact's household ids until after the insert
            //we'll check the trigger action again there to make sure it doesn't run twice
            if ( ta==triggerAction.afterInsert )
            {
                //If the user has chosen for all Contacts to have households, add them all to the list
                //for Household creation
                if (c.Household__c == null && currentHouseholdsSettings.Household_Rules__c == ALL_PROCESSOR)
                    householdInserts.add(c);
                //If the user has chosen for only Contacts connected to Individual Accounts to have Households
                //add them all to a list for evaluation
                else if (c.Household__c == null && currentHouseholdsSettings.Household_Rules__c == ALL_INDIVIDUALS_PROCESSOR)
                    contactEvaluations.add(c);
                else if  (c.Household__c != null)
                    householdnameupdates.add(c.Household__c);
            }

            //AFTER UPDATE
            if ( ta==triggerAction.afterUpdate )
            {            
                //if we're doing an update, pile up all of the households into a list
                //and send it to our naming code for action
                //first contact's names to their old names, and see if anything changed
                //salutation
                if (c.Household__c == null && currentHouseholdsSettings.Household_Rules__c == ALL_PROCESSOR)
                    householdInserts.add(c);
                else if (c.Household__c == null && currentHouseholdsSettings.Household_Rules__c == ALL_INDIVIDUALS_PROCESSOR)
                    contactEvaluations.add(c);
                
                if (newcmap.get(c.id).Salutation != oldcmap.get(c.id).Salutation)
                    householdnameupdates.add(c.Household__c);
                else if (newcmap.get(c.id).FirstName != oldcmap.get(c.id).Firstname )
                    householdnameupdates.add(c.Household__c);
                else if (newcmap.get(c.id).LastName != oldcmap.get(c.id).LastName)
                    householdnameupdates.add(c.Household__c);    
                
                //if they've changed households, we need to query the old
                //household to see if anybody is left, if so, send it for renaming
                //if not, delete it.
                else if (newcmap.get(c.id).Household__c != oldcmap.get(c.id).Household__c){
                    householdnameupdates.add(c.Household__c);
                    if (oldHouseholdSize.get(oldcmap.get(c.id).Household__c) > 0){
                        householdnameupdates.add(oldcmap.get(c.id).Household__c);
                    }
                    else if(oldHouseholdSize.get(oldcmap.get(c.id).Household__c) == 0){
                        blankHHDeletes.add(oldcmap.get(c.id).Household__c);
                    }       
                }                    
                else if (newcmap.get(c.id).Naming_Exclusions__c != oldcmap.get(c.id).Naming_Exclusions__c)
                    householdnameupdates.add(c.Household__c);
            }
            
            if ( ta==triggerAction.afterDelete ){
                if (c.Household__c != null )
                    householdDeletes.add(c);
            
                //check if this Contact is the loser in a merge
                if (c.MasterRecordId != null)
                    mergedWinningContact.add(c.MasterRecordId);
            }
            i += 1;
        }
        
        if (mergedWinningContact.size() > 0)
            contactMergeUpdate(mergedWinningContact);        
        
        if(!blankHHDeletes.isEmpty())
            Database.delete(blankHHDeletes);
        
        if (householdInserts.size() > 0 && ta==triggerAction.afterInsert)        
            insertHousehold(householdInserts, true);
        else if (householdInserts.size() > 0 && ta==triggerAction.afterUpdate)
            insertHousehold(householdInserts, false);
        
        if (contactEvaluations.size() > 0 && ta==triggerAction.afterInsert)        
            evaluateContacts(contactEvaluations, true);
        else if (contactEvaluations.size() > 0 && ta==triggerAction.afterUpdate)
            evaluateContacts(contactEvaluations, false);
        
        if (householdDeletes.size() > 0)        
            deleteHousehold(householdDeletes);
        
        if (currentHouseholdsSettings.Advanced_Household_Naming__c == true && householdnameupdates.size() > 0){
                          
            if (currentHouseholdsSettings.Async_Household_Naming__c == true)
                HouseholdNaming.FutureUpdateNames(householdnameupdates);
            else{
                HouseholdNaming hn = new HouseholdNaming(); 
                hn.UpdateNames(householdnameupdates);
            }                   
        }
    }
    
    public static void contactMergeUpdate(Set<Id> winningContacts){     
        Set<Id> oppIDs = new Set<Id>();
        List<OpportunityContactRole> ocrlist = new List<OpportunityContactRole>();
        ocrlist = [select OpportunityId from OpportunityContactRole where ContactId IN :winningContacts and isPrimary = true];      
        
        for (OpportunityContactRole ocr : ocrlist)
            oppIds.add(ocr.OpportunityId);
                
        if(!oppIDs.isEmpty())
            OpportunityRollups.rollupContactsandHouseholdsForTrigger(oppIds);
    }
    
    /// <name> insertHousehold </name>
    /// <summary> Creates a new Household record when a Contact does not have one </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
    public static void insertHousehold(Contact[] contacts, boolean isInsertTrigger)
    {
        List<Household__c> householdInserts = new List<Household__c>();
        //reload to evaluate insert criteria
        Households_Settings__c currentHouseholdsSettings = getHouseholdsSettings();
                
        set<string> HouseholdRecordTypeExclusions = new set<string>();
        set<id> conRecordTypesToExclude = new set<id>();
        if (currentHouseholdsSettings.Household_Creation_Excluded_Recordtypes__c != null) {
            HouseholdRecordTypeExclusions = new set<string>(currentHouseholdsSettings.Household_Creation_Excluded_Recordtypes__c.split(';'));
            conRecordTypesToExclude = RecordTypes.GetRecordTypeIdSet('Contact', HouseholdRecordTypeExclusions);            
        }
        
        boolean recordTypesOnCons = false;
        if(Schema.sObjectType.Contact.fields.getMap().get('RecordTypeId') != null)
            recordTypesOnCons = true;
        
        for(Contact c : contacts)
        {
            if (!recordTypesOnCons || !conRecordTypesToExclude.contains((id)c.get('RecordTypeId'))){            
                Household__c h = new Household__c(); 
                String hName = c.LastName;
                hName += ' ' + system.label.DefaultHouseholdName;
                h.Name = hName;
                //sync the primary address block
                h.MailingStreet__c = c.MailingStreet;
                h.MailingCity__c = c.MailingCity;
                h.MailingState__c = c.MailingState;
                h.MailingPostalCode__c  = c.MailingPostalCode;
                h.MailingCountry__c = c.MailingCountry;
                h.HouseholdPhone__c = c.HomePhone;
                h.HouseholdEmail__c = c.Email;
                householdInserts.add(h);
            }                
        }
        List<Contact> contactUpdates = new List<Contact>();
        
        if (householdInserts.size() > 0)
        {            
            //THIS NEEDS TO HANDLED -
            Database.SaveResult[] lsr = Database.insert(householdInserts, false);
            
            
                        
            Integer i = 0;
            for (Contact c : contacts)
            {
                //TODO: if household insert fails, there is no notification to the user
                if (lsr[i].isSuccess() == true)
                {
                    //write the new Household Ids to the Contacts
                    Contact clone = c.Clone(true,false);
                    clone.Household__c = lsr[i].getId();
                    contactUpdates.add(clone);
                }
                else{
                    Database.Error err = lsr[i].getErrors()[0];                 
                    c.addError(err.getMessage());
                }
                i += 1;
            }
            
            if (contactUpdates.size() > 0)
                Database.SaveResult[] dbsr = Database.update(contactUpdates, false);
        
            //SETTING CHECK HERE!!!
            if (currentHouseholdsSettings.Advanced_Household_Naming__c == true && isInsertTrigger){
                list<id> hhidsfornaming = new list<id>();
                
                for (Database.SaveResult sr : lsr){
                    if (sr.isSuccess())
                        hhidsfornaming.add(sr.getID());
                }
                
                //send it all out for (re)naming
                //secret setting for async processing... ooooooooh....
                
                if (currentHouseholdsSettings.Async_Household_Naming__c == true)
                    HouseholdNaming.FutureUpdateNames(hhidsfornaming);
                else{
                    HouseholdNaming hn = new HouseholdNaming();
                    hn.UpdateNames(hhidsfornaming);
                }
                    
            }
        }
    }
    
    /// <name> insertHousehold </name>
    /// <summary> Determines if a Contact Should have a household created </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
    public static void evaluateContacts(Contact[] contacts, boolean isAfterInsert) 
    {
        List<Contact> householdInserts = new List<Contact>();

        List<Id> accountIds = new List<Id>();
        for(Contact c : contacts)
        {
            if (c.accountId != null)
            {
                accountIds.add(c.AccountId); 
            }
        }
        //get all the Accounts so we can test to see if they are individuals
        Map<Id,Account> contactAccountMap = new Map<Id,Account>([Select Id, npe01__SYSTEMIsIndividual__c, Name from Account where Id in :accountIds]);
        for(Contact c : contacts)
        {
            if (c.AccountId != null){
                Account acc = contactAccountMap.get(c.AccountId);
                //check the system field on Account to see if the account is an individual
                if (acc.npe01__SYSTEMIsIndividual__c == true)
                {
                    householdInserts.add(c);
                }
            } else if (c.AccountId == null){
                householdInserts.add(c);
            }
        }
        if ( householdInserts.size() > 0)
        {
            //hand any Contacts that need Households over to the insert method
            insertHousehold(householdInserts, isAfterInsert);
        }
    }


    /// <name> deleteHousehold </name>
    /// <summary> Deletes a Household record when no Contacts are related to it </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
        public static void deleteHousehold(Contact[] contacts){
            
        list<Id> householdDeletes = new list<Id>();
        map<Id,Integer> householdCountMap = new map<Id,Integer>();
        list<id> householdrenames = new list<id>();
        //reload to evaluate delete criteria
        Households_Settings__c currentHouseholdsSettings = getHouseholdsSettings();

        //Generate a list of Household Ids
        for(Contact c : contacts){
            if (c.Household__c != null)
                householdCountMap.put(c.Household__c,0);
        }

        //Loop through all Contacts at one of the Household Ids
        for (Contact c : [Select Id, Household__c from Contact where Household__c in :householdCountMap.keyset()])
        {
            Integer lastCount = householdCountMap.get(c.Household__c);
            lastCount += 1;
            householdCountMap.put(c.Household__c,lastCount);
        }

        //Loop through all the contacts to determine if they can be deleted
        for (Contact c : contacts){
            //If there are no other Contacts on the Account
            if (householdCountMap.get(c.Household__c) < 1 )
                householdDeletes.add(c.Household__c);
            //otherwise, we need to update the household
            else     
                householdrenames.add(c.Household__c);        
        }

        if (householdDeletes.size() > 0)
            Database.DeleteResult[] lsr = Database.delete(householdDeletes, false);           
        
        if (currentHouseholdsSettings.Advanced_Household_Naming__c == true && householdrenames.size() > 0){
            if (currentHouseholdsSettings.Async_Household_Naming__c == true)
                HouseholdNaming.FutureUpdateNames(householdrenames);
            else{
                HouseholdNaming hn = new HouseholdNaming();
                hn.UpdateNames(householdrenames);
            }
        }
    }


    /// <name> getHouseholdLastTransaction </name>
    /// <summary>  </summary>
    webservice static String getHouseholdLastTransaction(Id householdId)
    {
        List<Id> contactIds = new List<Id>();
        List<Contact> contacts = [Select Id from Contact where Household__c = :householdId];
        for (contact c : contacts)
        {
            contactIds.add(c.Id);
        }
        Double total = 0;
        List<OpportunityContactRole> ocr = [Select Opportunity.Amount, Opportunity.CloseDate from OpportunityContactRole where ContactId in :contactIds AND Opportunity.isWon = true Order By Opportunity.CloseDate DESC];
        if (ocr.size() > 0)
        {
            Date lastTransaction = ocr[0].Opportunity.CloseDate;
            return String.valueOf(lastTransaction);
        }
        return null;
    }


    /// <name> getHouseholdTransactionTotal </name>
    /// <summary>  </summary>
    webservice static String getHouseholdTransactionTotal(Id householdId)
    {
        List<Id> contactIds = new List<Id>();
        List<Contact> contacts = [Select Id from Contact where Household__c = :householdId];
        for (contact c : contacts)
        {
            contactIds.add(c.Id);
        }
        Double total = 0;
        Set<Id> opps = new Set<Id>();
        
        for( OpportunityContactRole ocr : [Select Opportunity.Amount, OpportunityId From OpportunityContactRole where ContactId in :contactIds AND Opportunity.isWon = true])
        {
            if ( ocr.Opportunity.Amount != null )
            {
                opps.add(ocr.OpportunityId);

            }
        }
        for( Opportunity wonOpps : [Select Amount From Opportunity where Id in :opps])
        {
            total += wonOpps.Amount;
        }
        String totalString = system.label.DefaultHouseholdTransactionCurrency;
        Decimal totalFormat = Decimal.valueOf(total).setScale(2);
        totalString += totalFormat;
        return String.valueOf(totalString);
    }
    
    /// <name> getHouseholdLastTransaction </name>
    /// <summary>  </summary>
    public static String getHouseholdLastTransactionDate(Id householdId)
    {
        List<Id> contactIds = new List<Id>();
        List<Contact> contacts = [Select Id from Contact where Household__c = :householdId];
        for (contact c : contacts)
        {
            contactIds.add(c.Id);
        }
        Double total = 0;
        List<OpportunityContactRole> ocr = [Select Opportunity.Amount, Opportunity.CloseDate from OpportunityContactRole where ContactId in :contactIds AND Opportunity.isWon = true Order By Opportunity.CloseDate DESC];
        if (ocr.size() > 0)
        {
            return ocr[0].Opportunity.CloseDate.month() + '/' + ocr[0].Opportunity.CloseDate.day() + '/' + ocr[0].Opportunity.CloseDate.year();
        }
        return null;
    }
    
     /// <name> getHouseholdTransactionTotal </name>
    /// <summary>  </summary>
    public static String getHouseholdTransactionAmount(Id householdId)
    {
        List<Id> contactIds = new List<Id>();
        List<Contact> contacts = [Select Id from Contact where Household__c = :householdId];
        for (contact c : contacts)
        {
            contactIds.add(c.Id);
        }
        Double total = 0;
        Set<Id> opps = new Set<Id>();
        
        for( OpportunityContactRole ocr : [Select Opportunity.Amount, OpportunityId From OpportunityContactRole where ContactId in :contactIds AND Opportunity.isWon = true])
        {
            if ( ocr.Opportunity.Amount != null )
            {
                opps.add(ocr.OpportunityId);

            }
        }
        for( Opportunity wonOpps : [Select Amount From Opportunity where Id in :opps])
        {
            total += wonOpps.Amount;
        }
        String totalString = system.label.DefaultHouseholdTransactionCurrency;
        Decimal totalFormat = Decimal.valueOf(total).setScale(2);
        totalString += totalFormat;
        return String.valueOf(totalString);
    }
    
     //get the settings. handles the case where the managed value doesn't exist yet
    public static Households_Settings__c getHouseholdsSettings() {
        String oldProcessor = '';
        //if no settings exist, create defaults
        if (householdsSettings == null) {
            //first see if we already have settings
            householdsSettings = Households_Settings__c.getOrgDefaults();
            
            //modified to check again the Id instead of the object
            if (householdsSettings.Id == null) { 
                //get the model they used to be in 
                Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.SystemHouseholdProcessor__c; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                
                for(Schema.PicklistEntry pe : P){
                   // system.debug(pe.getValue() + ' : ' + pe.isDefaultValue());
                    if (pe.isDefaultValue()){
                        if(pe.getValue()==ALL_PROCESSOR){
                            oldProcessor = ALL_PROCESSOR;
                        } else if(pe.getValue()==ALL_INDIVIDUALS_PROCESSOR){
                            oldProcessor = ALL_INDIVIDUALS_PROCESSOR;
                        } else if(pe.getValue()==NO_HOUSEHOLDS_PROCESSOR){
                            oldProcessor = NO_HOUSEHOLDS_PROCESSOR;
                        }
                        break;
                    }
                }
                householdsSettings = new Households_Settings__c();
                //set them up with their old setting in the new settings object
                if(oldProcessor==ALL_PROCESSOR){
                    householdsSettings.Household_Rules__c = ALL_PROCESSOR;
                } else if(oldProcessor==ALL_INDIVIDUALS_PROCESSOR){
                    householdsSettings.Household_Rules__c = ALL_INDIVIDUALS_PROCESSOR;
                } else if(oldProcessor==NO_HOUSEHOLDS_PROCESSOR){
                    householdsSettings.Household_Rules__c = NO_HOUSEHOLDS_PROCESSOR;
                } else {
                    householdsSettings.Household_Rules__c = NO_HOUSEHOLDS_PROCESSOR;
                }
 
                householdsSettings.Household_Member_Contact_Role__c = label.Household_Member_Contact_Role;
                householdsSettings.Always_Rollup_to_Primary_Contact__c = false;
                householdsSettings.Enable_Opp_Rollup_Triggers__c = false;
                householdsSettings.Excluded_Account_Opp_Rectypes__c = null;
                householdsSettings.Excluded_Account_Opp_Types__c = null;
                householdsSettings.Excluded_Contact_Opp_Rectypes__c = null;
                householdsSettings.Excluded_Contact_Opp_Types__c = null;
                householdsSettings.Membership_Record_Types__c = null;
                householdsSettings.Rollup_N_Day_Value__c = 365;
                householdsSettings.Membership_Grace_Period__c = 30;
                householdsSettings.Advanced_Household_Naming__c = false;
                householdsSettings.Async_Household_Naming__c = false;
                householdsSettings.Setupownerid = UserInfo.getOrganizationId();
                householdsSettings.Schedule_Job_Limit__c = 25;
                householdsSettings.Household_OCR_Excluded_Recordtypes__c = null;
                householdsSettings.Household_Creation_Excluded_Recordtypes__c = null;
                insert householdsSettings;
            }
        }
        
        return householdsSettings;
    }
    
    public static Households_Settings__c getHouseholdsSettingsForTests(Households_Settings__c mySettings) {
        
        //clear out whatever settings exist
        delete [select id from npo02__Households_Settings__c]; 
         
        //create our own based on what's passed in from the test
        householdsSettings = new Households_Settings__c (
            Household_Rules__c = mySettings.Household_Rules__c,
            Household_Contact_Roles_On__c = mySettings.Household_Contact_Roles_On__c,
            Household_Member_Contact_Role__c = mySettings.Household_Member_Contact_Role__c,
            Always_Rollup_to_Primary_Contact__c = mySettings.Always_Rollup_to_Primary_Contact__c,
            Enable_Opp_Rollup_Triggers__c = mySettings.Enable_Opp_Rollup_Triggers__c,
            Excluded_Account_Opp_Rectypes__c = mySettings.Excluded_Account_Opp_Rectypes__c,
            Excluded_Account_Opp_Types__c = mySettings.Excluded_Account_Opp_Types__c,
            Excluded_Contact_Opp_Rectypes__c = mySettings.Excluded_Contact_Opp_Rectypes__c,
            Excluded_Contact_Opp_Types__c = mySettings.Excluded_Contact_Opp_Types__c,
            Membership_Grace_Period__c = mySettings.Membership_Grace_Period__c,
            Rollup_N_Day_Value__c = mySettings.Rollup_N_Day_Value__c, 
            Membership_Record_Types__c = mySettings.Membership_Record_Types__c,
            Advanced_Household_Naming__c = mySettings.Advanced_Household_Naming__c,
            Enable_Soft_Credit_Rollups__c = mySettings.Enable_Soft_Credit_Rollups__c,
            Soft_Credit_Roles__c = mySettings.Soft_Credit_Roles__c,        
            Household_OCR_Excluded_Recordtypes__c = mySettings.Household_OCR_Excluded_Recordtypes__c, 
            Household_Creation_Excluded_Recordtypes__c = mySettings.Household_Creation_Excluded_Recordtypes__c,
            Schedule_Job_Limit__c = 25
            );
        insert householdsSettings;
            
        return householdsSettings;
    }

}