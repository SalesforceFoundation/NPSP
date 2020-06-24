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
* @description Enhanced Recurring Donations Entry Form LWC Controller Test
*
*/
@isTest(IsParallel=true)
private with sharing class RD2_EntryFormController_TEST {

    /***
    * @description Verifies that Entry Form Controller gathers the correct org setting
    */
    @isTest
    private static void shouldReturnRDSettingForEntryForm() {
        Id accountId =  UTIL_UnitTestData_TEST.mockId(Account.SObjectType);

        Test.startTest();
        Map<String, Object> orgSettingsByKey = RD2_EntryFormController.getSetting(accountId);
        Test.stopTest();

        System.assertEquals(RD2_NamingService.isAutomaticNamingEnabled, ((Boolean) orgSettingsByKey.get('isAutoNamingEnabled')),
            'Recurring Donation Auto Naming setting should be returned accordingly');
        System.assertEquals(UserInfo.isMultiCurrencyOrganization(), (Boolean) orgSettingsByKey.get('isMultiCurrencyEnabled'),
            'Multi Currency Org should be detect in the configuration.');
        System.assertEquals(String.valueOf(Account.SObjectType), (String) orgSettingsByKey.get('parentSObjectType'),
            'Parent Sobject type should be correctly identified when value is not null');
        System.assertEquals(RD2_Constants.DAY_OF_MONTH_LAST_DAY, (String) orgSettingsByKey.get('dayOfMonthLastDay'),
            'JSON file should grab Last Day of Month Last_Day API value');
    }

    /***
    * @description Verifies that Entry Form Controller returns the expected results for Account for Donor Type
    */
    @isTest
    private static void shouldReturnAccountDonorType() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account a = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert a;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withAccount(a.Id)
            .withAmount(25)
            .withDefaultValues()
            .build();
        insert rd;

        Test.startTest();
        String donorType = RD2_EntryFormController.getDonorType(rd.Id);
        Test.stopTest();

        System.assertEquals('Account', donorType);
    }

    /***
    * @description Verifies that Entry Form Controller returns the expected results for Contact for Donor Type
    */
    @isTest
    private static void shouldReturnContactDonorType() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(c.Id)
            .withAmount(25)
            .withDefaultValues()
            .build();
        insert rd;

        Test.startTest();
        String donorType = RD2_EntryFormController.getDonorType(rd.Id);
        Test.stopTest();

        System.assertEquals('Contact', donorType);
    }

    /***
    * @description Verifies that Entry Form Controller excluded all NPSP packaged field and predefined excluded fields 
    */
    @isTest
    private static void shouldReturnRD2CustomFieldsWithoutNPSPNameSpaceAndExcludedFields() {
        Test.startTest();
        List<RD2_EntryFormController.CustomField> customFields = RD2_entryFormController.getCustomFieldSectionFields();
        Test.stopTest();

        for (RD2_EntryFormController.CustomField field : customFields) {
            System.assert(!RD2_EntryFormController.excludedCustomFields.contains(field.apiName),
                'Excluded fields should not be return:' + field.apiName);
            System.assert(!field.apiName.startsWith('npsp__'),
                'NPSP package field should not be return:' + field.apiName);
                System.assert(!field.apiName.startsWith('npe03__'),
                'NPSP package field should not be return:' + field.apiName);
        }
    }

}