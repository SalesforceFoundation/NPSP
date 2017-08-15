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
public class HH_HouseholdNaming_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    /*********************************************************************************************************
    * @description Test method for batch
    */
    public static testMethod void testBatch() {
        if (strTestOnly != '*' && strTestOnly != 'testBatch') return;
        
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
           npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
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
      if (strTestOnly != '*' && strTestOnly != 'HouseholdNamingTest') return;
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
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
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
        HH_HouseholdNaming.FutureUpdateNames(householdids);
        test.stoptest();
        //test a single member household, lastname, firstname, householdname:
        Contact con = [select npo02__Household__r.Name, npo02__Household__r.npo02__Informal_Greeting__c, npo02__Household__r.npo02__Formal_Greeting__c from Contact where FirstName = 'FirstName0'];
        system.assertEquals('LastName0 ' +  system.label.npo02.DefaultHouseholdName, con.npo02__household__r.Name);  
        system.assertEquals('FirstName0',con.npo02__household__r.npo02__Informal_Greeting__c);
        system.assertEquals('Mr. FirstName0 LastName0', con.npo02__household__r.npo02__Formal_Greeting__c);
        
    }
    
    /*********************************************************************************************************
    * @description tests updating and Household object's contact names
    */
    public static testMethod void HouseholdNamingUpdateTest(){
      if (strTestOnly != '*' && strTestOnly != 'HouseholdNamingUpdateTest') return;
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
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
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
        HH_HouseholdNaming hn = new HH_HouseholdNaming();
        test.startTest();
        hn.UpdateNames(newhhids);        
        
        test.stopTest();        
    }
    
    /*********************************************************************************************************
    * @description tests setting the naming order on Contacts
    */
    public static testMethod void testNamingOrder() {
      if (strTestOnly != '*' && strTestOnly != 'testNamingOrder') return;
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
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
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
        
        HH_HouseholdNaming hn = new HH_HouseholdNaming();
        
        hn.UpdateNames(new list<Id>{hh.id});
        
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
        
        hn.UpdateNames(new list<Id>{hh.id});
        
        hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c from npo02__Household__c where id = :hh.id LIMIT 1][0];
        
        system.assertequals('Test ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertequals('Joe ' + system.label.npo02.HouseholdNameConnector + ' Jim Test', hh.npo02__Formal_greeting__c);
        system.assertequals('Joe ' + system.label.npo02.HouseholdNameConnector + ' Jim', hh.npo02__Informal_greeting__c);
        
        con0.npo02__household__c = hh.id;
        con0.npo02__Household_Naming_Order__c = 0;
        con1.npo02__Household_Naming_Order__c = null;
        
        update con0;
        update con1;
        
        hn.UpdateNames(new list<Id>{hh.id});
        
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
        
        hn.UpdateNames(new list<Id>{hh.id});
        Test.stopTest();
        
        hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c from npo02__Household__c where id = :hh.id LIMIT 1][0];
        
        system.assertequals('Test ' + system.label.npo02.HouseholdNameConnector + ' Jones ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertequals('Jim ' + system.label.npo02.HouseholdNameConnector  + ' Joe Test ' + system.label.npo02.HouseholdNameConnector + ' John Jones', hh.npo02__Formal_greeting__c);
        system.assertequals('Jim, Joe ' + system.label.npo02.HouseholdNameConnector + ' John', hh.npo02__Informal_greeting__c);
        
        
    }  

    
    /*********************************************************************************************************
    * @description tests that case sensitive name changes on contacts update the Household name and greetings
    */
    public static testMethod void testCaseChanges() {
        if (strTestOnly != '*' && strTestOnly != 'testCaseChanges') return;
  
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
        if (strTestOnly != '*' && strTestOnly != 'testNamingOrder2') return;
  
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
        Account hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c, npe01__One2OneContact__c, Number_of_Household_Members__c from Account];
        system.assertEquals(con0.Id, hh.npe01__One2OneContact__c);
        system.assertEquals(3, hh.Number_of_Household_Members__c);
        system.assertEquals('smith ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertEquals('c0, c1 and c2 smith', hh.npo02__Formal_greeting__c);
        system.assertEquals('c0, c1 and c2', hh.npo02__Informal_greeting__c);
  
        con1.npo02__Household_Naming_Order__c = 0;
        update con1;

        // naming order overrides primary contact  
        hh = [select Id, Name, npo02__Formal_greeting__c, npo02__Informal_greeting__c, npe01__One2OneContact__c from Account];
        system.assertEquals(con0.Id, hh.npe01__One2OneContact__c);
        system.assertEquals('smith ' + system.label.npo02.DefaultHouseholdName, hh.Name);
        system.assertEquals('c1, c0 and c2 smith', hh.npo02__Formal_greeting__c);
        system.assertEquals('c1, c0 and c2', hh.npo02__Informal_greeting__c);
  
    }

    /*********************************************************************************************************
    @description
        Test strContactSelectStmtAllNamingFields property when Household Naming Settings is valid
        and the Automatic Household Naming is turned on 
    verify:
        Household Naming Settings fields are included in the SOQL.
        No error is raised when the SOQL is executed.
    **********************************************************************************************************/  
    private static testMethod void contactSoqlShouldContainHHNamingFieldsWhenAutomaticHouseholdNamingIsTurnedOn() {
        turnOnAutomaticHHNaming();
        setupHHNamingSettings();

        String soql = new HH_HouseholdNaming().strContactSelectStmtAllNamingFields;

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
    private static testMethod void contactSoqlShouldNotContainHHNamingFieldsWhenAutomaticHouseholdNamingIsTurnedOff() {
        turnOffAutomaticHHNaming();
        setupInvalidHHNamingSettings();

        String soql = new HH_HouseholdNaming().strContactSelectStmtAllNamingFields;

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
    private static testMethod void getHouseholdNamingContactFieldsShouldReturnEmptySetWhenAutomaticHouseholdNamingIsTurnedOff() {
        turnOffAutomaticHHNaming();
        setupInvalidHHNamingSettings();

        Set<String> fieldNames = new HH_HouseholdNaming().getHouseholdNamingContactFields();

        System.assert(fieldNames.isEmpty(), 'No field name should be returned: ' + fieldNames);
    }
    
    /*********************************************************************************************************
    @description
        Test getHouseholdNamingContactFields() method when Household Naming Settings is valid
        and the Automatic Household Naming is turned on
    verify:
        Returned set contains Contact field names specified in the Household Naming Settings.
    **********************************************************************************************************/  
    private static testMethod void getHouseholdNamingContactFieldsShouldReturnContactFieldNamesWhenAutomaticHouseholdNamingIsTurnedOn() {
        turnOnAutomaticHHNaming();
        setupHHNamingSettings();

        Set<String> fieldNames = new HH_HouseholdNaming().getHouseholdNamingContactFields();

        System.assertEquals(4, fieldNames.size(), fieldNames);  
        
        for (String fieldName : new String[] {
            'LastName', 'FirstName', 'Salutation', 'npe01__WorkEmail__c' //HH Naming fields
        }) {
            System.assert(fieldNames.contains(fieldName), fieldName + ' should be in: ' + fieldNames);
        }    
    }

    /*********************************************************************************************************
    @description
        Test isAutomaticNaming() method when the Automatic Household Naming is turned off
    verify:
        The method returns false.
    **********************************************************************************************************/  
    private static testMethod void isAutomaticNamingShouldReturnFalseWhenAutomaticHouseholdNamingIsTurnedOff() {
        turnOffAutomaticHHNaming();

        System.assert(!new HH_HouseholdNaming().isAutomaticNaming(), 'Automatic Household Naming should be turned off');
    }

    /*********************************************************************************************************
    @description
        Test isAutomaticNaming() method when the Automatic Household Naming is turned on
    verify:
        The method returns true.
    **********************************************************************************************************/  
    private static testMethod void isAutomaticNamingShouldReturnTrueWhenAutomaticHouseholdNamingIsTurnedOn() {
        turnOnAutomaticHHNaming();

        System.assert(new HH_HouseholdNaming().isAutomaticNaming(), 'Automatic Household Naming should be turned on');
    }

    // Helpers
    ////////////
    
    /*********************************************************************************************************
    * @description Turns on Automatic Household Naming
    * @return void
    **********************************************************************************************************/
    private static void turnOnAutomaticHHNaming() {
        setupAutomaticHHNaming(true);
    }

    /*********************************************************************************************************
    * @description Turns off Automatic Household Naming
    * @return void
    **********************************************************************************************************/
    private static void turnOffAutomaticHHNaming() {
        setupAutomaticHHNaming(false);
    }

    /*********************************************************************************************************
    * @description Configures Household Settings' Automatic Household Naming field
    * @param isOn Automatic Household Naming is turned on when parameter is true, otherwise, the settings is turned off
    * @return void
    **********************************************************************************************************/
    private static void setupAutomaticHHNaming(Boolean isOn) {
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR,
                npo02__Advanced_Household_Naming__c = isOn
            )
        );
    }
    /*********************************************************************************************************
    * @description Configures Household Naming Settings with invalid Name and Greetings formats
    * @return void
    **********************************************************************************************************/
    private static void setupInvalidHHNamingSettings() {
        setupHHNamingSettings(
            'The {!LastName}, {!{!FirstName}}} {!npe01__WorkEmail__c}} Family',
            '{!{!Salutation} {!FirstName}}} {!LastName}',
            '{!{!FirstName}}}'
        );
    }

    /*********************************************************************************************************
    * @description Configures Household Naming Settings with valid Name and Greetings formats
    * @return void
    **********************************************************************************************************/
    private static void setupHHNamingSettings() {
        setupHHNamingSettings(
            'The {!LastName}, {!{!FirstName} {!npe01__WorkEmail__c}} Family',
            '{!{!Salutation} {!FirstName}} {!LastName}',
            '{!{!FirstName}}'
        );
    }

    /*********************************************************************************************************
    * @description Configures Household Naming Settings 
    * @param hhNameFormat Household Naming Format
    * @param formalGreetingFormat Formal Greeting Format
    * @param informalGreetingFormat Informal Greeting Format
    * @return void
    **********************************************************************************************************/
    private static void setupHHNamingSettings(String hhNameFormat, String formalGreetingFormat, String informalGreetingFormat) {
        UTIL_CustomSettingsFacade.getHouseholdNamingSettingsForTests(
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
}