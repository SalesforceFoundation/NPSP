/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit tests for the RD -> Opportunity custom field mapper
*
*/
@IsTest(IsParallel=true)
public class RD2_CustomFieldMapper_TEST {

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final String PAYMENT_CHECK = 'Check';
    private static final Decimal RD_AMOUNT = 100;

    /***
     * @description Verifies the Recurring Donation is identified as unchanged
     * when the record has changed but the field is not part of the custom mapping settings
     */
    @IsTest
    private static void shouldIndicateRDIsUnchangedWhenFieldIsNotInCustomMapping() {
        createCustomFieldMapping('Name', 'Description');

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();

        npe03__Recurring_Donation__c updatedRD = rd.clone();
        updatedRD.npe03__Amount__c += 10;

        RD2_CustomFieldMapper fieldMapper = new RD2_CustomFieldMapper();
        System.assertEquals(false, fieldMapper.hasKeyFieldChanged(updatedRd, rd),
            'Record should be identified as unchanged since the npe03__Amount__c is not included in the custom mapping');
    }

    /***
     * @description Verifies the Recurring Donation is identified as changed
     * when the record has changed and the field is part of the custom mapping settings
     */
    @IsTest
    private static void shouldIndicateRDIsChangedWhenFieldIsInCustomMapping() {
        createCustomFieldMapping('npe03__Amount__c', 'Amount');

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();

        npe03__Recurring_Donation__c updatedRD = rd.clone();
        updatedRD.npe03__Amount__c += 10;

        RD2_CustomFieldMapper fieldMapper = new RD2_CustomFieldMapper();
        System.assertEquals(true, fieldMapper.hasKeyFieldChanged(updatedRd, rd),
            'Record should be identified as changed since the npe03__Amount__c is included in the custom mapping');
    }

    /***
     * @description Verifies an Opportunity is unchanged when custom field mapping is empty
     */
    @IsTest
    private static void shouldNotChangeOpportunityWhenCustomMappingIsEmpty() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        Opportunity opp = new TEST_OpportunityBuilder()
            .withAmount(RD_AMOUNT + 10)
            .build();
        String oppName = opp.Name;

        RD2_CustomFieldMapper fieldMapper = new RD2_CustomFieldMapper();
        fieldMapper.populateOpportunityFields(opp, rd);

