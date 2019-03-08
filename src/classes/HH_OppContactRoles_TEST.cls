/*
    Copyright (c) 2011, Salesforce.org
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
* @group Households
* @description This class contains unit tests for validating the behavior of the Household Opportunity Contact Role class
*/
@isTest
private class HH_OppContactRoles_TEST {
    private static final String OCR_DONOR_ROLE = 'Donor';
    private static final String HH_MEMBER_CONTACT_ROLE = 'Household Member';
    
    @isTest
    private static void opportunityWithHouseholdOne2One() {
        if (ADV_PackageInfo_SVC.useAdv()) return;

        opportunityWithHousehold(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    @isTest
    private static void opportunityWithHouseholdBucket() {
        if (ADV_PackageInfo_SVC.useAdv()) return;

        opportunityWithHousehold(CAO_Constants.BUCKET_PROCESSOR);
    }
    @isTest
    private static void opportunityWithHouseholdHHAccount() {
        if (ADV_PackageInfo_SVC.useAdv()) return;

        opportunityWithHousehold(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    /*********************************************************************************************************
    * @description Tests that household Opportunity Contact Roles are created under the different account models.
    * Verifies deceased contacts are not included.
    * @param strProcessor Which account model processor to test under.
    * @return void
    */
    private static void opportunityWithHousehold(String strProcessor) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = strProcessor,
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_DONOR_ROLE));
        
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE));
                
        //create contact
        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        con = getContacts(con.id)[0];

        Id accountId = con.AccountId;
        Id householdId = con.npo02__household__c;
        //create household member
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.AccountId = strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR ? accountId : null;
        con2.npo02__Household__c = householdId;
        insert con2;
        Contact con3 = UTIL_UnitTestData_TEST.getContact();
        con3.Deceased__c = true;
        con3.AccountId = strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR ? accountId : null;
        con3.npo02__Household__c = householdId;
        insert con3;

        Opportunity o = buildOpportunity(accountId);
        Test.startTest();
        insert o;
        Test.stopTest();

        List<OpportunityContactRole> createdRoles = getOppContactRoles(o.id);

