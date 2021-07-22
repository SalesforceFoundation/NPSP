/*
    Copyright (c) 2015, Salesforce.org
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
* @date 2015
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Test class for Opportunity Naming.
*/
@isTest
public with sharing class OPP_OpportunityNaming_TEST
{
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();
    private static final Date CLOSE_DATE = Date.today().addDays(1);
    private static final String CLOSE_DATE_FORMATTED = Datetime.newInstance(CLOSE_DATE.year(), CLOSE_DATE.month(), CLOSE_DATE.day()).format('yyyy.MM.dd');
    private static final Decimal OPP_AMOUNT = 8;

    /****
     * @description Creates data required for unit tests
     */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /*********************************************************************************************************
    * @description Returns an active record type id for the current profile.
    */
    private static Boolean hasActiveRecType() {
        Schema.RecordTypeInfo giftRecTypeInfo = UTIL_RecordTypes.getRecordTypeInfoForGiftsTests(Opportunity.SObjectType);

        if (giftRecTypeInfo == null) {
            return false;
        } else {
            return giftRecTypeInfo.isAvailable();
        }
    }

    /*******************************************************************************************************
    * @description Creates an opportunity name setting and an opportunity, verifies name is calculated and
    * dates with a blank naming scheme use a default international format.
    * Modifies the value of a field and clicks the rename button, verifies rename happened correctly.
    ********************************************************************************************************/
    @isTest
    static void testButton() {
        Opportunity_Naming_Settings__c ons = new Opportunity_Naming_Settings__c(
            Name = 'foo',
            Opportunity_Name_Format__c = '{!Account.Name} {!Contact.Name} {!CloseDate} {!RecordType.Name}',
            Attribution__c = Label.oppNamingBoth
        );
        if (hasActiveRecType()) {
            ons.Opportunity_Record_Types__c = UTIL_RecordTypes.getrecordTypeIdForGiftsTests(Opportunity.sObjectType);
        }
        insert ons;

        Account acc = new Account(Name='accname');
        insert acc;

        Contact con = new Contact(LastName='conname');
        insert con;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Name='temp',
            Amount=8,
            CloseDate = Date.newInstance(2000, 1, 1),
            Primary_Contact__c = con.Id
        );
        if (hasActiveRecType()) {
            opp.RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.SObjectType));
        }
        insert opp;

        List<Opportunity> queryOpp = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        String oppName = 'accname conname 2000.01.01';
        if (hasActiveRecType()) {
            oppName += ' ' + UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.SObjectType);
        }
        System.assertEquals(oppName, queryOpp[0].Name, 'The name should be calculated based on the setting.');

        acc.Name = 'newname';
        update acc;

        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        OPP_OpportunityNamingBTN_CTRL ctrl = new OPP_OpportunityNamingBTN_CTRL(sc);

        PageReference pageRef = Page.OPP_OpportunityNamingBTN;
        Test.setCurrentPage(pageRef);

        ctrl.buttonClick();

        queryOpp = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        oppName = 'newname conname 2000.01.01';
        if (hasActiveRecType()) {
            oppName += ' ' + UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.SObjectType);
        }
        System.assertEquals(oppName, queryOpp[0].Name, 'The name should be recalculated after clicking the button.');

    }

    /*******************************************************************************************************
    * @description Creates an opportunity name setting and an opportunity with a missing field and related
    * object. Verifies name is still calculated correctly with blanks instead of missing fields/objects.
    ********************************************************************************************************/
    @isTest
    static void testMissingData() {
        Opportunity_Naming_Settings__c ons = new Opportunity_Naming_Settings__c(
            Name = 'foo',
            Opportunity_Name_Format__c = '{!Account.Name} {!Account.npe01__One2OneContact__r.Primary_Affiliation__r.Name} {!Campaign.Name} {!Type} {!RecordType.Name}',
            Attribution__c = Label.oppNamingBoth
        );
        if (hasActiveRecType()) {
            ons.Opportunity_Record_Types__c = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);
        }

        insert ons;

        Account acc = new Account(Name='accname');
        insert acc;

        Contact con = new Contact(LastName='conname');
        insert con;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Name='temp',
            Amount=8,
            CloseDate = Date.newInstance(2000, 1, 1),
            npe01__Contact_Id_for_Role__c = con.Id
        );
        if (hasActiveRecType()) {
            opp.RecordTypeId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType,
                UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.SObjectType));
        }
        insert opp;

        List<Opportunity> queryOpp = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];

        String oppname = 'accname';
        if (hasActiveRecType()) {
            oppname += ' ' + UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.SObjectType);
        }
        System.assertEquals(oppname, queryOpp[0].Name, 'The name should be calculated based on the setting; missing fields should be excluded.');

    }

    /*******************************************************************************************************
    * @description Inserts 100 opportunities related to 100 accounts, and one opportunity related to a
    * contact. Verifies naming hasn't happened as naming settings haven't been inserted. Insert settings,
    * run batch naming job. Verify both types of opportunities have been named correctly.
    ********************************************************************************************************/
    @isTest
    static void testBulk() {
        list<Opportunity_Naming_Settings__c> onsList = new list<Opportunity_Naming_Settings__c>();
        onsList.add(new Opportunity_Naming_Settings__c(
            Name = 'foo',
            Opportunity_Record_Types__c = '',
            Opportunity_Name_Format__c = '{!Account.Name} {!Amount} {!Type} {!RecordType.Name}',
            Attribution__c = STG_PanelOppNaming_CTRL.AttributionOptions.Organization_Donations.name()
        ));
        onsList.add(new Opportunity_Naming_Settings__c(
            Name = 'foo2',
            Opportunity_Name_Format__c = '{!Contact.Name} {!Contact.HasOptedOutOfFax} {!Type} {!RecordType.Name}',
            Attribution__c = STG_PanelOppNaming_CTRL.AttributionOptions.Contact_Donations.name()
        ));

        if (hasActiveRecType()) {
            onsList[1].Opportunity_Record_Types__c = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);
        }

        Contact con = new Contact(LastName='conname', HasOptedOutOfFax=true);
        insert con;

        List<Contact> queryCon = [SELECT Id, AccountId FROM Contact WHERE Id = :con.Id];

        List<Account> listAcc = UTIL_UnitTestData_TEST.createMultipleTestAccounts(10, null);
        insert listAcc;

        List<Opportunity> listOpp = UTIL_UnitTestData_TEST.oppsForAccountListByRecTypeId(
            listAcc,
            null,
            UTIL_UnitTestData_TEST.getClosedWonStage(),
            Date.newInstance(2000, 1, 1),
            8, null,null);

        Opportunity opp = new Opportunity(
            AccountId = queryCon[0].AccountId,
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Name='Test',
            Amount=8.8,
            CloseDate = Date.newInstance(2000, 1, 1),
            npe01__Contact_Id_for_Role__c = con.id
        );
        if (hasActiveRecType()) {
            opp.RecordTypeId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SObjectType);
        }
        listOpp.add(opp);
        insert listOpp;

        //inserting settings after the fact so opps aren't named prematurely
        insert onsList;

        //blank out cached version so the inserted setting takes effect
        UTIL_ListCustomSettingsFacade.mapOppNamingSettings = null;

        //verify opps haven't been renamed yet
        List<Opportunity> queryOpp = [SELECT Name FROM Opportunity WHERE Id IN :listOpp];
        for (Opportunity thisopp : queryOpp) {
            System.assert(thisopp.Name.contains('Test'));
        }

        Test.startTest();
        STG_PanelOppNamingBatch_CTRL ctrl = new STG_PanelOppNamingBatch_CTRL();
        ctrl.runBatch();

        Test.stopTest();

        queryOpp = [
            SELECT Name, RecordType.Name, Account.npe01__SYSTEMIsIndividual__c
            FROM Opportunity
            WHERE AccountId = :queryCon[0].AccountId];

        String oppname = 'conname true';
        if (hasActiveRecType()) {
            oppname += ' ' + UTIL_RecordTypes.getrecordTypeNameForGiftsTests(Opportunity.SObjectType);
        }
        System.assertEquals(oppname, queryOpp[0].Name, 'The name should be calculated based on the individual attributed setting.');

        queryOpp = [SELECT Name FROM Opportunity WHERE AccountId != :queryCon[0].AccountId];

        for (Opportunity thisopp : queryOpp) {
            System.assert(!thisopp.Name.contains('8.00'), 'Opportunities have been renamed by batch process.');
            System.assert(thisopp.Name.contains('8'), 'Opportunities have been renamed by batch process.');
        }
    }

    /*******************************************************************************************************
    * @description Creates an invalid opportunity name setting. Inserts an opportunity. Verifies name left
    * unchanged and no exception is thrown.
    ********************************************************************************************************/
    @isTest
    static void testException() {
        Opportunity_Naming_Settings__c ons = new Opportunity_Naming_Settings__c(
            Name = 'foo',
            Opportunity_Name_Format__c = '{!Account.Invalid_Field}',
            Attribution__c = Label.oppNamingBoth
        );
        insert ons;

        Account acc = new Account(Name='accname');
        insert acc;

        Contact con = new Contact(LastName='conname');
        insert con;

        Opportunity opp = new Opportunity(
            AccountId = acc.id,
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Name='temp',
            Amount=8,
            CloseDate = Date.newInstance(2000, 1, 1),
            npe01__Contact_Id_for_Role__c = getContact().id
        );

        Exception oppException;

        Test.startTest();
        try {
            insert opp;
        } catch (Exception ex) {
            oppException = ex;
        }
        Test.stopTest();

        system.assertEquals(null, oppException, 'No exception should be thrown.');
        list<Opportunity> queryOpp = [SELECT Name FROM Opportunity WHERE Id = :opp.id];
        system.assertEquals('temp', queryOpp[0].Name, 'The name should not be calculated, as it is an invalid format based on the setting.');
        List<Error__c> errors = [select Id from Error__c];
        System.assertEquals(1, errors.size(), 'An error record should be created.');

    }

     /***
    * @description Verify the Opportunity name is generated when
    * non-English user creates an Opportunity
    */
    @isTest
    private static void shouldGenerateOppNameWhenNonEnglishUserCreatesAnOpp() {
        String optionName = STG_PanelOppNaming_CTRL.AttributionOptions.Both.name();
        setUpOppNamingSettings(new Map<String, Object>{ 'Attribution__c' => optionName });

        Contact contact = getContact();

        System.runAs(buildSpanishUser()) {
            Opportunity opp = buildOpportunity(contact.Id);
            insert opp;

            String oppName = oppGateway.getRecord(opp.Id).Name;

            String expectedName = contact.Name
                + ' $' + OPP_AMOUNT
                + ' ' + CLOSE_DATE_FORMATTED;
            System.assertEquals(expectedName, oppName, 'The name should be generated based on the setting; missing fields should be excluded.');
        }
    }

    /***
    * @description Verify the Opportunity name is re-generated when
    * non-English user clicks refresh name button
    */
    @isTest
    private static void shouldGenerateOppNameWhenNonEnglishUserClicksRefreshName() {
        String optionName = STG_PanelOppNaming_CTRL.AttributionOptions.Contact_Donations.name();
        setUpOppNamingSettings(new Map<String, Object>{ 'Attribution__c' => optionName });

        Contact contact = getContact();
        Opportunity opp;

        System.runAs(buildSpanishUser()) {
            opp = buildOpportunity(contact.Id);
            insert opp;
        }

        Decimal newAmount = OPP_AMOUNT + 10;
        opp = oppGateway.getRecord(opp.Id);
        opp.Amount = newAmount;
        update opp;

        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        OPP_OpportunityNamingBTN_CTRL ctrl = new OPP_OpportunityNamingBTN_CTRL(sc);

        PageReference pageRef = Page.OPP_OpportunityNamingBTN;
        pageRef.getParameters().put('id', String.valueOf(opp.Id));
        Test.setCurrentPage(pageRef);

        ctrl.buttonClick();

        String expectedName = contact.Name
            + ' $' + newAmount
            + ' ' + CLOSE_DATE_FORMATTED;
        System.assertEquals(expectedName, opp.Name, 'The name should be updated after the refresh name button is clicked.');
    }

    /***
    * @description Verify the Opportunity name is generated
    * when non-English user executes the Opp Naming batch
    */
    @isTest
    private static void shouldGenerateOppNameWhenNonEnglishUserExecutesTheBatch() {
        Opportunity opp;
        Contact contact = getContact();

        System.runAs(buildSpanishUser()) {
            opp = buildOpportunity(contact.Id);
            String originalOppName = opp.Name;
            insert opp;

            System.assertEquals(originalOppName, oppGateway.getRecord(opp.Id).Name,
                'The name should not be generated since naming is not configured in settings');

            String optionName = STG_PanelOppNaming_CTRL.AttributionOptions.Contact_Donations.name();
            setUpOppNamingSettings(new Map<String, Object>{ 'Attribution__c' => optionName });

            Test.startTest();
            STG_PanelOppNamingBatch_CTRL ctrl = new STG_PanelOppNamingBatch_CTRL();
            ctrl.runBatch();
            Test.stopTest();
        }

        String expectedName = contact.Name
            + ' $' + OPP_AMOUNT
            + ' ' + CLOSE_DATE_FORMATTED;
        System.assertEquals(expectedName, oppGateway.getRecord(opp.Id).Name,
            'The name should be generated after the batch is run.');
    }

    /***
    * @description Verifies Attribution value specified in settings is correctly
    * converted to the expected AttributionOption and label
    */
    @isTest
    private static void attributionSettingsShouldReturnSelectedOptionAndLabel() {
        STG_PanelOppNaming_CTRL.AttributionOptions option = STG_PanelOppNaming_CTRL.AttributionOptions.Both;
        String label = System.Label.oppNamingBoth;

        assertSelectedAttribution(System.Label.oppNamingBoth, option, label);
        assertSelectedAttribution(option.name(), option, label);

        option = STG_PanelOppNaming_CTRL.AttributionOptions.Contact_Donations;
        label = System.Label.oppNamingIndividual;

        assertSelectedAttribution(System.Label.oppNamingIndividual, option, label);
        assertSelectedAttribution(option.name(), option, label);
        assertSelectedAttribution('Contact Donations', option, label);

        option = STG_PanelOppNaming_CTRL.AttributionOptions.Organization_Donations;
        label = System.Label.oppNamingOrganizational;

        assertSelectedAttribution(System.Label.oppNamingOrganizational, option, label);
        assertSelectedAttribution(option.name(), option, label);
        assertSelectedAttribution('Organization Donations', option, label);
    }

    /***
    * @description Verifies expected AttributionOption is null and label is blank
    * when settings Attribution is null
    */
    @isTest
    private static void attributionSettingsShouldReturnBlankLabelWhenAttributionIsNull() {
        STG_PanelOppNaming_CTRL.AttributionSettings attributionSettings = new STG_PanelOppNaming_CTRL.AttributionSettings()
            .withSelected(null);

        System.assertEquals(null, attributionSettings.selectedOption,
            'The selected Attribution option should be null'
        );

        System.assertEquals('', attributionSettings.selectedLabel,
            'The selected Attribution label should be blank'
        );
    }

    /***
    * @description Verifies expected AttributionOption and label are the same as
    * settings Attribution value when it is not recognized as the AttributionOption
    */
    @isTest
    private static void attributionSettingsShouldReturnValueAsIsWhenAttributionIsNotAnOption() {
        String attribution = 'foo';
        STG_PanelOppNaming_CTRL.AttributionSettings attributionSettings = new STG_PanelOppNaming_CTRL.AttributionSettings()
            .withSelected(attribution);

        System.assertEquals(attribution, attributionSettings.selectedOption,
            'The selected Attribution option should match input value'
        );

        System.assertEquals(attribution, attributionSettings.selectedLabel,
            'The selected Attribution label should match input value when option is not recognized'
        );
    }

    /***
    * @description Asserts Attribution value specified in settings is correctly
    * converted to the expected AttributionOption and label
    * @param attribution Attribution value as provied in the settings
    * @param option Epxected Attribution option
    * @param label Expected Attribution label
    * @return void
    */
    private static void assertSelectedAttribution(String attribution, STG_PanelOppNaming_CTRL.AttributionOptions option, String label) {
        STG_PanelOppNaming_CTRL.AttributionSettings attributionSettings = new STG_PanelOppNaming_CTRL.AttributionSettings()
            .withSelected(attribution);

        System.assertEquals(option.name(), attributionSettings.selectedOption,
            'The selected Attribution option should match'
        );

        System.assertEquals(label, attributionSettings.selectedLabel,
            'The selected Attribution label should match'
        );
    }

    /***
    * @description Verifies attribution options are returned as SelectOptions
    */
    @isTest
    private static void attributionSettingsShouldReturnSelectOptions() {
        List<STG_PanelOppNaming_CTRL.AttributionOptions> options = STG_PanelOppNaming_CTRL.AttributionOptions.values();

        List<SelectOption> selectOptions = STG_PanelOppNaming_CTRL.listSOOpportunityAttribution;

        System.assertEquals(options.size(), selectOptions.size(), 'Panel should return options');
        for (Integer i = 0; i < options.size(); i++) {
            System.assertEquals(options[i].name(), selectOptions[i].getValue(), 'Options should match');
        }
    }

    /***
    * @description Verifies isBoth() returns true when settings Attribution value is Both
    */
    @isTest
    private static void attributionSettingsShouldReturnTrueWhenOptionIsBoth() {
        STG_PanelOppNaming_CTRL.AttributionSettings attributionSettings = new STG_PanelOppNaming_CTRL.AttributionSettings()
            .withSelected(STG_PanelOppNaming_CTRL.AttributionOptions.Both.name());

        System.assertEquals(true, attributionSettings.isBoth(),
            'The selected Attribution option should be Both'
        );

        attributionSettings.withSelected(System.Label.oppNamingBoth);

        System.assertEquals(true, attributionSettings.isBoth(),
            'The selected Attribution option should be Both'
        );
    }

    /***
    * @description Verifies isBoth() returns false when settings Attribution value is not Both
    */
    @isTest
    private static void attributionSettingsShouldReturnFalseWhenOptionIsNotBoth() {
        STG_PanelOppNaming_CTRL.AttributionSettings attributionSettings = new STG_PanelOppNaming_CTRL.AttributionSettings()
            .withSelected(STG_PanelOppNaming_CTRL.AttributionOptions.Contact_Donations.name());

        System.assertEquals(false, attributionSettings.isBoth(),
            'The selected Attribution option should not be Both'
        );

        attributionSettings.withSelected(System.Label.oppNamingOrganizational);

        System.assertEquals(false, attributionSettings.isBoth(),
            'The selected Attribution option should not be Both'
        );
    }

    // Helpers
    //////////////

    /***
     * @description Builds a user using Spanish language and locale
     * @return User
     */
    private static User buildSpanishUser() {
        User usr = UTIL_UnitTestData_Test.createUserWithoutInsert(UTIL_Profile.PROFILE_STANDARD_USER);

        usr.LanguageLocaleKey = 'es';
        usr.LocaleSidKey = 'es';
        return usr;
    }

    /***
     * @description Creates Opportunity naming settings
     * @param valueByField Other field values mapped by their field name
     * @return Opportunity Naming Settings
     */
    public static Opportunity_Naming_Settings__c setUpOppNamingSettings(Map<String, Object> valueByField) {
        Opportunity_Naming_Settings__c settings = new Opportunity_Naming_Settings__c(
            Name = 'foo',
            Opportunity_Name_Format__c = '{!Contact.Name} {!Amount} {!CloseDate} '
        );

        for (String field : valueByField.keySet()) {
            settings.put(field, valueByField.get(field));
        }
        insert settings;

        UTIL_ListCustomSettingsFacade.mapOppNamingSettings = null;

        return settings;
    }

    /***
     * @description Builds opportunity with specified fields
     * @param contactId The contact assigned to the opportunity
     * @return Opportunity
     */
    private static Opportunity buildOpportunity(Id contactId) {
        return new TEST_OpportunityBuilder()
            .withAmount(OPP_AMOUNT)
            .withContact(contactId)
            .withClosedWonStage()
            .withCloseDate(CLOSE_DATE)
            .build();
    }

    /***
     * @description Returns contact record
     * @return Contact
     */
    private static Contact getContact() {
        return [
            SELECT Name, FirstName, LastName, AccountId, Account.Name
            FROM Contact
            LIMIT 1
        ];
    }

}