        System.assertEquals(RD_AMOUNT + 10, opp.Amount,
            'Opportunity amount value should be unchanged');
        System.assertEquals(oppName, opp.Name,
            'Opportunity name should be unchanged');
    }

    /***
     * @description Verifies an Opportunity field is not populated 
     * from Recurring Donation when the custom field mapping does not include such field
     */
    @IsTest
    private static void shouldNotOverwriteOpportunityFieldWhenNotIncludedInCustomMapping() {
        createCustomFieldMapping('Name', 'Description');

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        Opportunity opp = new TEST_OpportunityBuilder()
            .withAmount(RD_AMOUNT + 10)
            .build();
        opp.Description = 'foo';

        RD2_CustomFieldMapper fieldMapper = new RD2_CustomFieldMapper();
        fieldMapper.populateOpportunityFields(opp, rd);

        System.assertEquals(RD_AMOUNT + 10, opp.Amount,
            'Opportunity amount value should be unchanged');
        System.assertEquals(rd.Name, opp.Description,
            'Opportunity description value should be changed based on custom mapping');
    }

    /***
     * @description Verifies an Opportunity field is populated 
     * from the Recurring Donation record based on the custom mapping
     */
    @IsTest
    private static void shouldOverwriteOpportunityFieldWhenIncludedInCustomMapping() {
        createCustomFieldMapping('npe03__Amount__c', 'Amount');

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        Opportunity opp = new TEST_OpportunityBuilder()
            .withAmount(RD_AMOUNT + 10)
            .build();

        RD2_CustomFieldMapper fieldMapper = new RD2_CustomFieldMapper();
        fieldMapper.populateOpportunityFields(opp, rd);

        System.assertEquals(RD_AMOUNT, opp.Amount,
            'Recurring Donation amount value should be copied into Opportunity amount field');
    }

    /***
     * @description Verifies it is indicated the Opportunity is changed
     * when the field is included in the custom field mapping
     * and Opportunity field value differs from the mapped field value on Recurring Donation
     */
    @IsTest
    private static void shouldIndicateChangeWhenFieldIsIncludedInCustomMappingAndValueIsChanged() {
        createCustomFieldMapping('npe03__Amount__c', 'Amount');

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        Opportunity opp = new TEST_OpportunityBuilder()
            .withAmount(RD_AMOUNT + 10)
            .build();

        RD2_CustomFieldMapper fieldMapper = new RD2_CustomFieldMapper();
        Boolean isChanged = fieldMapper.syncOpportunityFields(opp, rd);

        System.assertEquals(true, isChanged,
            'The sync should indicate the Opportunity record has been changed');
        System.assertEquals(RD_AMOUNT, opp.Amount,
            'Recurring Donation amount value should be copied into Opportunity amount field');
    }

    /***
     * @description Verifies it is indicated the Opportunity is not changed
     * when the field is included in the custom field mapping
     * and Opportunity field value is the same as the mapped field value on Recurring Donation
     */
    @IsTest
    private static void shouldNotIndicateChangeWhenFieldIsIncludedInCustomMappingAndValueIsSame() {
        createCustomFieldMapping('npe03__Amount__c', 'Amount');

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        Opportunity opp = new TEST_OpportunityBuilder()
            .withAmount(RD_AMOUNT)
            .build();

        RD2_CustomFieldMapper fieldMapper = new RD2_CustomFieldMapper();
        Boolean isChanged = fieldMapper.syncOpportunityFields(opp, rd);

        System.assertEquals(false, isChanged,
            'The sync should indicate the Opportunity record has not been changed');
    }

    /***
     * @description Verifies variables containing Recurring Donation and Opportunity field names
     * are populated based on the custom field mapping settings
     */
    @IsTest
    private static void shouldPopulateRDandOppFieldNamesWhenCustomMappingIsDefined() {
        insert new List<npe03__Custom_Field_Mapping__c>{
            buildCustomFieldMapping('npe03__Amount__c', 'Amount'),
            buildCustomFieldMapping('Name', 'Description')
        };

        Set<String> expectedRDFieldNames = new Set<String>{
            'npe03__Amount__c', 'Name'
        };
        Set<String> expectedOppFieldNames = new Set<String>{
            'Amount', 'Description'
        };

        RD2_CustomFieldMapper fieldMapper = new RD2_CustomFieldMapper();

        System.assertEquals(expectedRDFieldNames, fieldMapper.rdFieldNames,
            'The mapped field names on Recurring Donation SObject should match');
        System.assertEquals(expectedOppFieldNames, fieldMapper.oppFieldNames,
            'The mapped field names on Opportunity SObject should match');
    }


    // Helpers
    ////////////////////


    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return getRecurringDonationBuilder(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType));
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @param contactId Contact Id
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(contactId)
            .withAmount(RD_AMOUNT)
            .withPaymentMethod(PAYMENT_CHECK)
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withCalculateNextDonationDate();
    }

    /***
    * @description Removes current Custom Field Mappings and create a new one
    * in order to avoid reaching debug log size limit
    * @param rdFieldName Source field on Recurring Donation
    * @param oppFieldName Destination field on Opportunity
    * @return void
    */
    public static void createCustomFieldMapping(String rdFieldName, String oppFieldName) {
        insert buildCustomFieldMapping(rdFieldName, oppFieldName);
    }

    /***
    * @description Builds custom field mapping setting record to map
    * from a Recurring Donation field to the Opportunity field
    * @param rdFieldName Source field on Recurring Donation
    * @param oppFieldName Destination field on Opportunity
    * @return void
    */
    public static npe03__Custom_Field_Mapping__c buildCustomFieldMapping(String rdFieldName, String oppFieldName) {
        String name = System.now() + rdFieldName;

        return new npe03__Custom_Field_Mapping__c(
            Name = name.left(30),
            npe03__Recurring_Donation_Field__c = rdFieldName,
            npe03__Opportunity_Field__c = oppFieldName
        );
    }
}
