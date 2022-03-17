/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Recurring Donations
* @description Test class for RD2_SustainerEvaluationService
*/
@IsTest
private with sharing class RD2_SustainerEvaluationService_TEST {
    @IsTest
    private static void verifyContactWithActiveRDShouldSetSustainerToActive() {
        npe03__Recurring_Donation__c activeRd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusActive()
            .build();

        npe03__Recurring_Donation__c lapsedRd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusLapsed()
            .build();

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            activeRd, lapsedRd
        };

        Contact contactRecord = TEST_ContactBuilder.dummyContactWithRecurringDonation(rds);
        RD2_QueryService queryServiceStub = (RD2_QueryService)Test.createStub(
            RD2_QueryService.class,
            new RD2_QueryServiceMock(new List<Contact>{contactRecord}, null, null)
        );
        RD2_SustainerEvaluationService.queryService = queryServiceStub;

        Test.startTest();
        List<Contact> result = new RD2_SustainerEvaluationService()
            .withRecurringDonations(rds)
            .getContactsWithSustainerChanged();
        Test.stopTest();

        System.assertEquals(contactRecord.Id, result[0].Id, 'The expected Contact should be returned');
        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Active.name(), result[0].Sustainer__c,
        'Contact Sustainer should be set to Active when there is at least 1 Active RD on the Contact');
    }

    @IsTest
    private static void verifyContactWithLapsedRDShouldSetSustainerToLapsed() {
        npe03__Recurring_Donation__c lapsedRd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusLapsed()
            .build();

        npe03__Recurring_Donation__c closedRd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusClosed()
            .build();

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            lapsedRd, closedRd
        };

        Contact contactRecord = TEST_ContactBuilder.dummyContactWithRecurringDonation(rds);
        RD2_QueryService queryServiceStub = (RD2_QueryService)Test.createStub(
            RD2_QueryService.class,
            new RD2_QueryServiceMock(
                TEST_ContactBuilder.dummyContactListWithIds(),
                new List<Contact>{contactRecord},
                TEST_ContactBuilder.dummyContactListWithIds()
            )
        );
        RD2_SustainerEvaluationService.queryService = queryServiceStub;

        Test.startTest();
        List<Contact> result = new RD2_SustainerEvaluationService()
            .withRecurringDonations(rds)
            .getContactsWithSustainerChanged();
        Test.stopTest();

        System.assertEquals(contactRecord.Id, result[0].Id, 'The expected Contact should be returned');
        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Lapsed.name(), result[0].Sustainer__c,
        'Contact Sustainer should be set to Lapsed when there is at least 1 Lapsed RD on the Contact');
    }

    @IsTest
    private static void verifyContactWithOnlyClosedRDShouldSetSustainerToFormer() {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusClosed()
            .build()
        };

        List<Contact> contactList = new List<Contact>{TEST_ContactBuilder.dummyContactWithRecurringDonation(rds)};
        RD2_QueryService queryServiceStub = (RD2_QueryService)Test.createStub(
            RD2_QueryService.class,
            new RD2_QueryServiceMock(TEST_ContactBuilder.dummyContactListWithIds(),TEST_ContactBuilder.dummyContactListWithIds(), contactList)
        );
        RD2_SustainerEvaluationService.queryService = queryServiceStub;

        Test.startTest();
        List<Contact> result = new RD2_SustainerEvaluationService()
            .withContacts(contactList)
            .getContactsWithSustainerChanged();
        Test.stopTest();

        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Former.name(), result[0].Sustainer__c,
        'Contact Sustainer should be set to Former when there is at least 1 Former RD on the Contact');
    }

    public class RD2_QueryServiceMock implements StubProvider {
        List<Contact> contactsWithActiveRd;
        List<Contact> contactsWithLapsedRd;
        List<Contact> contactsWithClosedRd;

        public RD2_QueryServiceMock(List<Contact> contactsWithActiveRd, List<Contact> contactsWithLapsedRd, List<Contact> contactsWithClosedRd) {
            this.contactsWithActiveRd = contactsWithActiveRd;
            this.contactsWithLapsedRd = contactsWithLapsedRd;
            this.contactsWithClosedRd = contactsWithClosedRd;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            switch on stubbedMethodName {
                when 'getSObjectWithActiveRecurringDonations' {
                    return contactsWithActiveRd;
                }
                when 'getSObjectWithLapsedRecurringDonations' {
                    return contactsWithLapsedRd;
                }
                when 'getSObjectWithClosedRecurringDonations' {
                    return contactsWithClosedRd;
                }

            }
            return null;
        }
    }
}
