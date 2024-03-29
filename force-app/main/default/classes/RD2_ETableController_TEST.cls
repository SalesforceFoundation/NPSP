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
* @group Donation
* @description Unit Test Class for test the recurring donations controller and selector.
*/
@IsTest
public class RD2_ETableController_TEST {
    
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final String ALL_RD = 'All Recurring Donations';

    /**
    * @author Salesforce.org
    * @date 2022
    * @description Method to test that the results are returned correctly
    */
    @IsTest
    private static void testGetData() {
        
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        
        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        npe03__Recurring_Donation__c rDonation01 = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                                                                                .withContact(con.Id)
                                                                                .withAmount(100)
                                                                                .withDefaultValues()
                                                                                .withInstallmentPeriodMonthly()
                                                                                .withDayOfMonth('21')
                                                                                .withInstallmentFrequency(1)
                                                                                .build();

        npe03__Recurring_Donation__c rDonation02 = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                                                                                .withContact(con.Id)
                                                                                .withAmount(100)
                                                                                .withDefaultValues()
                                                                                .withInstallmentPeriodYearly()
                                                                                .withDayOfMonth('22')
                                                                                .withInstallmentFrequency(1)
                                                                                .build();

        npe03__Recurring_Donation__c rDonation03 = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                                                                                .withContact(con.Id)
                                                                                .withAmount(100)
                                                                                .withDefaultValues()
                                                                                .withInstallmentPeriod('1st and 15th')
                                                                                .withDayOfMonth('23')
                                                                                .withInstallmentFrequency(1)
                                                                                .build();

        npe03__Recurring_Donation__c rDonation04 = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                                                                                .withContact(con.Id)
                                                                                .withAmount(100)
                                                                                .withDefaultValues()
                                                                                .withInstallmentPeriodMonthly()
                                                                                .withDayOfMonth('24')
                                                                                .withInstallmentFrequency(2)
                                                                                .withStatus(RD2_Constants.STATUS_PAUSED)
                                                                                .build();

        npe03__Recurring_Donation__c rDonation05 = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                                                                                .withContact(con.Id)
                                                                                .withAmount(100)
                                                                                .withDefaultValues()
                                                                                .withInstallmentPeriodYearly()
                                                                                .withDayOfMonth('23')
                                                                                .withInstallmentFrequency(2)
                                                                                .withStatus(RD2_Constants.STATUS_CLOSED)
                                                                                .build();

        npe03__Recurring_Donation__c rDonation06 = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                                                                                .withContact(con.Id)
                                                                                .withAmount(100)
                                                                                .withDefaultValues()
                                                                                .withInstallmentPeriodWeekly()
                                                                                .withDayOfMonth('23')
                                                                                .withInstallmentFrequency(2)
                                                                                .build();

        List<SObject> records = new List<SObject> {rDonation01,rDonation02,rDonation03,rDonation04,rDonation05,rDonation06};
        RecurringDonationsSelectorMock mock = new RecurringDonationsSelectorMock(records);
        RD2_ETableController.selector = (RD2_ERecurringDonationsSelector) Test.createStub(RD2_ERecurringDonationsSelector.class, mock);
       
        Test.startTest();
        List<RD2_ETableController.TableView> result = RD2_ETableController.retrieveTableView(RD2_ETableController_TEST.ALL_RD);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Recurring Donations should not be null');
    }

    public class RecurringDonationsSelectorMock implements System.StubProvider{
        
        private SObject[] objectsToReturn;
        
        public RecurringDonationsSelectorMock(SObject[] objectToReturn) {
            this.objectsToReturn = objectToReturn;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
        Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
        List<Object> listOfArgs) {

            if (stubbedMethodName.equals('getRecurringDonations')) {
                return objectsToReturn;
            }
            return objectsToReturn;
        }
    }
}
