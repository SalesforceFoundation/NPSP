/*
    Copyright (c) 2011, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this List of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this List of conditions and the following disclaimer in the
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
* @date 2011 (1.x)
* @group Utilities
* @description Contains methods to create test data in various configurations as well to to retrieve specific settings,
* Disable TDTM triggers by function, check org configurations, etc.
*/

@isTest
public class UTIL_UnitTestData_TEST {

    /** @description A mock Account Id .*/
    public static final String MOCK_ACCOUNT_ID = Account.SObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';

    public static final String PROFILE_STANDARD_USER = UTIL_Profile.PROFILE_STANDARD_USER;
    public static final String PROFILE_READONLY_USER = UTIL_Profile.PROFILE_READ_ONLY;

    // =====================================================================================================
    // Methods to retrieve configured Stage/Status labels for the Opportunity and Task objects
    // =====================================================================================================

    public static String closedWonStage;
    public static String closedLostStage;
    public static String openStage;
    public static String closedTaskStatus;
    public static String openTaskStatus;

    /**
     * @description Retrieve the MasterLabel for the defined ClosedWon stage in the org for tests
     */
    public static String getClosedWonStage() {
        if (closedWonStage == null) {
            List<OpportunityStage> closedWonStages = [
                SELECT MasterLabel
                FROM OpportunityStage
                WHERE IsActive = TRUE
                AND IsWon = TRUE
            ];

            if (closedWonStages.size()>0) {
                closedWonStage = closedWonStages[0].MasterLabel;
            } else {
                closedWonStage = '';
            }
        }

        return closedWonStage;
    }

    /**
     * @description Retrieve the MasterLabel for the defined ClosedLost stage in the org for tests
     */
    public static String getClosedLostStage() {
        if (closedLostStage == null) {
            List<OpportunityStage> closedLostStages = [
                SELECT MasterLabel
                FROM OpportunityStage
                WHERE IsActive = TRUE
                AND IsWon = FALSE
                AND IsClosed = TRUE
            ];

            if (closedLostStages.size()>0) {
                closedLostStage = closedLostStages[0].MasterLabel;
            } else {
                closedLostStage = '';
            }
        }

        return closedLostStage;
    }

    /**
     * @description Retrieve the MasterLabel for the first open stage in the org for tests
     */
    public static String getOpenStage() {
        if (openStage == null) {
            List<OpportunityStage> openStages = [
                SELECT MasterLabel
                FROM OpportunityStage
                WHERE IsActive = TRUE
                AND IsWon = FALSE
            ];

            if (openStages.size()>0) {
                openStage = openStages[0].MasterLabel;
            } else {
                openStage = '';
            }
        }

        return openStage;
    }

    /**
     * @description Retrieve the MasterLabel for the defined Closed Task Status in the org for tests
     */
    public static String getClosedTaskStatus() {
        if (closedTaskStatus == null) {
            List<TaskStatus> closedTaskStatuses = [SELECT MasterLabel FROM TaskStatus WHERE IsClosed = true];

            if (closedTaskStatuses.size()>0) {
                closedTaskStatus = closedTaskStatuses[0].MasterLabel;
            } else {
                closedTaskStatus = '';
            }
        }

        return closedTaskStatus;
    }

    /**
     * @description Retrieve the MasterLabel for the first defined Open Task Status in the org for tests
     */
    public static String getOpenTaskStatus() {
        if (openTaskStatus == null) {
            List<TaskStatus> openTaskStatuses = [SELECT MasterLabel FROM TaskStatus WHERE IsClosed = false];

            if (openTaskStatuses.size()>0) {
                openTaskStatus = openTaskStatuses[0].MasterLabel;
            } else {
                openTaskStatus = '';
            }
        }

        return openTaskStatus;
    }

    // =====================================================================================================
    // Data Factory Methods - Contact, Account, Opportunity, Engagement Plan
    // =====================================================================================================

    /**
     * @description Return a single Contact SObject for tests with a unique last name
     * @return Contact
     */
    public static Contact getContact() {
        return new Contact (
            FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + getUniqueString(),
            npe01__Private__c = false,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
            OtherCity = 'Seattle'
        );
    }

