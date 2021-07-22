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
* @description Recurring Donations Naming Service tests
*
*/
@isTest(IsParallel=true)
public with sharing class RD2_NamingService_TEST {
    private static final String CURRENCY_CAD = 'CAD';
    private static final String CURRENCY_USD = 'USD';

    private static final Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
    private static Account accOrg = getOrgAccountMock();
    private static Account accHH = getHHAccountMock();

    /***
    * @description Verifies Recurring Donation Name is not generated when automatic naming is not enabled
    */
    @isTest
    private static void shouldNotAutogenerateNameWhenAutomaticNamingIsNotEnabled() {
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAmount(100)
            .build();

        String name = rd.Name;

        RD2_NamingService service = new RD2_NamingService();

        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertEquals(name, rd.Name, 'The name should not be generated.');
    }

    /***
    * @description Verifies Recurring Donation Name is generated when automatic naming is enabled
    */
    @isTest
    private static void shouldAutogenerateNameWhenAutomaticNamingIsEnabled() {
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAmount(100)
            .build();

        String name = rd.Name;

        RD2_NamingService service = buildAutomaticNamingService();
        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertNotEquals(name, rd.Name, 'The name should be generated.');
    }

    /***
    * @description Verifies generated Recurring Donation Name is constructed using
    * Account Name, Amount and the suffix.
    */
    @isTest
    private static void shouldAutogenerateNameUsingProvidedAccountAndAmount() {
        String currencyCode = UserInfo.getDefaultCurrency();
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.25)
            .withCurrencyIsoCode(currencyCode)
            .build();

        RD2_NamingService service = buildAutomaticNamingService(accOrg);
        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertEquals(getDefaultExpectedName(accOrg, '100.25', currencyCode), rd.Name, 'The name should match.');
    }

    /***
    * @description Verifies generated Recurring Donation Name is constructed using
    * Contact Name, Amount and the suffix; using Name Format 1
    */
    @isTest
    private static void shouldAutogenerateFormat1NameUsingProvidedContactAndAmount() {
        alternateNamingFormatTest(RD2_NamingService.RD_NAMING_OPTION_1);
    }

    /***
    * @description Verifies generated Recurring Donation Name is constructed using
    * Contact Name, Amount and the suffix; using Name Format 2
    */
    @isTest
    private static void shouldAutogenerateFormat2NameUsingProvidedContactAndAmount() {
        alternateNamingFormatTest(RD2_NamingService.RD_NAMING_OPTION_2);
    }

    /***
    * @description Verifies generated Recurring Donation Name is constructed using
    * Contact Name, Amount and the suffix; using Name Format 3.
    */
    @isTest
    private static void shouldAutogenerateFormat3NameUsingProvidedContactAndAmount() {
        alternateNamingFormatTest(RD2_NamingService.RD_NAMING_OPTION_3);
    }

    /***
    * @description Verifies generated Recurring Donation Name is constructed using the specified naming format
    */
    private static void alternateNamingFormatTest(String nameFormat) {
        String currencyCode = UserInfo.getDefaultCurrency();
        Contact contact = getContactMock();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(contact.Id)
            .withAmount(100.25)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1')
            .withCurrencyIsoCode(currencyCode)
            .build();

        npe03__Recurring_Donations_Settings__c rdSettings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        rdSettings.RecurringDonationNameFormat__c = nameFormat;

        RD2_NamingService service = buildAutomaticNamingService(new List<Account>(), new List<Contact>{ contact });
        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertEquals(getExpectedName(nameFormat,
                RD2_Constants.INSTALLMENT_PERIOD_MONTHLY,
                '100.25',
                currencyCode,
                contact, null
            ),
            rd.Name, 'The RD name should match.');
    }

    /***
    * @description Verifies generated Recurring Donation Name is constructed using
    * Account Name, Amount and the suffix.
    */
    @isTest
    private static void shouldAutogenerateNameUsingAccountAndAmountWhenNotHouseholdAccount() {
        String currencyCode = UserInfo.getDefaultCurrency();
        Contact contact = getContactMock();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withContact(contact.Id)
            .withAmount(100.25)
            .withCurrencyIsoCode(currencyCode)
            .build();

        RD2_NamingService service = buildAutomaticNamingService(
            new List<Account>{
                accOrg
            },
            new List<Contact>{ contact }
        );

        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertEquals(getDefaultExpectedName(accOrg, '100.25', currencyCode), rd.Name, 'The name should match.');
    }

    /***
    * @description Verifies generated Recurring Donation Name is constructed using
    * Contact Name, Amount and the suffix.
    */
    @isTest
    private static void shouldAutogenerateNameUsingProvidedContactAndAmount() {
        String currencyCode = UserInfo.getDefaultCurrency();
        Contact contact = getContactMock();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accHH.Id)
            .withContact(contact.Id)
            .withAmount(100.25)
            .withCurrencyIsoCode(currencyCode)
            .build();

        RD2_NamingService service = buildAutomaticNamingService(
            new List<Account>{
                accHH
            },
            new List<Contact>{ contact }
        );

        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertEquals(getDefaultExpectedName(contact, '100.25', currencyCode), rd.Name, 'The name should match.');
    }

    /***
    * @description Verifies formatted name contains currency symbol when multi-currency is enabled
    */
    @isTest
    private static void shouldUseCurrencySymbolInNameWhenMultiCurrencyIsEnabled() {
        if (!isMultiCurrencyEnabled) {
            return;
        }

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.25)
            .withCurrencyIsoCode(CURRENCY_CAD)
            .build();

        RD2_NamingService service = buildAutomaticNamingService(accOrg);
        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        String expectedName = accOrg.Name + ' $100.25 - ' + System.Label.RecurringDonationNameSuffix;
        System.assertEquals(expectedName, rd.Name, 'The amount format should match.');
    }

    /***
    * @description Verifies formatted name amount does not contain trailing zeros (.00 or .0)
    */
    @isTest
    private static void shouldReturnAmountWithoutTrailingZeros() {
        String currencyCode = UserInfo.getDefaultCurrency();
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .withCurrencyIsoCode(currencyCode)
            .build();

        RD2_NamingService service = buildAutomaticNamingService(accOrg);
        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertEquals(getDefaultExpectedName(accOrg, '100', currencyCode), rd.Name, 'The amount format should match.');
    }

    /***
    * @description Verifies donor name is abbreviated if total name construct is longer
    * than max name length on Recurring Donations (80 chars)
    */
    @isTest
    private static void shouldAbbreviateDonorNameIfLengthIsOverMax() {
        String currencyCode = UserInfo.getDefaultCurrency();
        final Integer accountNameLength = 210;
        String padding = 'Company';

        accOrg.Name = String.valueOf(accOrg.Name).rightPad(accountNameLength, padding).left(accountNameLength);
        System.assertEquals(accountNameLength, accOrg.Name.length(), 'Account Name should be of max length');

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .withCurrencyIsoCode(currencyCode)
            .build();

        RD2_NamingService service = buildAutomaticNamingService(accOrg);
        service.autogenerateNames(new List<npe03__Recurring_Donation__c>{ rd });

        String expectedSuffix = '... ' + getCurrencySymbol(currencyCode) + '100 - ' + System.Label.RecurringDonationNameSuffix;
        String expectedName = accOrg.Name.left(RD2_NamingService.MAX_NAME_LENGTH - expectedSuffix.length()) + expectedSuffix;

        System.assertEquals(expectedName, rd.Name, 'Recurring Donations Name should match.');
        System.assertEquals(RD2_NamingService.MAX_NAME_LENGTH, rd.Name.length(), 'Recurring Donation Name should be of max length');
    }

    /***
    * @description Should mark Recurring Donation record as changed when its Account has changed
    */
    @isTest
    private static void shouldReturnTrueWhenAccountHasChanged() {
        List<Account> accounts = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(2, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
        UTIL_UnitTestData_TEST.setMockIds(accounts);

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accounts[0].Id)
            .withAmount(100.00)
            .build();
        npe03__Recurring_Donation__c oldRd = new TEST_RecurringDonationBuilder()
            .withAccount(accounts[1].Id)
            .withAmount(100.00)
            .build();

        RD2_NamingService service = new RD2_NamingService();
        System.assertEquals(true, service.hasChanged(rd, oldRd), 'Service should indicate RD has changed');
    }

    /***
    * @description Should mark Recurring Donation record as changed when its Contact has changed
    */
    @isTest
    private static void shouldReturnTrueWhenContactHasChanged() {
        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        UTIL_UnitTestData_TEST.setMockIds(contacts);

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(contacts[0].Id)
            .withAmount(100.00)
            .build();
        npe03__Recurring_Donation__c oldRd = new TEST_RecurringDonationBuilder()
            .withContact(contacts[1].Id)
            .withAmount(100.00)
            .build();

        RD2_NamingService service = new RD2_NamingService();
        System.assertEquals(true, service.hasChanged(rd, oldRd), 'Service should indicate RD has changed');
    }

    /***
    * @description Should mark Recurring Donation record as changed when its Amount has changed
    */
    @isTest
    private static void shouldReturnTrueWhenAmountHasChanged() {
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .build();
        npe03__Recurring_Donation__c oldRd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.25)
            .build();

        RD2_NamingService service = new RD2_NamingService();
        System.assertEquals(true, service.hasChanged(rd, oldRd), 'Service should indicate RD has changed');
    }

    /***
    * @description Should mark Recurring Donation record as changed when its CurrencyIsoCode has changed
    */
    @isTest
    private static void shouldReturnTrueWhenCurrencyHasChanged() {
        if (!isMultiCurrencyEnabled) {
            return;
        }

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .withCurrencyIsoCode(CURRENCY_USD)
            .build();
        npe03__Recurring_Donation__c oldRd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .withCurrencyIsoCode(CURRENCY_CAD)
            .build();

        RD2_NamingService service = new RD2_NamingService();
        System.assertEquals(true, service.hasChanged(rd, oldRd), 'Service should indicate RD has changed');
    }

    /***
    * @description Should mark Recurring Donation record as changed when its when name contains REPLACE keyword
    */
    @isTest
    private static void shouldReturnTrueWhenNameIsTheReplaceKeyword() {
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withName(System.Label.npo02.NameReplacementText)
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .build();
        npe03__Recurring_Donation__c oldRd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .build();

        RD2_NamingService service = new RD2_NamingService();
        System.assertEquals(true, service.hasChanged(rd, oldRd), 'Service should indicate RD has changed');
    }

    /***
    * @description Should not mark Recurring Donation record as changed
    * when no field used in the name construct has changed
    */
    @isTest
    private static void shouldReturnFalseWhenNameConstructKeyFieldsAreUnchanged() {
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .build();
        npe03__Recurring_Donation__c oldRd = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withAmount(100.00)
            .build();

        RD2_NamingService service = new RD2_NamingService();
        System.assertEquals(false, service.hasChanged(rd, oldRd), 'Service should indicate RD is unchanged');
    }

    /***
    * @description Verifies name is auto-generated only for Recurring Donation records
    * having name construct fields changed
    */
    @isTest
    private static void shouldAutogenerateNameWhenNameConstructKeyFieldsAreChanged() {
        String currencyCode = UserInfo.getDefaultCurrency();
        TEST_RecurringDonationBuilder rdBuilder = new TEST_RecurringDonationBuilder()
            .withAccount(accOrg.Id)
            .withCurrencyIsoCode(currencyCode);
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            rdBuilder.withAmount(100).build(),
            rdBuilder.withAmount(200).build()
        };
        UTIL_UnitTestData_TEST.setMockIds(rds);

        String unchangedName = rds[0].Name;

        List<npe03__Recurring_Donation__c> oldRds = new List<npe03__Recurring_Donation__c>{
            rds[0].clone(),
            rds[1].clone()
        };
        oldRds[0].Id = rds[0].Id;
        oldRds[1].Id = rds[1].Id;
        oldRds[1].npe03__Amount__c = 180;

        RD2_NamingService service = buildAutomaticNamingService(accOrg);
        service.autogenerateNamesOnChange(rds, oldRds);

        System.assertEquals(unchangedName, rds[0].Name,
            'RD Name should not change when construct key fields are unchanged');

        System.assertEquals(getDefaultExpectedName(accOrg, '200', currencyCode), rds[1].Name,
            'RD Name should change when construct key fields are changed');
    }

    /***
    * @description Verifies Donor (Account/Contact) names are queried in order to construct the name
    */
    @isTest
    private static void shouldQueryForDonorInformation() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        insert accOrg = new Account(Name = 'RD2 Query Account');

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
        contact = [SELECT FirstName, LastName, AccountId FROM Contact WHERE Id = :contact.Id];

        String currencyCode = UserInfo.getDefaultCurrency();
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            new TEST_RecurringDonationBuilder()
                .withAccount(accOrg.Id)
                .withAmount(100)
                .withCurrencyIsoCode(currencyCode)
                .build(),
            new TEST_RecurringDonationBuilder()
                .withContact(contact.Id)
                .withAccount(contact.AccountId)
                .withAmount(200)
                .withCurrencyIsoCode(currencyCode)
                .build(),
            new TEST_RecurringDonationBuilder()
                .withAccount(accOrg.Id)
                .withContact(contact.Id)
                .withAmount(300)
                .withCurrencyIsoCode(currencyCode)
                .build()
        };

        RD2_NamingService service = buildAutomaticNamingService();
        service.autogenerateNames(rds);

        System.assertEquals(getDefaultExpectedName(accOrg, '100', currencyCode), rds[0].Name,
            'The Account name should be queried and incorporated into the name');
        System.assertEquals(getDefaultExpectedName(contact, '200', currencyCode), rds[1].Name,
            'The Contact name should be queried and incorporated into the name');
        System.assertEquals(getDefaultExpectedName(accOrg, '300', currencyCode), rds[2].Name,
            'The Account name should be queried and incorporated into the name');
    }

    /**
     * @description Validate that the NameFormat parser service properly identifies only {!field} format fields in the string
     */
    @IsTest
    private static void shouldParseNameFormatProperly() {

        String nameFormat1 = '{!Field1} {!Field2} {NotAField} $!NotAField {!Field3} !NotAField} [!NotAField]'; // Should parse into 3 fields

        RD2_NamingService.NameFormatter nameFormatter = new RD2_NamingService.NameFormatter();
        nameFormatter.nameFormat = nameFormat1;

        System.assertEquals(3, nameFormatter.fields.size(), 'This should parse out 3 individual fields');
    }


    // Helpers
    //////////////////


    /***
    * @description Builds expected name
    * @param acc Recurring Donation Account
    * @param amount String representation of the expected Amount value in the name
    * @param currencyCode Currency ISO code on the record
    * @return String Expected Recurring Donation name
    */
    public static String getDefaultExpectedName(Account acc, String amount, String currencyCode) {
        return acc.Name + ' ' + getCurrencySymbol(currencyCode) + amount + ' - ' + System.Label.RecurringDonationNameSuffix;
    }

    /***
    * @description Builds expected name
    * @param contact Recurring Donation Contact
    * @param amount String representation of the expected Amount value in the name
    * @param currencyCode Currency ISO code on the record
    * @return String Expected Recurring Donation name
    */
    public static String getDefaultExpectedName(Contact contact, String amount, String currencyCode) {
        String contactName = (String.isBlank(contact.FirstName) ? '' : (contact.FirstName + ' ')) + contact.LastName;

        return contactName + ' ' + getCurrencySymbol(currencyCode) + amount + ' - ' + System.Label.RecurringDonationNameSuffix;
    }

    /**
     * @description Retrieve the expected name in the correct format based on one of the 3 supported naming formats
     * @param nameFormat format to use
     * @param period Installment Period (api name)
     * @param amount Amount
     * @param currencyCode CurrencyCode (or null)
     * @param contact Contact object
     * @param account Account object
     * @return Formatted RD name
     */
    public static String getExpectedName(String nameFormat, String period, String amount, String currencyCode, Contact contact, Account account) {
        String donorName;
        if (contact != null) {
            donorName = (String.isBlank(contact.FirstName) ? '' : (contact.FirstName + ' ')) + contact.LastName;
        } else if (account != null) {
            donorName = account.Name;
        }

        period = UTIL_Describe.getTranslatedPicklistLabel(npe03__Recurring_Donation__c.SObjectType,
            npe03__Recurring_Donation__c.npe03__Installment_Period__c, period);

        String objectLabel = UTIL_Describe.getObjectLabel('npe03__Recurring_Donation__c');

        String expectedName;
        if (nameFormat == RD2_NamingService.RD_NAMING_OPTION_1) {
            expectedName = getDefaultExpectedName(contact, amount, currencyCode);

        } else if (nameFormat == RD2_NamingService.RD_NAMING_OPTION_2) {
            expectedName = donorName + ' ' + period + ' ' + objectLabel + ' - ' + getCurrencySymbol(currencyCode) + amount;

        } else if (nameFormat == RD2_NamingService.RD_NAMING_OPTION_3) {
            expectedName = donorName + ' ' + getCurrencySymbol(currencyCode) + amount + ' ' + period;
        }

        return expectedName;
    }

    /***
    * @description Returns currency code or symbol followed by a space if it is longer than one character
    * @return String Symbol for the provided currency ISO code
    */
    private static String getCurrencySymbol() {
        return getCurrencySymbol(UserInfo.getDefaultCurrency());
    }

    /***
    * @description Returns currency code or symbol followed by a space if it is longer than one character
    * @param currencyCode Currency ISO code on the record
    * @return String Symbol for the provided currency ISO code
    */
    private static String getCurrencySymbol(String currencyCode) {
        if (String.isBlank(currencyCode)) {
            currencyCode = UserInfo.getDefaultCurrency();
        }

        String currencySymbol = UTIL_Currency.getInstance().getCurrencySymbol(currencyCode);
        if (currencySymbol.length() > 1) {
            currencySymbol += ' ';
        }

        return currencySymbol;
    }

    /***
    * @description Builds naming service instance with specified Account as donor
    * @param acc Recurring Donation Account
    * @return RD2_NamingService Instance of the Recurring Donation Naming Service
    */
    private static RD2_NamingService buildAutomaticNamingService(Account acc) {
        return buildAutomaticNamingService(new List<Account>{ acc }, new List<Contact>());
    }

    /***
    * @description Builds naming service instance with specified Accounts and Contacts as donors
    * @param accounts Recurring Donation Accounts to be returned from the Mock Donor gateway
    * @param contacts Recurring Donation Contacts to be returned from the Mock Donor gateway
    * @return RD2_NamingService Instance of the Recurring Donation Naming Service
    */
    private static RD2_NamingService buildAutomaticNamingService(List<Account> accounts, List<Contact> contacts) {
        RD2_NamingService service = buildAutomaticNamingService();

        service.donorGateway = new RD2_Donor_TEST.GatewayMock()
            .withDonors(accounts)
            .withDonors(contacts);

        return service;
    }

    /***
    * @description Constructs naming service with Automatic Naming Enabled
    * @return RD2_NamingService Instance of the Recurring Donation Naming Service
    */
    private static RD2_NamingService buildAutomaticNamingService() {
        enableAutomaticNaming();

        return new RD2_NamingService();
    }

    /***
    * @description Enables Automatic Naming Enabled for tests
    * @return none
    */
    public static void enableAutomaticNaming() {
        RD2_NamingService.isAutomaticNamingEnabled = true;

        /*
        Recurring donation DML operation start failing when RD custom settings are (re)set in tests.
        Thus, RD2_NamingService.isAutomaticNamingEnabled is set for all calling methods instead
        setting the RD custom settings field. This way we can isolate the error source in the case of exception
        since common static custom settings var is unchanged.
        The RD2_NamingService class does test the custom setting field setup and retrieval.

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                EnableAutomaticNaming__c = true,
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
                npe03__Opportunity_Forecast_Months__c = 12
            )
        );
        */
    }

    /***
    * @description Builds an Organizational Account and sets mock Id as the Id
    * @return Account Mock Account record
    */
    private static Account getOrgAccountMock() {
        return new Account(
            Name = 'Donor Company',
            Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType)
        );
    }

    /***
    * @description Builds an Organizational Account and sets mock Id as the Id
    * @return Account Mock Account record
    */
    private static Account getHHAccountMock() {

        Id hhRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'HH_Account'].Id;
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (
                npe01__HH_Account_RecordTypeID__c = hhRecordTypeId
            )
        );

        return new Account(
            Name = 'Donor Company',
            Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType),
            RecordTypeId = RD2_NamingService.hhRecordTypeId
        );
    }

    /***
    * @description Builds a Contact and sets mock Id as the Id
    * @return Mock Contact record
    */
    private static Contact getContactMock() {
        return new Contact(
            LastName = 'Smith',
            Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType)
        );
    }

}