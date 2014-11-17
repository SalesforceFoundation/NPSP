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
* @date 2011 (2.0)
* @description Updates and managed opportunity contact roles for Household members, invoked via opp trigger 
*/
public class HH_OppContactRoles_TDTM extends TDTM_Runnable { 
	
    public HH_OppContactRoles_TDTM() {}    

    public static string strRefreshSetting = 'Open and Closed Opportunities';

//  public HH_OppContactRoles_TDTM(Opportunity[] opportunities, Opportunity[] oldOpportunities, HH_Households.triggerAction ta) {
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        npe01__Contacts_and_Orgs_Settings__c ContactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();
        npo02__Households_Settings__c currentHouseholdsSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        
        // bail out if the user has disabled household contact roles.
        if (!currentHouseholdsSettings.npo02__Household_Contact_Roles_On__c)
            return null;

        list<Opportunity> opportunities = newlist;
        list<Opportunity> oldOpportunities = oldlist;
   
        // for AfterInserts, we can just go ahead and do our work to create the household soft credits.
        // but for AfterUpdates, we only do work if the Opp's HH account has changed.
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
        	// from custom settings, see whether the user wants us to refresh soft credit ocrs.
        	// UNDONE: waiting to add the actual custom setting to use.
        	if (strRefreshSetting == null || strRefreshSetting == 'none')
        	   return null;
        	boolean isOpenOnly = (strRefreshSetting == 'Open Opportunities');
        	   
        	string strSoql = 'select Id, AccountId from Opportunity where Account.npe01__SYSTEM_AccountType__c = \'' + 
        	   CAO_Constants.HH_ACCOUNT_TYPE + '\' and ';
        	if (isOpenOnly)
        	   strSoql += ' IsClosed = false and ';
        	strSoql += '(Id in :opportunities or Id in :oldOpportunities)';
            
            map<Id, Opportunity> mapIdToOpp = null;
            
            // track which opps are moving between HH accounts
            list<Opportunity> listOppToProcess = new list<Opportunity>();

            // see if we have any Opps who have changed Household Accounts.
            for (integer i = 0; i < opportunities.size(); i++) {
                if (opportunities[i].AccountId != oldOpportunities[i].AccountId) {

                    // delay our soql until we know we need it.
                    if (mapIdToOpp == null) {
			            // query for the Opps of household accounts involved.
			            mapIdToOpp = new map<Id, Opportunity>((list<Opportunity>)database.query(strSoql));
                    }

                    if (mapIdToOpp.get(opportunities[i].Id) != null && mapIdToOpp.get(oldOpportunities[i].Id) != null) {
                        listOppToProcess.add(opportunities[i]);
                    }
                }
            }
            // bail out if the hh accounts did not change.
            if (listOppToProcess.size() == 0)
                return null;
            
            // delete the old household soft credits.
            delete [select Id from OpportunityContactRole where OpportunityId in :listOppToProcess and 
                Role = :currentHouseholdsSettings.npo02__Household_Member_Contact_Role__c];
            