    /**
     * @description Return a list of Contact SObjects for tests with a unique first and last name
     * @param n The number of Contact records to create
     * @return List<Contact>
     */
    public static List<Contact> createMultipleTestContacts(Integer n) {

        List<Contact> contactsToAdd = new List<Contact> ();

        for (Integer i=0; i<n; i++) {
            Contact newCon = getContact();
            newCon.FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS + getUniqueString();
            newCon.LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS;
            if (RLLP_OppRollup_UTIL.isMultiCurrency()) {
                newCon.put(RLLP_OppRollup_UTIL.mcFieldValues.get('Contact'), RLLP_OppRollup_UTIL.currCorporate);
            }

            contactsToAdd.add (newCon);
        }

        return contactsToAdd;
    }

    /**
     * @description Create an Opportunity for each Contact, but does not specify the AccountId on the Opportunity
     * @param contact List of Contacts to create Opps for
     * @param campaignId The CampaignId to use (or null)
     * @param stage The StageName to use (required)
     * @param closeDate The Closedate to use (required)
     * @param amt The Opp Amount (required)
     * @param recordTypeName The RecordType Label for the Opportunity (or null)
     * @param oppType The Opportunity.Type for the Opportunity (or null)
     * @return List<Opportunity>
     */
    public static List<Opportunity> oppsForContactList(List<Contact> contacts, Id campaignId,
            String stage, Date closeDate, Double amt, String recordTypeName, String oppType
    ) {
        Id rtId = UTIL_RecordTypes.getRecordTypeId (Opportunity.SObjectType, recordTypeName);
        return oppsForContactListByRecTypeId(contacts, campaignId, stage, closeDate, amt, rtId, oppType);
    }

    /**
     * @description Create an Opportunity for each Contact, but does not specify the AccountId on the Opportunity
     * @param contact List of Contacts to create Opps for
     * @param campaignId The CampaignId to use (or null)
     * @param stage The StageName to use (required)
     * @param closeDate The Closedate to use (required)
     * @param amt The Opp Amount (required)
     * @param rtId The RecordTypeId for the Opportunity (or null)
     * @param oppType The Opportunity.Type for the Opportunity (or null)
     * @return List<Opportunity>
     */
    public static List<Opportunity> oppsForContactListByRecTypeId(List<Contact> contacts, Id campaignId,
        String stage, Date closeDate, Double amt, Id rtId, String oppType
    ) {

        List<Opportunity> oppsToAdd = new List<Opportunity> ();

        for ( Contact thisCon : contacts ) {
            Opportunity newOpp = new Opportunity (
                Name = 'Test Opp ' + thisCon.FirstName + thisCon.LastName,
                Amount = amt,
                CloseDate = closeDate,
                StageName = stage,
                CampaignId = campaignId,
                Primary_Contact__c = thisCon.Id,
                Type = oppType
            );
            if (rtId != null) {
                newOpp.put('RecordTypeId', rtId);
            }
            oppsToAdd.add (newOpp);
        }
        return oppsToAdd;
    }

    /**
     * @description Create an Opportunity for each Contact, using their Account as the Opportunity's Account.
     * @param contact List of Contacts to create Opps for
     * @param campaignId The CampaignId to use (or null)
     * @param stage The StageName to use (required)
     * @param closeDate The Closedate to use (required)
     * @param amt The Opp Amount (required)
     * @param recordTypeName The RecordType Label for the Opportunity (or null)
     * @param oppType The Opportunity.Type for the Opportunity (or null)
     * @return List<Opportunity>
     */
    public static List<Opportunity> oppsForContactWithAccountList(List<Contact> contacts, Id campaignId,
            String stage, Date closeDate, Double amt, String recordTypeName, String oppType
    ) {
        Id rtId = UTIL_RecordTypes.getRecordTypeId (Opportunity.SObjectType,recordTypeName);
        return oppsForContactWithAccountListByRecTypeId(contacts, campaignId, stage, closeDate, amt, rtId, oppType);
    }