        if (strProcessor == CAO_Constants.BUCKET_PROCESSOR) {
            System.assertEquals(0,createdRoles.size());
        } else {
            System.assertEquals(2,createdRoles.size());
            System.assertEquals(OCR_DONOR_ROLE,createdRoles[0].Role);
            System.assert(createdRoles[0].IsPrimary);
            System.assertEquals(HH_MEMBER_CONTACT_ROLE,createdRoles[1].Role);
        }
    }

    /*********************************************************************************************************
    * @description Opportunity Contact Roles should not be created for Contacts referenced in Opportunities
    * with "Disable Contact Role Automation" when Household is being managed.
    */
    @isTest
    private static void shouldNotCreateOcrsWhenOppDisableContactRoleAutomationIsChecked() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_DONOR_ROLE));
        
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE));
                
        List<Contact> contacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(2);
        insert contacts;
        contacts = getContacts(contacts);

        List<Contact> householdMembers = UTIL_UnitTestData_TEST.createMultipleTestContacts(4);
        
        householdMembers[0].AccountId = contacts[0].AccountId;
        householdMembers[0].npo02__Household__c = contacts[0].npo02__household__c;
        householdMembers[1].Deceased__c = true;
        householdMembers[1].AccountId = contacts[0].AccountId;
        householdMembers[1].npo02__Household__c = contacts[0].npo02__household__c;

        householdMembers[2].AccountId = contacts[1].AccountId;
        householdMembers[2].npo02__Household__c = contacts[1].npo02__household__c;
        householdMembers[3].Deceased__c = true;
        householdMembers[3].AccountId = contacts[1].AccountId;
        householdMembers[3].npo02__Household__c = contacts[1].npo02__household__c;

        insert householdMembers;

        List<Opportunity> opps = new List<Opportunity>{
            buildOpportunity(contacts[0].AccountId),
            buildOpportunity(contacts[1].AccountId)
        };
        opps[0].DisableContactRoleAutomation__c = true;
        Test.startTest();
        insert opps;
        Test.stopTest();

        List<OpportunityContactRole> ocrs = getOppContactRoles(opps[0].id);
        System.assertEquals(0, ocrs.size(), 
            'No Opportunity Contact Role should be created for Opp with Disable Contact Role Automation checked: ' + ocrs);
            
        ocrs = getOppContactRoles(opps[1].id);
        System.assertEquals(2, ocrs.size(), 
            'Opportunity Contact Roles should be created for Opp with Disable Contact Role Automation unchecked: ' + ocrs);
    }

    @isTest
    private static void opportunityWithHouseholdNoRolesOne2One() {
        if (ADV_PackageInfo_SVC.useAdv()) return;

        opportunityWithHouseholdNoRoles(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    @isTest
    private static void opportunityWithHouseholdNoRolesBucket() {
        if (ADV_PackageInfo_SVC.useAdv()) return;
        
        opportunityWithHouseholdNoRoles(CAO_Constants.BUCKET_PROCESSOR);
    }
    @isTest
    private static void opportunityWithHouseholdNoRolesHHAccount() {
        if (ADV_PackageInfo_SVC.useAdv()) return;

        opportunityWithHouseholdNoRoles(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    /*********************************************************************************************************
    * @description Tests that household Opportunity Contact Roles are NOT created under the different account models
    * when the setting for contact roles is off.
    * @param strProcessor Which account model processor to test under.
    * @return void
    */
    private static void opportunityWithHouseholdNoRoles(String strProcessor) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(npe01__Account_Processor__c = strProcessor));
        
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR, 
                npo02__Household_Contact_Roles_On__c = false));

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        con = getContacts(con.id)[0];
        Id accountId = con.AccountId;
        Id householdId = con.npo02__household__c;

        //create household member
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.AccountId = strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR ? accountId : null;
        con2.npo02__Household__c = householdId;
        insert con2;

        Opportunity o = buildOpportunity(accountId);
        Test.startTest();
        insert o;
        Test.stopTest();

        List<OpportunityContactRole> createdRoles = getOppContactRoles(o.id);
        if (strProcessor == CAO_Constants.BUCKET_PROCESSOR) {
            System.assertEquals(0,createdRoles.size());
        } else {
            System.assertEquals(1,createdRoles.size());
        }
    }
    
    
    @isTest
    private static void opportunityWithNoHouseholdOne2One() {
        if (ADV_PackageInfo_SVC.useAdv()) return;
        
        opportunityWithNoHousehold(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    @isTest
    private static void opportunityWithNoHouseholdHHAccount() {
        if (ADV_PackageInfo_SVC.useAdv()) return;

        opportunityWithNoHousehold(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    /*********************************************************************************************************
    * @description Tests that household Opportunity Contact Roles are created under the different account models
    * when household objects is turned off.
    * @param strProcessor Which account model processor to test under.
    * @return void
    */
    private static void opportunityWithNoHousehold(String strProcessor) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(npe01__Account_Processor__c = strProcessor));
                
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c(
                npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR, 
                npo02__Household_Contact_Roles_On__c = true));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        
        con = getContacts(con.id)[0];
        Id accountId = con.AccountId;
        Id householdId = con.npo02__household__c;
        //create household member
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.npo02__Household__c = householdId;
        insert con2;

        Opportunity o = buildOpportunity(accountId);
        Test.startTest();
        insert o;
        Test.stopTest();
        
        List<OpportunityContactRole> createdRoles = getOppContactRoles(o.id);
        System.assertEquals(1,createdRoles.size());
    }
    
    
    @isTest
    private static void opportunityRegularAccountOne2One() {
        opportunityRegularAccount(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    @isTest
    private static void opportunityRegularAccountHHAccount() {
        opportunityRegularAccount(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    /*********************************************************************************************************
    * @description Tests that no Opportunity Contact Roles are created under the different account models for
    * a normal organizational account.
    * @param strProcessor Which account model processor to test under.
    * @return void
    */
    private static void opportunityRegularAccount(String strProcessor) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(npe01__Account_Processor__c = strProcessor));
                
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR, 
                npo02__Household_Contact_Roles_On__c = true));
        
        //create contact
        Account acct = new Account(Name = 'fake account');
        insert acct;
        Id accountId = acct.Id;

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.accountId = accountId;
        insert con;
        con = getContacts(con.id)[0];
        
        Id householdId = con.npo02__household__c;
        
        Opportunity o = buildOpportunity(accountId);
        Test.startTest();
        insert o;
        Test.stopTest();

        List<OpportunityContactRole> createdRoles = getOppContactRoles(o.id);
        System.assertEquals(0,createdRoles.size());
    }
    
    @isTest
    private static void ghIssue25() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_DONOR_ROLE,
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c ( 
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE));
       
        npo02__Household__c hh = new npo02__Household__c(Name ='hh');
        insert hh;
        Contact con1= new Contact(LastName='test1', npo02__Household__c = hh.id);
        Contact con2= new Contact(LastName='test2');
        insert con1;
        insert con2;

        Test.startTest();
        insert new List<Opportunity>{
            new Opportunity(
                Name = 'o1',
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                CloseDate = System.today(),
                Primary_Contact__c = (String)con1.id),
            new Opportunity(
                Name = 'o2',
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                CloseDate = System.today(),
                Primary_Contact__c = (String)con2.id)
        };
        Test.stopTest();
        
        System.assertEquals(2, [SELECT count() FROM Opportunity]);
        System.assertEquals(2, [SELECT count() FROM OpportunityContactRole]);
    }  
    
    @isTest
    private static void updateOppHHAccountRefreshNone() {
        updateOppHHAccount('none');
    }
    @isTest
    private static void updateOppHHAccountRefreshOpen() {
        updateOppHHAccount('Open Opportunities');
    }
    @isTest
    private static void updateOppHHAccountRefreshOpenAndClosed() {
        updateOppHHAccount('Open and Closed Opportunities');
    }
    /*********************************************************************************************************
    @description
    operation:
        move a contact with Opportunities to a different Household Account
    verify:
        both open and closed opps where the contact is primary, are moved to the new HH Account
        soft credit OCR's from the old Household are deleted
        soft credit OCR's for the new Household are created
    * @param strProcessor Which account model processor to test under.
    * @return void
    **********************************************************************************************************/            
    private static void updateOppHHAccount(String strRefresh) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_DONOR_ROLE));
        
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE));
        HH_OppContactRoles_TDTM.strRefreshSetting = strRefresh;
                
        List<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        System.assertEquals(null, listCon[0].AccountId); 
        List<Account> listAcc = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(3, CAO_Constants.HH_ACCOUNT_TYPE);
        insert listAcc;
        system.assertNotEquals(null, listAcc[0].Id);
        
        // specify the account for each contact, some sharing HH account.
        listCon[0].AccountId = listAcc[0].Id;
        listCon[1].AccountId = listAcc[0].Id;
        listCon[2].AccountId = listAcc[1].Id;
        listCon[3].AccountId = listAcc[1].Id;
        listCon[4].AccountId = listAcc[2].Id;
        insert listCon;
        
        List<Opportunity> listOppClosed = UTIL_UnitTestData_TEST.OppsForContactList(listCon, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
            System.today(), 100, null, null);
        insert listOppClosed;
                    
        List<Opportunity> listOppOpen = UTIL_UnitTestData_TEST.OppsForContactList(listCon, null, UTIL_UnitTestData_TEST.getOpenStage(),
            System.today(), 10, null, null);
        insert listOppOpen;
        
        //check for contact roles
        List<OpportunityContactRole> listOCR = [SELECT OpportunityId, Role, ContactId, IsPrimary FROM OpportunityContactRole];
        System.assertEquals(18, listOCR.size());

        List<Contact> acctSrcContacts = new List<Contact>{ listCon[0], listCon[1] };
        List<OpportunityContactRole> acctSrcOCRs = getOppContactRoles(acctSrcContacts);
        System.assertEquals(8, acctSrcOCRs.size());

        List<Contact> acctDestContacts = new List<Contact>{ listCon[2], listCon[3] };
        List<OpportunityContactRole> acctDestOCRs = getOppContactRoles(acctDestContacts);
        System.assertEquals(8, acctDestOCRs.size());

        // now let's move a contact to a different household
        listCon[0].AccountId = listAcc[1].Id;
        Test.startTest();
        update listCon[0];
        Test.stopTest();
        
        List<OpportunityContactRole> acctSrcOCRsUpdated = getOppContactRoles(new List<Contact>{ listCon[0] });
        System.assertEquals(4, acctSrcOCRsUpdated.size());

        System.assertEquals(listAcc[1].Id, listCon[0].AccountId);
        
        List<Contact> acctDestContactsUpdated = new List<Contact>{ listCon[0], listCon[2], listCon[3] };
        List<OpportunityContactRole> acctDestOCRsUpdated = getOppContactRoles(acctDestContactsUpdated);

        if (strRefresh.equalsIgnoreCase('none')) {
            System.assertEquals(12, acctDestOCRsUpdated.size());
        } else if (strRefresh.equalsIgnoreCase('Open Opportunities')) {
            System.assertEquals(14, acctDestOCRsUpdated.size());
        } else if (strRefresh.equalsIgnoreCase('Open and Closed Opportunities')) {
            System.assertEquals(16, acctDestOCRsUpdated.size());
        }
    }

    /*********************************************************************************************************
    * @description Tests that an Opportunity Contact Role is created when the deceased member is set as the primary
    * @return void
    */
    @isTest
    private static void opportunityDeceasedPrimaryAccount() {   
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_DONOR_ROLE));
        
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE));

        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.HH_ACCOUNT_TYPE, 1, 1, 1);
        Account acct = UTIL_UnitTestData_TEST.listAccT[0];
        Contact con = UTIL_UnitTestData_TEST.listConT[0];        
        con.Deceased__c = true;  
        update con;
                
        Opportunity o = buildOpportunity(acct.Id);
        o.Primary_Contact__c = con.Id;
        
        Test.startTest();
        insert o;
        Test.stopTest();

        List<OpportunityContactRole> createdRoles = getOppContactRoles(o.id);
        System.assertEquals(1, createdRoles.size(), 'The deceased contact should be added as the primary Contact Role for the Opportunity.');
        System.assertEquals(contactSettingsForTests.npe01__Opportunity_Contact_Role_Default_role__c, createdRoles[0].Role, 'The Role should match the default contact role.');
        System.assert(createdRoles[0].IsPrimary, 'The Contact Role should be flagged as primary.');
    }

    /*******************************************************************************************************
    * @description Move an Opportunity to a different HH Account and verifies primary OCR remains
    */ 
    @isTest
    private static void testOppsAcctChangeHHToHH() {
        testOppsAcctChange(CAO_Constants.HH_ACCOUNT_TYPE, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*******************************************************************************************************
    * @description Move an Opportunity to a different One2One Account and verifies primary OCR remains
    */ 
    @isTest
    private static void testOppsAcctChangeOne2OneToOne2One() {
        testOppsAcctChange(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Move an Opportunity from Org to HH Account and verifies primary OCR remains
    */ 
    @isTest
    private static void testOppsAcctChangeOrgToHH() {
        testOppsAcctChange(null, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*******************************************************************************************************
    * @description Move an Opportunity from HH to Org Account and verifies primary OCR remains
    */ 
    @isTest
    private static void testOppsAcctChangeHHToOrg() {
        testOppsAcctChange(CAO_Constants.HH_ACCOUNT_TYPE, null);
    }

    /*******************************************************************************************************
    * @description Move an Opportunity from Org to One2One Account and verifies primary OCR remains
    */ 
    @isTest
    private static void testOppsAcctChangeOrgToOne2One() {
        testOppsAcctChange(null, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Move an Opportunity frome One2One to Org Account and verifies primary OCR remains
    */ 
    @isTest
    private static void testOppsAcctChangeOne2OneToOrg() {
        testOppsAcctChange(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, null);
    }
    
    /*******************************************************************************************************
    * @description Move an Opportunity to a different Account type and verifies primary OCR remains
    */
    static void testOppsAcctChange(String accTypeSrc, String accTypeDst) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c(
                npe01__Opportunity_Contact_Role_Default_role__c = OCR_DONOR_ROLE));
        
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Contact_Roles_On__c = true,
                npo02__Household_Member_Contact_Role__c = HH_MEMBER_CONTACT_ROLE));

        // create our source account and contacts
        UTIL_UnitTestData_TEST.createAccountContactTestData(accTypeSrc, 1, 2, 1);
        Account accSrc = UTIL_UnitTestData_TEST.listAccT[0];
        List<Contact> listConSrc = UTIL_UnitTestData_TEST.listConT;        
        
        // create our destination account and contacts
        UTIL_UnitTestData_TEST.createAccountContactTestData(accTypeDst, 1, 2, 3);
        Account accDst = UTIL_UnitTestData_TEST.listAccT[0];
        List<Contact> listConDst = UTIL_UnitTestData_TEST.listConT;        
        
        // create an opp for each contact
        List<Contact> listConAll = new List<Contact>();
        listConAll.addAll(listConSrc);
        listConAll.addAll(listConDst);
        List<Opportunity> listOpp = UTIL_UnitTestData_TEST.OppsForContactList(listConAll, null, 
            UTIL_UnitTestData_TEST.getclosedWonStage(), System.today(), 100, null, null);
        insert listOpp;

        // move the first opportunity in the first account to the other account.
        Opportunity opp = listOpp[0];

        List<OpportunityContactRole> createdRoles = getPrimaryOppContactRoles(opp.id);

        opp.AccountId = accDst.Id;
        Test.startTest();
        update opp;
        Test.stopTest();

        List<OpportunityContactRole> updatedRoles = getPrimaryOppContactRoles(opp.id);

        // verify the primary ocr has not changed.
        System.assertEquals(createdRoles[0].ContactId, updatedRoles[0].ContactId);
    }

    // Helpers
    //////////

    /*******************************************************************************************************
    * @description Builds an Opportunity SObject
    * @param accountId Opportunity Account Id
    * @return Opportunity
    */
    private static Opportunity buildOpportunity(Id accountId) {
        return new Opportunity(
            Name = 'test oppty',
            CloseDate = Date.newInstance(2001, 12, 12),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            Amount = 100,
            AccountId = accountId
        );
    }

    /*******************************************************************************************************
    * @description Returns primary Opportunity Contact Role for the Opportunity
    * @param oppId Opportunity Id
    * @return List<OpportunityContactRole>
    */
    private static List<OpportunityContactRole> getPrimaryOppContactRoles(Id oppId) {
        return [
            SELECT Role, ContactId, IsPrimary 
            FROM OpportunityContactRole
            WHERE OpportunityId = :oppId AND IsPrimary = true 
            ORDER BY ContactId
        ];
    }

    /*******************************************************************************************************
    * @description Returns all Opportunity Contact Role for the Opportunity
    * @param oppId Opportunity Id
    * @return List<OpportunityContactRole>
    */
    private static List<OpportunityContactRole> getOppContactRoles(Id oppId) {
        return [
            SELECT Role, ContactId, IsPrimary 
            FROM OpportunityContactRole 
            WHERE OpportunityId = :oppId 
            ORDER BY ContactId
        ];
    }

    /*******************************************************************************************************
    * @description Returns Opportunity Contact Role for specified Contacts
    * @param contacts List of Contacts
    * @return List<OpportunityContactRole>
    */
    private static List<OpportunityContactRole> getOppContactRoles(List<Contact> contacts) {
        return [
            SELECT OpportunityId, Role, ContactId, IsPrimary 
            FROM OpportunityContactRole 
            WHERE ContactId IN :contacts
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
}