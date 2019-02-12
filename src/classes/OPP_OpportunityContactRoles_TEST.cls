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
private class OPP_OpportunityContactRoles_TEST {
 
    /*******************************************************************************************************
    * @description Role values to use in settings.
    */    
    private static final String OCR_ROLE_DONOR = 'Donor';
    private static final String OCR_ROLE_HONOREE = 'Honoree';
    private static final String OCR_ROLE_NOTIFICATION_RECIPIENT = 'Notification Recipient';
    private static final String OCR_ROLE_INFLUENCER = 'Influencer';
    private static final String OCR_ROLE_SOFT_CREDIT = 'Soft Credit';

    private static final String RELATIONSHIP_TYPE_FRIEND = 'Friend';
    private static final String RELATIONSHIP_TYPE_PARTNER = 'Partner';
    private static final String RELATIONSHIP_STATUS_CURRENT = 'Current';
    private static final String RELATIONSHIP_OCR_ROLE_TRIBUTE = 'Tribute';
    private static final String AFFILIATION_OCR_ROLE_SOLICITOR = 'Solicitor';
    private static final String HH_MEMBER_CONTACT_ROLE = 'Household Member';


    /*******************************************************************************************************
    * @description Test creation or upate of contact role for Organizational Account.
    */
    @isTest
    private static void testCreateUpdateCRForOrganizationalAccount() {
        Account acc = new Account(Name='test77');
        acc.npe01__SYSTEMIsIndividual__c = false;
        insert acc;

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.AccountId = acc.id;
        insert con;

        //Simulate user interface creation of opp from button on contact screen, 
        //i.e. Role field is blank in the new contact role.
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = acc.Id,
            CloseDate = date.today(), StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp1;
        
        //Make sure that we haven't created a contact role yet.
        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        System.assertEquals(0, result.size());
        
        //Insert the contact role with a blank Role field.
        OpportunityContactRole cr = new OpportunityContactRole (OpportunityId = opp1.Id, ContactId = con.Id, IsPrimary = true);
        insert cr;
        
        result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        System.assertEquals(con.Id, result[0].ContactId);
        
        //Now simulate import of an opp record with a contact ID.
        Opportunity opp2 = new Opportunity(
            Name = 'Apex Test Opp2',
            AccountId = acc.Id,
            Primary_Contact__c = con.Id,
            CloseDate = date.today(), StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp2;

        result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp2.Id];
        System.assertEquals(con.Id, result[0].ContactId);
        System.assertEquals(OCR_ROLE_SOFT_CREDIT, result[0].Role);
    }

    /*******************************************************************************************************
    * @description Test creation or upate of contact role for Individual Accounts.
    */
    @isTest
    private static void createOrUpdateCRForIndividualAccount() {
        Account acc = new Account(Name='test77');
        acc.npe01__SYSTEMIsIndividual__c = true;
        insert acc;

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.AccountId = acc.id;
        insert con;

        //Simulate user interface creation of opp from button on contact screen, 
        //i.e. Role field is blank in the new contact role.
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = acc.Id,
            CloseDate = date.today(), StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp1;

        //Make sure that we haven't created a contact role yet.
        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        System.assertEquals(0, result.size());

        //Insert the contact role with a blank Role field.
        OpportunityContactRole cr = new OpportunityContactRole (OpportunityId = opp1.Id, ContactId = con.Id, IsPrimary = true);
        insert cr;

        result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        System.assertEquals(con.Id, result[0].ContactId);

        //Now simulate import of an opp record with a contact ID.
        Opportunity opp2 = new Opportunity(
            Name = 'Apex Test Opp2',
            AccountId = acc.Id,
            Primary_Contact__c = con.Id,
            CloseDate = date.today(), StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp2;

        result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp2.Id];
        System.assertEquals(con.Id, result[0].ContactId);
        System.assertEquals(OCR_ROLE_DONOR, result[0].Role);
    }

