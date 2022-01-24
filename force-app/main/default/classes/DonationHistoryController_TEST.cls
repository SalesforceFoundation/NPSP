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
    * @description Method to generate test data.
    */
    @TestSetup
    static void makeData() {
        Date myDateTime = Date.newInstance(2020, 2, 2);
        Date dateTimeInPast = Date.newInstance(2019, 2, 2);
        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 3, 1);
        Account accSrc = UTIL_UnitTestData_TEST.listAccT[0];
        list<Contact> listConSrc = UTIL_UnitTestData_TEST.listConT; 

        /** 
         * opportunityHardCreditOfContact0 its a hard credit for contact 0. opportunityForContact1, anotherOpportunityForContact1 are related to the same account  which contact 0 is
         * related but they should not appear in the query as they are not hard credit for contact0. They could be soft credit for contact 0 but the entire configuration is not needed
         * for this test purpose.
        */
        Opportunity opportunityHardCreditOfContact0 = new Opportunity(
            Name='HardCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );
        Opportunity opportunityForContact1 = new Opportunity(
            Name='SoftCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[1].Id, 
            Amount=200, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );

        Opportunity anotherOpportunityForContact1 = new Opportunity(
            Name='SoftCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[1].Id, 
            Amount=200, 
            StageName='Closed Won', 
            CloseDate=dateTimeInPast
        );
        
        List<Opportunity> recordsOpp = new List<Opportunity> {opportunityHardCreditOfContact0, opportunityForContact1, anotherOpportunityForContact1};
        insert recordsOpp;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Method to test that the results are returned correctly
    */
    @IsTest
    private static void shouldReturnExpectedDonationHistoryResult() {
        Contact testContact = findContactByFirstname('TestFirstName10');
        
        Test.startTest();
        List<DonationHistoryController.DonationHistoryView> donationHistory = 
            DonationHistoryController.getDonationHistory(testContact.Id, 'lifetime');
        Test.stopTest();

        System.assertEquals(1, donationHistory.size(), 'Should return only 1 record');
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Method to test case in which data should not be returned.
    */
    @IsTest
    private static void shouldNotReturnDonationHistory() {
        Contact testContact = findContactByFirstname('TestFirstName12');
        
        Test.startTest();
        List<DonationHistoryController.DonationHistoryView> donationHistory = 
        DonationHistoryController.getDonationHistory(testContact.Id, 'lifetime');
        Test.stopTest();
        System.assertEquals(0, donationHistory.size(), 'Should not return records');
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Method to test validation of user permissions.
    */
    @IsTest
    private static void shouldThrowAccessException() {
        User u = UTIL_UnitTestData_TEST.createUser('Minimum Access - Salesforce');
        Contact testContact = findContactByFirstname('TestFirstName10');
        String message = '';
        try{
            Test.startTest();
            System.runAs(u){
                List<DonationHistoryController.DonationHistoryView> donationHistory = 
                DonationHistoryController.getDonationHistory(testContact.Id, 'lifetime'); 
            }
	        Test.stopTest();
        } catch(Exception e){
            message = e.getMessage();
        }
        System.assertEquals('Insufficient Permissions', message, 'should not have access to donationHistory');
    }

    @IsTest
    private static void shouldReturnYearsForFilter() {
        Contact thecontact = findContactByFirstname('TestFirstName11');
       
        List<String> donationsYears = DonationHistoryController.getYearsWithDonations(thecontact.id);
        System.assertNotEquals(null, donationsYears, 'donationsYears should not be null');
        System.assertEquals(2, donationsYears.size(), 'donationsYears should have 2 elements');
        System.assertEquals('2020', donationsYears[0], 'donationsYears should be in descendent order');

    }
    
    @IsTest
    private static void shouldReturnOneElementFor2019(){
        
        Contact testContact =findContactByFirstname('TestFirstName11');        
       
        Test.startTest();
        List<DonationHistoryController.DonationHistoryView> donationHistory = DonationHistoryController.getDonationHistory(testContact.Id, '2019');
        Test.stopTest();

        System.assertNotEquals(null, donationHistory, 'Donation History should not be empty');
        System.assertEquals(1, donationHistory.size(), 'donationHistory should contain only one element');
    }

    private static Contact findContactByFirstName(String firstName) {
        for (Contact c : [SELECT ID, Firstname
                          FROM Contact]) {
            if (c.Firstname == firstname) {
                return c;
            }
        }
        return null;
    }
    
}