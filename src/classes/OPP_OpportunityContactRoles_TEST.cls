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
* @date 2011 (1.x)
* @group Opportunity
* @description Tests for OpportunityContactRoles
*/
@isTest
public class OPP_OpportunityContactRoles_TEST {

    /*******************************************************************************************************
    * @description Role values to use in settings.
    */
    @TestVisible private static final String OPPORTUNITY_CONTACT_ROLE_DONOR = 'Donor';
    @TestVisible private static final String OPPORTUNITY_CONTACT_ROLE_HONOREE = 'Honoree';
    @TestVisible private static final String OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT = 'Notification Recipient';
    @TestVisible private static final String OPPORTUNITY_CONTACT_ROLE_INFLUENCER = 'Influencer';
    @TestVisible private static final String OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT = 'Soft Credit';

    /*******************************************************************************************************
    * @description Test creation or upate of contact role for Organizational Account.
    */
    @isTest
    static void testCreateUpdateCRForOrganizationalAccount() {
        Account acc = new Account(
            Name='test77',
            npe01__SYSTEMIsIndividual__c = false
            );
        insert acc;

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.AccountId = acc.Id;
        insert con;

        //Simulate user interface creation of opp from button on contact screen,
        //i.e. Role field is blank in the new contact role.
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp1;

        //Make sure that we haven't created a contact role yet.
        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        System.assertEquals(0, result.size());

        //Insert the contact role with a blank Role field.
        OpportunityContactRole cr = new OpportunityContactRole(
            OpportunityId = opp1.Id,
            ContactId = con.Id,
            IsPrimary = true
        );
        insert cr;

        result = [SELECT    OpportunityId,
                            ContactId,
                            Role
                  FROM OpportunityContactRole
                  WHERE     OpportunityId = :opp1.Id];
        System.assertEquals(con.Id, result[0].ContactId);

        //Now simulate import of an opp record with a contact ID.
        Opportunity opp2 = new Opportunity(
            Name = 'Apex Test Opp2',
            AccountId = acc.Id,
            Primary_Contact__c = con.Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp2;

        result = [SELECT    OpportunityId,
                            ContactId,
                            Role
                  FROM OpportunityContactRole
                  WHERE     OpportunityId = :opp2.Id];
        System.assertEquals(con.Id, result[0].ContactId);
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT, result[0].Role);
    }