    /*******************************************************************************************************
    * @description Disables OCR and verifies contact role isn't created.
    */
    @isTest
    private static void oppCRTriggerTurnedOff() {
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR, 
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_ROLE_DONOR));

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        
        Trigger_Handler__c triggerHandler = [SELECT Active__c FROM Trigger_Handler__c WHERE Class__c = 'OPP_OpportunityContactRoles_TDTM'];
        triggerHandler.Active__c = false;
        update triggerHandler;
        TDTM_ObjectDataGateway.ClearCachedTriggerHandlersForTest();
        
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
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
    private static void oppRolesForOneToOneContact() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, 
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_ROLE_DONOR
        ));

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        
        Contact[] createdContacts = [SELECT AccountId FROM Contact WHERE Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Primary_Contact__c = con.Id,
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(1, result.size());
        System.assertEquals(OCR_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].isPrimary);
        
       Opportunity[] oppResult = [SELECT AccountId FROM Opportunity WHERE Id = :opp1.Id];
       //should have the contact's one to one account
       System.assertEquals(createdContacts[0].AccountId, oppResult[0].AccountId);
    }
    
    /*******************************************************************************************************
    * @description Tests contact role creation for individual/bucket model using contact attribution.
    */
    @isTest
    private static void oppRolesForIndividualContact() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, 
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_ROLE_DONOR
        ));
              
        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        
        Contact[] createdContacts = [SELECT AccountId FROM Contact WHERE Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Primary_Contact__c = con.Id,
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();

        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        //should be one role
        System.assertEquals(1, result.size());
        System.assertEquals(OCR_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].isPrimary);
        
       Opportunity[] oppResult = [SELECT AccountId FROM Opportunity WHERE Id = :opp1.Id];
       //should be null account
       System.assertEquals(null, oppResult[0].AccountId);
    }
    
    /*******************************************************************************************************
    * @description Tests contact role creation for 1:1 model, using account attribution.
    */
    @isTest
    private static void oppRolesForOneToOneAccount() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, 
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_ROLE_DONOR
        ));
                
        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        
        Contact[] createdContacts = [SELECT AccountId FROM Contact WHERE Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = createdContacts[0].AccountId,
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(1, result.size());
        System.assertEquals(OCR_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].isPrimary);
    }

    /*******************************************************************************************************
    * @description Tests contact role creation for 1:1 model, using contact attribution.
    */
    @isTest
    private static void oppRolesForIndividualAccount() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, 
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_ROLE_DONOR
        ));
              
        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        
        Contact[] createdContacts = [SELECT AccountId FROM Contact WHERE Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();

        OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        //should be one role
        System.assertEquals(1, result.size());
        System.assertEquals(OCR_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].isPrimary);
        
        Opportunity[] oppResult = [SELECT AccountId FROM Opportunity WHERE Id = :opp1.Id];
        //should be null account
        System.assertEquals(null, oppResult[0].AccountId);
    }
    
    /*******************************************************************************************************
    * @description Puts a bad ID vaue in the Contact ID for Role field, verifies exception is thrown.
    */
    @isTest
    private static void oppRolesForBadId() {
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = 'junk',
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        Test.startTest();
        try {
            insert opp1;            
            
            OpportunityContactRole[] result = [SELECT OpportunityId, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
            //shouldn't be a contact role
            System.assertEquals(0, result.size());
            
            Opportunity[] oppResult = [SELECT AccountId FROM Opportunity WHERE Id = :opp1.Id];
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
    private static void honoreeNotificationBlankSettings(){
        List<contact> testCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testCons;

        Opportunity opp = new Opportunity(
            Name = 'Test',
            Primary_Contact__c = testCons[0].id,
            Honoree_Contact__c = testCons[1].id,
            Notification_Recipient_Contact__c = testCons[2].id,
            Notification_Recipient_Name__c = 'do not overwrite me',
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Contact> queryCon = [SELECT Id, Name FROM Contact WHERE Id IN :testCons];
        List<Opportunity> queryOpp = [SELECT Id, Notification_Recipient_Name__c, Honoree_Name__c FROM Opportunity WHERE Id = :opp.id];
        System.assertEquals(queryCon[1].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');
        System.assertEquals('do not overwrite me', queryOpp[0].Notification_Recipient_Name__c, 'Notifcation Recipient Name should not be overwritten.');

        List<OpportunityContactRole> queryOCR = [SELECT Id, ContactId, OpportunityId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:opp.id];
        System.assertEquals(1,queryOCR.size(), 'Only one Opportunity Contact Role should be created.');
        System.assertEquals(testCons[0].id, queryOCR[0].ContactId, 'Contact role should be for contact designated as primary.');
        System.assertEquals(true, queryOCR[0].isPrimary, 'Contact role marked primary.');
    }

    /*******************************************************************************************************
    * @description Populates Honoree and Notification Recipient contact role settings. Adds contacts for 
    * Honoree and Notification recipient contacts. Verifies contact roles are created correctly.
    */
    @isTest
    private static void honoreeNotificationInsert(){
        createHHAccountProcessorContactSettings();

        List<contact> testCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testCons;

        Opportunity opp = new Opportunity(
            Name = 'Test',
            Primary_Contact__c = testCons[0].id,
            Honoree_Contact__c = testCons[1].id,
            Notification_Recipient_Contact__c = testCons[2].id,
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Contact> queryCon = [SELECT Id, Name FROM Contact WHERE Id IN :testCons];
        List<Opportunity> queryOpp = [SELECT Id, Notification_Recipient_Name__c, Honoree_Name__c FROM Opportunity WHERE Id = :opp.id];
        System.assertEquals(queryCon[1].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');
        System.assertEquals(queryCon[2].Name, queryOpp[0].Notification_Recipient_Name__c, 'Notifcation Recipient Name should be populated.');

        List<OpportunityContactRole> queryOCR = [SELECT Id, ContactId, OpportunityId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:opp.id ORDER BY ContactId];
        System.assertEquals(3,queryOCR.size(), 'Three Opportunity Contact Roles should be created.');
        
        System.assertEquals(testCons[0].id,queryOCR[0].ContactId, 'First OCR is for primary contact.');
        System.assertEquals(true,queryOCR[0].isPrimary, 'Primary OCR is marked primary.');
        System.assertEquals(OCR_ROLE_DONOR, queryOCR[0].Role, 'Primary OCR has the correct role.');

        System.assertEquals(testCons[1].id,queryOCR[1].ContactId, 'Second OCR is for honoree contact.');
        System.assertEquals(false,queryOCR[1].isPrimary, 'Honoree OCR is not marked primary.');
        System.assertEquals(OCR_ROLE_HONOREE, queryOCR[1].Role, 'Honoree OCR has the correct role.');

        System.assertEquals(testCons[2].id,queryOCR[2].ContactId, 'Third OCR is for notification recipient contact.');
        System.assertEquals(false,queryOCR[2].isPrimary, 'Notification recipient OCR is not marked primary.');
        System.assertEquals(OCR_ROLE_NOTIFICATION_RECIPIENT, queryOCR[2].Role, 'Notification recipient OCR has the correct role.');
    }

    /*******************************************************************************************************
    * @description Updates an opportunity with Honoree and Notification Recipient contacts. Honoree is 
    * updated from one contact to another. Notification recipient is the same as the donor. Verifies that 
    * contact role deleted for first honoree, and created for the second honoree, but that no duplicate role
    * is created for the donor/notification recipient.
    */
    @isTest
    private static void honoreeNotificationUpdate(){
        createHHAccountProcessorContactSettings();

        List<contact> testCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testCons;

        Opportunity opp = new Opportunity(
            Name = 'Test',
            Primary_Contact__c = testCons[0].id,
            Honoree_Contact__c = testCons[2].id,
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp;

        List<Contact> queryCon = [SELECT Id, Name FROM Contact WHERE Id IN :testCons];
        List<Opportunity> queryOpp = [SELECT Id, Notification_Recipient_Name__c, Honoree_Name__c FROM Opportunity WHERE Id = :opp.id];
        System.assertEquals(queryCon[2].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');

        List<OpportunityContactRole> queryOCR = [SELECT Id, ContactId, OpportunityId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:opp.id ORDER BY ContactId];
        System.assertEquals(2,queryOCR.size(), 'Two Opportunity Contact Roles should be created.');

        System.assertEquals(testCons[0].id,queryOCR[0].ContactId, 'First OCR is for primary contact.');
        System.assertEquals(true,queryOCR[0].isPrimary, 'Primary OCR is marked primary.');
        System.assertEquals(OCR_ROLE_DONOR, queryOCR[0].Role, 'Primary OCR has the correct role.');

        System.assertEquals(testCons[2].id,queryOCR[1].ContactId, 'Second OCR is for honoree contact.');
        System.assertEquals(false,queryOCR[1].isPrimary, 'Honoree OCR is not marked primary.');
        System.assertEquals(OCR_ROLE_HONOREE, queryOCR[1].Role, 'Honoree OCR has the correct role.');

        opp.Honoree_Contact__c = testCons[1].id;
        opp.Notification_Recipient_Contact__c = testCons[0].id;

        Test.startTest();
        update opp;
        Test.stopTest();

        queryOpp = [SELECT Id, Notification_Recipient_Name__c, Honoree_Name__c FROM Opportunity WHERE Id = :opp.id];
        System.assertEquals(queryCon[1].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');
        System.assertEquals(queryCon[0].Name, queryOpp[0].Notification_Recipient_Name__c, 'Notifcation Recipient Name should be populated.');

        queryOCR = [SELECT Id, ContactId, OpportunityId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:opp.id ORDER BY ContactId];
        System.assertEquals(2,queryOCR.size(), 'Two Opportunity Contact Roles should be created.');
        
        System.assertEquals(testCons[0].id,queryOCR[0].ContactId, 'First OCR is for primary contact.');
        System.assertEquals(true,queryOCR[0].isPrimary, 'Primary OCR is marked primary.');
        System.assertEquals(OCR_ROLE_DONOR, queryOCR[0].Role, 'Primary OCR has the correct role.');

        System.assertEquals(testCons[1].id,queryOCR[1].ContactId, 'Second OCR is for honoree contact.');
        System.assertEquals(false,queryOCR[1].isPrimary, 'Honoree OCR is not marked primary.');
        System.assertEquals(OCR_ROLE_HONOREE, queryOCR[1].Role, 'Honoree OCR has the correct role.');

        opp.Honoree_Contact__c = null;
        update opp;

        queryOpp = [SELECT Id, Notification_Recipient_Name__c, Honoree_Name__c FROM Opportunity WHERE Id = :opp.id];
        System.assert(String.isBlank(queryOpp[0].Honoree_Name__c), 'Honoree Name should be deleted.');
    }

    /*******************************************************************************************************
    * @description Verifies that contact roles for household members aren't created as duplicates to contact
    * roles
    */
    @isTest
    private static void avoidDuplicateCRs(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        createHHAccountProcessorContactSettings();

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c='Household Member'
            )
        );

        Contact primaryCon = UTIL_UnitTestData_TEST.getContact();
        insert primaryCon;

        List<Contact> queryCon = [SELECT AccountId FROM Contact WHERE Id = :primaryCon.id];
        Id hhAccountId = queryCon[0].AccountId;

        List<contact> householdMembers = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        householdMembers[0].AccountId = hhAccountId;
        householdMembers[1].AccountId = hhAccountId;
        insert householdMembers;

        queryCon = [SELECT Id, AccountId, Name FROM Contact WHERE Id IN :householdMembers OR Id = :primaryCon.id];
        for (integer i=0; i<queryCon.size(); i++) {
            System.assertEquals(hhAccountId, queryCon[i].AccountId, 'Contacts should be in the same household.');
        }

        Opportunity opp = new Opportunity(
            Name = 'Test',
            Primary_Contact__c = primaryCon.id,
            Honoree_Contact__c = householdMembers[0].id,
            CloseDate = date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Opportunity> queryOpp = [SELECT Id, Notification_Recipient_Name__c, Honoree_Name__c FROM Opportunity WHERE Id = :opp.id];
        System.assertEquals(queryCon[1].Name, queryOpp[0].Honoree_Name__c, 'Honoree Name should be populated.');

        List<OpportunityContactRole> queryOCR = [SELECT Id, ContactId, OpportunityId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:opp.id ORDER BY ContactId];
        System.assertEquals(3, queryOCR.size(), 'Three Opportunity Contact Roles should be created.');
        
        System.assertEquals(primaryCon.Id, queryOCR[0].ContactId, 'First OCR is for primary contact.' + queryOCR[0]);
        System.assertEquals(true, queryOCR[0].isPrimary, 'Primary OCR is marked primary.' + queryOCR[0]);
        System.assertEquals(OCR_ROLE_DONOR, queryOCR[0].Role, 'Primary OCR has the correct role.' + queryOCR[0]);

        System.assertEquals(householdMembers[0].Id, queryOCR[1].ContactId, 'Second OCR is for honoree contact.');
        System.assertEquals(false,queryOCR[1].isPrimary, 'Honoree OCR is not marked primary.');
        System.assertEquals(OCR_ROLE_HONOREE, queryOCR[1].Role, 'Honoree OCR has the correct role.');

        System.assertEquals(householdMembers[1].Id, queryOCR[2].ContactId, 'Third OCR is for household member contact.');
        System.assertEquals(false,queryOCR[2].isPrimary, 'Household member OCR is not marked primary.');
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
    private static void testUpdatingPrimaryContact() {
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

        List<OpportunityContactRole> ocrs = [SELECT Id, ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :oppty.Id];
        System.assertEquals(1, ocrs.size());
        System.assertEquals(OCR_ROLE_DONOR, ocrs[0].Role);
        System.assertEquals(true, ocrs[0].IsPrimary);

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = oppty.id;
        ocr.ContactId =  testContacts[1].Id;
        ocr.Role = OCR_ROLE_INFLUENCER;
        insert ocr;

        ocrs = [SELECT Id, ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :oppty.Id];
        System.assertEquals(2, ocrs.size());

        for (OpportunityContactRole eachOCR : ocrs) {
            if (eachOCR.IsPrimary) {
                System.assertEquals(testContacts[0].Id, eachOCR.ContactId);
                System.assertEquals(OCR_ROLE_DONOR, eachOCR.Role);
            } else {
                System.assertEquals(testContacts[1].Id, eachOCR.ContactId);
                System.assertEquals(OCR_ROLE_INFLUENCER, eachOCR.Role);
            }
        }

        oppty.Primary_Contact__c = testContacts[1].Id;
        update oppty;
        Test.stopTest();

        List<OpportunityContactRole> ocrsUpdated = [SELECT Id, ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :oppty.Id];
        System.assertEquals(1, ocrsUpdated.size());

        System.assertEquals(OCR_ROLE_DONOR, ocrsUpdated[0].Role);
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
    private static void testPopulateAccountDetails() {
        Map<Id, Account> accountDetails = new Map<Id, Account>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert testContacts;
        testContacts = [SELECT Id, AccountId, FirstName, LastName FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(
            testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 100, null, null);

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
    @isTest
    private static void testPopulatePrimaryContactToOpportunities() {
        Map<Id, List<Id>> primaryContactToOpportunities = new Map<Id, List<Id>>();
        Map<Id, Account> accountDetails = new Map<Id, Account>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert testContacts;
        testContacts = [SELECT Id, AccountId, FirstName, LastName FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(
            testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 100, null, null);

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
    private static void testPopulateAccountToOpportunities() {
        Map<Id, List<Id>> accountToOpportunities = new Map<Id, List<Id>>();
        Map<Id, Account> accountDetails = new Map<Id, Account>();
        List<Account> testAccounts = new List<Account>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert testContacts;
        testContacts = [SELECT Id, AccountId, FirstName, LastName FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(
            testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 100, null, null);

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
    private static void testPopulateTransactionOCRs() {
        Map<Id, List<OpportunityContactRole>> transactionOCRs = new Map<Id, List<OpportunityContactRole>>();
        List<OpportunityContactRole> testOCRs = new List<OpportunityContactRole>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testContacts;
        testContacts = [SELECT Id, AccountId, FirstName, LastName FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(
            testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 100, null, null);

        insert testOpptys;
        testOpptys = [SELECT Id, AccountId, Primary_Contact__c FROM Opportunity];

        OpportunityContactRole ocr0 = new OpportunityContactRole();
        ocr0.OpportunityId = testOpptys[0].Id;
        ocr0.ContactId = testOpptys[0].Primary_Contact__c;
        ocr0.Role = OCR_ROLE_DONOR;
        testOCRs.add(ocr0);

        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId = testOpptys[0].Id;
        ocr1.ContactId = testContacts[2].Id;
        ocr1.Role = OCR_ROLE_SOFT_CREDIT;
        testOCRs.add(ocr1);

        OpportunityContactRole ocr2 = new OpportunityContactRole();
        ocr2.OpportunityId = testOpptys[1].Id;
        ocr2.ContactId = testOpptys[1].Primary_Contact__c;
        ocr2.Role = OCR_ROLE_SOFT_CREDIT;
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
        System.assertEquals(OCR_ROLE_DONOR, transactionOCRs.get(testOpptys[0].Id)[0].Role);
        System.assertEquals(OCR_ROLE_SOFT_CREDIT, transactionOCRs.get(testOpptys[1].Id)[0].Role);
    }


    /*********************************************************************************************************
    * @description Tests deleting an Opportunity's Opp.
    * verify:
    *   The OpportunityContactRoles were deleted accordingly.
    * @return void
    *********************************************************************************************************/
    @isTest
    private static void testClearOCRs() {
        List<OpportunityContactRole> ocrsToDelete = new List<OpportunityContactRole>();
        List<OpportunityContactRole> testOCRs = new List<OpportunityContactRole>();
        List<OpportunityContactRole> ocrsToDeleteImmediately = new List<OpportunityContactRole>();

        Map<Id, Map<Id, OpportunityContactRole>> opportunityToContactToOCR = new Map<Id, Map<Id, OpportunityContactRole>>();
        Map<Id, OpportunityContactRole> contactToOCR0 = new Map<Id, OpportunityContactRole>();
        Map<Id, OpportunityContactRole> contactToOCR1 = new Map<Id, OpportunityContactRole>();

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert testContacts;
        testContacts = [SELECT Id, AccountId, FirstName, LastName FROM Contact];

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(
            testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 100, null, null);

        insert testOpptys;
        testOpptys = [SELECT Id, AccountId, Primary_Contact__c FROM Opportunity];
        delete [SELECT Id FROM OpportunityContactRole WHERE OpportunityId IN :testOpptys];
        List<Opportunity> changedOpptys = new List<Opportunity>{ testOpptys[0], testOpptys[1] };

        OpportunityContactRole ocr0 = new OpportunityContactRole();
        ocr0.OpportunityId = testOpptys[0].Id;
        ocr0.ContactId = testOpptys[0].Primary_Contact__c;
        ocr0.Role = OCR_ROLE_DONOR;
        ocr0.isPrimary = true;
        testOCRs.add(ocr0);

        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId = testOpptys[0].Id;
        ocr1.ContactId = testContacts[2].Id;
        ocr1.Role = OCR_ROLE_SOFT_CREDIT;
        ocr1.isPrimary = false;
        testOCRs.add(ocr1);

        OpportunityContactRole ocr2 = new OpportunityContactRole();
        ocr2.OpportunityId = testOpptys[1].Id;
        ocr2.ContactId = testOpptys[1].Primary_Contact__c;
        ocr2.Role = OCR_ROLE_SOFT_CREDIT;
        ocr2.isPrimary = false;
        testOCRs.add(ocr2);

        insert testOCRs;

        contactToOCR0.put(ocr0.ContactId, ocr0);
        contactToOCR0.put(ocr1.ContactId, ocr1);
        contactToOCR1.put(ocr2.ContactId, ocr2);

        opportunityToContactToOCR.put(testOpptys[0].Id, contactToOCR0);
        opportunityToContactToOCR.put(testOpptys[1].Id, contactToOCR1);

        Test.startTest();

        testOCRs = [SELECT Id, OpportunityId, ContactId, Role, isPrimary FROM OpportunityContactRole];
        System.assertEquals(3, testOCRs.size());

        OPP_OpportunityContactRoles_TDTM oppOCRInstance = new OPP_OpportunityContactRoles_TDTM();
        oppOCRInstance.clearOCRs(opportunityToContactToOCR, changedOpptys, ocrsToDeleteImmediately);
        testOCRs = [SELECT Id, OpportunityId, ContactId, Role, isPrimary FROM OpportunityContactRole];
        System.assertEquals(1, testOCRs.size());

        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Validates that changing the Opp.AccountId to a null value or to a different Account does not
    * cause an error and that the related OCR's are valid
    */
    @isTest
    private static void testOppAccountIdChanges() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        Account orgAcct = new Account(Name = 'OrgTest567890', npe01__SYSTEMIsIndividual__c = false);
        insert orgAcct;
        
        createHHAccountProcessorContactSettings();

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                        npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR,
                        npo02__Household_Contact_Roles_On__c = true,
                        npo02__Household_Member_Contact_Role__c='Household Member'
                )
        );

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Contact c = [SELECT AccountId FROM Contact WHERE Id = :con.id LIMIT 1];

        Opportunity opp1 = new Opportunity(
                Name = 'Apex Test Opp 3',
                Primary_Contact__c = c.Id,
                CloseDate = date.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp1;

        opp1 = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opp1.Id LIMIT 1];
        System.assertNotEquals(null, opp1.AccountId);

        Test.startTest();
        opp1.AccountId = null;
        update opp1;
        OpportunityContactRole[] result = [SELECT OpportunityId, Opportunity.AccountId, ContactId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(1, result.size());
        System.assertEquals(OCR_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].isPrimary);

        opp1.AccountId = orgAcct.Id;
        update opp1;
        result = [SELECT OpportunityId, Opportunity.AccountId, ContactId, isPrimary, Role FROM OpportunityContactRole WHERE OpportunityId = :opp1.Id];
        //should be a contact role
        System.assertEquals(1, result.size());
        System.assertEquals(OCR_ROLE_DONOR, result[0].Role);
        System.assertEquals(true, result[0].isPrimary);
        System.assertNotEquals(null, result[0].Opportunity.AccountId);
    }

    /*******************************************************************************************************
    * @description Verifies OpportunityContactRoles (OCRs) are not created on an insert of Opportunities 
    * having "Disable Contact Role Automation" checkbox checked. If the checkbox would have been unchecked,
    * the OCRs should have been created.
    */
    @isTest
    private static void shouldNotCreateOcrsOnOppInsertWhenDisableContactRoleAutomationIsChecked() {
        createHHAccountProcessorContactSettings();

        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(7);
        insert contacts;

        List<Opportunity> opps = buildOppsDisableContactRoleAutomation(5);
        opps[0].Primary_Contact__c = contacts[0].Id;
        opps[1].Honoree_Contact__c = contacts[1].Id;
        opps[2].Notification_Recipient_Contact__c = contacts[2].Id;

        opps[3].Primary_Contact__c = contacts[3].Id;
        opps[3].Honoree_Contact__c = contacts[4].Id;
        opps[3].Notification_Recipient_Contact__c = contacts[5].Id;

        opps[4].Primary_Contact__c = contacts[6].Id;
        opps[4].Honoree_Contact__c = contacts[6].Id;
        opps[4].Notification_Recipient_Contact__c = contacts[6].Id;

        Test.startTest();
        insert opps;
        Test.stopTest();

        List<OpportunityContactRole> ocrs = getOppContactRoles(opps);
        System.assertEquals(0, ocrs.size(), 'No OCR should be created: ' + ocrs);

        Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>(opps);
        for (Opportunity actualOpp : getOpportunities(opps)) {
            Opportunity opp = oppsById.get(actualOpp.Id);

            if (actualOpp.Primary_Contact__c != null) {
                System.assertNotEquals(null, actualOpp.AccountId, 'Account should be set on an Opportunity with Primary Contact: ' + opp);
            }
            System.assertEquals(opp.Primary_Contact__c, actualOpp.Primary_Contact__c, 'Primary Contact should match');
            System.assertEquals(opp.Honoree_Contact__c, actualOpp.Honoree_Contact__c, 'Honoree Contact should match');
            System.assertEquals(opp.Notification_Recipient_Contact__c, actualOpp.Notification_Recipient_Contact__c, 'Notification Contact should match');
        }
    }

    /*******************************************************************************************************
    * @description Should not create OCRs when Primary Contact on an Opportunity is updated and the Opportunity
    * has "Disable Contact Role Automation" checkbox checked.
    */
    @isTest
    private static void shouldNotCreatePrimaryOcrOnOppUpdateWhenDisableContactRoleAutomationIsChecked() {
        createHHAccountProcessorContactSettings();

        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert contacts;

        Opportunity opp = buildOppsDisableContactRoleAutomation(1)[0];
        opp.Primary_Contact__c = contacts[0].Id;
        insert opp;

        List<OpportunityContactRole> ocrs = getOppContactRoles(new Set<Id>{ opp.Id });
        System.assertEquals(0, ocrs.size(), 'No OCR should be created: ' + ocrs);

        List<Opportunity> actualOpps = getOpportunities(opp.Id);
        Id oppAccountId = actualOpps[0].AccountId;
        System.assertNotEquals(null, oppAccountId, 'Account should be set on an Opportunity with Primary Contact: ' + opp);

        insert new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = contacts[1].Id,
            Role = OCR_ROLE_INFLUENCER,
            isPrimary = false
        );
        ocrs = getOppContactRoles(new Set<Id>{ opp.Id });
        System.assertEquals(1, ocrs.size(), 'One manual OCR should be created: ' + ocrs);
        System.assertEquals(false, ocrs[0].isPrimary, 'Should not be primary OCR: ' + ocrs);
        System.assertEquals(contacts[1].Id, ocrs[0].ContactId, 'Contact should match: ' + ocrs);

        Test.startTest();
        opp.Primary_Contact__c = contacts[2].Id;
        update opp;
        Test.stopTest();

        ocrs = getOppContactRoles(new Set<Id>{ opp.Id });
        System.assertEquals(1, ocrs.size(), 'Only manual OCR should exist: ' + ocrs);
        System.assertEquals(false, ocrs[0].isPrimary, 'Manual OCR should not be primary: ' + ocrs);
        System.assertEquals(contacts[1].Id, ocrs[0].ContactId, 'Manual OCR Contact should not be changed: ' + ocrs);

        actualOpps = getOpportunities(opp.Id);
        System.assertEquals(oppAccountId, actualOpps[0].AccountId, 
            'Account should not be updated when Primary Contact is updated: ' + opp);
    }

    /*******************************************************************************************************
    * @description Verifies existing primary OCR is not updated when Primary Contact is updated on
    * an Opportunity having "Disable Contact Role Automation" checkbox checked.
    */
    @isTest
    private static void shouldNotUpdateOcrOnOppUpdateWhenDisableContactRoleAutomationIsChecked() {
        createHHAccountProcessorContactSettings();

        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        insert contacts;

        Opportunity opp = buildOppsDisableContactRoleAutomation(1)[0];
        opp.Primary_Contact__c = contacts[0].Id;
        insert opp;

        List<OpportunityContactRole> ocrs = getOppContactRoles(new Set<Id>{ opp.Id });
        System.assertEquals(0, ocrs.size(), 'No OCR should be created: ' + ocrs);

        insert new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = contacts[0].Id,
            Role = OCR_ROLE_INFLUENCER,
            isPrimary = true
        );
        ocrs = getOppContactRoles(new Set<Id>{ opp.Id });
        System.assertEquals(1, ocrs.size(), 'One manual OCR should be created: ' + ocrs);
        System.assertEquals(true, ocrs[0].isPrimary, 'Should be primary OCR: ' + ocrs);
        System.assertEquals(contacts[0].Id, ocrs[0].ContactId, 'Contact should match: ' + ocrs);

        Test.startTest();
        opp.Primary_Contact__c = contacts[1].Id;
        update opp;
        Test.stopTest();

        ocrs = getOppContactRoles(new Set<Id>{ opp.Id });
        System.assertEquals(1, ocrs.size(), 'Only manual OCR should exist: ' + ocrs);
        System.assertEquals(true, ocrs[0].isPrimary, 'Manual OCR should stay as primary: ' + ocrs);
        System.assertEquals(contacts[0].Id, ocrs[0].ContactId, 'Manual OCR Contact should not be updated: ' + ocrs);
    }
    
    /*******************************************************************************************************
    * @description Verifies Opportunities processed in bulk have corrects OCRs created and updated 
    * based on their "Disable Contact Role Automation" checkbox.
    */
    @isTest
    private static void shouldAutomateSoftCreditOcrsOnlyForOppsWithDisableContactRoleAutomationIsUnchecked() {
        createHHAccountProcessorContactSettings();

        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(4);
        insert contacts;

        List<Opportunity> opps = new List<Opportunity>{
            buildOpportunities(1)[0],
            buildOppsDisableContactRoleAutomation(1)[0]
        };
        opps[0].Primary_Contact__c = contacts[0].Id;
        opps[1].Primary_Contact__c = contacts[2].Id;
        insert opps;

        List<OpportunityContactRole> ocrs = getOppContactRoles(opps);
        System.assertEquals(1, ocrs.size(), 'One OCR should be created: ' + ocrs);
        System.assertEquals(true, ocrs[0].isPrimary, 'OCR should be primary: ' + ocrs);
        System.assertEquals(opps[0].Id, ocrs[0].OpportunityId, 'OCR Opportunity should match: ' + ocrs);
        System.assertEquals(opps[0].Primary_Contact__c, ocrs[0].ContactId, 'OCR Contact should match: ' + ocrs);

        Test.startTest();
        opps[0].Primary_Contact__c = contacts[1].Id;
        opps[1].Primary_Contact__c = contacts[3].Id;
        update opps;
        Test.stopTest();

        ocrs = getOppContactRoles(opps);
        System.assertEquals(1, ocrs.size(), 'One OCR should exist: ' + ocrs);
        System.assertEquals(true, ocrs[0].isPrimary, 'The OCR should be primary: ' + ocrs);
        System.assertEquals(opps[0].Id, ocrs[0].OpportunityId, 'The OCR Opportunity should match: ' + ocrs);
        System.assertEquals(opps[0].Primary_Contact__c, ocrs[0].ContactId, 'The OCR Contact should match: ' + ocrs);
    }

    /*******************************************************************************************************
    * @description Verifies Opportunities having "Disable Contact Role Automation" checked do not have
    * OCRs created based on Relationships.
    */
    @isTest
    private static void shouldNotCreateRelationshipOcrsWhenOppDisableContactRoleAutomationIsChecked() {
        if (ADV_PackageInfo_SVC.useAdv()) return;

        createHHAccountProcessorContactSettings();

        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE));

        Integer size = 2;

        List<Contact> primaryContacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(size);
        insert primaryContacts;
        primaryContacts = getContacts(primaryContacts);

        List<Contact> householdMembers = UTIL_UnitTestData_TEST.createMultipleTestContacts(4);
        for (Integer i = 0; i < size; i++) {
            System.assertNotEquals(null, primaryContacts[i].npo02__household__c, 'Household should be created');

            householdMembers[i].AccountId = primaryContacts[i].AccountId;
            householdMembers[i].npo02__Household__c = primaryContacts[i].npo02__household__c;
        }
        insert householdMembers;

        List<npe4__Relationship__c> relationships = new List<npe4__Relationship__c>();
        for (Integer i = 0; i < size; i++) {
            relationships.add(new npe4__Relationship__c(
                npe4__Contact__c = primaryContacts[i].Id,
                npe4__RelatedContact__c = householdMembers[i].Id,
                npe4__Type__c = RELATIONSHIP_TYPE_FRIEND,
                npe4__Status__c = RELATIONSHIP_STATUS_CURRENT,
                Related_Opportunity_Contact_Role__c = RELATIONSHIP_OCR_ROLE_TRIBUTE
            ));
        }
        insert relationships;

        List<Opportunity> opps = new List<Opportunity>{
            buildOpportunities(1)[0],
            buildOppsDisableContactRoleAutomation(1)[0]
        };
        opps[0].Primary_Contact__c = primaryContacts[0].Id;
        opps[1].Primary_Contact__c = primaryContacts[1].Id;
        insert opps;

        List<OpportunityContactRole> ocrs = getOppContactRoles(opps);
        System.assertEquals(2, ocrs.size(), 'OCRs should be created: ' + ocrs);

        Boolean hasPrimary = false;
        for (OpportunityContactRole ocr : ocrs) {
            System.assertEquals(opps[0].Id, ocr.OpportunityId, 'OCR Opportunity should match: ' + ocr);

            if (ocr.isPrimary == true) {
                hasPrimary = true;
                System.assertEquals(OCR_ROLE_DONOR, ocr.Role, 'OCR Contact Role should match: ' + ocr);
                System.assertEquals(OCR_ROLE_DONOR, ocr.Role, 'OCR Contact Role should match: ' + ocr);
                System.assertEquals(opps[0].Primary_Contact__c, ocr.ContactId, 'OCR Contact should match: ' + ocr);
            } else {
                System.assertEquals(RELATIONSHIP_OCR_ROLE_TRIBUTE, ocr.Role, 'OCR Contact Role should match: ' + ocr);
                System.assertEquals(householdMembers[0].Id, ocr.ContactId, 'OCR Contact should match: ' + ocr);
            }
        }
        System.assertEquals(true, hasPrimary, 'One OCR should be primary: ' + ocrs);

        opps[0].Honoree_Contact__c = householdMembers[2].Id;
        opps[1].Honoree_Contact__c = householdMembers[3].Id;
        update opps;

        ocrs = getOppContactRoles(opps);
        System.assertEquals(3, ocrs.size(), 'OCRs should be created: ' + ocrs);
        for (OpportunityContactRole ocr : ocrs) {
            System.assertEquals(opps[0].Id, ocr.OpportunityId, 'OCR Opportunity should match: ' + ocr);
        }
    }

    /*******************************************************************************************************
    * @description Verifies Opportunities having "Disable Contact Role Automation" checked do not have
    * OCRs created based on Affiliations.
    */
    @isTest
    private static void shouldNotCreateAffiliationOcrsWhenOppDisableContactRoleAutomationIsChecked() {
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<Account> organizations = new List<Account>{
            new Account(Name = 'Org Disable Contact Role Automation Test Affiliations 1'),
            new Account(Name = 'Org Disable Contact Role Automation Test Affiliations 2')
        };
        insert organizations;

        createHHAccountProcessorContactSettings();

        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE));
        
        Integer size = 2;

        List<Contact> primaryContacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(size);
        insert primaryContacts;
        primaryContacts = getContacts(primaryContacts);

        List<npe5__Affiliation__c> affiliations = new List<npe5__Affiliation__c>();
        for (Integer i = 0; i < size; i++) {
            affiliations.add(new npe5__Affiliation__c(
                npe5__Organization__c = organizations[i].Id,
                npe5__Contact__c = primaryContacts[i].Id,
                npe5__Role__c = RELATIONSHIP_TYPE_PARTNER,
                npe5__Status__c = RELATIONSHIP_STATUS_CURRENT,
                Related_Opportunity_Contact_Role__c = AFFILIATION_OCR_ROLE_SOLICITOR
            ));
        }
        insert affiliations;

        List<Opportunity> opps = new List<Opportunity>{
            buildOpportunities(1)[0],
            buildOppsDisableContactRoleAutomation(1)[0]
        };
        for (Integer i = 0; i < size; i++) {
            opps[i].AccountId = organizations[i].Id;
            opps[i].Primary_Contact__c = primaryContacts[i].Id;
        }
        Test.startTest();
        insert opps;
        Test.stopTest();

        List<OpportunityContactRole> ocrs = getOppContactRoles(opps);
        System.assertEquals(1, ocrs.size(), 'OCR should be created: ' + ocrs);

        OpportunityContactRole ocr = ocrs[0];
        System.assertEquals(opps[0].Id, ocr.OpportunityId, 'OCR Opportunity should match: ' + ocr);
        System.assertEquals(true, ocr.isPrimary, 'The OCR should be primary: ' + ocr);
        System.assertEquals(opps[0].Primary_Contact__c, ocr.ContactId, 'OCR Contact should match: ' + ocr);
        System.assertEquals(OCR_ROLE_SOFT_CREDIT, ocr.Role, 'OCR Contact Role should match: ' + ocr);

        opps[0].Primary_Contact__c = null;
        opps[1].Primary_Contact__c = null;
        update opps;

        ocrs = getOppContactRoles(opps);
        System.assertEquals(1, ocrs.size(), 'OCR should be created: ' + ocrs);

        ocr = ocrs[0];
        System.assertEquals(opps[0].Id, ocr.OpportunityId, 'OCR Opportunity should match: ' + ocr);
        System.assertEquals(false, ocr.isPrimary, 'The OCR based on Affiliation should not be primary: ' + ocr);
        System.assertEquals(primaryContacts[0].Id, ocr.ContactId, 'OCR Contact should match: ' + ocr);
        System.assertEquals(AFFILIATION_OCR_ROLE_SOLICITOR, ocr.Role, 'OCR Contact Role should match: ' + ocr);
    }

    // Helpers
    //////////////

    /*******************************************************************************************************
    * @description Creates Contact Settings specifying OCR roles based on Contact assignment to Opportunity
    * @return void
    */
    private static void createHHAccountProcessorContactSettings() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_ROLE_DONOR,
                Contact_Role_for_Organizational_Opps__c = OCR_ROLE_SOFT_CREDIT,
                Honoree_Opportunity_Contact_Role__c = OCR_ROLE_HONOREE,
                Notification_Recipient_Opp_Contact_Role__c = OCR_ROLE_NOTIFICATION_RECIPIENT
            )
        );
    }

    /*******************************************************************************************************
    * @description Queries OCRs for specified Opportunities
    * @param opps Opportunity List
    * @return List<OpportunityContactRole> OCRs assigned to provided Opportunities
    */
    private static List<OpportunityContactRole> getOppContactRoles(List<Opportunity> opps) {
        return getOppContactRoles(extractIds(opps));
    }

    /*******************************************************************************************************
    * @description Queries OCRs for specified Opportunity
    * @param oppId Opportunity Id
    * @return List<OpportunityContactRole> OCRs assigned to provided Opportunities
    */
    private static List<OpportunityContactRole> getOppContactRoles(Id oppId) {
        return getOppContactRoles(new Set<Id>{ oppId });
    }

    /*******************************************************************************************************
    * @description Queries OCRs for specified Opportunities
    * @param oppIds Opportunity Ids
    * @return List<OpportunityContactRole> OCRs assigned to provided Opportunities
    */
    private static List<OpportunityContactRole> getOppContactRoles(Set<Id> oppIds) {
        return [
            SELECT OpportunityId, Opportunity.AccountId, ContactId, Contact.Name, isPrimary, Role 
            FROM OpportunityContactRole 
            WHERE OpportunityId IN :oppIds
        ];
    }

    /*******************************************************************************************************
    * @description Builds Opportunity sObjects
    * @param size Number of Opportunities to build
    * @return List<Opportunity> New Opportunities
    */
    private static List<Opportunity> buildOpportunities(Integer size) {
        return buildOpportunities(size, false);
    }

    /*******************************************************************************************************
    * @description Builds Opportunity sObjects and sets "Disable Contact Role Automation" to true
    * @param size Number of Opportunities to build
    * @return List<Opportunity> New Opportunities
    */
    private static List<Opportunity> buildOppsDisableContactRoleAutomation(Integer size) {
        return buildOpportunities(size, true);
    }

    /*******************************************************************************************************
    * @description Builds Opportunity sObjects
    * @param size Number of Opportunities to build
    * @param isDisableContactRoleAutomation Indicates if "Disable Contact Role Automation" is checked
    * @return List<Opportunity> New Opportunities
    */
    private static List<Opportunity> buildOpportunities(Integer size, Boolean isDisableContactRoleAutomation) {
        Date today = Date.today();
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < size; i++) {
            opps.add(new Opportunity(
                Name = 'OCR Opp ' + i,
                CloseDate = today,
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(), 
                Amount = 1000,
                DisableContactRoleAutomation__c = isDisableContactRoleAutomation
            ));
        }
        
        return opps;
    }

    /*******************************************************************************************************
    * @description Queries Opportunities
    * @param opps Existing Opportunity List
    * @return List<Opportunity> Opportunities
    */
    private static List<Opportunity> getOpportunities(List<Opportunity> opps) {
        return getOpportunities(extractIds(opps));
    }

    /*******************************************************************************************************
    * @description Queries Opportunity
    * @param oppId Opportunity Id
    * @return List<Opportunity> Opportunity in the list
    */
    private static List<Opportunity> getOpportunities(Id oppId) {
        return getOpportunities(new Set<Id>{ oppId });
    }

    /*******************************************************************************************************
    * @description Queries Opportunities
    * @param oppIds Opportunity Ids
    * @return List<Opportunity> Opportunities
    */
    private static List<Opportunity> getOpportunities(Set<Id> oppIds) {
        return [
            SELECT Id, AccountId, Account.Name, Primary_Contact__c, 
                Honoree_Contact__c, Notification_Recipient_Contact__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
    }

    /*******************************************************************************************************
    * @description Returns Contact SObjects
    * @param contactId Contact Id
    * @return List<Contact>
    */
    private static List<Contact> getContacts(Id contactId) {
        return getContacts(new List<Contact> { new Contact(Id = contactId) });
    }

    /*******************************************************************************************************
    * @description Returns Contact SObjects
    * @param contacts List of Contacts
    * @return List<Contact>
    */
    private static List<Contact> getContacts(List<Contact> contacts) {
        return [
            SELECT AccountId, npo02__Household__c 
            FROM Contact 
            WHERE Id IN :contacts
        ];
    }

    /*******************************************************************************************************
    * @description Extracts Ids from sObject list
    * @param sObjects SObject List
    * @return Set<Id> SObject Ids
    */
    private static Set<Id> extractIds(List<SObject> sObjects) {
        return new Map<Id, SObject>(sObjects).keySet();
    }

}