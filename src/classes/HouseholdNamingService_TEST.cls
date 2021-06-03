/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2011 (2.3)
* @group Households
* @description test class for Household naming functionality.
*/
@isTest
public class HouseholdNamingService_TEST {

    private static ContactSelector contactSelector {
        get {
            if (contactSelector == null) {
                contactSelector = new ContactSelector();
            }
            return contactSelector;
        }
        set;
    }

    /*********************************************************************************************************
    * @description Test method for batch
    */
    public static testMethod void testBatch() {
        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Always_Rollup_to_Primary_Contact__c = true,
                npo02__Enable_Opp_Rollup_Triggers__c = true,
                npo02__Excluded_Account_Opp_Rectypes__c = null,
                npo02__Excluded_Account_Opp_Types__c = null,
                npo02__Excluded_Contact_Opp_Rectypes__c = null,
                npo02__Excluded_Contact_Opp_Types__c = null,
                npo02__Membership_Record_Types__c = null,
                npo02__Advanced_Household_Naming__c = true
            ));

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
           npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
           npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
           npe01__Opportunity_Contact_Role_Default_role__c = CAO_Constants.OCR_DONOR_ROLE
        ));


        // create & insert contact(s)
        Contact[] TestCons = new contact[]{ new contact(
            FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__Private__c=false,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        ) };
        insert TestCons;

        //get the household to be updated
        id hhid = [select npo02__Household__r.id from Contact where id = :testcons[0].id].id;
        UTIL_Debug.debug('ID IS=================='+ hhid);

        HH_HouseholdNaming_BATCH batch = new HH_HouseholdNaming_BATCH(
        'select Id, LastName, ' + UTIL_Namespace.StrTokenNSPrefix('HHId__c') + ' from Contact where ' +
            UTIL_Namespace.StrTokenNSPrefix('HHId__c') + ' = \'' + hhid + '\' limit 200', true
        );

        Test.StartTest();
            id batchProcessId = database.executeBatch(batch);
        Test.StopTest();
    }

    /*********************************************************************************************************
    * @description tests FutureUpdateNames
    */
    public static testMethod void HouseholdNamingTest(){
      //settings
      npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Advanced_Household_Naming__c = true,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null
                ));

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = CAO_Constants.OCR_DONOR_ROLE
            ));

        integer i;

        list<Contact> insertlist = new list<Contact>();
        for (i = 0; i < 20; i++){
            Contact c = new Contact(LastName = 'LastName' + i, FirstName = 'FirstName' + i, Salutation = 'Mr.');
            if (i == 1){
                c.npo02__Naming_Exclusions__c = 'Household Name';
            }

            insertlist.add(c);
        }

        insert insertlist;
        list<id> householdids = new list<id>();

        list<Contact> clist = [select npo02__Naming_Exclusions__c, npo02__Household__r.id, npo02__Household__r.Name, npo02__Household__r.npo02__Informal_Greeting__c, npo02__Household__r.npo02__Formal_Greeting__c from Contact where id IN :insertlist limit 2000];

        for (Contact c : clist){
            if (c.npo02__household__r.id != null)
              householdids.add(c.npo02__household__r.id);
        }
        system.assert(householdids.size() > 0);

        //use future to prevent the before HH trigger from firing
        test.starttest();
        HouseholdNamingService.updateHouseholdNameAndMemberCountAsynchronously(householdids);
        test.stoptest();
        //test a single member household, lastname, firstname, householdname:
        Contact con = [
            SELECT npo02__Household__r.Name, npo02__Household__r.npo02__Informal_Greeting__c, npo02__Household__r.npo02__Formal_Greeting__c
            FROM Contact
            WHERE Id = :insertlist[0].Id];
        system.assertEquals('LastName0 ' +  system.label.npo02.DefaultHouseholdName, con.npo02__household__r.Name);
        system.assertEquals('FirstName0',con.npo02__household__r.npo02__Informal_Greeting__c);
        system.assert(con.npo02__household__r.npo02__Formal_Greeting__c.endsWith('FirstName0 LastName0'));

    }

    /*********************************************************************************************************
    * @description tests updating and Household object's contact names
    */
    public static testMethod void HouseholdNamingUpdateTest(){
      //settings
      npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Advanced_Household_Naming__c = true
                ));

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = CAO_Constants.OCR_DONOR_ROLE
            ));

        integer i;

        list<Contact> insertlist = new list<Contact>();
        for (i = 0; i < 20; i++){
            Contact c = new Contact(LastName = 'L' + i, FirstName = 'F' + i, Salutation = 'Mr.');
            if (i == 1){
                c.npo02__Naming_Exclusions__c = 'Household Name';
            }

            insertlist.add(c);
        }

        //turn off the before trigger via our processor:
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);
        insert insertlist;
        list<id> householdids = new list<id>();

        list<Contact> clist = [select npo02__Naming_Exclusions__c, npo02__Household__r.id, npo02__Household__r.Name, npo02__Household__r.npo02__Informal_Greeting__c, npo02__Household__r.npo02__Formal_Greeting__c from Contact where id IN :insertlist limit 2000];

        for (Contact c : clist){
            if (c.npo02__household__r.id != null)
              householdids.add(c.npo02__household__r.id);
        }

        //update some contacts and note the changes
        //set first one to the last household, next two to the second, next five to the third,
        //and next 10 to the last (array spots end, end - 1, etc.)
        integer counter = 0;
        for (Contact c : clist){
            if(counter == 0)
                c.npo02__Household__c = clist[clist.size() - 1].npo02__Household__c;
            else if (counter > 0 && counter < 3)
                c.npo02__Household__c = clist[clist.size() - 2].npo02__Household__c;
            else if (counter > 2 && counter < 8)
                c.npo02__Household__c = clist[clist.size() - 3].npo02__Household__c;
            else if (counter < 20)
                c.npo02__Household__c = clist[clist.size() - 4].npo02__Household__c;
            counter++;
        }
        //this should cause renaming to happen
        //but not trigger the before household_update, since
        //since it will be in the same transaction
        update clist;

        list<id> newhhids = new list<id>();
        newhhids.add(clist[clist.size() - 1].npo02__Household__r.id);
        newhhids.add(clist[clist.size() - 2].npo02__Household__r.id);
        newhhids.add(clist[clist.size() - 3].npo02__Household__r.id);
        newhhids.add(clist[clist.size() - 4].npo02__Household__r.id);

        //update our newly updated contact's households
        HouseholdNamingService householdNamingService = new HouseholdNamingService();
        test.startTest();
        householdNamingService.updateHouseholdNameAndMemberCount(newhhids);

        test.stopTest();
    }

    /*********************************************************************************************************
    * @description tests setting the naming order on Contacts
    */
    public static testMethod void testNamingOrder() {
      //settings
      npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Advanced_Household_Naming__c = true
                ));

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = CAO_Constants.OCR_DONOR_ROLE
            ));

        npo02__Household__c hh = new npo02__Household__c (
            Name = 'Household'
            );
        insert hh;

        Contact con0 = new Contact(
            FirstName = 'John',
            LastName = 'Jones'
            );
        insert con0;

        Contact con1 = new Contact(
            FirstName = 'Joe',
            LastName = 'Test',
            npo02__Household__c = hh.id
            );
        insert con1;

        Contact con2 = new Contact(
            FirstName = 'Jim',
            LastName = 'Test',
            npo02__Household__c = hh.id
            );
        insert con2;


        //test various re-orderings of names

        HouseholdNamingService householdNamingService = new HouseholdNamingService();

        householdNamingService.updateHouseholdNameAndMemberCount(new list<Id>{hh.id});

        hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c, Number_of_Household_Members__c from npo02__Household__c where id = :hh.id LIMIT 1][0];

        system.assertequals('Test ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assert(hh.npo02__Formal_greeting__c.contains('Joe'));
        system.assert(hh.npo02__Formal_greeting__c.contains('Jim'));
        system.assert(hh.npo02__Formal_greeting__c.endswith('Test'));
        system.assert(hh.npo02__Informal_greeting__c.contains('Joe'));
        system.assert(hh.npo02__Informal_greeting__c.contains('Jim'));
        system.assertEquals(2, hh.Number_of_Household_Members__c);

        con1.npo02__Household_Naming_Order__c = 0;
        con2.npo02__Household_Naming_Order__c = 1;

        update con1;
        update con2;

        householdNamingService.updateHouseholdNameAndMemberCount(new list<Id>{hh.id});

        hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c from npo02__Household__c where id = :hh.id LIMIT 1][0];

        system.assertequals('Test ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertequals('Joe ' + system.label.npo02.HouseholdNameConnector + ' Jim Test', hh.npo02__Formal_greeting__c);
        system.assertequals('Joe ' + system.label.npo02.HouseholdNameConnector + ' Jim', hh.npo02__Informal_greeting__c);

        con0.npo02__household__c = hh.id;
        con0.npo02__Household_Naming_Order__c = 0;
        con1.npo02__Household_Naming_Order__c = null;

        update con0;
        update con1;

        householdNamingService.updateHouseholdNameAndMemberCount(new list<Id>{hh.id});

        hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c, Number_of_Household_Members__c from npo02__Household__c where id = :hh.id LIMIT 1][0];

        system.assertequals('Jones ' + system.label.npo02.HouseholdNameConnector + ' Test ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertequals('John Jones ' + system.label.npo02.HouseholdNameConnector + ' Jim ' + system.label.npo02.HouseholdNameConnector + ' Joe Test', hh.npo02__Formal_greeting__c);
        system.assertequals('John, Jim ' + system.label.npo02.HouseholdNameConnector + ' Joe', hh.npo02__Informal_greeting__c);
        system.assertEquals(3, hh.Number_of_Household_Members__c);

        con0.npo02__Household_Naming_Order__c = null;
        con1.npo02__Household_Naming_Order__c = 2;

        // system limit profiling around this smaller scope of work.
        Test.startTest();
        update con0;
        update con1;

        householdNamingService.updateHouseholdNameAndMemberCount(new list<Id>{hh.id});
        Test.stopTest();

        hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c from npo02__Household__c where id = :hh.id LIMIT 1][0];

        system.assertequals('Test ' + system.label.npo02.HouseholdNameConnector + ' Jones ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertequals('Jim ' + system.label.npo02.HouseholdNameConnector  + ' Joe Test ' + system.label.npo02.HouseholdNameConnector + ' John Jones', hh.npo02__Formal_greeting__c);
        system.assertequals('Jim, Joe ' + system.label.npo02.HouseholdNameConnector + ' John', hh.npo02__Informal_greeting__c);
    }

    /*********************************************************************************************************
    @description
        Test updateNames() updates Household names only for specified Accounts or Households.
        Contacts having either Account or Household null are not processed unless their
        Household/Account is in the updateNames() argument list.
    verify:
        Names for specified Account/Households are updated.
    **********************************************************************************************************/
    private static testMethod void testUpdateNamesIsAppliedToSpecifiedHHsOnly() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_UnitTestData_TEST.turnOffAutomaticHHNaming();
        UTIL_UnitTestData_TEST.setupHHNamingSettings();
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c(
            npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR
        ));

        List<Account> accounts = buildHHAccounts(2);
        insert accounts;

        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Alpha', LastName = 'A', AccountId = accounts[0].Id),
            new Contact(FirstName = 'Beta', LastName = 'B', AccountId = accounts[1].Id),
            new Contact(FirstName = 'Charlie', LastName = 'C', npe01__Private__c = true)
        };

        // Execute Contact insert in start/stopTest() to complete Household future jobs
        Test.startTest();
        insert contacts;
        Test.stopTest();

        List<Contact> actualContacts = getContactsOrderById();

        Contact actual = actualContacts[0];
        System.assertEquals(accounts[0].Name, actual.Account.Name, 'Account Name should be unchanged: ' + actual);

        actual = actualContacts[1];
        System.assertEquals(accounts[1].Name, actual.Account.Name, 'Account Name should be unchanged: ' + actual);

        actual = actualContacts[2];
        System.assertEquals(null, actual.AccountId, 'Account should not be specified for a private Contact: ' + actual);

        UTIL_UnitTestData_TEST.turnOnAutomaticHHNaming();

        HouseholdNamingService householdNamingService = new HouseholdNamingService();
        // Specify null argument -> ensure records with null Account or Household do not have names updated
        List<Id> hhIds = new List<Id>{ contacts[0].AccountId, null };

        householdNamingService.updateHouseholdNameAndMemberCount(hhIds);

        actualContacts = getContactsOrderById();

        // Verify Account names are changed for Accounts specified to the updateNames()
        actual = actualContacts[0];
        System.assertEquals(buildFormattedHHName(contacts[0]), actual.Account.Name, 'Account Name should be formatted HH Name now: ' + actual);

        // Verify Account names are not changed for Accounts not specified to the updateNames()
        actual = actualContacts[1];
        System.assertEquals(accounts[1].Name, actual.Account.Name, 'Account Name should be unchanged: ' + actual);

        actual = actualContacts[2];
        System.assertEquals(null, actual.AccountId, 'Account should not be specified for a private Contact: ' + actual);
    }

    /*********************************************************************************************************
    * @description tests that case sensitive name changes on contacts update the Household name and greetings
    */
    public static testMethod void testCaseChanges() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        Contact con = new Contact(firstname='joe', lastname='smith');
        insert con;

        Account hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c from Account];

        system.assertEquals('smith ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertEquals('joe smith', hh.npo02__Formal_greeting__c);
        system.assertEquals('joe', hh.npo02__Informal_greeting__c);

        con.firstname = 'Joe';
        con.lastname = 'Smith';
        Test.startTest();
        update con;
        Test.stopTest();

        hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c from Account];

        system.assertEquals('Smith ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertEquals('Joe Smith', hh.npo02__Formal_greeting__c);
        system.assertEquals('Joe', hh.npo02__Informal_greeting__c);
    }

    /*********************************************************************************************************
    * @description tests name ordering since we changed to not force primary first
    */
    public static testMethod void testNamingOrder2() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        TDTM_ProcessControl.allowRecursionForComplexTestDataSetup();

        Contact con0 = new Contact(FirstName='c0', LastName='smith');
        insert con0;
        con0 = [Select Id, FirstName, LastName, AccountId from Contact];
        system.assertNotEquals(null, con0.AccountId);

        Contact con1 = new Contact(FirstName='c1', LastName='smith', AccountId=con0.AccountId);
        Contact con2 = new Contact(FirstName='c2', LastName='smith', AccountId=con0.AccountId);
        Test.startTest();
        insert new list<Contact>{con1,con2};
        Test.stopTest();

        // primary contact defaults to first in order
        Account hh = [SELECT Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c, npe01__One2OneContact__c, Number_of_Household_Members__c FROM Account];
        system.assertEquals(con0.Id, hh.npe01__One2OneContact__c);
        system.assertEquals(3, hh.Number_of_Household_Members__c);
        system.assertEquals('smith ' + System.Label.npo02.DefaultHouseholdName, hh.Name);
        system.assertEquals('c0, c1' + CAO_Constants.HH_NAME_CONNECTOR + 'c2 smith', hh.npo02__Formal_greeting__c);
        system.assertEquals('c0, c1' + CAO_Constants.HH_NAME_CONNECTOR + 'c2', hh.npo02__Informal_greeting__c);

        con1.npo02__Household_Naming_Order__c = 0;
        update con1;

        // naming order overrides primary contact
        hh = [SELECT Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c, npe01__One2OneContact__c FROM Account];
        system.assertEquals(con0.Id, hh.npe01__One2OneContact__c);
        system.assertEquals('smith ' + System.Label.npo02.DefaultHouseholdName, hh.Name);
        system.assertEquals('c1, c0' + CAO_Constants.HH_NAME_CONNECTOR + 'c2 smith', hh.npo02__Formal_greeting__c);
        system.assertEquals('c1, c0' + CAO_Constants.HH_NAME_CONNECTOR + 'c2', hh.npo02__Informal_greeting__c);

    }

    /*********************************************************************************************************
    @description
        Test strContactSelectStmtAllNamingFields property when Household Naming Settings is valid
        and the Automatic Household Naming is turned on
    verify:
        Household Naming Settings fields are included in the SOQL.
        No error is raised when the SOQL is executed.
    **********************************************************************************************************/
    private static testMethod void testSoqlContainsHHNamingFieldsWhenAutomaticHHNamingIsOn() {
        UTIL_UnitTestData_TEST.turnOnAutomaticHHNaming();

        UTIL_UnitTestData_TEST.setupHHNamingSettings(
            'The {!LastName}, {!{!FirstName} {!npe01__WorkEmail__c}} Family',
            '{!{!Salutation} {!FirstName}} {!LastName}',
            '{!{!FirstName}}'
        );

        String soql = contactSelector.getQueryForContactNamingFields();

        for (String fieldName : new String[] {
            'Id', 'HHId__c', 'npo02__Naming_Exclusions__c', // mandatory fields
            'LastName', 'FirstName', 'Salutation', 'npe01__WorkEmail__c' //HH Naming fields
        }) {
            System.assert(soql.contains(fieldName), fieldName + ' should be in the SOQL: ' + soql);
        }

        //verify the soql is valid and will not raise exceptions
        System.assert(!soql.contains('}'), 'SOQL should be correct: ' + soql);

        try {
            List<Contact> contacts = Database.Query(soql);
        } catch (Exception e) {
            System.assert(false, 'Unexpected error raised for SOQL: ' + soql);
        }
    }

    /*********************************************************************************************************
    @description
        Test strContactSelectStmtAllNamingFields property when Household Naming Settings is invalid
        and the Automatic Household Naming is turned off
    verify:
        Household Naming Settings fields are not included in the SOQL.
        No error is raised when the SOQL is executed.
    **********************************************************************************************************/
    private static testMethod void testSoqlDoesNotContainHHNamingFieldsWhenAutomaticHHNamingIsOff() {
        UTIL_UnitTestData_TEST.turnOffAutomaticHHNaming();

        UTIL_UnitTestData_TEST.setupHHNamingSettings(
            'The {!LastName}, {!{!FirstName}}} {!npe01__WorkEmail__c}} Family',
            '{!{!Salutation} {!FirstName}}} {!LastName}',
            '{!{!FirstName}}}'
        );

        String soql = contactSelector.getQueryForContactNamingFields();

        for (String fieldName : new String[] {
            'Id', 'HHId__c', 'npo02__Naming_Exclusions__c' // mandatory fields
        }) {
            System.assert(soql.contains(fieldName), fieldName + ' should be in the SOQL: ' + soql);
        }

        for (String fieldName : new String[] {
            'LastName', 'FirstName', 'Salutation', 'npe01__WorkEmail__c' //HH Naming fields
        }) {
            System.assert(!soql.contains(fieldName), fieldName + ' should not be in the SOQL: ' + soql);
        }

        //verify the soql is valid and will not raise exceptions
        System.assert(!soql.contains('}'), 'SOQL should be correct: ' + soql);

        try {
            List<Contact> contacts = Database.Query(soql);
        } catch (Exception e) {
            System.assert(false, 'Unexpected error raised for SOQL: ' + soql);
        }
    }

    /*********************************************************************************************************
    @description
        Test getHouseholdNamingContactFields() method when Household Naming Settings is invalid
        and the Automatic Household Naming is turned off
    verify:
        Returned set is empty.
    **********************************************************************************************************/
    private static testMethod void testNoFieldIsReturnedWhenAutomaticHHNamingIsOff() {
        UTIL_UnitTestData_TEST.turnOffAutomaticHHNaming();
        UTIL_UnitTestData_TEST.setupInvalidHHNamingSettings();

        Set<String> fieldNames = new HouseholdNamingService().getHouseholdNamingContactFields();

        System.assert(fieldNames.isEmpty(), 'No field name should be returned: ' + fieldNames);
    }

    /*********************************************************************************************************
    @description
        Test getHouseholdNamingContactFields() method when Household Naming Settings is valid
        and the Automatic Household Naming is turned on
    verify:
        Returned set contains Contact field names specified in the Household Naming Settings.
    **********************************************************************************************************/
    private static testMethod void testReturnedFieldsWhenAutomaticHHNamingIsOn() {
        UTIL_UnitTestData_TEST.turnOnAutomaticHHNaming();

        UTIL_UnitTestData_TEST.setupHHNamingSettings(
            'The {!lastname}, {!{!firstname}} Family',
            '{!{!SALUTATION} {!FirstName}} {!LASTNAME}',
            '{!{!FirstName}}'
        );

        Set<String> fieldNames = new HouseholdNamingService().getHouseholdNamingContactFields();

        // LastName is added to the HH Naming fields even if it is not in format fields
        Set<String> expectedFieldNames = new Set<String>{ 'lastname', 'LASTNAME', 'LastName', 'firstname', 'FirstName', 'SALUTATION' };

        System.assertEquals(expectedFieldNames.size(), fieldNames.size(), 'Expected names: ' + expectedFieldNames + '; Actual names: ' + fieldNames);

        System.assert(expectedFieldNames.containsAll(fieldNames), 'Expected names: ' + expectedFieldNames + '; Actual names: ' + fieldNames);
    }

    /*********************************************************************************************************
    @description
        Test isAutomaticNaming() method when the Automatic Household Naming is turned off
    verify:
        The method returns false.
    **********************************************************************************************************/
    private static testMethod void testIsAutomaticNamingReturnsFalseWhenAutomaticHHNamingIsOff() {
        UTIL_UnitTestData_TEST.turnOffAutomaticHHNaming();

        System.assert(!new HouseholdSettings().isAdvancedHouseholdNaming(), 'Automatic Household Naming should be ' +
                'turned' +
                ' off');
    }

    /*********************************************************************************************************
    @description
        Test isAutomaticNaming() method when the Automatic Household Naming is turned on
    verify:
        The method returns true.
    **********************************************************************************************************/
    private static testMethod void testIsAutomaticNamingReturnsTrueWhenAutomaticHHNamingIsOn() {
        UTIL_UnitTestData_TEST.turnOnAutomaticHHNaming();

        System.assert(new HouseholdSettings().isAdvancedHouseholdNaming(), 'Automatic Household Naming should be ' +
                'turned on');
    }

    /*********************************************************************************************************
    @description
        Test getHouseholdContacts() returns empty list on empty/null Account/Household Ids input arg.
    verify:
        An empty list is returned.
    **********************************************************************************************************/
    private static testMethod void testGetHouseholdContactsReturnsEmptyList() {
        // The private Contact should not be returned by the query
        insert new Contact(LastName = 'foo', npe01__Private__c = true);

        List<Id> hhIds = null;
        List<Contact> contacts = contactSelector.householdMembersFor(hhIds);
        System.assertEquals(0, contacts.size(), 'The Contact list should contain no record for null Id list argument: ' + contacts);

        hhIds = new List<Id>();
        contacts = contactSelector.householdMembersFor(hhIds);
        System.assertEquals(0, contacts.size(), 'The Contact list should contain no record for empty Id list arg: ' + contacts);

        hhIds.add(null);
        contacts = contactSelector.householdMembersFor(hhIds);
        System.assertEquals(0, contacts.size(), 'The Contact list should contain no record when Id list arg contains null: ' + contacts);

        hhIds.add(UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID);
        contacts = contactSelector.householdMembersFor(hhIds);
        System.assertEquals(0, contacts.size(), 'The Contact list should contain no record for Account without Contacts: ' + contacts);
    }

    /*********************************************************************************************************
    @description
        Test getHouseholdContacts() returns data for specified Accounts/Households only.
    verify:
        Contacts for specified Accounts/Households are selected.
        Contacts with null Account and not referencing the input Household are not selected.
        Contacts with null Account and null Household are not selected.
    **********************************************************************************************************/
    private static testMethod void testGetHouseholdContactsReturnsDataForSpecifiedHHOnly() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c(
            npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR
        ));
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c(
            npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR
        ));

        List<Account> accounts = buildHHAccounts(3);
        insert accounts;

        List<npo02__Household__c> hhs = buildHouseholds(1);
        insert hhs;

        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Alpha', LastName = 'A', AccountId = accounts[0].Id),
            new Contact(FirstName = 'Beta', LastName = 'B', AccountId = accounts[1].Id, npo02__Household__c = hhs[0].Id),
            new Contact(FirstName = 'Charlie', LastName = 'C', AccountId = accounts[2].Id),
            new Contact(FirstName = 'Delta', LastName = 'D', npe01__Private__c = true)
        };

        // Execute Contact insert in start/stopTest() to complete Household future jobs
        Test.startTest();
        insert contacts;
        Test.stopTest();

        List<Contact> actualContacts = getContactsOrderById();
        for (Integer i = 0; i < contacts.size(); i++) {
            Contact actual = actualContacts[i];
            System.assertEquals(contacts[i].npo02__Household__c, actual.npo02__Household__c, 'Household should be unchanged: ' + actual);
            System.assertEquals(contacts[i].AccountId, actual.AccountId, 'Account should be unchanged: ' + actual);
        }

        HouseholdNamingService householdNamingService = new HouseholdNamingService();

        // Provide null Id to ensure records with null Account/Household are not selected unless
        // their Household/Account is provided in the input Id list
        List<Id> hhIds = new List<Id>{ accounts[0].Id, hhs[0].Id, null };

        List<Contact> hhContacts = contactSelector.householdMembersFor(hhIds);

        Set<Id> hhContactIds = new Map<Id, Contact>(hhContacts).keySet();
        Set<Id> expectedContactIds = new Set<Id>{ contacts[0].Id, contacts[1].Id };
        System.assertEquals(expectedContactIds.size(), hhContactIds.size(), 'The Contact query should be correct: ' + hhContacts);
        System.assert(expectedContactIds.containsAll(hhContactIds), 'Expected Contacts do not match returned list: ' + hhContacts);
    }


    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Builds Household Account Type Accounts
    * @param size Number of Accounts to build
    * @return List<Account>
    **********************************************************************************************************/
    private static List<Account> buildHHAccounts(Integer size) {
        return buildAccounts(size, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*********************************************************************************************************
    * @description Builds Accounts
    * @param size Number of Accounts to build
    * @param accountType Account Type
    * @return List<Account>
    **********************************************************************************************************/
    private static List<Account> buildAccounts(Integer size, String accountType) {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < size; i++) {
            accounts.add(new Account(
                Name = 'ACC' + i,
                npe01__SYSTEM_AccountType__c = accountType
            ));
        }

        return accounts;
    }

    /*********************************************************************************************************
    * @description Builds Households
    * @param size Number of Households to build
    * @return List<npo02__Household__c>
    **********************************************************************************************************/
    private static List<npo02__Household__c> buildHouseholds(Integer size) {
        List<npo02__Household__c> hhs = new List<npo02__Household__c>();

        for (Integer i = 0; i < size; i++) {
            hhs.add(new npo02__Household__c(
                Name = 'HH' + i
            ));
        }

        return hhs;
    }

    /*********************************************************************************************************
    * @description Retrieves Contacts ordered by First Name
    * @return List<Contact>
    **********************************************************************************************************/
    private static List<Contact> getContactsOrderById() {
        return [
            SELECT FirstName, LastName, AccountId,
                Account.Name, npo02__Household__c, npo02__Household__r.Id, npo02__Household__r.Name,
                npo02__Household__r.npo02__Formal_Greeting__c, npo02__Household__r.npo02__Informal_Greeting__c
            FROM Contact
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description Builds default Household name based on the Contact's Last Name
    * @param c Contact
    * @return String Default Household name
    **********************************************************************************************************/
    private static String buildDefaultHHName(Contact c) {
        return c.LastName + ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    /*********************************************************************************************************
    * @description Builds Household name based on the Household Naming Format
    * @param c Contact
    * @return String Formatted Household name
    **********************************************************************************************************/
    private static String buildFormattedHHName(Contact c) {
        return String.format('{0} {1} Household', new String[] { c.FirstName, c.LastName });
    }
}