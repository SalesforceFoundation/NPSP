/*
    Copyright (c) 2021, Salesforce.org
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
* @group Donation
* @description Class for test list donation history controller.
*/
@IsTest
public class DonationHistoryController_TEST {
    

    /**
    * @author Salesforce.org
    * @date 2021
    * @description Method to test that the results are returned correctly
    */
    @IsTest
    private static void shouldReturnExpectedDonationHistoryResult() {
        Date myDateTime = Date.newInstance(2020, 2, 2);
        Date dateTimeInPast = Date.newInstance(2019, 2, 2);

        IdGen gen = new IdGen();
        Opportunity opportunityHardCreditOfContact0 = new Opportunity(
            Name = 'HardCredit1', 
            AccountId = gen.generate(Account.SObjectType),
            Primary_Contact__c= gen.generate(Contact.SObjectType), 
            Amount = 400, 
            StageName = 'Closed Won', 
            CloseDate = myDateTime
        );

        Opportunity opportunityAnotherHardCreditOfContact0 = new Opportunity(
            Name = 'HardCredit2', 
            AccountId = gen.generate(Account.SObjectType), 
            Primary_Contact__c = gen.generate(Contact.SObjectType), 
            Amount = 400, 
            StageName = 'Closed Won', 
            CloseDate = dateTimeInPast
        );

        List<SObject> records = new List<SObject> {opportunityHardCreditOfContact0, opportunityAnotherHardCreditOfContact0};
        DonationHistorySelectorMock mock = new DonationHistorySelectorMock(records, null, null);
        DonationHistoryService service = new DonationHistoryService();
        service.selector = (DonationHistorySelector) Test.createStub(DonationHistorySelector.class, mock);

        DonationHistoryController.historyService = service;
        Test.startTest();

        DonationHistoryController.DonationHistoryAppView donationHistory = 
            DonationHistoryController.getDonationHistory(new IdGen().generate(Contact.SObjectType), 0, 'lifetime');
        Test.stopTest();

        System.debug(donationHistory);
        System.assertEquals(2, donationHistory.donations.size(), 'Should return only 2 record');
    }

    /**
    * @author Salesforce.org
    * @date 2021
    * @description Method to test validation of user permissions.
    */
    @IsTest
    private static void shouldThrowAccessException() {
        User standardUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);

        String message = '';
        try{
            DonationHistorySelectorMock mock = new DonationHistorySelectorMock(null, null, null);
            DonationHistoryService service = new DonationHistoryService();
            service.selector = (DonationHistorySelector) Test.createStub(DonationHistorySelector.class, mock);

            DonationHistoryController.historyService = service;
            Test.startTest();

            System.runAs(standardUser){
                DonationHistoryController.DonationHistoryAppView donationHistory = 
                DonationHistoryController.getDonationHistory(new IdGen().generate(Contact.getSObjectType()), 0, 'lifetime'); 
            }
	        Test.stopTest();

        } catch(Exception e){
            message = e.getMessage();
        }
        System.assertEquals(Label.commonInsufficientPermissions, message, 'should not have access to donationHistory');
    }
    
    @IsTest
    private static void shouldReturnOneElementFor2019(){
        
        Date myDateTime = Date.newInstance(2020, 2, 2);
        Date dateTimeInPast = Date.newInstance(2019, 2, 2);
        IdGen gen = new IdGen();

        Opportunity opportunityHardCreditOfContact0 = new Opportunity(
            Name = 'HardCredit1', 
            AccountId = gen.generate(Account.SObjectType), 
            Primary_Contact__c = gen.generate(Contact.SObjectType), 
            Amount = 400, 
            StageName = 'Closed Won', 
            CloseDate = myDateTime
        );

        List<SObject> records = new List<SObject> {opportunityHardCreditOfContact0};
        DonationHistorySelectorMock mock = new DonationHistorySelectorMock(records, null, null);
        DonationHistoryService service = new DonationHistoryService();
        service.selector = (DonationHistorySelector) Test.createStub(DonationHistorySelector.class, mock);

        DonationHistoryController.historyService = service;       
       
        Test.startTest();
        DonationHistoryController.DonationHistoryAppView donationHistory = DonationHistoryController.getDonationHistory(new IdGen().generate(Contact.SObjectType), 0, '2019');
        Test.stopTest();

        System.assertNotEquals(null, donationHistory, 'Donation History should not be empty');
        System.assertEquals(1, donationHistory.donations.size(), 'donationHistory should contain only one element');
    }

    @isTest
    private static void shouldReturnYearsForFilter(){
        List<String> years = new List<String> {'2020', '2019'};
        DonationHistorySelectorMock mock = new DonationHistorySelectorMock(null, null, years);
        DonationHistoryService service = new DonationHistoryService();
        service.selector = (DonationHistorySelector) Test.createStub(DonationHistorySelector.class, mock);
        DonationHistoryController.historyService = service;

        List<String> donationsYears = DonationHistoryController.getYearsWithDonations(new IdGen().generate(Contact.SObjectType));
        System.assertNotEquals(null, donationsYears, 'donationsYears should not be null');
        System.assertEquals(2, donationsYears.size(), 'donationsYears should have 2 elements');
        System.assertEquals('2020', donationsYears[0], 'donationsYears should be in descendent order');
    }

    
    public class DonationHistorySelectorMock implements System.StubProvider{
        private SObject[] objectsToReturn;
        private Integer totalRecords;
        private List<String> yearsWithDonation;


        public DonationHistorySelectorMock(SObject[] objectToReturn, Integer totalRecords, List<String> yearsWithDonation) {
            this.objectsToReturn = objectToReturn;
            this.totalRecords = totalRecords;
            this.yearsWithDonation = yearsWithDonation;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
        Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
        List<Object> listOfArgs) {

            if (stubbedMethodName.equals('getYearsWithDonationForContact')) {
                return yearsWithDonation;
            }

            if (stubbedMethodName.equals('getTotalNumberOfRecords') || stubbedMethodName.equals('getTotalNumberOfRecordsWithYear')) {
                if (totalRecords != null) {
                    return totalRecords;
                }
                return objectsToReturn.size();
            }
            return objectsToReturn;
        }

    }

    public class IdGen {
        private  Integer fakeIdCount = 0;
        private  final String ID_PATTERN = '000000000000';

        /**
         * Generate a fake Salesforce Id for the given SObjectType
         */
        public Id generate(Schema.SObjectType sobjectType) {
            String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
            fakeIdCount++;

            String fakeIdPrefix = ID_PATTERN.substring(0, 12 - fakeIdCount.format().length());

            return Id.valueOf(keyPrefix + fakeIdPrefix + fakeIdCount);
        }
    }
}