    /*******************************************************************************************************
    * @description Test creation or upate of contact role for Individual Accounts.
    */
    @isTest
    static void createOrUpdateCRForIndividualAccount() {
        Account acc = new Account(
            Name='test77',
            npe01__SYSTEMIsIndividual__c = true
        );
        insert acc;

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.AccountId = acc.Id;
        insert con;

        //Simulate user interface creation of opp from button on contact screen,
        //i.e. Role field is blank in the new contact role.
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp1;

        //Make sure that we haven't created a contact role yet.
        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        System.assertEquals(0, result.size());

        //Insert the contact role with a blank Role field.
        OpportunityContactRole cr = new OpportunityContactRole(
            OpportunityId = opp1.Id,
            ContactId = con.Id,
            IsPrimary = true
        );
        insert cr;

        result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        System.assertEquals(con.Id, result[0].ContactId);

        //Now simulate import of an opp record with a contact ID.
        Opportunity opp2 = new Opportunity(
            Name = 'Apex Test Opp2',
            AccountId = acc.Id,
            Primary_Contact__c = con.Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp2;

        result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp2.Id];
        System.assertEquals(con.Id, result[0].ContactId);
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, result[0].Role);
    }

    /*******************************************************************************************************
    * @description Disables OCR and verifies contact role isn't created.
    */
    @isTest
    static void oppCRTriggerTurnedOff() {
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR));

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Trigger_Handler__c triggerHandler = [SELECT Active__c FROM Trigger_Handler__c WHERE Class__c = 'OPP_OpportunityContactRoles_TDTM'];
        triggerHandler.Active__c = false;
        update triggerHandler;
        TDTM_ObjectDataGateway.ClearCachedTriggerHandlersForTest();

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = con.Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(0, result.size());

        Opportunity[] oppResult = [SELECT AccountId FROM Opportunity WHERE Id = :opp1.Id];
        //should have the contact's one to one account
        System.assertEquals(null, oppResult[0].AccountId);
    }

    /*******************************************************************************************************
    * @description Tests contact role creation for 1:1 model, using contact attribution.
    */
    @isTest
    static void oppRolesForOneToOneContact() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR
            )
        );

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Contact[] createdContacts = [SELECT     AccountId
                                     FROM Contact
                                     WHERE      Id = :con.Id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Primary_Contact__c = con.Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [SELECT   OpportunityId,
                                                    ContactId,
                                                    IsPrimary,
                                                    Role
                                           FROM OpportunityContactRole
                                           WHERE    OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(1, result.size());
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].IsPrimary);

       Opportunity[] oppResult = [SELECT    AccountId
                                  FROM Opportunity
                                  WHERE     Id = :opp1.Id];
       //should have the contact's one to one account
       System.assertEquals(createdContacts[0].AccountId, oppResult[0].AccountId);
    }

    /*******************************************************************************************************
    * @description Tests contact role creation for individual/bucket model using contact attribution.
    */
    @isTest
    static void oppRolesForIndividualContact() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR
            )
        );

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Contact[] createdContacts = [SELECT     AccountId
                                     FROM Contact
                                     WHERE      Id = :con.Id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Primary_Contact__c = con.Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();

        OpportunityContactRole[] result = [SELECT   OpportunityId,
                                                    ContactId,
                                                    IsPrimary,
                                                    Role
                                           FROM OpportunityContactRole
                                           WHERE    OpportunityId = :opp1.Id];
        //should be one role
        System.assertEquals(1, result.size());
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].IsPrimary);

       Opportunity[] oppResult = [SELECT    AccountId
                                  FROM Opportunity
                                  WHERE Id = :opp1.Id];
       //should be null account
       System.assertEquals(null, oppResult[0].AccountId);
    }

    /*******************************************************************************************************
    * @description Tests contact role creation for 1:1 model, using account attribution.
    */
    @isTest
    static void oppRolesForOneToOneAccount() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR
            )
        );

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Contact[] createdContacts = [SELECT     AccountId
                                     FROM Contact
                                     WHERE      Id = :con.Id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = createdContacts[0].AccountId,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [SELECT   OpportunityId,
                                                    ContactId,
                                                    IsPrimary,
                                                    Role
                                           FROM OpportunityContactRole
                                           WHERE    OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(1, result.size());
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].IsPrimary);
    }

    /*******************************************************************************************************
    * @description Tests contact role creation for 1:1 model, using contact attribution.
    */
    @isTest
    static void oppRolesForIndividualAccount() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR
            )
        );

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Contact[] createdContacts = [SELECT     AccountId
                                     FROM Contact
                                     WHERE      Id = :con.Id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = con.Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();

        OpportunityContactRole[] result = [SELECT   OpportunityId,
                                                    ContactId,
                                                    IsPrimary,
                                                    Role
                                           FROM OpportunityContactRole
                                           WHERE    OpportunityId = :opp1.Id];
        //should be one role
        System.assertEquals(1, result.size());
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].IsPrimary);

        Opportunity[] oppResult = [SELECT   AccountId
                                   FROM Opportunity
                                   WHERE    Id = :opp1.Id];
        //should be null account
        System.assertEquals(null, oppResult[0].AccountId);
    }

    /*******************************************************************************************************
    * @description Puts a bad ID vaue in the Contact ID for Role field, verifies exception is thrown.
    */
    @isTest
    static void oppRolesForBadId() {
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = 'junk',
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        Test.startTest();
        try {
            insert opp1;

            OpportunityContactRole[] result = [SELECT   OpportunityId,
                                                        ContactId,
                                                        Role
                                               FROM OpportunityContactRole
                                               WHERE    OpportunityId = :opp1.Id];
            //shouldn't be a contact role
            System.assertEquals(0, result.size());

            Opportunity[] oppResult = [SELECT   AccountId
                                       FROM Opportunity
                                       WHERE    Id = :opp1.Id];
            //shouldn't be an account
            System.assertEquals(null, oppResult[0].AccountId);
        } catch (exception e) {
            System.assert(e.getMessage().contains(Label.npe01.Opportunity_Contact_Role_Error_Bad_Contact_Id));
        }
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Leaves Honoree and Notification Recipient contact role settings blank. Adds contacts for
    * Honoree and Notification recipient contacts. Verifies Name fields updated when blank, verifies no
    * contact roles are created.
    */
    @isTest
    static void honoreeNotificationBlankSettings(){
        List<contact> testCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testCons;

        Opportunity opp = new Opportunity(
            Name = 'Test',
            Primary_Contact__c = testCons[0].Id,
            Honoree_Contact__c = testCons[1].Id,
            Notification_Recipient_Contact__c = testCons[2].Id,
            Notification_Recipient_Name__c = 'do not overwrite me',
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Contact> queryCon = [SELECT    Id,
                                            Name
                                  FROM Contact
                                  WHERE     Id IN :testCons];
        List<Opportunity> queryOpp = [SELECT    Id,
                                                Notification_Recipient_Name__c,
                                                Honoree_Name__c
                                      FROM Opportunity
                                      WHERE     Id = :opp.Id];
        System.assertEquals(queryCon[1].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');
        System.assertEquals('do not overwrite me', queryOpp[0].Notification_Recipient_Name__c, 'Notifcation Recipient Name should not be overwritten.');

        List<OpportunityContactRole> queryOCR = [SELECT     Id,
                                                            ContactId,
                                                            OpportunityId,
                                                            IsPrimary,
                                                            Role
                                                FROM OpportunityContactRole
                                                WHERE   OpportunityId =:opp.Id];
        System.assertEquals(1,queryOCR.size(), 'Only one Opportunity Contact Role should be created.');
        System.assertEquals(testCons[0].Id, queryOCR[0].ContactId, 'Contact role should be for contact designated as primary.');
        System.assertEquals(true, queryOCR[0].IsPrimary, 'Contact role marked primary.');
    }

    /*******************************************************************************************************
    * @description Populates Honoree and Notification Recipient contact role settings. Adds contacts for
    * Honoree and Notification recipient contacts. Verifies contact roles are created correctly.
    */
    @isTest
    static void honoreeNotificationInsert(){
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT
            )
        );

        List<contact> testCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testCons;

        Opportunity opp = new Opportunity(
            Name = 'Test',
            Primary_Contact__c = testCons[0].Id,
            Honoree_Contact__c = testCons[1].Id,
            Notification_Recipient_Contact__c = testCons[2].Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Contact> queryCon = [SELECT    Id,
                                            Name
                                  FROM Contact
                                  WHERE     Id IN :testCons];
        List<Opportunity> queryOpp = [SELECT    Id,
                                                Notification_Recipient_Name__c,
                                                Honoree_Name__c
                                      FROM Opportunity
                                      WHERE     Id = :opp.Id];
        System.assertEquals(queryCon[1].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');
        System.assertEquals(queryCon[2].Name, queryOpp[0].Notification_Recipient_Name__c, 'Notifcation Recipient Name should be populated.');

        List<OpportunityContactRole> queryOCR = [SELECT     Id,
                                                            ContactId,
                                                            OpportunityId,
                                                            IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:opp.Id ORDER BY ContactId];
        System.assertEquals(3,queryOCR.size(), 'Three Opportunity Contact Roles should be created.');

        System.assertEquals(testCons[0].Id,queryOCR[0].ContactId, 'First OCR is for primary contact.');
        System.assertEquals(true,queryOCR[0].IsPrimary, 'Primary OCR is marked primary.');
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, queryOCR[0].Role, 'Primary OCR has the correct role.');

        System.assertEquals(testCons[1].Id,queryOCR[1].ContactId, 'Second OCR is for honoree contact.');
        System.assertEquals(false,queryOCR[1].IsPrimary, 'Honoree OCR is not marked primary.');
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_HONOREE, queryOCR[1].Role, 'Honoree OCR has the correct role.');

        System.assertEquals(testCons[2].Id,queryOCR[2].ContactId, 'Third OCR is for notification recipient contact.');
        System.assertEquals(false,queryOCR[2].IsPrimary, 'Notification recipient OCR is not marked primary.');
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT, queryOCR[2].Role, 'Notification recipient OCR has the correct role.');
    }

    /*******************************************************************************************************
    * @description Updates an opportunity with Honoree and Notification Recipient contacts. Honoree is
    * updated from one contact to another. Notification recipient is the same as the donor. Verifies that
    * contact role deleted for first honoree, and created for the second honoree, but that no duplicate role
    * is created for the donor/notification recipient.
    */
    @isTest
    static void honoreeNotificationUpdate(){
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT
            )
        );

        List<contact> testCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testCons;

        Opportunity opp = new Opportunity(
            Name = 'Test',
            Primary_Contact__c = testCons[0].Id,
            Honoree_Contact__c = testCons[2].Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp;

        List<Contact> queryCon = [SELECT Id, Name FROM Contact WHERE Id IN :testCons];
        List<Opportunity> queryOpp = [SELECT    Id,
                                                Notification_Recipient_Name__c,
                                                Honoree_Name__c
                                      FROM Opportunity
                                      WHERE     Id = :opp.Id];
        System.assertEquals(queryCon[2].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');

        List<OpportunityContactRole> queryOCR = [SELECT     Id,
                                                            ContactId,
                                                            OpportunityId,
                                                            IsPrimary,
                                                            Role
                                                 FROM OpportunityContactRole
                                                 WHERE      OpportunityId =:opp.Id ORDER BY ContactId];
        System.assertEquals(2, queryOCR.size(), 'Two Opportunity Contact Roles should be created.');

        System.assertEquals(testCons[0].Id, queryOCR[0].ContactId, 'First OCR is for primary contact.');
        System.assertEquals(true, queryOCR[0].IsPrimary, 'Primary OCR is marked primary.');
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, queryOCR[0].Role, 'Primary OCR has the correct role.');

        System.assertEquals(testCons[2].Id, queryOCR[1].ContactId, 'Second OCR is for honoree contact.');
        System.assertEquals(false, queryOCR[1].IsPrimary, 'Honoree OCR is not marked primary.');
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_HONOREE, queryOCR[1].Role, 'Honoree OCR has the correct role.');

        opp.Honoree_Contact__c = testCons[1].Id;
        opp.Notification_Recipient_Contact__c = testCons[0].Id;

        Test.startTest();
        update opp;
        Test.stopTest();

        queryOpp = [SELECT  Id,
                            Notification_Recipient_Name__c,
                            Honoree_Name__c
                    FROM Opportunity
                    WHERE   Id = :opp.Id];
        System.assertEquals(queryCon[1].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');
        System.assertEquals(queryCon[0].Name, queryOpp[0].Notification_Recipient_Name__c, 'Notifcation Recipient Name should be populated.');

        queryOCR = [SELECT  Id,
                            ContactId,
                            OpportunityId,
                            IsPrimary,
                            Role
                    FROM OpportunityContactRole
                    WHERE   OpportunityId =:opp.Id
                    ORDER BY ContactId];
        System.assertEquals(2, queryOCR.size(), 'Two Opportunity Contact Roles should be created.');

        System.assertEquals(testCons[0].Id, queryOCR[0].ContactId, 'First OCR is for primary contact.');
        System.assertEquals(true, queryOCR[0].IsPrimary, 'Primary OCR is marked primary.');
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, queryOCR[0].Role, 'Primary OCR has the correct role.');

        System.assertEquals(testCons[1].Id, queryOCR[1].ContactId, 'Second OCR is for honoree contact.');
        System.assertEquals(false, queryOCR[1].IsPrimary, 'Honoree OCR is not marked primary.');
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_HONOREE, queryOCR[1].Role, 'Honoree OCR has the correct role.');

        opp.Honoree_Contact__c = null;
        update opp;

        queryOpp = [SELECT  Id,
                            Notification_Recipient_Name__c,
                            Honoree_Name__c
                    FROM Opportunity
                    WHERE   Id = :opp.Id];
        System.assert(String.isBlank(queryOpp[0].Honoree_Name__c), 'Honoree Name should be deleted.');
    }

    /*******************************************************************************************************
    * @description Verifies that contact roles for household members aren't created as duplicates to contact
    * roles
    */
    @isTest
    static void avoidDuplicateCRs(){
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT
            )
        );

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c='Household Member'
            )
        );

        Contact primaryCon = UTIL_UnitTestData_TEST.getContact();
        insert primaryCon;

        List<Contact> queryCon = [SELECT    AccountId
                                  FROM Contact
                                  WHERE     Id = :primaryCon.Id];
        Id hhAccountId = queryCon[0].AccountId;

        List<contact> householdMembers = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        householdMembers[0].AccountId = hhAccountId;
        householdMembers[1].AccountId = hhAccountId;
        insert householdMembers;

        queryCon = [SELECT  Id,
                            AccountId,
                            Name
                    FROM Contact
                    WHERE   Id IN :householdMembers OR
                            Id = :primaryCon.Id];
        for (Integer i=0; i < queryCon.size(); i++) {
            System.assertEquals(hhAccountId, queryCon[i].AccountId, 'Contacts should be in the same household.');
        }

        Opportunity opp = new Opportunity(
            Name = 'Test',
            Primary_Contact__c = primaryCon.Id,
            Honoree_Contact__c = householdMembers[0].Id,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Opportunity> queryOpp = [SELECT    Id,
                                                Notification_Recipient_Name__c,
                                                Honoree_Name__c
                                      FROM Opportunity
                                      WHERE     Id = :opp.Id];
        System.assertEquals(queryCon[1].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');

        List<OpportunityContactRole> queryOCR = [SELECT     Id,
                                                            ContactId,
                                                            OpportunityId,
                                                            IsPrimary,
                                                            Role
                                                 FROM OpportunityContactRole
                                                 WHERE      OpportunityId =:opp.Id
                                                 ORDER BY ContactId];
        System.assertEquals(3, queryOCR.size(), 'Three Opportunity Contact Roles should be created.');

        System.assertEquals(primaryCon.Id, queryOCR[0].ContactId, 'First OCR is for primary contact.' + queryOCR[0]);
        System.assertEquals(true, queryOCR[0].IsPrimary, 'Primary OCR is marked primary.' + queryOCR[0]);
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, queryOCR[0].Role, 'Primary OCR has the correct role.' + queryOCR[0]);

        System.assertEquals(householdMembers[0].Id, queryOCR[1].ContactId, 'Second OCR is for honoree contact.');
        System.assertEquals(false, queryOCR[1].IsPrimary, 'Honoree OCR is not marked primary.');
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_HONOREE, queryOCR[1].Role, 'Honoree OCR has the correct role.');

        System.assertEquals(householdMembers[1].Id, queryOCR[2].ContactId, 'Third OCR is for household member contact.');
        System.assertEquals(false, queryOCR[2].IsPrimary, 'Household member OCR is not marked primary.');
        System.assertEquals('Household Member', queryOCR[2].Role, 'Household member OCR has the correct role.');
    }

    /*********************************************************************************************************
    * @description Tests updating the Opportunity's Primary Contact to Contact that has an associated
    *               Opportunity Contact Role.
    * verify:
    *   The updated Opportunity Contact Role has the IsPrimary flag selected.
    * @return void
    *********************************************************************************************************/
    @isTest
    static void testUpdatingPrimaryContact() {
        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        insert testContacts;

        Opportunity oppty = new Opportunity(
            Name = 'Update Primary Contact Test Oppty',
            AccountId = testContacts[0].AccountId,
            Primary_Contact__c = testContacts[0].Id,
            Amount = 100,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage());

        Test.startTest();
        insert oppty;

        List<OpportunityContactRole> ocrs = [SELECT     Id,
                                                        ContactId,
                                                        Role,
                                                        IsPrimary
                                             FROM OpportunityContactRole
                                             WHERE OpportunityId = :oppty.Id];
        System.assertEquals(1, ocrs.size());
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, ocrs[0].Role);
        System.assertEquals(true, ocrs[0].IsPrimary);

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = oppty.Id;
        ocr.ContactId =  testContacts[1].Id;
        ocr.Role = OPPORTUNITY_CONTACT_ROLE_INFLUENCER;
        insert ocr;

        ocrs = [SELECT  Id,
                        ContactId,
                        Role,
                        IsPrimary
                FROM OpportunityContactRole
                WHERE OpportunityId = :oppty.Id];
        System.assertEquals(2, ocrs.size());

        for (OpportunityContactRole eachOCR : ocrs) {
            if (eachOCR.IsPrimary) {
                System.assertEquals(testContacts[0].Id, eachOCR.ContactId);
                System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, eachOCR.Role);
            } else {
                System.assertEquals(testContacts[1].Id, eachOCR.ContactId);
                System.assertEquals(OPPORTUNITY_CONTACT_ROLE_INFLUENCER, eachOCR.Role);
            }
        }

        oppty.Primary_Contact__c = testContacts[1].Id;
        update oppty;
        Test.stopTest();

        List<OpportunityContactRole> ocrsUpdated = [SELECT  Id,
                                                            ContactId,
                                                            Role,
                                                            IsPrimary
                                                    FROM OpportunityContactRole
                                                    WHERE   OpportunityId = :oppty.Id];
        System.assertEquals(1, ocrsUpdated.size());

        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, ocrsUpdated[0].Role);
        System.assertEquals(oppty.Primary_Contact__c, testContacts[1].Id);
        System.assertEquals(oppty.Primary_Contact__c, ocrsUpdated[0].ContactId);
    }

    /*********************************************************************************************************
    * @description Tests retrieving the Opportunity's associated Account's details.
    * verify:
    *   The Opportunity's Account details are retrieved.
    * @return void
    *********************************************************************************************************/
    @isTest
    static void testPopulateAccountDetails() {
        Map<Id, Account> accountDetails = new Map<Id, Account>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert testContacts;
        testContacts = [SELECT  Id,
                                AccountId,
                                FirstName,
                                LastName
                        FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
                                                                                            System.today(), 100, null, null);

        Test.startTest();
        insert testOpptys;

        OPP_OpportunityContactRoles_TDTM oppOCRInstance = new OPP_OpportunityContactRoles_TDTM();
        accountDetails = oppOCRInstance.populateAccountDetails(testOpptys);
        Test.stopTest();

        System.assertEquals(5, accountDetails.size());
        System.assertEquals(testContacts[0].AccountId, accountDetails.get(testContacts[0].AccountId).Id);
        System.assertEquals(testContacts[3].AccountId, accountDetails.get(testContacts[3].AccountId).Id);
    }

    /*********************************************************************************************************
    * @description Tests retrieving the Opportunity's associated Primary Contact's details.
    * verify:
    *   The updated Opportunity's Primary Contact details are retrieved.
    * @return void
    *********************************************************************************************************/
    @isTest static void testPopulatePrimaryContactToOpportunities() {
        Map<Id, List<Id>> primaryContactToOpportunities = new Map<Id, List<Id>>();
        Map<Id, Account> accountDetails = new Map<Id, Account>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert testContacts;
        testContacts = [SELECT  Id,
                                AccountId,
                                FirstName,
                                LastName
                        FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
                                                                                            System.today(), 100, null, null);

        Test.startTest();
        insert testOpptys;

        OPP_OpportunityContactRoles_TDTM oppOCRInstance = new OPP_OpportunityContactRoles_TDTM();
        accountDetails = oppOCRInstance.populateAccountDetails(testOpptys);

        primaryContactToOpportunities = oppOCRInstance.populatePrimaryContactToOpportunities(testOpptys, accountDetails);
        Test.stopTest();

        System.assertEquals(5, primaryContactToOpportunities.size());
        System.assertEquals(testOpptys[0].Id, primaryContactToOpportunities.get(testContacts[0].Id)[0]);
        System.assertEquals(testOpptys[3].Id, primaryContactToOpportunities.get(testContacts[3].Id)[0]);
    }

    /*********************************************************************************************************
    * @description Tests populating a Map of the Opportunity's associated Account Id to  Opportunity Ids.
    * verify:
    *   The Map was populated accordingly.
    * @return void
    *********************************************************************************************************/
    @isTest
    static void testPopulateAccountToOpportunities() {
        Map<Id, List<Id>> accountToOpportunities = new Map<Id, List<Id>>();
        Map<Id, Account> accountDetails = new Map<Id, Account>();
        List<Account> testAccounts = new List<Account>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert testContacts;
        testContacts = [SELECT  Id,
                                AccountId,
                                FirstName,
                                LastName
                        FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
                                                                                            System.today(), 100, null, null);

        Test.startTest();
        insert testOpptys;

        OPP_OpportunityContactRoles_TDTM oppOCRInstance = new OPP_OpportunityContactRoles_TDTM();
        accountDetails = oppOCRInstance.populateAccountDetails(testOpptys);
        for (Account eachAccount : accountDetails.values()) {
            eachAccount.npe01__SYSTEMIsIndividual__c = false;
            testAccounts.add(eachAccount);
        }
        update testAccounts;

        accountToOpportunities = oppOCRInstance.populateAccountToOpportunities(testOpptys, accountDetails);
        Test.stopTest();

        System.assertEquals(5, accountToOpportunities.size());
        System.assertEquals(testOpptys[0].Id, accountToOpportunities.get(testContacts[0].AccountId)[0]);
        System.assertEquals(testOpptys[3].Id, accountToOpportunities.get(testContacts[3].AccountId)[0]);
    }

    /*********************************************************************************************************
    * @description Tests populating a Map of the Opportunity and its associated OpportunityContactRoles.
    * verify:
    *   The Map was populated accordingly.
    * @return void
    *********************************************************************************************************/
    @isTest
    static void testPopulateTransactionOCRs() {
        Map<Id, List<OpportunityContactRole>> transactionOCRs = new Map<Id, List<OpportunityContactRole>>();
        List<OpportunityContactRole> testOCRs = new List<OpportunityContactRole>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testContacts;
        testContacts = [SELECT  Id,
                                AccountId,
                                FirstName,
                                LastName
                        FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
                                                                                            System.today(), 100, null, null);

        insert testOpptys;
        testOpptys = [SELECT    Id,
                                AccountId,
                                Primary_Contact__c
                      FROM Opportunity];

        OpportunityContactRole ocr0 = new OpportunityContactRole();
        ocr0.OpportunityId = testOpptys[0].Id;
        ocr0.ContactId = testOpptys[0].Primary_Contact__c;
        ocr0.Role = OPPORTUNITY_CONTACT_ROLE_DONOR;
        testOCRs.add(ocr0);

        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId = testOpptys[0].Id;
        ocr1.ContactId = testContacts[2].Id;
        ocr1.Role = OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT;
        testOCRs.add(ocr1);

        OpportunityContactRole ocr2 = new OpportunityContactRole();
        ocr2.OpportunityId = testOpptys[1].Id;
        ocr2.ContactId = testOpptys[1].Primary_Contact__c;
        ocr2.Role = OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT;
        testOCRs.add(ocr2);

        insert testOCRs;

        Test.startTest();

        OPP_OpportunityContactRoles_TDTM oppOCRInstance = new OPP_OpportunityContactRoles_TDTM();
        oppOCRInstance.populateTransactionOCRs(transactionOCRs, ocr0);
        oppOCRInstance.populateTransactionOCRs(transactionOCRs, ocr1);
        oppOCRInstance.populateTransactionOCRs(transactionOCRs, ocr2);

        Test.stopTest();

        System.assertEquals(2, transactionOCRs.size());
        System.assertEquals(2, transactionOCRs.get(testOpptys[0].Id).size());
        System.assertEquals(1, transactionOCRs.get(testOpptys[1].Id).size());
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, transactionOCRs.get(testOpptys[0].Id)[0].Role);
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT, transactionOCRs.get(testOpptys[1].Id)[0].Role);
    }

    /*********************************************************************************************************
    * @description Tests deleting an Opportunity's Opp.
    * verify:
    *   The OpportunityContactRoles were deleted accordingly.
    * @return void
    *********************************************************************************************************/
    @isTest
    static void testClearOCRs() {
        List<OpportunityContactRole> ocrsToDelete = new List<OpportunityContactRole>();
        List<OpportunityContactRole> testOCRs = new List<OpportunityContactRole>();
        List<OpportunityContactRole> ocrsToDeleteImmediately = new List<OpportunityContactRole>();

        Map<Id, Map<Id, OpportunityContactRole>> opportunityToContactToOCR = new Map<Id, Map<Id, OpportunityContactRole>>();
        Map<Id, OpportunityContactRole> contactToOCR0 = new Map<Id, OpportunityContactRole>();
        Map<Id, OpportunityContactRole> contactToOCR1 = new Map<Id, OpportunityContactRole>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testContacts;
        testContacts = [SELECT  Id,
                                AccountId,
                                FirstName,
                                LastName
                        FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
                                                                                            System.today(), 100, null, null);

        insert testOpptys;
        testOpptys = [SELECT    Id,
                                AccountId,
                                Primary_Contact__c
                      FROM Opportunity];
        delete [SELECT  Id
                FROM OpportunityContactRole
                WHERE   OpportunityId IN :testOpptys];
        List<Opportunity> changedOpptys = new List<Opportunity>{ testOpptys[0], testOpptys[1] };

        OpportunityContactRole ocr0 = new OpportunityContactRole();
        ocr0.OpportunityId = testOpptys[0].Id;
        ocr0.ContactId = testOpptys[0].Primary_Contact__c;
        ocr0.Role = OPPORTUNITY_CONTACT_ROLE_DONOR;
        ocr0.IsPrimary = true;
        testOCRs.add(ocr0);

        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId = testOpptys[0].Id;
        ocr1.ContactId = testContacts[2].Id;
        ocr1.Role = OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT;
        ocr1.IsPrimary = false;
        testOCRs.add(ocr1);

        OpportunityContactRole ocr2 = new OpportunityContactRole();
        ocr2.OpportunityId = testOpptys[1].Id;
        ocr2.ContactId = testOpptys[1].Primary_Contact__c;
        ocr2.Role = OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT;
        ocr2.IsPrimary = false;
        testOCRs.add(ocr2);

        insert testOCRs;

        contactToOCR0.put(ocr0.ContactId, ocr0);
        contactToOCR0.put(ocr1.ContactId, ocr1);
        contactToOCR1.put(ocr2.ContactId, ocr2);

        opportunityToContactToOCR.put(testOpptys[0].Id, contactToOCR0);
        opportunityToContactToOCR.put(testOpptys[1].Id, contactToOCR1);

        Test.startTest();

        testOCRs = [SELECT  Id,
                            OpportunityId,
                            ContactId,
                            Role,
                            IsPrimary
                    FROM OpportunityContactRole];
        System.assertEquals(3, testOCRs.size());

        OPP_OpportunityContactRoles_TDTM oppOCRInstance = new OPP_OpportunityContactRoles_TDTM();
        oppOCRInstance.clearOCRs(opportunityToContactToOCR, changedOpptys, ocrsToDeleteImmediately, new Map<Id, List<Tribute__c>>());
        testOCRs = [SELECT  Id,
                            OpportunityId,
                            ContactId,
                            Role,
                            IsPrimary
                    FROM OpportunityContactRole];
        System.assertEquals(1, testOCRs.size());

        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Validates that changing the Opp.AccountId to a null value or to a different Account does not
    * cause an error and that the related OCR's are valid
    */
    @isTest
    static void testOppAccountIdChanges() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        Account orgAcct = new Account(
            Name = 'OrgTest567890',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT
                )
        );

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                        npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR,
                        npo02__Household_Contact_Roles_On__c = true,
                        npo02__Household_Member_Contact_Role__c='Household Member'
                )
        );

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Contact c = [SELECT     AccountId
                     FROM Contact
                     WHERE      Id = :con.Id
                     LIMIT 1];

        Opportunity opp1 = new Opportunity(
                Name = 'Apex Test Opp 3',
                Primary_Contact__c = c.Id,
                CloseDate = Date.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp1;

        opp1 = [SELECT  Id,
                        AccountId
                FROM Opportunity
                WHERE   Id = :opp1.Id
                LIMIT 1];
        System.assertNotEquals(null, opp1.AccountId);

        Test.startTest();
        opp1.AccountId = null;
        update opp1;
        OpportunityContactRole[] result = [SELECT   OpportunityId,
                                                    Opportunity.AccountId,
                                                    ContactId,
                                                    IsPrimary,
                                                    Role
                                           FROM OpportunityContactRole
                                           WHERE    OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(1, result.size());
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].IsPrimary);

        opp1.AccountId = orgAcct.Id;
        update opp1;
        result = [SELECT    OpportunityId,
                            Opportunity.AccountId,
                            ContactId,
                            IsPrimary,
                            Role
                  FROM OpportunityContactRole
                  WHERE     OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(1, result.size());
        System.assertEquals(OPPORTUNITY_CONTACT_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].IsPrimary);
        System.assertNotEquals(null, result[0].Opportunity.AccountId);
    }

    /*******************************************************************************************************
    * @description Tests method to Populate OCR related Maps
    */
    @isTest
    static void testPopulateOCRMapsMethod() {
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT
            )
        );

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(4);
        insert testContacts;
        testContacts = [SELECT  Id,
                                AccountId,
                                FirstName,
                                LastName
                        FROM Contact];

        List<Contact> testContactsForOpps = new List<Contact>();
        for (Integer i=0; i < 3; i++) {
            testContactsForOpps.add(testContacts[i]);
        }

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(testContactsForOpps, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
                                                                                            System.today(), 100, null, null);


    insert testOpptys;

        // Set Notification Recipient Contact on first Opportunity so it will have a non primary OCR
        Opportunity opp1 = new Opportunity(
            Id = testOpptys[0].Id,
            Notification_Recipient_Contact__c = testContacts[3].Id
        );
        update opp1;

        Map<Id, OpportunityContactRole> mapOppIdPrimaryOCR = new Map<Id, OpportunityContactRole>();
        Map<Id, Map<Id, OpportunityContactRole>> mapOppIdMapConIdOCR = new Map<Id, Map<Id, OpportunityContactRole>>();
        Set<String> uniqueOCRKeys = new Set<String>();

        List<OpportunityContactRole> ocrs = [SELECT     Id,
                                                        OpportunityId,
                                                        ContactId,
                                                        Role,
                                                        IsPrimary
                                            FROM OpportunityContactRole];

        System.assertEquals (4, ocrs.size());

        OPP_OpportunityContactRoles_TDTM.populateOCRMaps(testOpptys, mapOppIdPrimaryOCR, mapOppIdMapConIdOCR, uniqueOCRKeys);

        System.assertEquals(3, mapOppIdPrimaryOCR.size());
        System.assertEquals(3, mapOppIdMapConIdOCR.size());

        System.assertEquals(2, mapOppIdMapConIdOCR.get(testOpptys[0].Id).size());
        System.assertEquals(1, mapOppIdMapConIdOCR.get(testOpptys[1].Id).size());
        System.assertEquals(1, mapOppIdMapConIdOCR.get(testOpptys[2].Id).size());
        System.assertEquals(4, uniqueOCRKeys.size());

        for (OpportunityContactRole ocr : ocrs) {
            System.assertEquals(true, uniqueOCRKeys.contains(OPP_OpportunityContactRoles_TDTM.calcUniqueOCRKey(ocr)));

            if (ocr.IsPrimary) {
                System.assertEquals(mapOppIdPrimaryOCR.get(ocr.OpportunityId).Id, ocr.Id);
            }
        }
    }

    /*******************************************************************************************************
    * @description Tests method to Calculate Unique OCR Key for OpportunityContactRole
    */
    @isTest
    static void testCalcUniqueOCRKeyMethod() {
         npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OPPORTUNITY_CONTACT_ROLE_DONOR,
                Honoree_Opportunity_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_HONOREE,
                Notification_Recipient_Opp_Contact_Role__c = OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT
            )
        );

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert testContacts;
        testContacts = [SELECT  Id,
                                AccountId,
                                FirstName,
                                LastName
                        FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
                                                                                            System.today(), 100, null, null);

        insert testOpptys;

        List<OpportunityContactRole> ocrs = [SELECT     Id,
                                                        OpportunityId,
                                                        ContactId,
                                                        Role,
                                                        IsPrimary
                                            FROM OpportunityContactRole];

        System.assertEquals(1, ocrs.size());

        System.assertEquals(ocrs[0].OpportunityId + '-' + ocrs[0].ContactId + '-' + ocrs[0].Role, OPP_OpportunityContactRoles_TDTM.calcUniqueOCRKey(ocrs[0]));
    }
}