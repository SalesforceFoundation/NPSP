/*
    Copyright (c) 2022 Salesforce.org
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
* @description Donations tests.
*/
@IsTest
private class Donations_TEST {

    @IsTest
    static void shouldReturn3OpenDonationsForContactDonor() {
        // Arrange:
        Id dummyContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        DonationSelectorMock donationSelectorMock = new DonationSelectorMock(new List<Opportunity> {
            new Opportunity(),
            new Opportunity(),
            new Opportunity()
        });
        Donations donations = new Donations(dummyContactId, stubFor(donationSelectorMock));

        // Act:
        List<Donation> openDonationsForDummyContact = donations.all();

        // Assert:
        System.assertEquals(3, openDonationsForDummyContact.size(),
            'Should return 3 open donations for contact donor');
    }

    @IsTest
    static void shouldReturn5OpenDonationsForForAccountDonor() {
        // Arrange:
        Id dummyAccountId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);
        DonationSelectorMock donationSelectorMock = new DonationSelectorMock(new List<Opportunity> {
            new Opportunity(),
            new Opportunity(),
            new Opportunity(),
            new Opportunity(),
            new Opportunity()
        });
        Donations donations = new Donations(dummyAccountId, stubFor(donationSelectorMock));

        // Act:
        List<Donation> openDonationsForDummyAccount = donations.all();

        // Assert:
        System.assertEquals(5, openDonationsForDummyAccount.size(),
            'Should return 5 open donations for account donor');
    }

    @IsTest
    static void shouldReturnDonationsForGivenOpportunities() {
        // Arrange:
        List<Id> dummyOpportunityIds = new List<Id> {
            UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType)
        };
        DonationSelectorMock donationSelectorMock = new DonationSelectorMock(new List<Opportunity> {
            new Opportunity(Id = dummyOpportunityIds[0]),
            new Opportunity(Id = dummyOpportunityIds[1]),
            new Opportunity(Id = dummyOpportunityIds[2])
        });
        Donations donations = new Donations(dummyOpportunityIds, stubFor(donationSelectorMock));

        // Act:
        List<Donation> donationsForDummyOpportunities = donations.all();

        // Assert:
        System.assertEquals(3, donationsForDummyOpportunities.size(),
            'Should return 3 donations for the provided opportunities');
    }

    @IsTest
    static void shouldReturnDonationForGivenGift() {
        // Arrange:
        List<Id> dummyOpportunityIds = new List<Id> {
            UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType)
        };
        DonationSelectorMock donationSelectorMock = new DonationSelectorMock(new List<Opportunity> {
            new Opportunity(Id = dummyOpportunityIds[0], Amount = 100),
            new Opportunity(Id = dummyOpportunityIds[1], Amount = 200),
            new Opportunity(Id = dummyOpportunityIds[2], Amount = 300)
        });
        DataImport__c dummyDataImport = new DataImport__c(DonationImported__c = dummyOpportunityIds[1]);
        Donations donations = new Donations(dummyOpportunityIds, stubFor(donationSelectorMock));

        // Act:
        Donation secondDonation = donations.getDonationFor(dummyDataImport);

        // Assert:
        System.assertEquals(200, secondDonation.opportunity().Amount,
            'Should return 200 as the amount for the second donation');
        System.assertEquals(dummyOpportunityIds[1], secondDonation.opportunity().Id,
            'Should return the second opportunity id');
    }

    @IsTest
    static void shouldNotReturnDonationForNonExistantGift() {
        // Arrange:
        List<Id> dummyOpportunityIds = new List<Id> {
            UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType)
        };
        DonationSelectorMock donationSelectorMock = new DonationSelectorMock(new List<Opportunity> {
            new Opportunity(Id = dummyOpportunityIds[0], Amount = 100)
        });
        DataImport__c dummyDataImport = new DataImport__c(
            DonationImported__c = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType)
        );
        Donations donations = new Donations(dummyOpportunityIds, stubFor(donationSelectorMock));

        // Act:
        Donation nonExistantDonation = donations.getDonationFor(dummyDataImport);

        // Assert:
        System.assertEquals(null, nonExistantDonation,
            'Should be null for non-existant donation');
    }

    private class DonationSelectorMock implements StubProvider {

        private List<Opportunity> opportunitiesToReturn;
        
        public DonationSelectorMock(List<Opportunity> opportunities) {
            this.opportunitiesToReturn = opportunities;
        }

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'getOpenDonations' {
                    return opportunitiesToReturn;
                }
                when 'getDonation' {
                    return opportunitiesToReturn;
                }
                when 'getDonations' {
                    return opportunitiesToReturn;
                }
            }

            return null;
        }
    }

    private static DonationSelector stubFor(DonationSelectorMock donationSelectorMock) {
        return (DonationSelector) Test.createStub(
            DonationSelector.class,
            donationSelectorMock
        );
    }
}
