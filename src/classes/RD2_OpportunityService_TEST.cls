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
@isTest
private with sharing class RD2_OpportunityService_TEST {

    private static final String AFFILIATION_OCR_ROLE_SOLICITOR = 'Solicitor';
    private static final String RELATIONSHIP_TYPE_EMPLOYEE = 'Employee';
    private static final String RELATIONSHIP_STATUS_CURRENT = 'Current';
    private static final String PLEDGED_STAGENAME = 'Pledged';
    private static final String PROMISED_STAGENAME = 'Promised';
    private static final String CREDITCARD = 'Credit Card';

    /***
    * @description Verifies if it creates opportunities when an recurring donation
      is inserted with a contact and the stage is pledged.
    */
    @isTest
    private static void shouldCreateOppWhenRDIsInsertedWithContact() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Map<npe03__Recurring_Donation__c,List<Date>> rdsWithCloseDates = new Map<npe03__Recurring_Donation__c,List<Date>>();
        List<Date> CloseDate = new List<Date> ();
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c> ();
        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c> ();
        List<Opportunity> oppCreated = new List<Opportunity> ();
        List<npe01__OppPayment__c> paymentForOpps = new List<npe01__OppPayment__c> ();
        String oppNameFormat = '';

        CloseDate.add(System.today()+2);
        CloseDate.add(System.today()+5);

        createRdSettingsWithStage(PLEDGED_STAGENAME);

        List<Contact> primaryContacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(1);
        insert primaryContacts;
        primaryContacts = getContacts(primaryContacts);

        Campaign campaign = new Campaign(Name = 'TeaCampaign', IsActive = true);
        insert campaign;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(primaryContacts[0].Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('20')
            .withPaymentMethod(CREDITCARD)
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withAmount(415)
            .withCampaign(campaign.id)
            .build();

        insert rd;

        rd = getRd(rd);
        System.assert(rd != null );

        oppNameFormat = rd.npe03__Donor_Name__c +  ' ' + rd.npe03__Amount__c.format();
        oppNameFormat += ' ' + CloseDate[0].format() +   ' ' + UTIL_Describe.getObjectLabel('npe03__Recurring_Donation__c');

        rdsWithCloseDates.put(rd, CloseDate);

        Test.startTest();
        RD2_OpportunityService rdService = new RD2_OpportunityService();
        rdService.createInstallmentOpportunities(rdsWithCloseDates);
        Test.stopTest();

        oppCreated = getOpps();
        paymentForOpps = getPaymentRecForOpps(oppCreated);

        System.assertEquals(OppCreated[0].npe01__Contact_Id_for_Role__c, primaryContacts[0].id);
        System.assertEquals(OppCreated[0].Amount, rd.npe03__Amount__c);
        System.assertEquals(OppCreated[0].Primary_Contact__c, rd.npe03__Contact__c);
        System.assertEquals(OppCreated[0].Name, oppNameFormat);
        System.assertEquals(OppCreated[0].CloseDate, CloseDate[0]);
        System.assertEquals(OppCreated[0].CampaignId, rd.npe03__Recurring_Donation_Campaign__c);
        System.assertEquals(OppCreated[0].StageName, PLEDGED_STAGENAME);
        System.assertEquals(paymentForOpps[0].npe01__Payment_Method__c, CREDITCARD);

    }

    /***
    * @description Verifies if it creates opportunities when an recurring donation
      is inserted with an account and the stage is Promised.
    */
    @isTest
    private static void shouldCreateOppWhenRDinsertedWithAccountAndAffiliation() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Map<npe03__Recurring_Donation__c,List<Date>> rdsWithCloseDates = new Map<npe03__Recurring_Donation__c,List<Date>>();
        List<Date> CloseDate = new List<Date> ();
        List<Opportunity> oppCreated = new List<Opportunity> ();
        List<npe01__OppPayment__c> paymentForOpps = new List<npe01__OppPayment__c> ();
        String oppNameFormat = '';


        CloseDate.add(System.today()+2);
        CloseDate.add(System.today()+5);

        createRdSettingsWithStage(PROMISED_STAGENAME);

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

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withAccount(acc.Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('20')
            .withPaymentMethod(CREDITCARD)
            .withDateEstablished(Date.newInstance(2019, 11, 15))
            .withAmount(415)
            .withCampaign(campaign.Id)
            .build();

        insert rd;

        rd = getRd(rd);
        System.assert(rd != null );

        oppNameFormat = rd.npe03__Donor_Name__c +  ' ' + rd.npe03__Amount__c.format();
        oppNameFormat += ' ' + CloseDate[0].format() +  ' ' + UTIL_Describe.getObjectLabel('npe03__Recurring_Donation__c');

        rdsWithCloseDates.put(rd, CloseDate);

        Test.startTest();
        RD2_OpportunityService rds = new RD2_OpportunityService();
        rds.createInstallmentOpportunities(rdsWithCloseDates);
        Test.stopTest();

        oppCreated = getOpps();
        List<OpportunityContactRole> ocrs = getOppContactRoles(new Set<Id>{ oppCreated[0].id });
        System.assertEquals(1, ocrs.size(), 'OCR should be created: ' + ocrs);
        paymentForOpps = getPaymentRecForOpps(oppCreated);

        OpportunityContactRole ocr = ocrs[0];

        System.assertEquals(OppCreated[0].Amount, rd.npe03__Amount__c);
        System.assertEquals(OppCreated[0].Name, oppNameFormat);
        System.assertEquals(OppCreated[0].CloseDate, CloseDate[0]);
        System.assertEquals(OppCreated[0].CampaignId, rd.npe03__Recurring_Donation_Campaign__c);
        System.assertEquals(OppCreated[0].StageName, PROMISED_STAGENAME);
        System.assertEquals(paymentForOpps[0].npe01__Payment_Method__c, CREDITCARD);
        System.assertEquals(OppCreated[0].Id, ocr.OpportunityId, 'OCR Opportunity should match: ' + ocr);
        System.assertEquals(AFFILIATION_OCR_ROLE_SOLICITOR, ocr.Role, 'OCR Contact Role should match: ' + ocr);
        System.assertEquals(OppCreated[0].CloseDate, CloseDate[0]);

    }

    /*******************************************************************************************************
    * @description Creates recurring donation settings
    * @param Installment stagename
    * @return void
    */
    private static void createRdSettingsWithStage(String stageName) {
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
            SELECT OpportunityId, Opportunity.AccountId, ContactId, Contact.Name, IsPrimary, Role
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
            SELECT AccountId, npo02__Household__c, Name
            FROM Contact
            WHERE Id IN :contacts
        ];
    }

    /*******************************************************************************************************
    * @description Returns Recurring Donation SObjects
    * @param Recurring donation
    * @return npe03__Recurring_Donation__c record
    */
    private static npe03__Recurring_Donation__c getRd(npe03__Recurring_Donation__c rd) {
        return [
            SELECT Id, npe03__Amount__c, npe03__Contact__c, npe03__Recurring_Donation_Campaign__c,
            npe03__Organization__c, npe03__Donor_Name__c, PaymentMethod__c, npe03__Total_Paid_Installments__c
            FROM npe03__Recurring_Donation__c
            WHERE Id = :rd.Id
        ];
    }

    /*******************************************************************************************************
    * @description Returns Opportunities SObjects
    * @return List<Opportunity>
    */
    private static List<Opportunity> getOpps() {
        return [
            SELECT Id, Name, npe03__Recurring_Donation__c, Amount, CampaignId, StageName,
            CloseDate, AccountId, npe01__Contact_Id_for_Role__c, Primary_Contact__c
            FROM Opportunity
            WHERE CreatedDate = Today AND CampaignId != null
        ];
    }

    /*******************************************************************************************************
    * @description Returns OppPayment SObjects
    * @param List<Opportunity>
    * @return List<npe01__OppPayment__c>
    */
    private static List<npe01__OppPayment__c> getPaymentRecForOpps(List<Opportunity> opps) {
        return [
            SELECT Id,npe01__Payment_Method__c, npe01__Opportunity__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c IN :opps
        ];
    }

}