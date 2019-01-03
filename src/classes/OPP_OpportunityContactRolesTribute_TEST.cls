/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Opportunity
* @description Tests for OpportunityContactRoles as pertains to Multiple Tributes functionality
*/
@isTest
public class OPP_OpportunityContactRolesTribute_TEST {

    /*******************************************************************************************************
    * @description Initializes NPSP Contact and Org Settings for OCR Tribute Tests, allowing calling method
    * to specify Multiple Tributes Type supported
    * @param tributeType Type of Tributes supported
    *******************************************************************************************************/
    @isTest
    public static npe01__Contacts_and_Orgs_Settings__c createContactAndOrgSettingsForOCRTributeTests(String tributeType) {
        return UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(
                        npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                        npe01__Opportunity_Contact_Role_Default_role__c = OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_DONOR,
                        Honoree_Opportunity_Contact_Role__c = OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_HONOREE,
                        Notification_Recipient_Opp_Contact_Role__c = OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT,
                        Multiple_Tributes__c = tributeType
                )
        );
    }

    /******************************************************************************************************
    * @description Test Create Opporunity with SingleTribute Only mode
    */
    @isTest
    static void createOppWithTributeSingle() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_SINGLE_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Create and Insert Opportunity
        Account orgAcct = new Account(
            Name = 'MultipleTributeAccount1',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        Opportunity oppToInsert = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation1',
            Amount = 1000,
            CloseDate = Date.today(),
            Honoree_Name__c = 'John Smith',
            Notification_Recipient_Name__c = 'Mark Smith'
        );

        Test.startTest();
        insert oppToInsert;
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Tribute__c], 'No Tributes Expected');

        //verify that the Tribute field is still on opp
        List<Opportunity> opp = [SELECT Id FROM Opportunity WHERE Honoree_Name__c = 'John Smith' AND Notification_Recipient_Name__c = 'Mark Smith' AND Id =: oppToInsert.Id];
        System.assertEquals(1, opp.size(), 'One opportunity expected');
    }

    /******************************************************************************************************
    * @description Test Create/Update Opportunity/Tribute with Mix mode (Allow both Tribute object
    * and Tribute Field)
    ********************************************************************************************************/
    @isTest
    static void createOppWithTributeMultipleLoose() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Create and Insert Opportunity
        Account orgAcct = new Account(
            Name = 'MultipleTributeAccount2',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        List<Opportunity> oppsToInsert = new List<Opportunity>();

        Opportunity opp1 = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Honoree_Name__c = 'John Smith',
            Notification_Recipient_Name__c = 'Mark Smith'
        );
        oppsToInsert.add(opp1);

        Opportunity opp2 = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation3',
            Amount = 1000,
            CloseDate = Date.today()
        );
        oppsToInsert.add(opp2);

        Test.startTest();

        insert oppsToInsert;

        System.assertEquals(0, [SELECT Count() FROM Tribute__c], 'No Tributes Expected');

        //Now insert a Tribute for opp2, should not have any issue
        Tribute__c tri = new Tribute__c(
            Opportunity__c = opp2.Id,
            Honoree_Name__c = 'John Smith'
        );
        insert tri;

        //System should allow update of Tribute info on Opp1
        opp1.Honoree_Name__c = 'Mike Brown';
        update opp1;

        opp1 = [SELECT  Id, Honoree_Name__c FROM Opportunity WHERE Id =: opp1.Id];
        System.assertEquals('Mike Brown', opp1.Honoree_Name__c);

        //system should prevent update of Tribute information on Opp2 since Opp2 has a separate related Tribute record on it
        //and this is not allowed
        try {
            opp2.Honoree_Name__c = 'Mike Brown';
            update opp2; //System should throw an exception here
            System.assert(false, 'Failed to assert exception when attempted update on Opportunity in Multiple Tribute only mode.');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.errMultipleTributesEnforceMultiple));
        }

        Test.stopTest();
    }

    /******************************************************************************************************
    * @description Test Create/Update Opportunity with Multiple Tribute only mode
    ********************************************************************************************************/
    @isTest
    static void createOppWithTributeMultipleStrict() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Create and Insert Opportunity
        Account orgAcct = new Account(
            Name = 'MultipleTributeAccount3',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        Opportunity opp = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Honoree_Name__c = 'John Smith',
            Notification_Recipient_Name__c = 'Mark Smith'
        );

        Test.startTest();
        insert opp;

        //verify that the there is one tribute in the org, and Tribute fields get cleared
        List<Tribute__c> tributes = [SELECT Id, Opportunity__c, Honoree_Name__c, Opportunity__r.Honoree_Name__c, Opportunity__r.Notification_Recipient_Name__c FROM Tribute__c];
        System.assertEquals(1, tributes.size());
        System.assertEquals(opp.Id, tributes[0].Opportunity__c);
        System.assertEquals('John Smith', tributes[0].Honoree_Name__c);
        System.assertEquals(null, tributes[0].Opportunity__r.Honoree_Name__c);

        //verify that system will not Allow update Tribute on Opp
        try {
            opp.Honoree_Name__c = 'Mike Brown';
            update opp; //System should throw an exception here
            System.assert(false);
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.errMultipleTributesEnforceMultiple));
        }

        Test.stopTest();
    }

    /******************************************************************************************************
    * @description Test clear OCR and Sync OCR for Multiple Tributes
    ********************************************************************************************************/
    @isTest
    static void updatePrimaryContactOfOpportunity(){

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Insert Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        insert cons;

        Opportunity opp = new Opportunity(
            Name = 'Test Update Primary Contact of Opportunity',
            Primary_Contact__c = cons[0].Id,
            Honoree_Contact__c = cons[1].Id,
            Notification_Recipient_Contact__c = cons[2].Id,
            CloseDate = Date.today(),
            StageName = closedWonStageName
        );
        insert opp;

        List<OpportunityContactRole> ocrs = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        delete ocrs;

        OpportunityContactRole garbageOCR = new OpportunityContactRole();
        garbageOCR.OpportunityId = opp.Id;
        garbageOCR.ContactId = cons[3].Id;
        garbageOCR.Role = OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_HONOREE;
        garbageOCR.isPrimary = false;

        insert garbageOCR;

        //When the Primary Contact changes on the Opp, system should create the missing donor OCR.
        // It will not remove the garbageOCR because we do not know if an end user added this OCR.
        opp = [SELECT Primary_Contact__c FROM Opportunity WHERE Id =: opp.Id];
        opp.Primary_Contact__c = cons[4].Id;
        Test.startTest();
        update opp;
        Test.stopTest();

        ocrs = [SELECT Id, ContactId, Contact.Name, OpportunityId, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityId =:opp.Id ORDER BY Contact.Name];

        System.assertEquals(4, ocrs.size());

        System.assertEquals(cons[1].Id, ocrs[0].ContactId);
        System.assertEquals(false, ocrs[0].IsPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_HONOREE, ocrs[0].Role);

        System.assertEquals(cons[2].Id, ocrs[1].ContactId);
        System.assertEquals(false, ocrs[1].isPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT, ocrs[1].Role);

        System.assertEquals(cons[3].Id, ocrs[2].ContactId);
        System.assertEquals(false, ocrs[2].isPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_HONOREE, ocrs[2].Role);

        System.assertEquals(cons[4].Id, ocrs[3].ContactId);
        System.assertEquals(true, ocrs[3].isPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_DONOR, ocrs[3].Role);
    }

    /******************************************************************************************************
    * @description Test Method to take a List of Opportunities and return a Map of Lists of Associated Tributes
    * keyed by Opportunity Id
    ********************************************************************************************************/
    @isTest
    static void populateTributesByOpportunityIdMethod() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Create and Insert Opportunity
        Account orgAcct = new Account(
            Name = 'MultipleTributeAccount3',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        //Insert Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        insert cons;


        Opportunity opp = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Honoree_Contact__c = cons[0].Id,
            Notification_Recipient_Name__c = 'Mark Smith'
        );

        Test.startTest();
        insert opp;

        //Now insert a Tribute for opp2, should not have any issue
        Tribute__c tri = new Tribute__c(
            Opportunity__c = opp.Id,
            Honoree_Contact__c = cons[1].Id
        );
        insert tri;

        // Retrieve Tributes
        List<Tribute__c> tributes = [SELECT Id, Opportunity__c, Honoree_Contact__c FROM Tribute__c];

        Map<Id, List<Tribute__c>> oppsToTributes = OPP_OpportunityContactRoles_TDTM.populateTributesByOpportunityId(new List<Opportunity> { opp });
        System.assertEquals (1, oppsToTributes.size());
        System.assertEquals (true, oppsToTributes.containsKey(opp.Id));
        System.assertEquals (2, oppsToTributes.get(opp.Id).size());
    }

    /******************************************************************************************************
    * @description Test Method to take Map of List of Tributes keyed by Opportunity Id and convert to a
    * Map of Tributes by Tribute Id
    ********************************************************************************************************/
    @isTest
    static void convertListOfTributesByOppIdToMapByTributeIdMethod() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Create and Insert Opportunity
        Account orgAcct = new Account(
            Name = 'MultipleTributeAccount3',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        //Insert Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        insert cons;


        Opportunity opp = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Honoree_Contact__c = cons[0].Id,
            Notification_Recipient_Name__c = 'Mark Smith'
        );

        Test.startTest();
        insert opp;

        //Now insert a Tribute for opp2, should not have any issue
        Tribute__c tri = new Tribute__c(
            Opportunity__c = opp.Id,
            Honoree_Contact__c = cons[1].Id
        );
        insert tri;

        // Retrieve Tributes
        List<Tribute__c> tributes = [SELECT Id, Opportunity__c, Honoree_Contact__c FROM Tribute__c];

        Map<Id, List<Tribute__c>> oppsToTributes = OPP_OpportunityContactRoles_TDTM.populateTributesByOpportunityId(new List<Opportunity> { opp });

        Map<Id, Tribute__c> tribs = OPP_OpportunityContactRoles_TDTM.convertListOfTributesByOppIdToMapByTributeId(oppsToTributes);

        for (Tribute__c trib : tributes) {
            System.assertEquals (true, tribs.containsKey(trib.Id));
            System.assertEquals (true, tribs.get(trib.id).Id == trib.Id);
        }
    }

    /******************************************************************************************************
    * @description Test Method for needs ManageOCR Method
    ********************************************************************************************************/
    @isTest
    static void needsManageOCRMethod() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Create and Insert Opportunity
        Account orgAcct = new Account(
            Name = 'MultipleTributeAccount3',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        //Insert three Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(4);
        insert cons;

        Opportunity opp = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Honoree_Contact__c = cons[0].Id,
            Notification_Recipient_Contact__c = cons[1].Id,
            Primary_Contact__c = cons[2].Id
        );

        Opportunity oldOpp = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Honoree_Contact__c = cons[0].Id,
            Notification_Recipient_Contact__c = cons[1].Id,
            Primary_Contact__c = cons[2].Id
        );

        Set<Id> honoreeIdSet = new Set<Id>();

        Test.startTest();

        System.assertEquals (false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(null, null, honoreeIdSet, false, 'NO_FIELD', null), 'getRole will return a Null, which will cause it to decide this field/test is not in use, same as if role value was not set');

        System.assertEquals (false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, null, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT, cons[0].Id), 'Honoree Superceded by Primary Contact, no old record');

        System.assertEquals (true, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, null, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT, cons[1].Id), 'Honoree Not Superceded by Primary Contact, no old record');

        System.assertEquals (false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, null, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, cons[1].Id), 'Notification Recipient Superceded by Primary Contact, no old record, no honorees present');

        System.assertEquals (true, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, null, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, cons[3].Id), 'Notification Recipient Not Superceded by Primary Contact or Honoree Id Set, no old record, no honorees present');

        honoreeIdSet.add(cons[2].Id);

        System.assertEquals (true, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, null, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, cons[3].Id), 'Notification Recipient Not Superceded by Primary Contact or Honoree Id Set, 1 Honoree Present');
        honoreeIdSet.add(cons[1].Id);

        System.assertEquals (false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, null, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, cons[3].Id), 'Notification Recipient Superceded by Honoree Id Set, 2 Honoree Present');

        honoreeIdSet.clear();

        System.assertEquals (false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, oldOpp, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT, null), 'Honoree has not changed, and not ignoring field changes, no Primary Contact present');

        oldOpp.Honoree_Contact__c = cons[1].Id;

        System.assertEquals (true, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, oldOpp, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT, null), 'Honoree has changed, and not ignoring field changes, no Primary Contact present');
        // Setting Honoree Contact to null on both old and new records
        opp.Honoree_Contact__c = null;
        oldOpp.Honoree_Contact__c = null;

        System.assertEquals(false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, oldOpp, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT, null), 'Honoree is null and has not changed, and not ignoring field changes, no Primary Contact present');

        // Setting Honoree Contact to same on both old and new records
        opp.Honoree_Contact__c = cons[1].Id;
        oldOpp.Honoree_Contact__c = cons[1].Id;

        System.assertEquals(true, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, oldOpp, honoreeIdSet, true, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT, null), 'Honoree is not null and has not changed and is ignoring field changes, no Primary Contact present');

        opp.Honoree_Contact__c = cons[2].Id;
        System.assertEquals (false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, oldOpp, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT, cons[2].Id), 'Honoree same as Primary Contact so update should not be needed');

        opp.Notification_Recipient_Contact__c = cons[2].Id;
        System.assertEquals(false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, oldOpp, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, cons[2].Id), 'Notification Recipient Contact same as Primary Contact so update should not be needed');

        // Setting Notification Recipient Contact to value in honoreeIdSet
        opp.Notification_Recipient_Contact__c = cons[1].Id;
        oldOpp.Notification_Recipient_Contact__c = cons[2].Id;
        honoreeIdSet.add(cons[1].Id);

        System.assertEquals(false, OPP_OpportunityContactRoles_TDTM.needsManageOCR(opp, oldOpp, honoreeIdSet, false, OPP_OpportunityContactRoles_TDTM.FIELD_NAME_NOTIFICATION_RECIPIENT_CONTACT, cons[2].Id), 'Notification Recipient is not null and has changed and matches one of the honorees');
    }

    /******************************************************************************************************
    * @description Test Method for Is Equivalent OCR Method
    ********************************************************************************************************/
    @isTest
    static void isEquivalentOCRMethod() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Create and Insert Opportunity
        Account orgAcct = new Account(
            Name = 'MultipleTributeAccount3',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        //Insert four Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(4);
        insert cons;

        Opportunity opp = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Honoree_Contact__c = cons[0].Id,
            Notification_Recipient_Contact__c = cons[1].Id,
            Primary_Contact__c = cons[2].Id
        );

        insert opp;

        Test.startTest();

        // Null values are not considered equivalent
        System.assertEquals (false, OPP_OpportunityContactRoles_TDTM.isEquivalentOCR(null, null));

        OpportunityContactRole ocr1 = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = cons[0].Id,
            Role = OPP_OpportunityContactRoles_TDTM.getRole(OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT)
        );

        OpportunityContactRole ocr2 = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = cons[0].Id,
            Role = OPP_OpportunityContactRoles_TDTM.getRole(OPP_OpportunityContactRoles_TDTM.FIELD_NAME_HONOREE_CONTACT)
        );

        // OCR1 and OCR2 have the same OpportunityId, ContactId and Role, and thus are considered equivalent
        System.assertEquals (true, OPP_OpportunityContactRoles_TDTM.isEquivalentOCR(ocr1, ocr2));
    }

    /******************************************************************************************************
    * @description Test Method for Determine Opps Requiring Reevaluation Method
    ********************************************************************************************************/
    @isTest
    static void determineOppsRequiringOCREvaluationMethod() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        npe01__Contacts_and_Orgs_Settings__c testSettings = createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL);

        String closedWonStageName = UTIL_UnitTestData_TEST.getClosedWonStage();

        //Create and Insert Opportunity
        Account orgAcct = new Account(
            Name = 'MultipleTributeAccount2',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert orgAcct;

        //Insert six Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(6);
        insert cons;

        List<Opportunity> oppsToInsert = new List<Opportunity>();

        Opportunity opp1 = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Primary_Contact__c = cons[0].Id,
            Honoree_Contact__c = cons[1].Id,
            Notification_Recipient_Contact__c = cons[2].Id
        );
        oppsToInsert.add(opp1);

        Opportunity opp2 = new Opportunity(
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation3',
            Amount = 1000,
            CloseDate = Date.today()
        );
        oppsToInsert.add(opp2);

        Test.startTest();

        insert oppsToInsert;

        //Now insert a Tribute for opp2, should not have any issue
        Tribute__c tri = new Tribute__c(
            Opportunity__c = opp2.Id,
            Honoree_Contact__c = cons[4].Id
        );
        insert tri;

        List<Opportunity> opps = [SELECT Id, Primary_Contact__c, Honoree_Contact__c, Notification_Recipient_Contact__c, AccountId FROM Opportunity];

        Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>();

        Map<Id, List<Tribute__c>> tributesByOpp = new Map<Id, List<Tribute__c>>();

        tributesByOpp.put(tri.Opportunity__c, new List<Tribute__c> { tri});
        Map<Id, List<Tribute__c>> oldTributesByOpp = new Map<Id, List<Tribute__c>>();

        // Test 1, Inserted two Opps (simulated by having no old Opps records)
        List<Opportunity> changedOpps = OPP_OpportunityContactRoles_TDTM.determineOppsRequiringOCREvaluation(opps, oldOpps, tributesByOpp, oldTributesByOpp);

        System.assertEquals(2, changedOpps.size());

        // Test 2, Updated no Opps, 1 flagged because simulated insertion of Tribute
        for (Opportunity opp : opps) {
            oldOpps.put (opp.Id, opp);
        }

        changedOpps = OPP_OpportunityContactRoles_TDTM.determineOppsRequiringOCREvaluation(opps, oldOpps, tributesByOpp, oldTributesByOpp);

        System.assertEquals(1, changedOpps.size());
        System.assertEquals(opp2.Id, changedOpps.get(0).Id);

        Opportunity oldOpp = new Opportunity(
            Id = opp1.Id,
            AccountId = orgAcct.Id,
            StageName = closedWonStageName,
            Name = 'Donation2',
            Amount = 1000,
            CloseDate = Date.today(),
            Primary_Contact__c = cons[0].Id,
            Honoree_Contact__c = cons[1].Id,
            Notification_Recipient_Contact__c = cons[4].Id
        );

        oldOpps.put(oldOpp.Id, oldOpp);
        oldTributesByOpp.put(tri.Opportunity__c, new List<Tribute__c> { tri });

        // Simulating an updated Opportunity this time
        changedOpps = OPP_OpportunityContactRoles_TDTM.determineOppsRequiringOCREvaluation(opps, oldOpps, tributesByOpp, oldTributesByOpp);

        System.assertEquals(1, changedOpps.size());
        System.assertEquals(opp1.Id, changedOpps.get(0).Id);

        Tribute__c oldTri = new Tribute__c(
            Id = tri.Id,
            Honoree_Contact__c = cons[5].Id
        );

        // Reset old opportunity back to no changes
        oldOpps.put(opp1.Id, opp1);

        // Setup "Old Tribute" for test
        oldTributesByOpp.put(tri.Opportunity__c, new List<Tribute__c> { oldTri });
        // Simulating an updated Tribute this time

        changedOpps = OPP_OpportunityContactRoles_TDTM.determineOppsRequiringOCREvaluation(opps, oldOpps, tributesByOpp, oldTributesByOpp);

        System.assertEquals(1, changedOpps.size());
        System.assertEquals(opp2.Id, changedOpps.get(0).Id);
    }
}