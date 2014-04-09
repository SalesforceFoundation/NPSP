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

    global void execute(Database.BatchableContext bc, Sobject[] result) {

        List<Contact> consForUpdate = new List<Contact>();
        List<OpportunityContactRole> ocrsForUpdate = new List<OpportunityContactRole>();
        List<Opportunity> oppsForUpdate = new List<Opportunity>();

        Map<Id, Account> hh2account = new Map<Id, Account>();
        Map<Id, Account> con2account = new Map<Id, Account>();

        List<npo02__Household__c> hhscope = (List<npo02__Household__c>)result;
        consForUpdate = [select AccountId, Name, npo02__Household__c, npo02__TotalOppAmount__c, npe01__Primary_Address_Type__c, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode from Contact where npo02__Household__c IN :hhscope];
        ocrsForUpdate = [select Opportunity.AccountId, Contact.npo02__Household__c, Opportunity.Id from OpportunityContactRole where isPrimary = true and ContactId IN :consForUpdate and Opportunity.npe01__Is_Opp_From_Individual__c = 'true'];

        /********************************************************************/
        /** Generating a new Household Account for each Household in scope **/
        /********************************************************************/

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

        insert hh2Account.values();

        //save the contact giving amount to determine the primary contact
        Map<Id, Double> conGiving = new Map<Id, Double>();
        //Map of the Account back to the all of the new Household members
        Map<Id, List<Contact>> consWithNewHousehold = new Map<Id, List<Contact>>();

        Map<Id, Map<Id,ContactAddress>> addressMap = new Map<Id, Map<Id,ContactAddress>>();

        /***********************************************************************/
        /** Attaching current Household members to the new Household Account  **/
        /***********************************************************************/

        for (Contact c : consForUpdate){
            Account a = hh2Account.get(c.npo02__Household__c);
            c.AccountId = a.Id;
            if (!conGiving.containsKey(a.Id) || (conGiving.containsKey(a.Id) && c.npo02__TotalOppAmount__c > conGiving.get(a.Id))){
                a.npe01__One2OneContact__c = c.Id;
                conGiving.put(a.Id, c.npo02__TotalOppAmount__c);
            }
            con2account.put(c.Id, a);

            //build a map of cons with the new household to use later for address
            if (consWithNewHousehold.containsKey(a.Id)){
                consWithNewHousehold.get(a.Id).add(c);
            }
            else{
                consWithNewHousehold.put(a.Id, new List<Contact>{c});
            }
        }
        update consForUpdate;
        update hh2Account.values();

        /***************************************************************/
        /** Porting all existing opportunities to the new hh accounts **/
        /***************************************************************/

        for (OpportunityContactRole ocr : ocrsForUpdate) {
            Opportunity o = new Opportunity (id = ocr.OpportunityId);
            o.AccountId = con2Account.get(ocr.ContactId).Id;
            oppsForUpdate.add(o);
        }
        if (!oppsForUpdate.isEmpty())
            update oppsForUpdate;

        /******************************************************************************/
        /** Moving any activities and tasks from the Household object to the Account **/
        /******************************************************************************/

        List<Task> tasksForUpdate = new List<Task>();
        tasksForUpdate = [select WhatId from Task where WhatId IN :hhscope];

        for (Task t : tasksForUpdate)
            t.WhatId = hh2Account.get(t.WhatId).Id; 

        update tasksForUpdate;

        /**********************************************************************/
        /** Address Mapping from existing Contacts to new Household Accounts **/
        /**********************************************************************/

        consForUpdate.clear();
        List<Address__c> addressesForInsert = new List<Address__c>();
        List<Account> hhAccountsForUpdate = new List<Account>();

        for (Id accountId : consWithNewHousehold.keySet()){
            List<Contact> conList = consWithNewHousehold.get(accountId);

            //if its the only Contact and it has an address recorded, just use that address
            if (conList.size() == 1){
                ContactAddress cadd = new ContactAddress(conList[0]);
                if (cadd.hasAddress()){
                    addressesForInsert.add(new Address__c(
                    MailingStreet__c = cadd.MailingStreet,
                    MailingState__c = cadd.MailingState,
                    MailingPostalCode__c = cadd.MailingZip,
                    MailingCountry__c = cadd.MailingCountry,
                    MailingCity__c = cadd.MailingCity,
                    Default_Address__c = true,
                    Address_Type__c = conList[0].npe01__Primary_Address_Type__c,
                    Household_Account__c = accountId
                    ));

                    Account myHHAccount = con2Account.get(conList[0].Id);
                    myHHAccount.ShippingStreet = cadd.MailingStreet;
                    myHHAccount.ShippingState = cadd.MailingState;
                    myHHAccount.ShippingPostalCode = cadd.MailingZip;
                    myHHAccount.ShippingCountry = cadd.MailingCountry;
                    myHHAccount.ShippingCity = cadd.MailingCity;
                    hhAccountsForUpdate.add(myHHAccount);
                }
            }

            //multiple contacts
            else{
                
                //map of household ids to Contacts
                Map<Account, List<Contact>> hhAccount2Contacts = new Map<Account, List<Contact>>();
                ContactAddress baseHHAddress;
                //for each of hte contacts in the household
                for (Contact c : conList){
                    ContactAddress cadd = new ContactAddress(c);
                    if (cadd.hasAddress()){
                        addressesForInsert.add(new Address__c(
                        MailingStreet__c = cadd.MailingStreet,
                        MailingState__c = cadd.MailingState,
                        MailingPostalCode__c = cadd.MailingZip,
                        MailingCountry__c = cadd.MailingCountry,
                        MailingCity__c = cadd.MailingCity,
                        Default_Address__c = true,
                        Address_Type__c = c.npe01__Primary_Address_Type__c,
                        Household_Account__c = c.AccountId
                        ));

                        //we have other addresses for this HH
                        if (baseHHAddress != null){

                        }
                        //its the first address for this house
                        else{
                            baseHHAddress = cadd;
                            Account myHHAccount = con2Account.get(c.Id);
                            myHHAccount.ShippingStreet = cadd.MailingStreet;
                            myHHAccount.ShippingState = cadd.MailingState;
                            myHHAccount.ShippingPostalCode = cadd.MailingZip;
                            myHHAccount.ShippingCountry = cadd.MailingCountry;
                            myHHAccount.ShippingCity = cadd.MailingCity;
                            hhAccountsForUpdate.add(myHHAccount);
                        }
                    }

                    //this contact doesn't have an address, attempt to assign the hh default if it already exists
                    else{
                        if (baseHHAddress != null){
                            c.MailingStreet = baseHHAddress.MailingStreet;
                            c.MailingCity = baseHHAddress.MailingCity;
                            c.MailingState = baseHHAddress.MailingState;
                            c.MailingCountry = baseHHAddress.MailingCountry;
                            c.MailingPostalCode = baseHHAddress.MailingZip;
                            consForUpdate.add(c);
                        }
                    }
                }
            }
        }
        if (consForUpdate.size() > 1) update consForUpdate;
        if (addressesForInsert.size() > 1) insert addressesForInsert;
        if (hhAccountsForUpdate.size() > 1) update hhAccountsForUpdate;

/*
            //deal with addresses using hte map compiled previously

            //if we don't already have an address associated w/ this HH
            if (!addressMap.containsKey(a.Id)){
                addressMap.put(a.Id, new Map<Id, ContactAddress>{c.Id => new ContactAddress(c)});
            }
            //if this household already has some members that have addresses and they match the existing members
            else if (addressMap.containsKey(a.Id) && addressMap.get(a.Id).get(c.Id).compare(new ContactAddress(c))){
                
            }
            */

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

    public class ContactAddress{

        public ContactAddress(Contact c){
            this.MailingStreet = c.MailingStreet;
            this.MailingCity = c.MailingCity;
            this.MailingState = c.MailingState;
            this.MailingZip = c.MailingPostalCode;
            this.MailingCountry = c.MailingCountry;
        }

        public String MailingStreet;
        public String MailingCity;
        public String MailingState;
        public String MailingZip;
        public String MailingCountry;

        public Boolean isSameAddress(CONV_Account_Conversion_BATCH.ContactAddress ca){
            if(this.MailingStreet == ca.MailingStreet && 
               this.MailingCity == ca.MailingCity && 
               this.MailingState == ca.MailingState &&
               this.MailingZip == ca.MailingZip &&
               this.MailingCountry == ca.MailingCountry)
                return true;
            else
                return false;
        }

        public Boolean hasAddress(){
            if(MailingStreet != null ||
               MailingCity != null ||
               MailingState != null ||
               MailingZip != null ||
               MailingCountry != null)
                return true;
            else
                return false;
        }
    }
}