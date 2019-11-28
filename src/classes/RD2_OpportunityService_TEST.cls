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
    private static final String PAYMENT_CREDIT_CARD = 'Credit Card';

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final List<Date> closeDates = new List<Date>{
        System.today() + 2,
        System.today() + 5
    };


    /****
     * @description Creates data required for unit tests
     */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /***
     * @description Verifies a Pledged Opp is created for the new recurring donation when
     * Installment Opportunity Stage Name in settings is Pledged
     */
    @isTest
    private static void shouldCreateOppWhenRDIsInsertedWithContact() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        createRdSettingsWithStage(PLEDGED_STAGENAME);

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        String expectedOppName = getExpectedSpecializedOppName(rd, closeDates[0]);
        
        testAndAssertOppService(rd, expectedOppName);

        List<Opportunity> opps = getOpportunities();

        System.assertEquals(opps[0].npe01__Contact_Id_for_Role__c, getContact().Id);
        System.assertEquals(opps[0].Amount, rd.npe03__Amount__c);
        System.assertEquals(opps[0].Primary_Contact__c, rd.npe03__Contact__c);
        System.assertEquals(opps[0].CloseDate, closeDates[0]);
        System.assertEquals(opps[0].CampaignId, rd.npe03__Recurring_Donation_Campaign__c);
        System.assertEquals(opps[0].StageName, PLEDGED_STAGENAME);
        System.assertEquals(getPayments(opps)[0].npe01__Payment_Method__c, PAYMENT_CREDIT_CARD);
    }

    /***
     * @description Verifies a Promised Opp is created for the new recurring donation when
     * Installment Opportunity Stage Name in settings is Promised
     */
    @isTest
    private static void shouldCreateOppWhenRDinsertedWithAccountAndAffiliation() {        
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        createRdSettingsWithStage(PROMISED_STAGENAME);

        Account acc = UTIL_UnitTestData_TEST.getOrgAccount();
        insert acc;

        npe5__Affiliation__c affiliation = new npe5__Affiliation__c(
            npe5__Organization__c = acc.Id,
            npe5__Role__c = RELATIONSHIP_TYPE_EMPLOYEE,
            npe5__Contact__c = getContact().Id,
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
            .withPaymentMethod(PAYMENT_CREDIT_CARD)
            .withDateEstablished(Date.newInstance(2019, 11, 15))
            .withAmount(415)
            .withCampaign(campaign.Id)
            .build();
        insert rd;

        rd = rdGateway.getRecord(rd.Id);

        String expectedOppName = getExpectedSpecializedOppName(rd, closeDates[0]);
        
        testAndAssertOppService(rd, expectedOppName);

        List<Opportunity> opps = getOpportunities();

        List<OpportunityContactRole> ocrs = getOppContactRoles(new Set<Id>{ opps[0].Id });
        System.assertEquals(1, ocrs.size(), 'OCR should be created: ' + ocrs);

        System.assertEquals(opps[0].Amount, rd.npe03__Amount__c);
        System.assertEquals(opps[0].CloseDate, closeDates[0]);
        System.assertEquals(opps[0].CampaignId, rd.npe03__Recurring_Donation_Campaign__c);
        System.assertEquals(opps[0].StageName, PROMISED_STAGENAME);
        System.assertEquals(getPayments(opps)[0].npe01__Payment_Method__c, PAYMENT_CREDIT_CARD);
        System.assertEquals(opps[0].Id, ocrs[0].OpportunityId, 'OCR Opportunity should match: ' + ocrs[0]);
        System.assertEquals(AFFILIATION_OCR_ROLE_SOLICITOR, ocrs[0].Role, 'OCR Contact Role should match: ' + ocrs[0]);
        System.assertEquals(opps[0].CloseDate, closeDates[0]);
    }

    /***
     * @description Verifies an Opportunity name has the specialized format when
     * Opportunity naming is not configured in NPSP Settings
     */
    @isTest
    private static void shouldCreateOppWithSpecialFormatWhenNoOppNamingSpecified() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        
        createRdSettingsWithStage(PLEDGED_STAGENAME);

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        String expectedOppName = getExpectedSpecializedOppName(rd, closeDates[0]);
        
        testAndAssertOppService(rd, expectedOppName);
    }

    /***
     * @description Verifies an Opportunity name is set as configured in NPSP Settings Opportunity naming
     */
    @isTest
    private static void shouldCreateOppNameWithOppNamingSpecifiedInSettings() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        insert new Opportunity_Naming_Settings__c(
            Name = 'Test Opp Naming Settings',
            Opportunity_Name_Format__c = '{!Contact.Name} {!CloseDate}',
            Attribution__c = System.Label.oppNamingBoth
        );

        //blank out cached version so the inserted setting takes effect
        UTIL_ListCustomSettingsFacade.mapOppNamingSettings = null;
        
        createRdSettingsWithStage(PLEDGED_STAGENAME);

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        Datetime dt = Datetime.newInstance(closeDates[0].year(), closeDates[0].month(), closeDates[0].day());
        String expectedOppName = rd.npe03__Donor_Name__c + ' ' + dt.format('yyyy.MM.dd');

        testAndAssertOppService(rd, expectedOppName);
    }


    // Helper Methods
    //////////////////

    /***
    * @description Calls Opportunity service to create Opportunities. Verifies *first retrieved* Opportunity name
    * @param rd Recurring Donation
    * @param expectedOppName Expected Opportunity name for the first retrieved Opportunity
    * @return void
    */
    private static void testAndAssertOppService(npe03__Recurring_Donation__c rd, String expectedOppName) {
        Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates = new Map<npe03__Recurring_Donation__c, List<Date>>();
        rdsWithCloseDates.put(rd, closeDates);

        Test.startTest();
        RD2_OpportunityService service = new RD2_OpportunityService();
        service.createInstallmentOpportunities(rdsWithCloseDates);
        Test.stopTest();

        List<Opportunity> opps = getOpportunities();

        System.assertEquals(closeDates.size(), opps.size(), 'Number of Opportunities should match expected close dates');
        System.assertEquals(opps[0].Name, expectedOppName, 'Opportunity Name should match');
    }

    /***
    * @description Creates Recurring Donation record
    * @return npe03__Recurring_Donation__c
    */
    private static npe03__Recurring_Donation__c createRecurringDonation() {
        Campaign campaign = new Campaign(Name = 'TeaCampaign', IsActive = true);
        insert campaign;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(getContact().Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withAmount(415)
            .withPaymentMethod(PAYMENT_CREDIT_CARD)
            .withCampaign(campaign.Id)
            .build();

        insert rd;

        return rdGateway.getRecord(rd.Id);
    }

    /***
    * @description Creates Recurring Donation settings
    * @param stageName Installment Opportunity Stage 
    * @return void
    */
    private static void createRdSettingsWithStage(String stageName) {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            InstallmentOppStageName__c = stageName,
            npe03__Add_Campaign_to_All_Opportunites__c = true,
            IsRecurringDonations2Enabled__c = true
        ));
    }

    /***
    * @description Builds Specialized name format for opportunity
    * @param rd Recurring Donation record
    * @param closeDate Opportunity Close Date
    * @return String Expected Opportunity name
    */
    public static String getExpectedSpecializedOppName(npe03__Recurring_Donation__c rd, Date closeDate) {
        return
            rd.npe03__Donor_Name__c +  ' ' +
            System.Label.npe03.RecurringDonationPrefix + ' (' +
            (rd.npe03__Total_Paid_Installments__c != null ? rd.npe03__Total_Paid_Installments__c + 1 : 1) + ') ' +
            closeDate.format();
    }

    /***
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

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId, Account.Name
            FROM Contact
            LIMIT 1
        ];
    }

    /***
    * @description Retrieves Opportunities 
    * @return List<Opportunity>
    */
    private static List<Opportunity> getOpportunities() {
        return [
            SELECT Id, Name, npe03__Recurring_Donation__c, Amount, CampaignId, StageName,
            CloseDate, AccountId, npe01__Contact_Id_for_Role__c, Primary_Contact__c
            FROM Opportunity
            WHERE CreatedDate = Today AND CampaignId != null
            ORDER BY CloseDate //ensure Opps are returned in the predictable order
        ];
    }

    /***
    * @description Retrieves Payments for specified Opportunities
    * @param opps Specified Opportunities
    * @return List<npe01__OppPayment__c>
    */
    private static List<npe01__OppPayment__c> getPayments(List<Opportunity> opps) {
        return [
            SELECT Id,npe01__Payment_Method__c, npe01__Opportunity__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c IN :opps
        ];
    }

}