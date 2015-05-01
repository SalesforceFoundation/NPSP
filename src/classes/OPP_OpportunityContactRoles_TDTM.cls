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
* @date 2011 (1.x)
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Provides opportunity and contact role support for all models  
*/
public without sharing class OPP_OpportunityContactRoles_TDTM extends TDTM_Runnable {

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        	
        DmlWrapper dmlWrapper = null;
        
        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
        	setOpportunityAccountField((list<Opportunity>) newlist);
        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
        	dmlWrapper = new DmlWrapper();
        	createOrUpdateContactRoles((list<Opportunity>) newlist, dmlWrapper);
            // we can't defer the dml.  too many of our other opp related triggers depend on the ocr's being saved.
          	TDTM_TriggerHandler.processDML(dmlWrapper);
        	dmlWrapper = null;
        }
        
        return dmlWrapper;
    }
 
    private void createOrUpdateContactRoles(list<Opportunity> listOpp, DmlWrapper dmlWrapper) {
    	
        Map<Id, Opportunity> oppsInsertCR = new map<Id, Opportunity>(listOpp);        
        List<OpportunityContactRole> CRUpdates = new List<OpportunityContactRole>();

        //Get existing contact roles for the trigger opps. 
        List<OpportunityContactRole> CRs = [select OpportunityId, ContactId, Role, IsPrimary from OpportunityContactRole where IsPrimary = true and OpportunityId in :oppsInsertCR.keySet()];

        //Check for primary CR with no role value; save those for updates.
        if(CRs.size() > 0){
            for(OpportunityContactRole cr : CRs){
                if(cr.Role == null){
                    CRUpdates.add(cr);
                }
                oppsInsertCR.remove(cr.OpportunityId);
            }
        }

        //Create CRs.
        if (oppsInsertCR.size() > 0){
            insertCR(oppsInsertCR.values(), dmlWrapper);
        }

        //Update existing CRs.
        if (CRUpdates.size() > 0){
            updateCR(CRUpdates, dmlWrapper);
        }
    }

    /// <name> getDefaultRole </name>
    /// <summary> Return the default role from the custom setting.  Use custom setting for default role value.</summary>
    private static String getDefaultRole(){
        return UTIL_CustomSettingsFacade.getContactsSettings().npe01__Opportunity_Contact_Role_Default_role__c;
    }

    /// <name> insertCR </name>
    /// <summary> Creates a new Contact Role record when an opp is inserted and there is no primary CR.  Use custom setting for default role value.</summary>
    /// <param name="opportunties"> List of opportunities meeting trigger criteria </param>
    private static void insertCR(Opportunity[] opportunities, DmlWrapper dmlWrapper){

        List<OpportunityContactRole> CRs = new List<OpportunityContactRole>();

        //Straightforward creation of opp contact role.      
        for(Opportunity o : opportunities){
            if(o.npe01__Contact_ID_for_Role__c != null) {
                try {
                    CRs.add(new OpportunityContactRole(OpportunityId = o.Id, ContactId = o.npe01__Contact_ID_for_Role__c, Role = getDefaultRole(), IsPrimary = true));
                } catch (exception e) {
                    o.addError(Label.npe01.Opportunity_Contact_Role_Error_Bad_Contact_Id);
                }
            }
        }
        if (CRs.size() > 0){
            //Database.SaveResult[] lsr = Database.insert(CRs, false);
            dmlWrapper.objectsToInsert.addAll((list<SObject>) CRs); 
        }
    }

    /// <name> UpdateCR </name>
    /// <summary> Update a primary contact role where the role field is empty.  Use custom setting for default role value.</summary>
    /// <param name="CRs"> List of contact roles  </param>
    private static void updateCR(OpportunityContactRole[] CRs, DmlWrapper dmlWrapper){

        for(OpportunityContactRole cr : CRs){
            cr.Role = getDefaultRole();
        }
        //Database.SaveResult[] lsr = Database.update(CRs, false);
        dmlWrapper.objectsToUpdate.addAll((List<SObject>)CRs);
    }
    
    //truncate string representation of an ID to 15 chars
    private static string shortenId(String idForShortening){
        if(idForShortening.length() >= 15) {
            idForShortening = idForShortening.subString(0,15);
        }           
        return idForShortening;
    }
    
    //fill one-to-one and HH Accounts for Opportunities where a Contact id is supplied
    private static void setOpportunityAccountField(List<Opportunity> oppList) {
        
        Map<String,Account> contactsAndOneToOneAccounts = new Map<String,Account>();
        Set<String> primaryContactIds = new Set<String>();
        Set<Id> oppAccounts = new Set<Id>();
        
        for(Opportunity o : oppList){
            if(o.AccountId != null && o.npe01__Contact_Id_for_role__c == null){
                oppAccounts.add(o.AccountId);
            }
            
            if(o.AccountId == null && o.npe01__Contact_Id_for_role__c != null){
                primaryContactIds.add(o.npe01__Contact_Id_for_role__c);                
            }
        }
        Map<Id,Account> primaryAccounts = new Map<Id,Account>([select id, npe01__One2OneContact__c, npe01__SYSTEM_AccountType__c from Account where id IN :oppAccounts]);
         
        List<Contact> primaryContacts = new List<Contact>();
        primaryContacts = [select AccountId,Account.Id,Account.npe01__SYSTEM_AccountType__c from Contact where Id IN :primaryContactIds];
        for(Contact thisContact : primaryContacts) {
            contactsAndOneToOneAccounts.put(shortenId(string.valueOf(thisContact.Id)),thisContact.Account);
        }
        //loop through opps again and then put the right accountid on the opp
        for(Opportunity o : oppList){
            //add the contact id from the Account. if it's not valid it won't error
            if(o.AccountId != null && o.npe01__Contact_Id_for_role__c == null){
            	Account acc = primaryAccounts.get(o.AccountId);
                if(acc.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE || 
                    acc.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE){
                    o.npe01__Contact_Id_for_role__c = acc.npe01__One2OneContact__c;
                }
            }
            
            if(o.AccountId == null && o.npe01__Contact_Id_for_role__c != null){ //using the contact id, pull the account from the map
                
                if(contactsAndOneToOneAccounts.get(shortenId(o.npe01__Contact_Id_for_role__c))!=null){
                    Account accountForContact = contactsAndOneToOneAccounts.get(shortenId(o.npe01__Contact_Id_for_role__c));
                    //for one-to-one accounts and HH Accounts, set the account id
                    if(accountForContact.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE || 
                        accountForContact.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE){
                        o.AccountId = accountForContact.Id;
                    }
                } else {
                    o.addError(Label.npe01.Opportunity_Contact_Role_Error_Bad_Contact_Id);
                }            
            }
        }       
    }       
}