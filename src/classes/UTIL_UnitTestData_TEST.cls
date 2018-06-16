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
* @description Provides automated generation of unit test data for tests throughout the org 
*/

@isTest
public class UTIL_UnitTestData_TEST { 
    /** @description A mock Account Id .*/
    public static final String MOCK_ACCOUNT_ID = Account.sObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
    
    static final String PROFILE_STANDARD_USER = 'Standard User';

// create data for use in unit tests
// should not be referenced by production code
    public static string closedWonStage;
    public static string closedLostStage;
    public static string openStage;
    public static string closedTaskStatus;
    public static string openTaskStatus;
    
    public static String getClosedWonStage(){
        if (closedWonStage == null){
            List<OpportunityStage> closedWonStages = [select masterlabel from opportunitystage where isActive = true and iswon = true];
            
            if(closedWonStages.size()>0){
                closedWonStage = closedWonStages[0].masterlabel;
            } else {
                closedWonStage = '';
            }
        }
        
        return closedWonStage;
    }
    
    public static String getClosedLostStage(){
        if (closedLostStage == null){
            List<OpportunityStage> closedLostStages = [select masterlabel from opportunitystage where isActive = true and iswon = false and isClosed = true];
            
            if(closedLostStages.size()>0){
                closedLostStage = closedLostStages[0].masterlabel;
            } else {
                closedLostStage = '';
            }
        }
        
        return closedLostStage;
    }

    public static String getOpenStage(){
        if (openStage == null){
            List<OpportunityStage> openStages = [select masterlabel from opportunitystage where isActive = true and iswon = false];
            
            if(openStages.size()>0){
                openStage = openStages[0].masterlabel;
            } else {
                openStage = '';
            }
        }
        
        return openStage;
    }

    public static String getClosedTaskStatus(){
        if (closedTaskStatus == null){
            List<TaskStatus> closedTaskStatuses = [SELECT masterlabel FROM TaskStatus WHERE isClosed = true];
            
            if(closedTaskStatuses.size()>0){
                closedTaskStatus = closedTaskStatuses[0].masterlabel;
            } else {
                closedTaskStatus = '';
            }
        }
        
        return closedTaskStatus;
    }

    public static String getOpenTaskStatus(){
        if (openTaskStatus == null){
            List<TaskStatus> openTaskStatuses = [SELECT masterlabel FROM TaskStatus WHERE isClosed = false];
            
            if(openTaskStatuses.size()>0){
                openTaskStatus = openTaskStatuses[0].masterlabel;
            } else {
                openTaskStatus = '';
            }
        }
        
        return openTaskStatus;
    }
    
    public static Contact getContact() {
    	return new Contact (
                FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c = false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
                OtherCity = 'Seattle'
            );
    }
    
    public static List<Contact> CreateMultipleTestContacts (integer n) {
        
        List<contact> ContactsToAdd = New List<contact> ();
        
        for (integer i=0;i<n;i++) {
            Contact newCon = New Contact (
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS + i,
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
                OtherCity = 'Seattle'
            );
            //since we're running rollup code on a manually created contacts in RLLP_OppRollup_TEST, we have to manually set currency field in multicurrency
            if (RLLP_OppRollup_UTIL.isMultiCurrency()) {
                newCon.put(RLLP_OppRollup_UTIL.mcFieldValues.get('Contact'), RLLP_OppRollup_UTIL.currCorporate);
            }

            ContactsToAdd.add (newCon);
        }
        

        // testing doing the insert in the calling code - will maybe reinstate this
        //insert ContactsToAdd;
        
        return ContactsToAdd;
    }

    public static List<Opportunity> OppsForContactList (List<Contact> Cons, id CampId, string Stage, date Close, double Amt, string rectype, string oppType) {
        id rtid = UTIL_RecordTypes.GetRecordTypeId (Opportunity.sObjectType,rectype);
        return OppsForContactListByRecTypeId(Cons, CampId, Stage, Close, Amt, rtid, oppType);
    }

