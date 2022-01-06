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
    * @description Method to generate Filter rules.
    */
    static void generateFilterRules() {
        String filterGroupId = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupsJSON = '[' + CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId, 'TestFilterGroup') + ']';
        String filterRulesJSON = '[' +
                CMT_UnitTestData_TEST.createFilterRuleRecord(null, filterGroupId,
                        'NPSP_OppsSoftCreditRoles',
                        'Partial_Soft_Credit__c',
                        'Role_Name__c',
                        'In List',
                        'Matched Donor;Soft Credit;Household Member') + ']';
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(
                filterGroupsJSON, List<Filter_Group__mdt>.class);
    
        CMT_FilterRule_SEL.cachedFilterRules = (List<Filter_Rule__mdt>)JSON.deserialize(
                filterRulesJSON, List<Filter_Rule__mdt>.class);
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Method to generate test data.
    */
    @TestSetup
    static void makeData() {
        Date myDateTime = Date.newInstance(2020, 2, 2);

        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 3, 1);
        Account accSrc = UTIL_UnitTestData_TEST.listAccT[0];
        list<Contact> listConSrc = UTIL_UnitTestData_TEST.listConT; 

        Opportunity opportunityHardCredit = new Opportunity(
            Name='HardCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );
        Opportunity opportunitySoftCredit = new Opportunity(
            Name='SoftCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[1].Id, 
            Amount=200, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );
        Opportunity opportunityPartialSoftCredit = new Opportunity(
            Name='PartialSoftCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[1].Id, 
            Amount=150, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );
        Opportunity opportunityInfluencer = new Opportunity(
            Name='InfluencerOpportunity', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[1].Id, 
            Amount=150,
            StageName='Closed Won', 
            CloseDate=myDateTime
        );
        List<Opportunity> recordsOpp = new List<Opportunity>();
        recordsOpp.add(opportunityHardCredit);
        recordsOpp.add(opportunitySoftCredit);
        recordsOpp.add(opportunityPartialSoftCredit);
        recordsOpp.add(opportunityInfluencer);
        insert recordsOpp;

        OpportunityContactRole oppCntRoleSoftCredit = new OpportunityContactRole(
            Role='Soft Credit', 
            OpportunityId=opportunitySoftCredit.Id, 
            ContactId=listConSrc[0].Id, 
            isPrimary=false
        );
        OpportunityContactRole oppCntRolePartialSoftCredit = new OpportunityContactRole(
            Role='Soft Credit', 
            OpportunityId=opportunityPartialSoftCredit.Id, 
            ContactId=listConSrc[0].Id, 
            isPrimary=false
        );
        OpportunityContactRole oppCntRoleInfluencerCredit = new OpportunityContactRole(
            Role='Influencer', 
            OpportunityId=opportunityInfluencer.Id, 
            ContactId=listConSrc[0].Id, 
            isPrimary=false
        );
        List<OpportunityContactRole> recordsOcr = new List<OpportunityContactRole>();
        recordsOcr.add(oppCntRoleSoftCredit);
        recordsOcr.add(oppCntRolePartialSoftCredit);
        recordsOcr.add(oppCntRoleInfluencerCredit);
        insert recordsOcr;

        Partial_Soft_Credit__c partialSoftCredit = new Partial_Soft_Credit__c (
            Amount__c=50,
            Contact__c=listConSrc[0].Id,
            Opportunity__c=opportunityPartialSoftCredit.Id,
            Contact_Role_ID__c=oppCntRolePartialSoftCredit.Id
        );
        insert partialSoftCredit;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Method to test that the results are returned correctly
    */
    @IsTest
    private static void shouldReturnExpectedDonationHistoryResult() {
        generateFilterRules();
        Contact testContact = [
            SELECT
                Id
            FROM Contact
            WHERE FirstName = 'TestFirstName10'
            LIMIT 1
        ];        
        Boolean influencer = false;
        Boolean role = false;
        Test.startTest();
        List<DonationHistoryController.DonationHistoryView> donationHistory = 
        DonationHistoryController.getDonationHistory(testContact.Id);
        Test.stopTest();

        for(DonationHistoryController.DonationHistoryView donation : donationHistory){
            if(donation.role == 'Influencer'){
                influencer = true;
            }
            if(donation.role != 'Soft Credit' && donation.role != 'Donor'){
                role = true;
            }
        }
        System.assertEquals(false, influencer, 'Must not have an influencer role');
        System.assertEquals(false, role, 'Roles must be Soft credit or Donor');
        System.assertEquals(3, donationHistory.size(), 'Should return only 3 records');
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Method to test case in which data should not be returned.
    */
    @IsTest
    private static void shouldNotReturnDonationHistory() {
        generateFilterRules();
        Contact testContact = [
            SELECT
                Id
            FROM Contact
            WHERE FirstName = 'TestFirstName12'
            LIMIT 1
        ];
        
        Test.startTest();
        List<DonationHistoryController.DonationHistoryView> donationHistory = 
        DonationHistoryController.getDonationHistory(testContact.Id);
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
        generateFilterRules();
        User u = UTIL_UnitTestData_TEST.createUser('Minimum Access - Salesforce');
        Contact testContact = [
            SELECT
            Id
            FROM Contact
            WHERE FirstName = 'TestFirstName10'
            LIMIT 1
        ];    
        String message = '';
        try{
            Test.startTest();
            System.runAs(u){
                List<DonationHistoryController.DonationHistoryView> donationHistory = 
                DonationHistoryController.getDonationHistory(testContact.Id); 
            }
	        Test.stopTest();
        } catch(Exception e){
            message = e.getMessage();
        }
        System.assertEquals('Insufficient Permissions', message, 'should not have access to donationHistory');
    }
}