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
    private static final Id RECORD_TYPE_FAKE_ID = '0120x00000QF099999';

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final List<Date> closeDates = new List<Date>{
        System.today() + 2,
        System.today() + 5
    };

     private static final TEST_SobjectGateway.ErrorGateway errorGateway = new TEST_SobjectGateway.ErrorGateway();

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
     * @description Verifies if it creates opportunities with specialized format when
     * no opportunity naming is specified in NPSP Settings
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
     * @description Verifies if it creates opportunities with specialized format for the
     * next opportunity when no opportunity naming is specified in NPSP Settings
     */
    @isTest
    private static void shouldCreateOppNameWithSpecialFormatForNextOpportunity() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        
        createRdSettingsWithStage(PLEDGED_STAGENAME);

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        String expectedOppName = getExpectedSpecializedOppName(rd, closeDates[0]);

        testAndAssertOppService(rd, expectedOppName);
    }

    /***
     * @description Verifies if it creates opportunities with opportunity naming format in NPSP Settings.
     */
    @isTest
    private static void shouldCreateOppNameWithOppNamingSpecifiedInSettings() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        insert new Opportunity_Naming_Settings__c(
            Name = 'Opp Naming Settings',
            Opportunity_Name_Format__c = '{!Contact.Name} {!RecordType.Name} {!CloseDate}',
            Attribution__c = System.Label.oppNamingBoth
        );
        
        createRdSettingsWithStage(PLEDGED_STAGENAME);

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        String expectedOppName = getExpectedOppNameBasedOnSettings(rd, closeDates[0]);

        testAndAssertOppService(rd, expectedOppName);
    }

    /***
    * @description Verifies the installment opportunities are created with the record types set in the NPSP setting
    */
    @isTest
    private static void shouldSetOppRecordTypeIdFromSettings() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Id rdSettingRecordTypeId = UTIL_RecordTypes_TEST.getNonDefaultRecordType(Opportunity.sObjectType);

        Map<String, Object> rdSettingFieldMap = new Map<String, Object>{
            'npe03__Record_Type__c' => rdSettingRecordTypeId
        };
        createRdSettingsWithFieldMap(rdSettingFieldMap);

        Test.startTest();
        createRecurringDonation();
        Test.stopTest();

        Opportunity installmentOpp = getOpportunities()[0];

        System.assert(installmentOpp != null, 'An opportunity should be created for each recurring donation record');
        System.assertEquals(rdSettingRecordTypeId, installmentOpp.RecordTypeId,
            'The record type should be configured according to the NPSP Opportunity Default Record Type');
    }

    /***
    * @description The installment opportunity should have the default record type of the current user when the record
    * type is not set in NPSP setting
    */
    @isTest
    private static void shouldKeepDefaultOppRecordTypeIfRecordTypeSettingNotSet() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        createRdSettingsWithFieldMap(null);

        Test.startTest();
        createRecurringDonation();
        Test.stopTest();

        Opportunity installmentOpp = getOpportunities()[0];

        Id defaultRecordTypeId = UTIL_RecordTypes_TEST.getDefaultRecordType(Opportunity.sObjectType);

        System.assert(installmentOpp != null, 'An opportunity should be created for each recurring donation record');
        System.assertEquals(defaultRecordTypeId, installmentOpp.RecordTypeId,
            'The record type should be the default opp record type when NPSP default record type is null');
    }

    /***
    * @description The installment opportunity should keep the original record type when the NPSP opp default record type
    * is updated
    */
    @isTest
    private static void shouldNotUpdateOppRecordTypeWhenRecordTypeSettingChange() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        createRdSettingsWithFieldMap(null);
        npe03__Recurring_Donation__c rd = createRecurringDonation();

        Opportunity installmentOpp = new TEST_OpportunityBuilder()
            .withAmount(100)
            .withAccount(getContact().AccountId)
            .withClosedWonStage()
            .withCloseDate(Date.today())
            .withRecurringDonation(rd.Id)
            .withCampaign(rd.npe03__Recurring_Donation_Campaign__c)
            .build();
        insert installmentOpp;

        Test.startTest();
        Id rdSettingRecordTypeId = UTIL_RecordTypes_TEST.getNonDefaultRecordType(Opportunity.sObjectType);

        Map<String, Object> rdSettingFieldMap = new Map<String, Object>{
            'npe03__Record_Type__c' => rdSettingRecordTypeId
        };
        createRdSettingsWithFieldMap(rdSettingFieldMap);
        
        Test.stopTest();

        installmentOpp = getOpportunities()[0];   

        System.assertNotEquals(rdSettingRecordTypeId, installmentOpp.RecordTypeId,
            'The record type should not be updated to NPSP default record type if the opp is already created before the update');
    }

    /***
    * @description Error__c records should be created and opportunity records should not be inserted 
    *   when creating a RD if the NPSP Opportunity record type is invalid
    */
    @isTest
    private static void shouldLogErrorAndBlockOppCreationWhenOppDefaultRecordTypeIsInvalid() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Map<String, Object> rdSettingFieldMap = new Map<String, Object>{
            'npe03__Record_Type__c' => RECORD_TYPE_FAKE_ID
        };
        createRdSettingsWithFieldMap(rdSettingFieldMap);

        Test.startTest();
        createRecurringDonations(2);
        Test.stopTest();

        System.assert(getOpportunities().isEmpty(), 
            'No installment opportunity should be created when the default record type on the setting is invalid');

        List<Error__c> errors = errorGateway.getRecords();

        System.assertEquals(2, errors.size(), '2 Error records should be created for each installment opp');

        for (Error__c error : errors) {
            System.assert(error.Full_Message__c.contains(String.valueOf(RECORD_TYPE_FAKE_ID)),
                'The error message should be related to the invalid record type Id');
        }    
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

    private static npe03__Recurring_Donation__c createRecurringDonation() {
        return createRecurringDonations(1)[0];
    }
    /***
    * @description Creates a single Recurring Donation record
    * @return npe03__Recurring_Donation__c
    */
    private static List<npe03__Recurring_Donation__c> createRecurringDonations(Integer size) {
        Campaign campaign = new Campaign(Name = 'TeaCampaign', IsActive = true);
        insert campaign;

        List<npe03__Recurring_Donation__c> rds = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(getContact().Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withAmount(415)
            .withPaymentMethod(PAYMENT_CREDIT_CARD)
            .withCampaign(campaign.Id)
            .build(size);

        insert rds;

        return rdGateway.getRecords(rds);
    }



    /***
    * @description Creates Recurring Donation settings
    * @param stageName Installment Opportunity Stage 
    * @return void
    */
    private static void createRdSettingsWithStage(String stageName) {
        createRdSettingsWithFieldMap(new Map<String, Object>{'InstallmentOppStageName__c' => stageName});
    }

    /***
    * @description Genenric version of creating Recurring Donations Settings
    * @param fieldMap a map of field name to value
    * @return void
     */
    private static void createRdSettingsWithFieldMap(Map<String, Object> fieldMap) {
        npe03__Recurring_Donations_Settings__c rdSetting = new npe03__Recurring_Donations_Settings__c(
            npe03__Add_Campaign_to_All_Opportunites__c = true,
            IsRecurringDonations2Enabled__c = true,
            npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name() 
        );
        
        if (fieldMap != null) {
            for (String field : fieldMap.keySet()) {
                rdSetting.put(field, fieldMap.get(field));
            }
        }
        UTIL_CustomSettingsFacade.reloadCustomSettingsOnRecordTypeCleanup();
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(rdSetting);
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
    * @description Builds Opportunity name format from settings
    * @param rd Recurring Donation record
    * @param closeDate Opportunity Close Date
    * @return String Expected Opportunity name
    */
    public static String getExpectedOppNameBasedOnSettings(npe03__Recurring_Donation__c rd, Date closeDate) {

        Datetime dt = Datetime.newInstance(closeDate.year(), closeDate.month(), closeDate.day());
        String formattedDate = dt.format('yyyy.MM.dd');
        String recordTypeName = UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.sObjectType);

        return
            rd.npe03__Donor_Name__c +  ' ' +
            recordTypeName + ' ' +
            formattedDate;
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
            CloseDate, AccountId, npe01__Contact_Id_for_Role__c, Primary_Contact__c, RecordTypeId
            FROM Opportunity
            WHERE CreatedDate = Today AND CampaignId != null
            ORDER BY CloseDate, CreatedDate //ensure Opps are returned in the predictable order
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