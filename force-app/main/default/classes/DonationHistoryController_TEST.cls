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
    @IsTest
    private static void shouldReturnExpectedDonationHistoryResult() {
        Date myDateTime = Date.newInstance(2020, 2, 2);

        Account mockDefaultAccount = new Account(Name = 'Default Account');
        insert mockDefaultAccount;

        Contact mockDefaultContact = new Contact(
            FirstName='Alice', 
            LastName='Patterson', 
            AccountId=mockDefaultAccount.Id
        );
        Contact secondaryContact = new Contact(
            FirstName='Josh', 
            LastName='Patterson',
            AccountId=mockDefaultAccount.Id
        );
        insert mockDefaultContact;
        insert secondaryContact;

        Opportunity opportunityHardCredit = new Opportunity(
            Name='HardCredit1', 
            AccountId=mockDefaultAccount.Id, 
            Primary_Contact__c=mockDefaultContact.Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );
        Opportunity opportunitySoftCredit = new Opportunity(
            Name='SoftCredit1', 
            AccountId=mockDefaultAccount.Id, 
            Primary_Contact__c=secondaryContact.Id, 
            Amount=200, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );
        Opportunity opportunityPartialSoftCredit = new Opportunity(
            Name='PartialSoftCredit1', 
            AccountId=mockDefaultAccount.Id, 
            Primary_Contact__c=secondaryContact.Id, 
            Amount=150, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );
        Opportunity opportunityInfluencer = new Opportunity(
            Name='InfluencerOpportunity', 
            AccountId=mockDefaultAccount.Id, 
            Primary_Contact__c=secondaryContact.Id, 
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
            ContactId=mockDefaultContact.Id, 
            isPrimary=false
        );
        OpportunityContactRole oppCntRolePartialSoftCredit = new OpportunityContactRole(
            Role='Soft Credit', 
            OpportunityId=opportunityPartialSoftCredit.Id, 
            ContactId=mockDefaultContact.Id, 
            isPrimary=false
        );
        OpportunityContactRole oppCntRoleInfluencerCredit = new OpportunityContactRole(
            Role='Influencer', 
            OpportunityId=opportunityInfluencer.Id, 
            ContactId=mockDefaultContact.Id, 
            isPrimary=false
        );
        List<OpportunityContactRole> recordsOcr = new List<OpportunityContactRole>();
        recordsOcr.add(oppCntRoleSoftCredit);
        recordsOcr.add(oppCntRolePartialSoftCredit);
        recordsOcr.add(oppCntRoleInfluencerCredit);
        insert recordsOcr;

        Partial_Soft_Credit__c partialSoftCredit = new Partial_Soft_Credit__c (
            Amount__c=50,
            Contact__c=mockDefaultContact.Id,
            Opportunity__c=opportunityPartialSoftCredit.Id,
            Contact_Role_ID__c=oppCntRolePartialSoftCredit.Id
        );
        insert partialSoftCredit;
        
        Test.startTest();
        List<DonationHistoryController.DonationHistory> donationHistory = DonationHistoryController.getDonationHistory(mockDefaultContact.Id);
        Test.stopTest();

        for(DonationHistoryController.DonationHistory donation : donationHistory){
            System.assertNotEquals('Influencer', donation.role, 'Must not have an influencer role');
            System.assert(donation.role == 'Soft Credit' || donation.role == 'Donor', 'Roles must be Soft credit or Donor');
        }
        System.assertEquals(3, donationHistory.size(), 'Should return only 3 records');
    }
}