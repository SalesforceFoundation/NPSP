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
* @description Test for Create Opportunities from Recurring Donations
*
*/
@isTest(IsParallel=true)
private with sharing class RD2_OpportunityService_TEST {

    private static final String AFFILIATION_OCR_ROLE_SOLICITOR = 'Solicitor';
    private static final String RELATIONSHIP_TYPE_EMPLOYEE = 'Employee';
    private static final String RELATIONSHIP_STATUS_CURRENT = 'Current';
    private static final String PLEDGED_STAGENAME = 'Pledged';
    private static final String PROMISED_STAGENAME = 'Promised';

    /***
    * @description Verifies if it creates opportunities when an recurring donation
      is inserted with a contact and the stage is pledged.
    */
    @isTest
    private static void shouldCreateOppWhenRDIsInsertedWithContact() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        createRdSettingsWithStage(PLEDGED_STAGENAME);

        Map<npe03__Recurring_Donation__c,List<Date>> rdsWithCloseDates = new Map<npe03__Recurring_Donation__c,List<Date>>();
        List<Date> CloseDate = new List<Date> ();

        CloseDate.add(System.today()+2);
        CloseDate.add(System.today()+5);

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Campaign campaign = new Campaign(Name = 'TeaCampaign', IsActive = true);
        insert campaign;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(con.Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withAmount(415)
            .withCampaign(campaign.id)
            .build();

        insert rd;

        rd.PaymentMethod__c ='Credit Card';
        update rd;

        System.assert([
            SELECT id
            FROM npe03__Recurring_Donation__c].size()>0 );

        rdsWithCloseDates.put(rd, CloseDate);

        RD2_OpportunityService rds = new RD2_OpportunityService();
        rds.createInstallmentOpportunities(rdsWithCloseDates);

        Opportunity opp = [select id,name,npe03__Recurring_Donation__c,amount, campaignid, closedate, accountid, npe01__Contact_Id_For_Role__c from opportunity where createddate=today and campaignid != null limit 1];
        System.debug('Opportunity created:' + opp);

        System.assertEquals(opp.closedate, CloseDate[0]);

    }

    /***
    * @description Verifies if it creates opportunities when an recurring donation
      is inserted with an account and the stage is Promised.
    */
    @isTest
    private static void shouldCreateOppWhenRDinsertedWithAccountAndAffiliation() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        createRdSettingsWithStage(PROMISED_STAGENAME);

        Map<npe03__Recurring_Donation__c,List<Date>> rdsWithCloseDates = new Map<npe03__Recurring_Donation__c,List<Date>>();
        List<Date> CloseDate = new List<Date> ();

        CloseDate.add(System.today()+2);
        CloseDate.add(System.today()+5);

        Account acc = UTIL_UnitTestData_TEST.getOrgAccount();
        insert acc;

        List<Contact> primaryContacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(1);
        insert primaryContacts;
        primaryContacts = getContacts(primaryContacts);

        npe5__Affiliation__c affiliation = new npe5__Affiliation__c(
            npe5__Organization__c = acc.Id,
            npe5__Role__c = RELATIONSHIP_TYPE_EMPLOYEE,
            npe5__Contact__c = primaryContacts[0].Id,
            npe5__Status__c = RELATIONSHIP_STATUS_CURRENT,
            Related_Opportunity_Contact_Role__c = AFFILIATION_OCR_ROLE_SOLICITOR
            );

        insert affiliation;

        Campaign campaign = new Campaign(Name = 'TeaCampaign', IsActive = true);
        insert campaign;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(acc.Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withAmount(415)
            .withCampaign(campaign.id)
            .build();

        insert rd;

        rd.PaymentMethod__c ='Credit Card';
        update rd;

        System.assert([
            SELECT id
            FROM npe03__Recurring_Donation__c].size()>0 );

        rdsWithCloseDates.put(rd, CloseDate);

        Test.startTest();
        RD2_OpportunityService rds = new RD2_OpportunityService();
        rds.createInstallmentOpportunities(rdsWithCloseDates);
        Test.stopTest();

        Opportunity opp = [select id,name,npe03__Recurring_Donation__c,amount, campaignid, closedate, accountid, npe01__Contact_Id_For_Role__c from opportunity where createddate=today and campaignid != null limit 1];
        System.debug('Opportunity created:' + opp);

        List<OpportunityContactRole> ocrs = getOppContactRoles(new Set<Id>{ opp.id });
        System.assertEquals(1, ocrs.size(), 'OCR should be created: ' + ocrs);

        OpportunityContactRole ocr = ocrs[0];
        System.assertEquals(opp.Id, ocr.OpportunityId, 'OCR Opportunity should match: ' + ocr);
        System.assertEquals(AFFILIATION_OCR_ROLE_SOLICITOR, ocr.Role, 'OCR Contact Role should match: ' + ocr);

        System.assertEquals(opp.closedate, CloseDate[0]);

    }
    /*******************************************************************************************************
    * @description Creates recurring donation settings
    * @param Installment stagename
    * @return void
    */
    public static void createRdSettingsWithStage(String stageName) {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            InstallmentOppStageName__c = stageName,
            npe03__Add_Campaign_to_All_Opportunites__c = true,
            IsRecurringDonations2Enabled__c = true
        ));
    }

    /*******************************************************************************************************
    * @description Queries OCRs for specified Opportunities
    * @param oppIds Opportunity Ids
    * @return List<OpportunityContactRole> OCRs assigned to provided Opportunities
    */
    private static List<OpportunityContactRole> getOppContactRoles(Set<Id> oppIds) {
        return [
            SELECT OpportunityId, Opportunity.AccountId, ContactId, Contact.Name, isPrimary, Role
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds
        ];
    }

    /*******************************************************************************************************
    * @description Returns Contact SObjects
    * @param contacts List of Contacts
    * @return List<Contact>
    */
    private static List<Contact> getContacts(List<Contact> contacts) {
        return [
            SELECT AccountId, npo02__Household__c
            FROM Contact
            WHERE Id IN :contacts
        ];
    }

}