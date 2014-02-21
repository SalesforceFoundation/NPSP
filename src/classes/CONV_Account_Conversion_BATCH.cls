/*
    Copyright (c) 2014, Salesforce.com Foundation
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
* @date 2014
* @description Provides a batch conversion interface for porting 1x1 or Individual Contacts to the Household Account model
*/
global with sharing class CONV_Account_Conversion_BATCH implements Database.Batchable<SObject>{

    public String query {get; set;}

    /** @description constructor for the class */
    public CONV_Account_Conversion_BATCH(string q) {
        query = q;
    }

    /** @description Start method of batch class */
    global database.Querylocator start(Database.BatchableContext bc) {
        
        //turn off all existing TDTM-related trigger operations to avoid duplicative processing
        List<Trigger_Handler__c> updateTriggerHandlers = new List<Trigger_Handler__c>();
        for (Trigger_Handler__c t : [select Active__c from Trigger_Handler__c]){
            t.Active__c = false;
            updateTriggerHandlers.add(t);
        }
        update updateTriggerHandlers;

        return Database.getQueryLocator(query); 
    }

    /** @description The execution logic for the batch */
    global void execute(Database.BatchableContext bc, Sobject[] result) {

        List<Contact> consForUpdate = new List<Contact>();
        List<OpportunityContactRole> ocrsForUpdate = new List<OpportunityContactRole>();
        List<Opportunity> oppsForUpdate = new List<Opportunity>();
        
        Map<Id, Account> hh2account = new Map<Id, Account>();
        Map<Id, Id> con2account = new Map<Id, Id>();
        
        List<npo02__Household__c> hhscope = (List<npo02__Household__c>)result;
        consForUpdate = [select AccountId, Name, npo02__Household__c from Contact where npo02__Household__c IN :hhscope];
        ocrsForUpdate = [select Opportunity.AccountId, Contact.npo02__Household__c, Opportunity.Id from OpportunityContactRole where isPrimary = true and ContactId IN :consForUpdate and Opportunity.npe01__Is_Opp_From_Individual__c = 'true'];

        //generate new Household Account for each Household in scope
        for (npo02__Household__c hh : hhscope){
            Account a = new Account(
            Name = hh.Name, npo02__TotalOppAmount__c = hh.npo02__TotalOppAmount__c,
            npo02__TotalMembershipOppAmount__c = hh.npo02__TotalMembershipOppAmount__c,
            npo02__SmallestAmount__c = hh.npo02__SmallestAmount__c, npo02__SYSTEM_CUSTOM_NAMING__c = hh.npo02__SYSTEM_CUSTOM_NAMING__c,
            npo02__OppsClosedThisYear__c = hh.npo02__OppsClosedThisYear__c, npo02__OppsClosedLastYear__c = hh.npo02__OppsClosedLastYear__c,
            npo02__OppsClosedLastNDays__c = hh.npo02__OppsClosedLastNDays__c, npo02__OppsClosed2YearsAgo__c = hh.npo02__OppsClosed2YearsAgo__c,
            npo02__OppAmountThisYear__c = hh.npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c = hh.npo02__OppAmountLastYear__c,
            npo02__OppAmountLastNDays__c = hh.npo02__OppAmountLastNDays__c, npo02__OppAmount2YearsAgo__c = hh.npo02__OppAmount2YearsAgo__c,
            npo02__NumberOfMembershipOpps__c = hh.npo02__NumberOfMembershipOpps__c, npo02__NumberOfClosedOpps__c = hh.npo02__NumberOfClosedOpps__c,
            npo02__MembershipJoinDate__c = hh.npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c = hh.npo02__MembershipEndDate__c,
            npo02__LastOppAmount__c = hh.npo02__LastOppAmount__c, npo02__LastMembershipOrigin__c = hh.npo02__LastMembershipOrigin__c,
            npo02__LastMembershipLevel__c = hh.npo02__LastMembershipLevel__c, npo02__LastMembershipDate__c = hh.npo02__LastMembershipDate__c,
            npo02__LastMembershipAmount__c = hh.npo02__LastMembershipAmount__c, npo02__LastCloseDate__c = hh.npo02__LastCloseDate__c,
            npo02__LargestAmount__c = hh.npo02__LargestAmount__c, npo02__Informal_Greeting__c = hh.npo02__Informal_Greeting__c,
            npo02__HouseholdPhone__c = hh.npo02__HouseholdPhone__c, npo02__Formal_Greeting__c = hh.npo02__Formal_Greeting__c,
            npo02__FirstCloseDate__c = hh.npo02__FirstCloseDate__c, npo02__Best_Gift_Year__c = hh.npo02__Best_Gift_Year__c,
            npo02__Best_Gift_Year_Total__c = hh.npo02__Best_Gift_Year_Total__c, Type = 'Household', npe01__SYSTEM_AccountType__c = 'HH Account');

            if (CAO_Constants.getContactsSettings().npe01__HH_Account_RecordTypeID__c != null)
                a.RecordTypeId = CAO_Constants.getContactsSettings().npe01__HH_Account_RecordTypeID__c;

            hh2Account.put(hh.id, a);
        }

        List<Database.SaveResult> sr = Database.insert(hh2Account.values());

        //attached current Household members to the new Household Account
        for (Contact c : consForUpdate){
        	Account a = hh2Account.get(c.npo02__Household__c);
            c.AccountId = a.Id;
            con2account.put(c.Id, a.Id);
        }
        Database.update(consForUpdate);

        //port all existing opportunities to the new hh accounts
        for (OpportunityContactRole ocr : ocrsForUpdate) {
            Opportunity o = new Opportunity (id = ocr.OpportunityId);
            o.AccountId = con2Account.get(ocr.ContactId);
            oppsForUpdate.add(o);
        }
        if (!oppsForUpdate.isEmpty())
            Database.update(oppsForUpdate);

        //finally, get any activities and tasks from the Household object and move them to the Account
        List<Task> tasksForUpdate = new List<Task>();
        tasksForUpdate = [select WhatId from Task where WhatId IN :hhscope];

        for (Task t : tasksForUpdate)
            t.WhatId = hh2Account.get(t.WhatId).Id; 

        Database.update(tasksForUpdate);
    }
    /** @description Finish method for the batchable class. */
    global void finish(Database.BatchableContext bc) {
        //restore the trigger handlers
        List<Trigger_Handler__c> updateTriggerHandlers = new List<Trigger_Handler__c>();
        for (Trigger_Handler__c t : [select Active__c from Trigger_Handler__c]){
            t.Active__c = true;
            updateTriggerHandlers.add(t);
        }
        update updateTriggerHandlers;
    }
}