    /**
     * @description Create an Opportunity for each Contact, using their Account as the Opportunity's Account.
     * @param contact List of Contacts to create Opps for
     * @param campaignId The CampaignId to use (or null)
     * @param stage The StageName to use (required)
     * @param closeDate The Closedate to use (required)
     * @param amt The Opp Amount (required)
     * @param rtId The RecordTypeId for the Opportunity (or null)
     * @param oppType The Opportunity.Type for the Opportunity (or null)
     * @return List<Opportunity>
     */
    public static List<Opportunity> oppsForContactWithAccountListByRecTypeId (List<Contact> contacts, Id campaignId,
            String stage, Date closeDate, Double amt, Id rtId, String oppType
    ) {

        List<Opportunity> oppsToAdd = new List<Opportunity> ();

        for (Contact thisCon : contacts) {
            Opportunity newOpp = new Opportunity (
                Name = 'Test Opp ' + thisCon.FirstName + thisCon.LastName,
                Amount = amt,
                CloseDate = closeDate,
                StageName = stage,
                CampaignId = campaignId,
                AccountId = thisCon.AccountId,
                Primary_Contact__c = thisCon.Id,
                Type = oppType
            );
            if (rtId != null) {
                newOpp.put('RecordTypeId', rtId);
            }
            oppsToAdd.add (newOpp);
        }
        return oppsToAdd;
    }