            // now continue with our processing to create the new household soft credits
            opportunities = listOppToProcess;
        }
   
        DmlWrapper dmlWrapper = new DmlWrapper();
                             
        set<string> HouseholdOCRRecordTypeExclusions = new set<string>();
        set<id> conRecordTypesToExclude = new set<id>();
        if (currentHouseholdsSettings.npo02__Household_OCR_Excluded_Recordtypes__c != null) {
            HouseholdOCRRecordTypeExclusions = new set<string>(currentHouseholdsSettings.npo02__Household_OCR_Excluded_Recordtypes__c.split(';'));
            conRecordTypesToExclude = UTIL_RecordTypes.GetRecordTypeIdSet('Contact', HouseholdOCRRecordTypeExclusions);            
        }
        
        boolean recordTypesOnCons = false;
        if (Schema.sObjectType.Contact.fields.getMap().get('RecordTypeId') != null)
            recordTypesOnCons = true;
                
        // get all Opps in the trigger set that are for individual accounts 
        // issue 318, also get Contact ID for Role if available
        map<Id, Opportunity> oppsForContactRoles = new map<Id,Opportunity>([select Id, npe01__Contact_Id_for_Role__c, AccountId, account.npe01__One2OneContact__c,
            account.npe01__SYSTEMIsIndividual__c, account.npe01__SYSTEM_AccountType__c from Opportunity 
            where Id IN :opportunities AND account.npe01__SYSTEMIsIndividual__c = true]);
        
        if (oppsForContactRoles.size() > 0) {
            
            // set of contact Ids on Accounts for Opps in the trigger set
            Set<Id> contactIds = new Set<Id>();         
            
            // real contacts queried from that list of Ids on the Accounts
            List<Contact> individualContacts = new List<Contact>();
            
            // list of contacts queried for households of contacts on the opps
            List<Contact> householdContacts = new List<Contact>();
            
            // map Contacts to Opps
            Map<id,List<Opportunity>> contactIdToOpps = new Map<id, List<Opportunity>>();
            
            // map Household Id to the member Contacts
            // note that householdId can be either a Household__c or a HH Account.
            Map<id,List<Contact>> householdIdToContact = new Map<id, List<Contact>>();           
            
            // query for OppConRoles where primary=true and OppID in arg set
            map<String,Id> contactOppToContactRole = new map<String,Id>();
            OpportunityContactRole[] conRoles = [select Id,OpportunityId, ContactId From OpportunityContactRole WHERE IsPrimary = true AND Opportunity.Id IN :oppsForContactRoles.values() ];
            //UTIL_Debug.debug('DJH***** conRoles: ' + conRoles);
            String uniqueConRole = '';
            // now loop through the results and build the map
            for (OpportunityContactRole thisCR : conRoles) {
                contactIds.add(thisCR.ContactId);
                if (contactIdToOpps.get(thisCR.ContactId) == null)
                    contactIdToOpps.put(thisCR.ContactId, new List<Opportunity>());
                contactIdToOpps.get(thisCR.ContactId).add(oppsForContactRoles.get(thisCR.OpportunityId));    
                uniqueConRole = string.valueOf(thisCR.OpportunityId) + string.valueOf(thisCR.ContactId);
                contactOppToContactRole.put(uniqueConRole , thisCR.Id);
                
                // now remove any npe01__Contact_Id_for_role__c or npe01__One2OneContact__c that may conflict with the primary ocr already created
                oppsForContactRoles.get(thisCR.OpportunityId).npe01__Contact_Id_for_role__c = null;
                oppsForContactRoles.get(thisCR.OpportunityId).account.npe01__One2OneContact__c = null;
            }

            // loop throught the Opportunities
            for (Opportunity thisOpp : oppsForContactRoles.values()) { 

                // grab all the contacts off the Accounts or via the role lookup
                if (thisOpp.account.npe01__One2OneContact__c != null && thisOpp.account.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE)
                    contactIds.add(thisOpp.account.npe01__One2OneContact__c);
                else if (thisOpp.npe01__Contact_Id_for_Role__c != null) 
                    contactIds.add(thisOpp.npe01__Contact_Id_for_Role__c);
                                    
                // create the map of contacts to opps
                if (contactIdToOpps.get(thisOpp.account.npe01__One2OneContact__c) == null && contactIdToOpps.get(thisOpp.npe01__Contact_Id_for_Role__c) == null) {
                    if (thisOpp.account.npe01__One2OneContact__c != null && thisOpp.account.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE)
                        contactIdToOpps.put(thisOpp.account.npe01__One2OneContact__c, new List<Opportunity>());
                    else if (thisOpp.npe01__Contact_Id_for_Role__c != null)
                        contactIdToOpps.put(thisOpp.npe01__Contact_Id_for_Role__c, new List<Opportunity>());                                          
                }
                
                if (thisOpp.account.npe01__One2OneContact__c != null && thisOpp.account.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE)
                    contactIdToOpps.get(thisOpp.account.npe01__One2OneContact__c).add(thisOpp);
                else if (contactIdToOpps.get(thisOpp.npe01__Contact_Id_For_Role__c) != null) 
                    contactIdToOpps.get(thisOpp.npe01__Contact_Id_For_Role__c).add(thisOpp);                                            
            }            
            
        

            // map for contacts to their households because we can't get a query with Opp Id, Contact Id, and Household Id
            map<Id,Id> contactIdToHouseholdId = new map<Id,Id>();
            
            // query all contacts to get the Household Ids
            individualContacts = [select id, npo02__Household__c, AccountId, Account.npe01__SYSTEM_AccountType__c from Contact where Id IN :contactIds];
            
            // create a map of contacts and their Household Ids
            for (Contact myContact : individualContacts) {  
                if (myContact.Account.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) {
                    contactIdToHouseholdId.put(myContact.Id, myContact.AccountId);                          
                } else if (myContact.npo02__household__c!=null) {
                    contactIdToHouseholdId.put(myContact.Id, myContact.npo02__household__c);        
                }       
            }
            
            list<id> c2HId = contactIdToHouseholdId.values();
            // query all contacts in all the Households
            if (recordTypesOnCons)
                householdContacts = database.query('select id, npo02__Household__c, RecordTypeId, AccountId, Account.npe01__SYSTEM_AccountType__c from Contact where npo02__Household__c IN :c2HId or AccountId in :c2HId');
            else
                householdContacts = database.query('select id, npo02__Household__c, AccountId, Account.npe01__SYSTEM_AccountType__c from Contact where npo02__Household__c IN :c2HId or AccountId in :c2HId');
                                
            // create a map of Household Id to list of member contacts
            for (Contact myContact : householdContacts) {
                ID hhId;
                if (myContact.Account.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) {
                    hhId = myContact.AccountId;
                } else {
                    hhId = myContact.npo02__household__c;
                }
                if (householdIdToContact.get(hhId) == null) {
                    householdIdToContact.put(hhId,new List<Contact>());                   
                }
                householdIdToContact.get(hhId).add(myContact);
            }
            
            
            // list to hold new contact roles
            List<OpportunityContactRole> contactRolesForCreation = new List<OpportunityContactRole>();
            List<OpportunityContactRole> contactRolesForUpdate = new List<OpportunityContactRole>();
            
            // loop through all contacts that have opps
            for (Id thisContactId : contactIdToOpps.keySet()) {
                // loop through all opps
                for (Opportunity thisOpp : contactIdToOpps.get(thisContactId)) {
                    
                    if (contactIdToHouseholdId.get(thisContactId) != null) {
                        // loop through all households members
                        for (Contact householdMember : householdIdToContact.get(contactIdToHouseholdId.get(thisContactId))) {
                            
                            // different role for primary donor
                            if (thisContactId == householdMember.Id) {
                                uniqueConRole = string.valueOf(thisOpp.Id) + string.valueOf(householdMember.Id);
                                if (contactOppToContactRole.get(uniqueConRole) != null) {
                                    OpportunityContactRole thisRole = new OpportunityContactRole(id=contactOppToContactRole.get(uniqueConRole));
                                    thisRole.Role = ContactsSettings.npe01__Opportunity_Contact_Role_Default_role__c;
                                    contactRolesForUpdate.add(thisRole);                                    
                                } else {
                                    OpportunityContactRole thisRole = new OpportunityContactRole();
                                    thisRole.OpportunityId = thisOpp.Id;
                                    thisRole.ContactId = householdMember.Id;
                                    thisRole.Role = ContactsSettings.npe01__Opportunity_Contact_Role_Default_role__c;
                                    thisRole.isPrimary = true;
                                    contactRolesForCreation.add(thisRole);
                                }
                            } else {
                                // exclude any Contacts with an excluded record type
                                if (recordTypesOnCons && conRecordTypesToExclude.contains((id)householdMember.get('RecordTypeId'))) {
                                   // backwards, but prevents having to query for a RecordTypeId that may or may not be there...
                                                                                            
                                } else {
                                    OpportunityContactRole thisRole = new OpportunityContactRole();
                                    thisRole.OpportunityId = thisOpp.Id;
                                    thisRole.ContactId = householdMember.Id;
                                    thisRole.Role = currentHouseholdsSettings.npo02__Household_Member_Contact_Role__c;
                                    contactRolesForCreation.add(thisRole);
                                }
                            }                            
                        }
                    }                   
                }
            }
            
            if (contactrolesforCreation != null) {
            	dmlWrapper.objectsToInsert.addAll((list<SObject>)contactrolesforCreation);
            	//UTIL_Debug.debug('DJH***** contractrolesforCreation: ' + contactrolesforCreation);
                //insert contactrolesforCreation;   
            }
            
            if (contactRolesForUpdate != null) {
                dmlWrapper.objectsToUpdate.addAll((List<SObject>)contactRolesForUpdate);
                //UTIL_Debug.debug('DJH***** contractrolesForUpdate: ' + contactrolesForUpdate);
                //update contactRolesForUpdate;   
            }   
        }
    
    return dmlWrapper;
    }
}