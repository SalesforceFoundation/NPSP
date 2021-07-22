/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description DonationService tests.
*/
@isTest
private class DonationService_TEST {

    @isTest
    static void shouldReturn2OpenDonationsForDonor() {
        DonationSelectorMock mockedSelector = new DonationSelectorMock();
        DonationService donationService = new DonationService();
        donationService.donationSelector = stubFor(mockedSelector);
        Id DUMMY_ORG_ID = UTIL_UnitTestData_TEST.mockId(Account.getSObjectType());

        DonationsView donationView = donationService.getDonationsView(DUMMY_ORG_ID);

        System.assertEquals(2, donationView.donations.size());
        System.assertEquals(3, donationView.donations[0].unpaidPayments.size());
        System.assertEquals(0, donationView.donations[1].unpaidPayments.size());
    }

    private class DonationSelectorMock implements StubProvider {
        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'getOpenDonations' {
                    Id DUMMY_OPPORTUNITY_ID_0 = UTIL_UnitTestData_TEST.mockId(Opportunity.getSObjectType());
                    Id DUMMY_OPPORUNITY_ID_1 = UTIL_UnitTestData_TEST.mockId(Opportunity.getSObjectType());

                    Account DUMMY_ORGANIZATION_ACCOUNT = UTIL_UnitTestData_TEST.buildOrganizationAccount();
                    DUMMY_ORGANIZATION_ACCOUNT.Id = UTIL_UnitTestData_TEST.mockId(Account.getSObjectType());

                    List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c> {
                        new npe01__OppPayment__c(
                            npe01__Paid__c=false,
                            npe01__Written_Off__c=false,
                            npe01__Opportunity__c=DUMMY_OPPORTUNITY_ID_0
                        ),
                        new npe01__OppPayment__c(
                            npe01__Paid__c=false,
                            npe01__Written_Off__c=false,
                            npe01__Opportunity__c=DUMMY_OPPORTUNITY_ID_0
                        ),
                        new npe01__OppPayment__c(
                            npe01__Paid__c=false,
                            npe01__Written_Off__c=false,
                            npe01__Opportunity__c=DUMMY_OPPORTUNITY_ID_0
                        )
                    };

                    List<Opportunity> opps = new List<Opportunity> {
                        new Opportunity(
                            Id=DUMMY_OPPORTUNITY_ID_0,
                            Name='Dummy Opp',
                            StageName=UTIL_UnitTestData_TEST.getOpenStage(),
                            Amount=1,
                            CloseDate=Date.today(),
                            AccountId=DUMMY_ORGANIZATION_ACCOUNT.Id
                        ),
                        new Opportunity(
                            Id=DUMMY_OPPORUNITY_ID_1,
                            Name='Dummy Opp',
                            StageName=UTIL_UnitTestData_TEST.getOpenStage(),
                            Amount=2,
                            CloseDate=Date.today(),
                            AccountId=DUMMY_ORGANIZATION_ACCOUNT.Id
                        )
                    };

                    Opportunity oppsWithChildPayments = mockRelationshipFor(opps[0], payments);
                    opps[0] = oppsWithChildPayments;

                    return opps;
                }
            }

            return null;
        }
    }

    private static DonationSelector stubFor(DonationSelectorMock donationSelectorMock) {
        return (DonationSelector) Test.createStub(DonationSelector.class, donationSelectorMock);
    }

    private static Opportunity mockRelationshipFor(
        Opportunity parentOpportunity,
        List<npe01__OppPayment__c> childPayments) {

            String parentJSON = JSON.serialize(parentOpportunity);
            String childPaymentsJSON = '"npe01__OppPayment__r": {'
                + '"totalSize": ' + childPayments.size() + ', '
                + '"done": true,'
                + '"records": ' + JSON.serialize(childPayments)
                + '}';

            parentJSON = parentJSON.substring(0, parentJSON.length() - 1)
                + ','
                + childPaymentsJSON
                + '}';

            return (Opportunity) JSON.deserialize(parentJSON, Opportunity.class);
    }
}