    public static List<Opportunity> OppsForContactListByRecTypeId (List<Contact> Cons, id CampId, string Stage, date Close, double Amt, Id rtid, string oppType) {
     
        // given a List of Contacts,
        // add one Opp per contact w/ the specified data
        // TBD should allow specifying rectype (optional)
    
        List<Opportunity> OppsToAdd = new List<Opportunity> ();
        UTIL_Debug.debug('recordtypeintest: ' + rtid);

        for ( Contact thisCon : Cons ) {
            Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ' + thisCon.FirstName + thisCon.LastName,
                Amount = Amt,
                CloseDate = Close,
                StageName = Stage,
                CampaignId = CampId,
                Primary_Contact__c = thisCon.Id,
                type = oppType
            );
            if(rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }
            oppsToAdd.add (newOpp);
        }
        return oppsToAdd;
    }

    /*******************************************************************************************************
    * @description Create an Opportunity for each Contact, using their Account as the Opportunity's Account.
    */
    public static List<Opportunity> OppsForContactWithAccountList (List<Contact> Cons, id CampId, string Stage, date Close, double Amt, string rectype, string oppType) {
        id rtid = UTIL_RecordTypes.GetRecordTypeId (Opportunity.sObjectType,rectype);
        return OppsForContactWithAccountListByRecTypeId(Cons, CampId, Stage, Close, Amt, rtid, oppType);
    }

    /*******************************************************************************************************
    * @description Create an Opportunity for each Contact, using their Account as the Opportunity's Account.
    */
    public static List<Opportunity> OppsForContactWithAccountListByRecTypeId (List<Contact> Cons, id CampId, string Stage, date Close, double Amt, Id rtid, string oppType) {
     
        // given a List of Contacts,
        // add one Opp per contact w/ the specified data
    
        List<Opportunity> OppsToAdd = new List<Opportunity> ();
        UTIL_Debug.debug('recordtypeintest: ' + rtid);

        for ( Contact thisCon : Cons ) {
            Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ' + thisCon.FirstName + thisCon.LastName,
                Amount = Amt,
                CloseDate = Close,
                StageName = Stage,
                CampaignId = CampId,
                AccountId = thisCon.AccountId,
                Primary_Contact__c = thisCon.Id,
                type = oppType
            );
            if(rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }
            oppsToAdd.add (newOpp);
        }
        return oppsToAdd;
    }

    public static List<Opportunity> OppsForAccountList (List<Account> listAcc, id CampId, string Stage, date Close, double Amt, string rectype, string oppType) {
        id rtid = UTIL_RecordTypes.GetRecordTypeId (Opportunity.sObjectType,rectype);
        return OppsForAccountListByRecTypeId(listAcc, CampId, Stage, Close, Amt, rtid, oppType);
    }

    public static List<Opportunity> OppsForAccountListByRecTypeId (List<Account> listAcc, id CampId, string Stage, date Close, double Amt, Id rtid, string oppType) {
     
        // given a List of Accounts,
        // add one Opp per Account w/ the specified data
    
        List<Opportunity> OppsToAdd = new List<Opportunity> ();
        UTIL_Debug.debug('recordtypeintest: ' + rtid);

        for (Account acc : listAcc) {
            Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ' + acc.Name,
                AccountId = acc.Id,
                Amount = Amt,
                CloseDate = Close,
                StageName = Stage,
                CampaignId = CampId,
                type = oppType
            );
            if (rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }
            oppsToAdd.add (newOpp);
        }
        return oppsToAdd;
    }

    public static List<Account> CreateMultipleTestAccounts (integer n, string strType) {
        
        List<Account> AcctsToAdd = New List<Account> ();
        
        for (integer i=0;i<n;i++) {
            Account newAcct = New Account (
                Name = 'Yet Another Org ' + i,
                npe01__SYSTEM_AccountType__c = strType
            );
            if (strType != null) {
            	newAcct.npe01__SYSTEMIsIndividual__c = true;
            	if (strType == CAO_Constants.BUCKET_ORGANIZATION_TYPE)
            	   newAcct.name = CAO_Constants.BUCKET_ACCOUNT_NAME;
            }
            AcctsToAdd.add (newAcct);
        }
        
        return AcctsToAdd;
    }

    /**
     * @description Create Engagement Plan Templates for unit testing.
     * @param n The number of Engagement Plan Templates to be created
     * @return List of Engagement Plan Templates
     */
    public static List<Engagement_Plan_Template__c> createEPTemplates (integer n) {
        // Holds the list of EP Templates to be returned
        List<Engagement_Plan_Template__c> EPTemplatesToAdd = New List<Engagement_Plan_Template__c>();
        
        for (integer i=0 ;i<n; i++) {
            EPTemplatesToAdd.add(new Engagement_Plan_Template__c(Name = 'Test ' + i));
        }
        
        return EPTemplatesToAdd;
    }

    /**
     * @description Create Engagement Plan Tasks for unit testing.
     * @param n The number of Engagement Plan Tasks per Template to be created
     * @param listEPTemplates The templates the EP Tasks will belong to
     * @return List of Engagement Plan Templates
     */
    public static List<Engagement_Plan_Task__c> createEPTasksForTemplates (integer n, List<Engagement_Plan_Template__c> listEPTemplates) {
        // Holds the list of EP Tasks to be returned
        List<Engagement_Plan_Task__c> EPTasksToAdd = New List<Engagement_Plan_Task__c>();
        
        for (Engagement_Plan_Template__c epTemplate : listEPTemplates) {
            for (integer i=0 ;i<n; i++) {
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

    /**
     * @description Create a new user for unit testing.
     * @param strUsername The username for the user to be created
     * @param strRolename The name of the UserRole to associate with the user (will be created if does not exist)
     * @return User
     */
    public static User createNewUserWithRoleForTests(String strUsername, String strRolename) {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = :PROFILE_STANDARD_USER
        ];

        UserRole r;
        User u;

        // to work around mixed DML errors during tests, you must
        // create user roles and accounts in their own transactions.
        // got this hack from the web.
        System.runAs(new User(Id = UserInfo.getUserId())) {
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

            u = new User(
                Alias = 'jsmith',
                Email = 'jsmith@acme.com',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LastName = 'Smith',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserRoleId = r.Id,
                Username = strUsername
            );

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

        System.runAs(new User(Id = UserInfo.getUserId())) {
            u.isActive = false;
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
     * @return User
     */
    public static User createUser(String profileName) {
        User u = buildUser(buildUniqueLastName(), profileName);

        //create the user
        System.runAs(u) {}

        return u;      
    } 

    /**
     * @description Construct a unique last name to be assigned to a User
     * @return String
     */
    static String buildUniqueLastName() {
        return UserInfo.getOrganizationId() +
            String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') +
            Integer.valueOf(math.rint(math.random()*2000000));
    }

    /**
     * @description Set new User fields
     * @param lastName Last Name
     * @param profileName Profile Name
     * @return User
     */
    static User buildUser(String lastName, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE name = :profileName];
        String alias = lastName.replaceAll(' ', '').leftPad(8, '0').right(8);
        String email = lastName.left(70) + '@email.com';

        return new User(
            LastName = lastName, 
            Email = email, 
            ProfileId = p.id,
            UserName = email,
            Alias = alias, 
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1'
        );
    }

    /**
     * @description Assert a Visualforce page has an error message displayed
     * @param expectedMsg Expected error message
     * @return void
     */
    public static void assertPageHasError(String expectedMsg) {
        ApexPages.Message[] msgs = ApexPages.getMessages();

        System.assert(
            ApexPages.hasMessages(ApexPages.Severity.ERROR), 
            'Expected page to contain at least one error message. Messages: ' + msgs
        );
 
        for (ApexPages.Message msg : msgs) {
            if (msg.getSummary().contains(expectedMsg) && msg.getSeverity() == ApexPages.Severity.ERROR) {
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

    public static list<Account> listAccT;
    public static list<Contact> listConT;
    
    /*********************************************************************************************************
    * @description Creates x accounts of the given type, each with y Contacts.
    * @param accType The Account Type to create (CAO_Constants.HH_ACCOUNT_TYPE, etc.)
    * @param cAcc the number of Accounts to create
    * @param cCon the number of Contacts to create per Account
    * @param iUnique the number to start with when naming the contacts and addresses
    * @return  void
    **********************************************************************************************************/
    public static void createAccountContactTestData(string accType, integer cAcc, integer cCon, integer iUnique) {
        
        //npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettings();
            
        listConT = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(cAcc * cCon);
        listAccT = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(cAcc, accType);
        insert listAccT;
        
        // set each contact's account, and give them a unique name and mailing address
        for (integer i = 0; i < cAcc; i++) {
            for (integer j = 0; j < cCon; j++) {
            	integer iCon = (i * cCon) + j;
            	Contact con = listConT[iCon]; 
            	con.Firstname = 'TestFirstname' + iUnique + iCon;
                con.Lastname = 'TestLastname' + iUnique + iCon;
                con.AccountId = listAccT[i].Id;
                con.MailingStreet = 'Street' + iUnique + iCon;
                con.MailingCity = 'City' + iUnique + iCon;
            }
        }        
        insert listConT;
    }

    private static testMethod void testCreateNewUserWithDefaultRole() {
        String randomUsername = 'test@test.com.' + Math.random();

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

    private static testMethod void testCreateNewUserWithRandomRole() {
        String randomUsername = 'test@test.com.' + Math.random();
        String randomRolename = 'RoleName' + Math.random();

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

    private static testMethod void testCreateNewInactiveUserForTests() {
        String randomUsername = 'test@test.com.' + Math.random();

        User returnedUser = createNewInactiveUserForTests(randomUsername);

        User queriedUser = [
            SELECT IsActive
            FROM User
            WHERE Id = :returnedUser.Id
        ];

        System.assertEquals(false, returnedUser.IsActive);
        System.assertEquals(false, queriedUser.IsActive);
    }

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
                Name_Connector__c = label.npo02.HouseholdNameConnector,
                Name_Overrun__c = label.npo02.HouseholdNameOverrun,
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
        UTIL_UnitTestData_TEST.turnOffAutomaticHHNaming();
    }

    /*********************************************************************************************************
    * @description Extracts Ids of sObjects
    * @param sObjects List of sObjects
    * @return Set<Id> Set of sObjects' Ids
    **********************************************************************************************************/
    public static Set<Id> extractIds(List<sObject> sObjects) {
        return (new Map<Id, sObject>(sObjects)).keySet();
    }

    /*********************************************************************************************************
    * @description Sets the Fixed Search Results to the Ids of the sObjects
    * @param sObjects List of sObjects
    **********************************************************************************************************/
    public static void setFixedSearchResults(List<sObject> sObjects) {
        Test.setFixedSearchResults(new List<Id>(extractIds(sObjects)));
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
}