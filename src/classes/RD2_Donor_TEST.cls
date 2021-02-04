/*
    Copyright (c) 2019 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
* @author Salesforce.org
* @date 2019
* @group Recurring Donations
* @description Recurring Donations Donor record and gateway tests
*
*/
@isTest(IsParallel=true)
public with sharing class RD2_Donor_TEST {

    /***
    * @description Verifies Donor fields are set correctly based on the Account data
    */
    @isTest
    private static void shouldSetDonorWhenAccountDataIsProvided() {
        Account acc = new Account(
            Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType),
            Name = CAO_Constants.OCR_DONOR_ROLE,
            RecordTypeId = RD2_NamingService.hhRecordTypeId
        );
        RD2_Donor.Record donor = new RD2_Donor.Record(acc.Id, acc.Name, acc.RecordTypeId);

        System.assertEquals(acc.Id, donor.recordId, 'Donor Id should match');
        System.assertEquals(acc.Name, donor.Name, 'Donor Name should match');
        System.assertEquals(acc.RecordTypeId, donor.recordTypeId, 'Donor Record Type Id should match');
    }

    /***
    * @description Verifies Donor Name is set correctly based on the Contact data
    */
    @isTest
    private static void shouldSetDonorWhenContactDataIsProvided() {
        Contact contact = new Contact(
            Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType),
            FirstName = 'Jane',
            LastName = 'Smith'
        );
        RD2_Donor.Record donor = new RD2_Donor.Record(contact.Id, contact.FirstName + ' ' + contact.LastName);

        System.assertEquals(contact.Id, donor.recordId, 'Donor Id should match');
        System.assertEquals(contact.FirstName + ' ' + contact.LastName, donor.Name, 'Donor Name should match');
    }

    /***
    * @description Verifies Donor (Account/Contact) names are queried
    * in order to construct the Recurring Donation name
    */
    @isTest
    private static void shouldReturnReferencedAccountsAndContactsAsDonors() {
        List<Account> accounts = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(2, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
        insert accounts;

        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        insert contacts;

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            new TEST_RecurringDonationBuilder()
                .withAccount(accounts[0].Id)
                .withContact(contacts[0].Id)
                .withAmount(100)
                .build(),
            new TEST_RecurringDonationBuilder()
                .withContact(contacts[1].Id)
                .withAmount(100)
                .build()
        };

        RD2_Donor.Gateway donorGateway = new RD2_Donor.Gateway();
        Map<Id, RD2_Donor.Record> donors = donorGateway.getDonors(rds);

        System.assertEquals(3, donors.size(), 'Donors should be returned: ' + donors);
        System.assertEquals(false, donors.containsKey(accounts[1].Id), 'Donors should not include Account not referenced by an RD');
    }



    /***
    * @description Mock for the Donor Gateway instance returning donors
    */
    public class GatewayMock implements RD2_Donor.IGateway {
        private Map<Id, RD2_Donor.Record> donorById = new Map<Id, RD2_Donor.Record>();

        /***
        * @description Specifies Account records to return as donor data
        * @param accounts Account records
        * @return GatewayMock Mock Donor Gateway instance
        */
        public GatewayMock withDonors(List<Account> accounts) {
            for (Account acc : accounts) {
                donorById.put(acc.Id, new RD2_Donor.Record(acc.Id, acc.Name, acc.RecordTypeId));
            }
            return this;
        }

        /***
        * @description Specifies Contact records to return as donor data
        * @param contacts Contact records
        * @return GatewayMock Mock Donor Gateway instance
        */
        public GatewayMock withDonors(List<Contact> contacts) {
            for (Contact c : contacts) {
                String contactName = (String.isBlank(c.FirstName) ? '' : c.FirstName + ' ') + c.LastName;

                donorById.put(c.Id, new RD2_Donor.Record(c.Id, contactName));
            }
            return this;
        }

        /***
        * @description Returns donor data for the specified Recurring Donation records
        * @param rds Recurring Donation records
        * @return Map<Id, RD2_Donor.Record> Donors by Id
        */
        public Map<Id, RD2_Donor.Record> getDonors(List<npe03__Recurring_Donation__c> rds) {
            return donorById;
        }
    }

}