    /**
     * @description Create one Opportunity per Account for a provided list of Accounts
     * @param accounts List of Accounts to create Opps for
     * @param campaignId The CampaignId to use (or null)
     * @param stage The StageName to use (required)
     * @param closeDate The Closedate to use (required)
     * @param amt The Opp Amount (required)
     * @param recordTypeName The RecordType Label for the Opportunity (or null)
     * @param oppType The Opportunity.Type for the Opportunity (or null)
     * @return List<Opportunity>
     */
    public static List<Opportunity> oppsForAccountList (List<Account> accounts, Id campId, String stage,
            Date closeDate, Double amt, String recordTypeName, String oppType) {
        Id rtId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, recordTypeName);
        return oppsForAccountListByRecTypeId(accounts, campId, stage, closeDate, amt, rtId, oppType);
    }

    /**
     * @description Create one Opportunity per Account for a provided list of Accounts
     * @param accounts List of Accounts to create Opps for
     * @param campaignId The CampaignId to use (or null)
     * @param stage The StageName to use (required)
     * @param closeDate The Closedate to use (required)
     * @param amt The Opp Amount (required)
     * @param rtId The RecordTypeId for the Opportunity (or null)
     * @param oppType The Opportunity.Type for the Opportunity (or null)
     * @return List<Opportunity>
     */
    public static List<Opportunity> oppsForAccountListByRecTypeId (List<Account> accounts, Id campaignId,
            String stage, Date closeDate, Double amt, Id rtId, String oppType
    ) {

        List<Opportunity> oppsToAdd = new List<Opportunity> ();

        for (Account acc : accounts) {
            Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ' + acc.Name,
                AccountId = acc.Id,
                Amount = amt,
                CloseDate = closeDate,
                StageName = stage,
                CampaignId = campaignId,
                Type = oppType
            );
            if (rtId != null) {
                newOpp.put('RecordTypeId', rtId);
            }
            oppsToAdd.add (newOpp);
        }
        return oppsToAdd;
    }

    /**
     * @description Creates a defined number of Test Account records of the specified "Type"
     * @param n Number of Accounts to create
     * @param strType CAO_Constants.BUCKET_ORGANIZATION_TYPE, ONE_TO_ONE_ORGANIZATION_TYPE
     * @return List<Account>
     */
    public static List<Account> createMultipleTestAccounts (Integer n, String strType) {

        List<Account> accountsToAdd = new List<Account> ();

        for (Integer i=0; i<n; i++) {
            Account newAcct = new Account (
                Name = 'Test Account ' + getUniqueString(),
                npe01__SYSTEM_AccountType__c = strType
            );
            if (strType != null) {
                newAcct.npe01__SYSTEMIsIndividual__c = true;
                if (strType == CAO_Constants.BUCKET_ORGANIZATION_TYPE) {
                    newAcct.Name = CAO_Constants.BUCKET_ACCOUNT_NAME;
                }
            }
            accountsToAdd.add (newAcct);
        }

        return accountsToAdd;
    }

    /**
     * @description Builds an Organization Account
     * @return Account
     */
    public static Account buildOrganizationAccount() {
        return new Account(
            Name = getUniqueString(),
            npe01__SYSTEMIsIndividual__c = false
        );
    }

    /***
    * @description Builds a Household Account
    * @return Account
    */
    public static Account buildHouseholdAccount() {
        return createMultipleTestAccounts(1, CAO_Constants.HH_ACCOUNT_TYPE)[0];
    }


    public static List<Account> listAccT;
    public static List<Contact> listConT;

    /*********************************************************************************************************
    * @description Creates x accounts of the given type, each with y Contacts each with a unique name
    * and mailing address
    * @param accType The Account Type to create (CAO_Constants.HH_ACCOUNT_TYPE, etc.)
    * @param cAcc the number of Accounts to create
    * @param cCon the number of Contacts to create per Account
    * @param iUnique the number to start with when naming the contacts and addresses
    * @return  void
    **********************************************************************************************************/
    public static void createAccountContactTestData(String accType, Integer cAcc, Integer cCon, Integer iUnique) {

        listConT = createMultipleTestContacts(cAcc * cCon);
        listAccT = createMultipleTestAccounts(cAcc, accType);
        insert listAccT;

        for (Integer i = 0; i < cAcc; i++) {
            for (Integer j = 0; j < cCon; j++) {
                Integer iCon = (i * cCon) + j;
                String unique = getUniqueString();

                Contact con = listConT[iCon];
                con.FirstName = 'TestFirstName' + iUnique + iCon;
                con.LastName = 'TestLastName' + iUnique + iCon + unique;
                con.AccountId = listAccT[i].Id;
                con.MailingStreet = 'Street' + iUnique + iCon + unique;
                con.MailingCity = 'City' + iUnique + iCon;
            }
        }
        insert listConT;
    }

    //Utility method for creating a sample template.
    public static FORM_Template createSampleTemplate () {
        
        FORM_Element field = new FORM_Element('field',
                                              'True',
                                               null,
                                               'CustomLabel',
                                               new List<String>{'Account_1_Name','Account_1_Country'});
        
        FORM_Element widget = new FORM_Element('widget',
                                               'DisplayRule',
                                               'ComponentName',
                                                new List<String>{'Contact_1_First_Name',                        'Contact_1_Last_Name'});
        
        FORM_Element[] elements = new FORM_Element[]{field,widget};

        FORM_Section section = new FORM_Section('SectionLabel',
                                                'Accordion',
                                                'Expanded',
                                                'True',
                                                elements);
        
        FORM_Layout layout = new FORM_Layout('DefaultMappingSet',
                                            new FORM_Section[]{section});

        FORM_Template template = new FORM_Template('Sample Template',
                                                   'This is the description.',
                                                   '1.0',
                                                   layout);
        return template;
    }

    //Utility method for creating sample column headers.
    public static List<Custom_Column_Header__c> createSampleColumnHeaders () {
        
        Custom_Column_Header__c columnHeader = new Custom_Column_Header__c();
        columnHeader.Name = 'sampleColumnHeader';
        columnHeader.List_Name__c = 'Sample List';
        columnHeader.Index__c = 0;
        columnHeader.Field_Api_Name__c = 'Sample_Field__c';

        Custom_Column_Header__c columnHeader2 = new Custom_Column_Header__c();
        columnHeader2.Name = 'sampleColumnHeader2';
        columnHeader2.List_Name__c = 'Sample List 2';
        columnHeader2.Index__c = 0;
        columnHeader2.Field_Api_Name__c = 'Sample_Field_2__c';

        Custom_Column_Header__c columnHeader3 = new Custom_Column_Header__c();
        columnHeader3.Name = 'sampleColumnHeader3';
        columnHeader3.List_Name__c = 'Sample List 2';
        columnHeader3.Index__c = 1;
        columnHeader3.Field_Api_Name__c = 'Sample_Field_3__c';

        return new List<Custom_Column_Header__c> { columnHeader, columnHeader2, columnHeader3 };
    }

    // Method to create instance of field mappings to use in test data
    public static BDI_MappingServiceAdvanced createSampleFieldMappings() {
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c =                                                            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance(
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME, true);
        
        return mappingService;
    }

    /**
     * @description Create Engagement Plan Templates for unit testing.
     * @param n The number of Engagement Plan Templates to be created
     * @return List of Engagement Plan Templates
     */
    public static List<Engagement_Plan_Template__c> createEPTemplates (Integer n) {
        List<Engagement_Plan_Template__c> EPTemplatesToAdd = new List<Engagement_Plan_Template__c>();

        for (Integer i=0 ;i<n; i++) {
            EPTemplatesToAdd.add(new Engagement_Plan_Template__c(Name = 'Test ' + getUniqueString()));
        }

        return EPTemplatesToAdd;
    }

    /**
     * @description Create Engagement Plan Tasks for unit testing.
     * @param n The number of Engagement Plan Tasks per Template to be created
     * @param listEPTemplates The templates the EP Tasks will belong to
     * @return List of Engagement Plan Templates
     */
    public static List<Engagement_Plan_Task__c> createEPTasksForTemplates (Integer n, List<Engagement_Plan_Template__c> listEPTemplates) {
        List<Engagement_Plan_Task__c> EPTasksToAdd = new List<Engagement_Plan_Task__c>();

        for (Engagement_Plan_Template__c epTemplate : listEPTemplates) {
            for (Integer i=0 ;i<n; i++) {
                EPTasksToAdd.add(
                    new Engagement_Plan_Task__c(
                    Engagement_Plan_Template__c = epTemplate.Id,
                    Priority__c = 'Medium'
                    )
                );
            }
        }

        return EPTasksToAdd;
    }

    // =====================================================================================================
    // Methods to Create Test Users
    // =====================================================================================================

    /**
     * @description Create a new user for unit testing.
     * @param strUsername The username for the user to be created
     * @param strRolename The name of the UserRole to associate with the user (will be created if does not exist)
     * @return User
     */
    public static User createNewUserWithRoleForTests(String strUsername, String strRolename) {
        UserRole r;
        User u;

        // to work around mixed DML errors during tests, you must
        // create user roles and accounts in their own transactions.
        // got this hack from the web.
        System.runAs(getCurrentUserForRunAs()) {
            Integer existingRoleCount = [
                SELECT COUNT()
                FROM UserRole
                WHERE Name = :strRolename
            ];

            if (existingRoleCount >= 1) {
                r = [
                    SELECT Id
                    FROM UserRole
                    WHERE Name = :strRolename
                    LIMIT 1
                ];
            } else {
                r = new UserRole(Name=strRolename);
                insert r;
            }

            u = buildUser('Smith', PROFILE_STANDARD_USER);
            u.UserRoleId = r.Id;
            u.Username = strUsername;

            insert u;
        }
        return u;
    }

    /**
     * @description Create a new user for unit testing.
     * @param strUsername The username for the user to be created
     * @return User
     */
    public static User createNewUserForTests(String strUsername) {
        return createNewUserWithRoleForTests(strUsername, 'COO');
    }

    /**
     * @description Create a new inactive user for unit testing.  This user will have IsActive set to false.
     * @param strUsername The username for the user to be created
     * @return User
     */
    public static User createNewInactiveUserForTests(String strUsername) {
        User u = createNewUserForTests(strUsername);

        System.runAs(UTIL_UnitTestData_TEST.getCurrentUserForRunAs())  {
            u.IsActive = false;
            update u;
        }

        return u;
    }

    /**
     * @description Create a User having Standard User profile assigned
     * @return User
     */
    public static User createStandardProfileUser() {
        return createUser(PROFILE_STANDARD_USER);
    }

    /**
     * @description Create a User having specified profile assigned
     * @param profileName Profile Name
     * @return Inserted User
     */
    public static User createUser(String profileName) {
        User u = createUserWithoutInsert(profileName);

        //create the user
        System.runAs(u) {}

        return u;
    }

    /**
     * @description Build a User having specified profile assigned, but do not insert
     * @param profileName Profile Name
     * @return User
     */
    public static User createUserWithoutInsert(String profileName) {
        return buildUser(buildUniqueLastName(), profileName);
    }

    /**
      * @description Generate a unique string to append to indexed fields to make them unique
      */
    public static String getUniqueString() {
        return String.valueOf(Math.abs(Crypto.getRandomLong()));
    }

    /**
     * @description Construct a unique last name to be assigned to a User
     * @return String
     */
    private static String buildUniqueLastName() {
        return UserInfo.getOrganizationId() +
            String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','') +
            Integer.valueOf(Math.rint(Math.random()*2000000));
    }

    /**
     * @description Build a new User using the Locale and Language settings from the Current User
     * @param lastName Last Name
     * @param profileName Profile Name
     * @return User
     */
    private static User buildUser(String lastName, String profileName) {
        return buildUser(lastName, profileName, UserInfo.getLocale());
    }

    /**
     * @description Build a new User using the specified Locale.
     * @param lastName Last Name
     * @param profileName Profile Name
     * @param localSidKey An NPSP supported locale key (EN_us, es, de, fr, or NL_nl)
     * @return User
     */
    private static User buildUser(String lastName, String profileName, String localSidKey) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

        String alias = lastName.replaceAll(' ', '').leftPad(8, '0').right(8);
        String email = lastName.left(70) + '@email.npsp';

        return new User(
            LastName = lastName,
            Email = email,
            ProfileId = p.Id,
            Username = email,
            Alias = alias,
            TimeZoneSidKey = UserInfo.getTimeZone().toString(),
            LocaleSidKey = (localSidKey != null ? localSidKey : UserInfo.getLocale()),
            LanguageLocaleKey = UserInfo.getLanguage(),
            EmailEncodingKey = 'ISO-8859-1'
        );
    }

    /**
     * @description Retrieve the current User record
     */
    public static User getCurrentUserForRunAs() {
        return new User(Id = UserInfo.getUserId());
    }

    // =====================================================================================================
    // Methods to configure Household Naming Settings
    // =====================================================================================================

    /*********************************************************************************************************
    * @description Turns on Automatic Household Naming
    * @return void
    **********************************************************************************************************/
    public static void turnOnAutomaticHHNaming() {
        setupAutomaticHHNaming(true);
    }

    /*********************************************************************************************************
    * @description Turns off Automatic Household Naming
    * @return void
    **********************************************************************************************************/
    public static void turnOffAutomaticHHNaming() {
        setupAutomaticHHNaming(false);
    }

    /*********************************************************************************************************
    * @description Configures Household Settings' Automatic Household Naming field
    * @param isOn Automatic Household Naming is turned on when parameter is true, otherwise, the settings is turned off
    * @return void
    **********************************************************************************************************/
    public static void setupAutomaticHHNaming(Boolean isOn) {
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR,
                npo02__Advanced_Household_Naming__c = isOn
            )
        );
    }

    /*********************************************************************************************************
    * @description Configures Household Naming Settings with invalid Name and Greetings formats
    * @return Household_Naming_Settings__c
    **********************************************************************************************************/
    public static Household_Naming_Settings__c setupInvalidHHNamingSettings() {
        return setupHHNamingSettings(
            '{!{!FirstName}} {!LastName}} Household',
            '{!{!Title} {!FirstName}}}{!LastName}',
            '{!{!FirstName}}}'
        );
    }

    /*********************************************************************************************************
    * @description Configures Household Naming Settings with valid Name and Greetings formats
    * @return Household_Naming_Settings__c
    **********************************************************************************************************/
    public static Household_Naming_Settings__c setupHHNamingSettings() {
        return setupHHNamingSettings(
            '{!{!FirstName} {!LastName}} Household',
            '{!{!Title} {!FirstName}} {!LastName}',
            '{!{!FirstName}}'
        );
    }

    /*********************************************************************************************************
    * @description Configures Household Naming Settings
    * @param hhNameFormat Household Naming Format
    * @param formalGreetingFormat Formal Greeting Format
    * @param informalGreetingFormat Informal Greeting Format
    * @return Household_Naming_Settings__c
    **********************************************************************************************************/
    public static Household_Naming_Settings__c setupHHNamingSettings(String hhNameFormat, String formalGreetingFormat, String informalGreetingFormat) {
        return UTIL_CustomSettingsFacade.getHouseholdNamingSettingsForTests(
            new Household_Naming_Settings__c(
                Household_Name_Format__c = hhNameFormat,
                Formal_Greeting_Format__c = formalGreetingFormat,
                Informal_Greeting_Format__c = informalGreetingFormat,
                Name_Connector__c = System.Label.npo02.HouseholdNameConnector,
                Name_Overrun__c = System.Label.npo02.HouseholdNameOverrun,
                Contact_Overrun_Count__c = 9,
                Implementing_Class__c = 'HH_NameSpec'
            )
        );
    }

    // =====================================================================================================
    // Methods to disable blocks of TDTM trigger handlers to aid in staying within unit test governor limits
    // =====================================================================================================

    /* @description Disable all Affiliations related trigger handlers when not needed to improve performance */
    public static void disableAffiliationsTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('Contact', 'AFFL_Affiliations_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Account', 'AFFL_Affiliations_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('npe5__Affiliation__c', 'AFFL_Affiliations_TDTM', false);
    }
    /* @description Disable all Relationship related trigger handlers when not needed to improve performance */
    public static void disableRelationshipTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('CampaignMember', 'REL_Relationships_Cm_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Contact', 'REL_Relationships_Con_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('npe4__Relationship__c', 'REL_Relationships_TDTM', false);
    }
    /* @description Disable all OppContactRole elated trigger handlers when not needed to improve performance */
    public static void disableOCRTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'OPP_OpportunityContactRoles_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'HH_OppContactRoles_TDTM', false);
    }
    /* @description Disable all non-OCR related Opportunity trigger handlers when not needed to improve performance */
    public static void disableOppNonOCRTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'MTCH_Opportunity_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'PSC_Opportunity_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'OPP_CampaignMember_TDTM', false);
    }
    /* @description Disable all OppRollup related trigger handlers when not needed to improve performance */
    public static void disableRollupTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'RLLP_OppRollup_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Task', 'EP_TaskRollup_TDTM', false);
    }
    /* @description Disable all OppRollup related trigger handlers when not needed to improve performance */
    public static void disableCustomizableRollupTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'CRLP_Rollup_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('npe01__OppPayment__c', 'CRLP_Rollup_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Allocation__c', 'CRLP_Rollup_TDTM', false);
    }
    /* @description Disable all Account/Contact Merge related trigger handlers when not needed to improve performance */
    public static void disableMergeTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('Contact', 'CON_ContactMerge_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Account', 'ACCT_AccountMerge_TDTM', false);
    }
    /* @description Disable all HH Naming related trigger handlers and setting when not needed to improve performance */
    public static void disableHHNamingTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('Contact', 'HH_Households_TDTM', false);
        turnOffAutomaticHHNaming();
    }
    /* @description Disable all HH Naming related trigger handlers and setting when not needed to improve performance */
    public static void disableAddressTriggers() {
        createDefaultTDTMHandlers();
        TDTM_ProcessControl.toggleTriggerState('Account', 'ADDR_Account_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Contact', 'ADDR_Contact_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState(UTIL_Namespace.StrTokenNSPrefix('Address__c'), 'ADDR_Addresses_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState(UTIL_Namespace.StrTokenNSPrefix('Address__c'), 'ADDR_Validator_TDTM', false);
        turnOffAutomaticHHNaming();
    }

    /**
     * @description Create the default trigger handler records if they haven't already been created
     */
    private static Boolean haveTriggerRecordsBeenCreated = false;
    private static void createDefaultTDTMHandlers() {
        if (!haveTriggerRecordsBeenCreated && TDTM_Config_API.getCachedRecords().size() == 0) {
            insert TDTM_DefaultConfig.getDefaultRecords();
            TDTM_ObjectDataGateway.ClearCachedTriggerHandlersForTest();
            haveTriggerRecordsBeenCreated = true;
        }
    }

    // =====================================================================================================
    // Miscellaneous Utility Methods specifically for ue in Unit Tests
    // =====================================================================================================

    /***
    * @description Sets the Fixed Search Results to the Ids of the sObjects
    * @param sObjects List of sObjects
    */
    public static void setFixedSearchResults(List<sObject> sObjects) {
        Test.setFixedSearchResults(new List<Id>(UTIL_SObject.extractIds(sObjects)));
    }

    /**
     * @description Returns True if the Account.Name is encrypted.
     * It is mainly used in test methods with Individual Account model which is not supported when the Account.Name is encrypted.
     */
    public static Boolean isAccountNameEncrypted() {
        return !Schema.sObjectType.Account.fields.Name.isFilterable();
    }

    /**
    * @description Returns a currency that isn't the org default so we can test behavior for multicurrency orgs.
    * To get the default currency code, use UTIL_CurrencyCache.getOrgDefaultCurrency()
    */
    @TestVisible
    private static UTIL_CurrencyCache.CurrencyData nonDefaultCurrencyType {
        get {
            if (nonDefaultCurrencyType == null) {
                List<SObject> nonDefaultCurrency = Database.query(
                    'SELECT IsoCode FROM CurrencyType WHERE IsCorporate = false LIMIT 1'
                );
                if (nonDefaultCurrency.size() > 0) {
                    String nonDefaultCurrencyCode = (String)nonDefaultCurrency[0].get('IsoCode');
                    nonDefaultCurrencyType = UTIL_CurrencyCache.cachedMapOfRatesByCurrencyCode.get(nonDefaultCurrencyCode);
                }
            }
            return nonDefaultCurrencyType;
        }
        set;
    }

    /***
    * @description Ensures that mockIds() does not produce the same ID twice
    */
    private static Integer dummyIdCounter {
        get {
            if (dummyIdCounter == null) {
                dummyIdCounter = 0;
            }
            dummyIdCounter++;
            return dummyIdCounter;
        }
        set;
    }

    /***
    * @description Generates a mock Id for an sObject
    */
    public static Id mockId(SObjectType sObjectType) {
        return mockIds(sObjectType, 1)[0];
    }

    /***
    * @description Generates mock Ids for an sObject
    */
    public static List<Id> mockIds(SObjectType sObjectType, Integer size) {
        String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
        List<Id> ids = new List<Id>();

        for (Integer i = 0; i < size; i++) {
            Integer uniqueCounter = dummyIdCounter;
            ids.add(keyPrefix + '0'.repeat(12 - String.valueOf(uniqueCounter).length()) + uniqueCounter);
        }

        return ids;
    }

    /***
    * @description Sets mock Ids for a list of sObjects
    */
    public static void setMockIds(List<SObject> records) {
        for (SObject record : records) {
            record.Id = mockId(record.getSObjectType());
        }
    }

    /**
     * @description Assert a Visualforce page has an error message displayed
     * @param expectedMsg Expected error message
     * @return void
     */
    public static void assertPageHasError(String expectedMsg) {
        assertPageHasMessage(expectedMsg, ApexPages.Severity.ERROR);
    }

    /**
     * @description Assert a Visualforce page has a message displayed
     * @param expectedMsg Expected error message
     * @param expectedSeverity Expected severity level
     * @return void
     */
    public static void assertPageHasMessage(String expectedMsg, ApexPages.Severity expectedSeverity) {
        ApexPages.Message[] msgs = ApexPages.getMessages();

        System.assert(
            ApexPages.hasMessages(expectedSeverity),
            'Expected page to contain at least one error message. Messages: ' + msgs
        );

        for (ApexPages.Message msg : msgs) {
            if (msg.getSummary().contains(expectedMsg) && msg.getSeverity() == expectedSeverity) {
                return;
            }
        }

        System.assert(false,
            String.format(
                'Cannot find "{0}" in the page messages: ' + msgs,
                new String[] { expectedMsg }
            )
        );
    }

    // =====================================================================================================
    // Test Methods for this Class
    // =====================================================================================================

    /**
     * @description Verify that a new User is inserted with the specified Username
     */
    @IsTest
    private static void shouldCreateNewUserWithDefaultRole() {
        String randomUsername = 'test@test.com.' + getUniqueString();

        User returnedUser = createNewUserForTests(randomUsername);
        User queriedUser = [
            SELECT
                Username,
                UserRole.Name
            FROM User
            WHERE Id = :returnedUser.Id
        ];

        System.assert(randomUsername.equalsIgnoreCase(queriedUser.Username));
        System.assertEquals('COO', queriedUser.UserRole.Name);
    }

    /**
     * @description Verify that a new User is inserted with the specified Username and a random Role Name
     */
    @IsTest
    private static void shouldCreateNewUserWithRandomRole() {
        String randomUsername = 'test@test.com.' + getUniqueString();
        String randomRolename = 'RoleName' + getUniqueString();

        User returnedUser = createNewUserWithRoleForTests(
            randomUsername,
            randomRolename
        );

        User queriedUser = [
            SELECT
                Username,
                UserRole.Name
            FROM User
            WHERE Id = :returnedUser.Id
        ];

        System.assert(randomUsername.equalsIgnoreCase(queriedUser.Username));
        System.assert(randomRoleName.equalsIgnoreCase(queriedUser.UserRole.Name));
    }

    /**
     * @description Verify that a new Inactive User is inserted with the specified Username
     */
    @IsTest
    private static void shouldCreateNewInactiveUserForTests() {
        String randomUsername = 'test@test.com.' + getUniqueString();

        User returnedUser = createNewInactiveUserForTests(randomUsername);

        User queriedUser = [
            SELECT IsActive
            FROM User
            WHERE Id = :returnedUser.Id
        ];

        System.assertEquals(false, returnedUser.IsActive);
        System.assertEquals(false, queriedUser.IsActive);
    }
}