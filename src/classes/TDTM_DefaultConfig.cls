/*
    Copyright (c) 2013, Salesforce.com Foundation
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
public without sharing class TDTM_DefaultConfig {

    public static List<Trigger_Handler__c> getDefaultRecords() {
        List<Trigger_Handler__c> handlers = new List<Trigger_Handler__c>();

        //Affiliations on Account
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 2, Object__c = 'Account', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));

        //Affiliations on Contact
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
                    
        // Affiliations on Affiliation
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'npe5__Affiliation__c', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
                    
        // Relationships on CampaignMember
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Cm_TDTM', Load_Order__c = 1, Object__c = 'CampaignMember', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
        
        // Relationships on Contact
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Con_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));
        
        // Relationships on npe4__Relationship__c
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_TDTM', Load_Order__c = 1, Object__c = 'npe4__Relationship__c', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate;AfterDelete'));
                                         
        // Account Management on Contact
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ACCT_IndividualAccounts_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate;AfterDelete'));

        // Account Management on Account
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ACCT_Accounts_TDTM', Load_Order__c = 1, Object__c = 'Account', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterUpdate'));

        // OpportunityContactRole support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'HH_OppContactRoles_TDTM', Load_Order__c = 1, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));

        // HH Object support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'HH_HHObject_TDTM', Load_Order__c = 1, Object__c = 'npo02__Household__c', 
              Trigger_Action__c = 'BeforeUpdate;AfterUpdate'));

        // HH Object contact trigger support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'HH_Households_TDTM', Load_Order__c = 0, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));
                
        // RecurringDonations on Opportunity
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'RD_RecurringDonations_Opp_TDTM', Load_Order__c = 1, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterUpdate'));

        // RecurringDonations on RecurringDonations
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'RD_RecurringDonations_TDTM', Load_Order__c = 1, Object__c = 'npe03__Recurring_Donation__c', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate'));
        
        // OppRollups on Opportunity
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'RLLP_OppRollup_TDTM', Load_Order__c = 1, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));

        // Payments on Opportunity
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'PMT_Payment_TDTM', Load_Order__c = 1, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));

        // OpportunityContactRoles on Opportunity
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'OPP_OpportunityContactRoles_TDTM', Load_Order__c = 0, Object__c = 'Opportunity', 
              Trigger_Action__c = 'BeforeInsert;AfterInsert'));
          
        // Addresses on Address object - copies address from Address__c to Contact and Account
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ADDR_Addresses_TDTM', Load_Order__c = 1, Object__c = 'Address__c', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate'));
                    
        // Addresses on Contact object - creates Address__c record from Contact
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ADDR_Contact_TDTM', Load_Order__c = 2, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate'));
        
        // Addresses on Account object - creates Address__c record from Account
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ADDR_Account_TDTM', Load_Order__c = 1, Object__c = 'Account', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate'));
        
        // Address Verification/Normalization on Address object
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ADDR_Validator_TDTM', Load_Order__c = 1, Object__c = 'Address__c', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate'));

        // Payment Allocation on Allocation object
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ALLO_Allocations_TDTM', Load_Order__c = 1, Object__c = 'Allocation__c', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate;AfterDelete'));

        // Payment Allocation on Opportunity object
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ALLO_Allocations_TDTM', Load_Order__c = 2, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));

        // Currency adjustment of allocations on Campaign object
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ALLO_Multicurrency_TDTM', Load_Order__c = 1, Object__c = 'Campaign', 
              Trigger_Action__c = 'AfterUpdate'));

        // Currency adjustment of allocations on Recurring Donation object
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ALLO_Multicurrency_TDTM', Load_Order__c = 1, Object__c = 'npe03__Recurring_Donation__c', 
              Trigger_Action__c = 'AfterUpdate'));

        return handlers;
    }
    
    /**
      * Returns a map that specifies how the old NPSP settings match to the new Cumulus TDTM classes
      */
    public static Map<String, String> getNpspToCumulusMap() {
    	Map<String, String> npspToCumulusMap = new Map<String, String>();
    	
    	//No code refs in Cumulus - ref in IndividualAccounts trigger in Contacts_and_Organizations package
    	npspToCumulusMap.put('npe01__DISABLE_IndividualAccounts_trigger__c', 'ACCT_IndividualAccounts_TDTM'); 
    	//Flag removed from OPP_OpportunityContactRoles_TDTM class - this TDTM class is being referred to by two of the old flags,
    	//this one and the one right below.
    	npspToCumulusMap.put('npe01__DISABLE_OpportunityAccount_trigger__c', 'OPP_OpportunityContactRoles_TDTM');
    	//No code refs in Cumulus - ref in OpportunityContactRoles trigger in Contacts_and_Organizations package
    	npspToCumulusMap.put('npe01__DISABLE_OpportunityContactRoles_trigger__c', 'OPP_OpportunityContactRoles_TDTM');
    	//Flag removed from PMT_Payment_TDTM
    	npspToCumulusMap.put('npe01__DISABLE_OpportunityPayments_trigger__c', 'PMT_Payment_TDTM');
    	
    	//Flag removed from RLLP_OppRollup_TDTM
    	npspToCumulusMap.put('npo02__DISABLE_Household_Opportunity_trigger__c', 'HH_OppContactRoles_TDTM');
    	//No code refs in Cumulus - ref in HouseholdAfter trigger in Households package
    	npspToCumulusMap.put('npo02__DISABLE_HouseholdAfter_trigger__c', 'HH_HHObject_TDTM');
    	//No code refs in Cumulus - ref in HouseholdBefore trigger in Households package - We are going to ignore this flag 
    	//because the before logic is tightly coupled to the after logic and it wouldn't make sense to disable on its own
    	npspToCumulusMap.put('npo02__DISABLE_HouseholdBefore_trigger__c', '');	
    	//No code refs in Cumulus - ref in Households trigger in Households package
    	npspToCumulusMap.put('npo02__DISABLE_Households_trigger__c', 'HH_Households_TDTM'); 
    	//No code refs in Cumulus or NPSP
    	npspToCumulusMap.put('npo02__DISABLE_OpportunityRollup_trigger__c', 'RLLP_OppRollup_TDTM');
    	
    	////Flag removed from line 57 of RD_RecurringDonations_TDTM
    	npspToCumulusMap.put('npe03__DISABLE_Donations_trigger__c', 'RD_RecurringDonations_Opp_TDTM');
    	//Flag removed from line 107 of RD_RecurringDonations_TDTM
    	npspToCumulusMap.put('npe03__DISABLE_RecurringDonations_trigger__c', 'RD_RecurringDonations_TDTM');
    	
    	//No code refs in Cumulus - ref in RelationshipCampaignMembers trigger in Relationshipsv
    	npspToCumulusMap.put('npe4__DISABLE_RelationshipCM_trigger__c', 'REL_Relationships_Cm_TDTM');
    	//No code refs in Cumulus - ref in RelationshipContacts trigger in Relationships package
    	npspToCumulusMap.put('npe4__DISABLE_RelationshipContacts_trigger__c', 'REL_Relationships_Con_TDTM'); 
    	//No code refs in Cumulus - ref in Relationships trigger in Relatioships package
    	npspToCumulusMap.put('npe4__DISABLE_Relationships_trigger__c', 'REL_Relationships_TDTM'); 
    	
    	return npspToCumulusMap;
    }
}