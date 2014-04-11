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
        Map<Id, Address__c> addressesForInsert = new Map<Id, Address__c>();
        List<Account> hhAccountsForUpdate = new List<Account>();

        for (Id accountId : consWithNewHousehold.keySet()){
            List<Contact> conList = consWithNewHousehold.get(accountId);

            //if its the only Contact and it has an address recorded, just use that address
            if (conList.size() == 1){
                ContactAddress cadd = new ContactAddress(conList[0]);
                if (cadd.hasAddress()){
                    Address__c a = new Address__c(MailingStreet__c = cadd.MailingStreet,
                    MailingState__c = cadd.MailingState,
                    MailingPostalCode__c = cadd.MailingZip,
                    MailingCountry__c = cadd.MailingCountry,
                    MailingCity__c = cadd.MailingCity,
                    Default_Address__c = true,
                    Address_Type__c = conList[0].npe01__Primary_Address_Type__c,
                    Household_Account__c = accountId);
                    addressesForInsert.put(accountId, a);

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

                Map<Contact, ContactAddress> HHaddresses = new Map<Contact, ContactAddress>();
                Map<String, Integer> addressFrequency = new Map<String, Integer>();
                Map<String, Double> addressHighestGiver = new Map<String, Double>();
                Map<String, ContactAddress> uniqueContactAddress = new Map<String, ContactAddress>();

                //build the list of new address__c objects that are present and grab some stats to
                //determine the default address.  First frequency, then total giving amount
                for (Contact c : conList){
                    ContactAddress cadd = new ContactAddress(c);
                    if (cadd.hasAddress()){
                        HHaddresses.put(c, cadd);
                        uniqueContactAddress.put(cadd.getMD5(), cadd);

                        if (!addressFrequency.containsKey(cadd.getMD5()))
                            addressFrequency.put(cadd.getMD5(),1);
                        else{
                            Integer addrCount = addressFrequency.get(cadd.getMd5());
                            addrCount++;
                            addressFrequency.put(cadd.getMD5(), addrCount);
                        }

                        if (!addressHighestGiver.containsKey(cadd.getMD5()))
                            addressHighestGiver.put(cadd.getMD5(), c.npo02__TotalOppAmount__c);
                        else{
                            Double OppTotal = addressHighestGiver.get(cadd.getMD5());
                            if (c.npo02__TotalOppAmount__c > OppTotal)
                                addressHighestGiver.put(cadd.getMD5(), c.npo02__TotalOppAmount__c);
                        }
                    }
                    else
                        HHaddresses.put(c, null);
                }

                //loop through the unique addresses create address objects and determine the master address
                Boolean hasDefaultAddr = false;
                Integer addresscount = uniqueContactAddress.keySet().size();
                Integer counter = 0;
                String masteraddresshash = '';
                
                for (String MD5Hash : uniqueContactAddress.keySet()){
                    ContactAddress cadd = uniqueContactAddress.get(MD5Hash);
                    counter ++;
                    //is this the top address in this household?
                    
                    if (!hasDefaultAddr){
                        //first try address frequency
                        Integer addCount = addressFrequency.get(MD5Hash);
                        for (Integer i : addressFrequency.values()){
                            if(addCount > i)
                                hasDefaultAddr = true;
                            else
                                hasDefaultAddr = false;
                        }
                        //if we can't determine based on the frequency, try the largest giver
                        if(!hasDefaultAddr){
                            Double giverAmount = addressHighestGiver.get(MD5Hash);
                            for (Double d : addressHighestGiver.values()){
                                if (giverAmount > d)
                                    hasDefaultAddr = true;
                                else
                                    hasDefaultAddr = false;
                            }
                        }
                    }
                    
                    //finally, if this is the last address adn we still don't have a default, use this one
                    if(!hasDefaultAddr && counter == addresscount)
                        hasDefaultAddr = true;
                        
                        Address__c a = new Address__c(
                                            MailingStreet__c = cadd.MailingStreet,
                                            MailingState__c = cadd.MailingState,
                                            MailingPostalCode__c = cadd.MailingZip,
                                            MailingCountry__c = cadd.MailingCountry,
                                            MailingCity__c = cadd.MailingCity,
                                            Default_Address__c = (hasDefaultAddr ? true : false),
                                            Address_Type__c = cadd.contact.npe01__Primary_Address_Type__c,
                                            Household_Account__c = cadd.contact.AccountId
                                            );

                    if (hasDefaultAddr){
                        masteraddresshash = MD5Hash;
                        addressesForInsert.put(cadd.contact.AccountId, a);
                    }
                    else
                        addressesForInsert.put(cadd.contact.Id, a);
                }

                //set the household address fields to the default address values
                ContactAddress masteraddress = uniqueContactAddress.get(masteraddresshash);
                Account a = con2Account.get(masteraddress.contact.Id);
                a.BillingStreet = masteraddress.MailingStreet;
                a.BillingCity = masteraddress.MailingCity;
                a.BillingPostalCode = masteraddress.MailingZip;
                a.BillingCountry = masteraddress.MailingCountry;
                a.BillingState = masteraddress.MailingState;
                hhAccountsForUpdate.add(a);

                //set any non-addressed contacts to the default address
                for (Contact c : HHaddresses.keySet()){
                    ContactAddress ca = HHAddresses.get(c);
                    if (!ca.hasAddress()){
                        c.MailingStreet = masteraddress.MailingStreet;
                        c.MailingState = masteraddress.MailingState;
                        c.MailingPostalCode = masteraddress.MailingZip;
                        c.MailingCountry = masteraddress.MailingCountry;
                        c.MailingCity = masteraddress.MailingCity;
                        consForUpdate.add(c);
                    }
                }
            }//close else
        }//close for household

        if (consForUpdate.size() > 1) update consForUpdate;
        if (addressesForInsert.values().size() > 1) insert addressesForInsert.values();
        if (hhAccountsForUpdate.size() > 1) update hhAccountsForUpdate;

        consForUpdate.clear();

        //set the lookup value and address override box on each contact for the address its current using
        //this has to happen after the other inserts as we need the address IDs for the lookups
        for (Id accountId : consWithNewHousehold.keySet()){
            List<Contact> conList = consWithNewHousehold.get(accountId);
            for (Contact c : conList){
                //This Contact ID is not in the 'unique address' list, so set it to the hh address
                if (!addressesForInsert.containsKey(c.id)){
                    c.Current_Address__c = addressesForInsert.get(accountId).Id;
                    consForUpdate.add(c);
                }

                //this contact address is not hte master address, associate contact with other address and set override
                else{
                    c.Current_Address__c = addressesForInsert.get(c.Id).Id;
                    c.is_Address_Override__c = true;
                    consForUpdate.add(c);
                }
            }
        }

        //update the contacts with the correct address lookup
        if (consForUpdate.size() > 1) update consForUpdate;

    }//close execute method

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
            this.contact = c;
            this.MailingStreet = c.MailingStreet;
            this.MailingCity = c.MailingCity;
            this.MailingState = c.MailingState;
            this.MailingZip = c.MailingPostalCode;
            this.MailingCountry = c.MailingCountry;
            this.AddressBlob = Blob.valueOf(c.MailingStreet + c.MailingCity + c.MailingState + c.MailingPostalCode + c.MailingCountry);
        }

        public Contact contact;
        public String MailingStreet;
        public String MailingCity;
        public String MailingState;
        public String MailingZip;
        public String MailingCountry;
        private Blob AddressBlob;
        private String MD5;

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

        public String getMD5(){
            if (MD5 != null){
                return MD5;
            }
            else{
                Blob MD5Hash;
                MD5Hash = System.Crypto.generateDigest('MD5', AddressBlob);
                MD5 = MD5Hash.toString();
                return MD5;
            }
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