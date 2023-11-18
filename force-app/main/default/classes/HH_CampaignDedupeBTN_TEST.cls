/*
    Copyright (c) 2011, Salesforce.org
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
* @date 2011 (2.3)
* @group Households
* @description test class for the campaign dedupe button from the campaign record
*/
@isTest
private class HH_CampaignDedupeBTN_TEST {

    /**
     * @description Create the Campaign and the two default CampaignMemberStatus values. Normally Salesforce will
     * auto-create the Sent/Received records in the CampaignMemberStatus object, however that doesn't happen in
     * a Unit Test.
     */
    @TestSetup
    private static void testDataSetup() {
        Campaign camp = new Campaign (
            Name = 'MyCampaign',
            Status = 'Planned',
            IsActive = true
        );
        insert camp;

        List<CampaignMemberStatus> campStatuses = new List<CampaignMemberStatus>{
            new CampaignMemberStatus(
                Label = Label.CampaignMemberStatusNonResponded,
                SortOrder = 10,
                IsDefault = true,
                HasResponded = false,
                CampaignId = camp.Id
            ),
            new CampaignMemberStatus(
                Label = Label.CampaignMemberStatusResponded,
                SortOrder = 20,
                IsDefault = false,
                HasResponded = true,
                CampaignId = camp.Id
            )
        };
        insert campStatuses;
    }

    /*******************************************************************************************************
    * @description test the Campaign Dedupe controller
    * @return voId
    ********************************************************************************************************/
    private static testMethod void shouldValidateDuplicateHouseholdCampaignMembers(){
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
            npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
            npo02__Always_Rollup_to_Primary_Contact__c = false,
            npo02__Enable_Opp_Rollup_Triggers__c = true,
            npo02__Excluded_Account_Opp_Rectypes__c = null,
            npo02__Excluded_Account_Opp_Types__c = null,
            npo02__Excluded_Contact_Opp_Rectypes__c = null,
            npo02__Excluded_Contact_Opp_Types__c = null,
            npo02__Membership_Record_Types__c = null,
            npo02__Use_Fiscal_Year_for_Rollups__c = true,
            npo02__Rollup_N_Day_Value__c = 10,
            npo02__Household_Mailing_List_ID__c = '0000000'
        ));

        // create test data
        Account acct = new Account (
            Name='Test Account'
        );
        insert acct;

        Contact con = new Contact (
            FirstName='Kevin',
            LastName='Test',
            AccountId = acct.Id,
            npo02__TotalOppAmount__c = 100
        );
        insert con;

        Id hhId = [SELECT npo02__Household__r.Id FROM Contact WHERE Id = :con.Id].npo02__Household__c;
        System.assert(hhId != null);

        Contact con2 = new Contact (
            FirstName = 'Amy',
            LastName = 'Test',
            AccountId = acct.Id,
            npo02__Household__c = hhId
        );
        insert con2;
        System.assert(con2.npo02__Household__c != null);

        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];

        System.assertEquals(2, [SELECT Count() FROM CampaignMemberStatus],
            [SELECT Label, HasResponded FROM CampaignMemberStatus]
        );

        final String sentStatus =
            [SELECT Label
                FROM CampaignMemberStatus
                WHERE CampaignId = :camp.Id
                AND HasResponded = false LIMIT 1].Label;
        final String rcvdStatus =
            [SELECT Label
                FROM CampaignMemberStatus
                WHERE CampaignId = :camp.Id
                AND HasResponded = true LIMIT 1].Label;

        // Two contacts in the same household adding to the same campaign
        List<CampaignMember> campMembers = new List<CampaignMember>{
            new CampaignMember(
                CampaignId = camp.Id,
                ContactId = con.Id,
                Status = sentStatus
            ),
            new CampaignMember(
                CampaignId = camp.Id,
                ContactId = con2.Id,
                Status = rcvdStatus
            )
        };
        insert campMembers;

        // Run the duplicate check report
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(camp);
        HH_CampaignDedupeBTN_CTRL deduper = new HH_CampaignDedupeBTN_CTRL(sc);
        deduper.hasAccess = true;
        deduper.RunReport();
        Test.stopTest();

        // Retrieve the status values for the two Contacts
        String campM1Status = [SELECT Status FROM CampaignMember WHERE Id = :campMembers[0].Id].Status;
        String campM2Status = [SELECT Status FROM CampaignMember WHERE Id = :campMembers[1].Id].Status;

        // One Contact will be Sent
        System.assertEquals(sentStatus, campM1Status);

        // The other Contact will be Responded - Duplicate Household
        String dupeRcvdStatus = rcvdStatus.left(40- (System.Label.hhCmpDedupeStatus).length()) + System.Label.hhCmpDedupeStatus;
        System.assertEquals(dupeRcvdStatus, campM2Status);
    }
}