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
* @group Tribute
* @group-content ../../ApexDocContent/Tributes.htm
* @description The Test for TBU_OpportunityContactRole_TDTM
*/
@isTest
private class TBU_OpportunityContactRoles_TEST {

    /******************************************************************************************************
    * @description Test update Honoree/Notification Name when the look up changes
    ********************************************************************************************************/
    @isTest
    static void populateHonoreeNotificationNameField() {
        OPP_OpportunityContactRolesTribute_TEST.createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL);

        //Insert three Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert cons;

        Opportunity opp = new Opportunity(
                Primary_Contact__c = cons[0].Id,
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                Name = 'Donation3',
                Amount = 1000,
                CloseDate = Date.today()
                );

        insert opp;

        //insert Tribute Record
        Tribute__c newTri = new Tribute__c(
                Opportunity__c = opp.Id,
                Honoree_Contact__c = cons[1].Id
        );

        Test.startTest();
        insert newTri;


        cons = [SELECT Id, Name FROM Contact WHERE Id IN :cons];

        newTri = [SELECT Id, Honoree_Name__c FROM Tribute__c WHERE Id = :newTri.Id];
        System.assertEquals(cons[1].Name, newTri.Honoree_Name__c);

        //Now update the Tribute Honoree Contact and Notification Contact, system should update the corresponding Name field
        newTri.Honoree_Contact__c = cons[2].Id;
        update newTri;

        newTri = [SELECT Id, Honoree_Name__c FROM Tribute__c WHERE Id = :newTri.Id];
        System.assertEquals(cons[2].Name, newTri.Honoree_Name__c);

        Test.stopTest();
    }

    /******************************************************************************************************
    * @description Prevent user insert Tribute record if the current setting is Single Tribute only
    ********************************************************************************************************/
    @isTest static void preventHonoreeNotificationInsertSingleTribute() {
        OPP_OpportunityContactRolesTribute_TEST.createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_Single_VAL);

        //Insert three Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert cons;

        Opportunity opp = new Opportunity(
                Primary_Contact__c = cons[0].Id,
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                Name = 'Donation3',
                Amount = 1000,
                CloseDate = Date.today());

        insert opp;

        //insert Tribute Record
        Tribute__c newTri = new Tribute__c(
                Opportunity__c = opp.Id,
                Honoree_Contact__c = cons[1].Id
        );

        Test.startTest();
        try {
            insert newTri;
            System.assert(false); //System should throw exception
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.errMultipleTributesEnforceSingle) == true);
        }
        Test.stopTest();
    }

    /******************************************************************************************************
    * @description Prevent user insert Tribute record if the current setting is Mix mode
    ********************************************************************************************************/
    @isTest
    static void preventHonoreeNotificationInsertMultipleTributeLose() {
        OPP_OpportunityContactRolesTribute_TEST.createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL);

        //Insert three Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert cons;

        Opportunity opp = new Opportunity(
                Primary_Contact__c = cons[0].Id,
                Honoree_Contact__c = cons[1].Id,
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                Name = 'Donation3',
                Amount = 1000,
                CloseDate = Date.today());

        insert opp;

        //insert Tribute Record
        Tribute__c newTri = new Tribute__c(
                Opportunity__c = opp.Id,
                Honoree_Contact__c = cons[1].Id
        );

        Test.startTest();
        try {
            insert newTri;
            System.assert(false); //System should throw exception
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.errMultipleTributesFlexibleUpdate) == true);
        }
        Test.stopTest();
    }

    /******************************************************************************************************
    * @description Test creating OCR based on the Honoree/Notification when insert Tribute
    ********************************************************************************************************/
    @isTest
    static void honoreeNotificationInsert() {
        OPP_OpportunityContactRolesTribute_TEST.createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL);

        //Insert three Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert cons;

        Opportunity opp = new Opportunity(
                Name = 'Test',
                Primary_Contact__c = cons[0].Id,
                Notification_Recipient_Contact__c = cons[2].Id,
                CloseDate = Date.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        insert opp;

        Tribute__c newTribute = new Tribute__c(
                Opportunity__c = opp.Id,
                Honoree_Contact__c = cons[1].Id
        );

        Test.startTest();
        insert newTribute;
        Test.stopTest();

        //System should create a Tribute Record and Populate the Honoree/Notification Name
        List<Contact> queryCon = [SELECT Id, Name FROM Contact WHERE Id IN :cons];
        List<Tribute__c> queryTribute = [SELECT Id, Honoree_Name__c FROM Tribute__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(queryCon[1].Name, queryTribute[0].Honoree_Name__c);

        //System should create 3 OCR with different Role
        List<OpportunityContactRole> queryOCR = [SELECT         Id,
                                                                ContactId,
                                                                OpportunityId,
                                                                IsPrimary,
                                                                Role
                                                 FROM OpportunityContactRole
                                                 WHERE          OpportunityId =:opp.Id
                                                 ORDER BY       ContactId];
        System.assertEquals(3, queryOCR.size());

        System.assertEquals(cons[0].Id, queryOCR[0].ContactId);
        System.assertEquals(true, queryOCR[0].IsPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_DONOR, queryOCR[0].Role);

        System.assertEquals(cons[1].Id, queryOCR[1].ContactId);
        System.assertEquals(false, queryOCR[1].IsPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_HONOREE, queryOCR[1].Role);

        System.assertEquals(cons[2].Id, queryOCR[2].ContactId);
        System.assertEquals(false, queryOCR[2].IsPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_NOTIFICATION_RECIPIENT, queryOCR[2].Role);
    }

    /******************************************************************************************************
    * @description Test upserting OCR based on the Honoree/Notification when insert/update Tribute
    ********************************************************************************************************/
    @isTest
    static void honoreeNotificationUpdate() {
        OPP_OpportunityContactRolesTribute_TEST.createContactAndOrgSettingsForOCRTributeTests(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL);

        //Insert three Contacts
        List<Contact> cons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
        insert cons;

        Opportunity opp = new Opportunity(
                Name = 'Test',
                Primary_Contact__c = cons[0].Id,
                Honoree_Contact__c = cons[2].Id,
                CloseDate = Date.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );

        insert opp;

        //System should populate Honoree Name on Tribute
        List<Contact> queryCon = [SELECT Id, Name FROM Contact WHERE Id IN :cons];
        List<Tribute__c> queryTribute = [SELECT Id, Honoree_Name__c FROM Tribute__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(queryCon[2].Name, queryTribute[0].Honoree_Name__c);

        //System should create 2 OCR
        List<OpportunityContactRole> queryOCR = [SELECT         Id,
                                                                ContactId,
                                                                OpportunityId,
                                                                IsPrimary,
                                                                Role
                                                 FROM OpportunityContactRole
                                                 WHERE          OpportunityId =:opp.Id
                                                 ORDER BY       ContactId];
        System.assertEquals(2, queryOCR.size());

        System.assertEquals(cons[0].Id, queryOCR[0].ContactId);
        System.assertEquals(true, queryOCR[0].IsPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_DONOR, queryOCR[0].Role);

        System.assertEquals(cons[2].Id, queryOCR[1].ContactId);
        System.assertEquals(false, queryOCR[1].IsPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_HONOREE, queryOCR[1].Role);

        //Now Try to update the Honoree/Notification on tribute
        queryTribute[0].Honoree_Contact__c = cons[1].Id;

        Test.startTest();
        update queryTribute;
        Test.stopTest();

        //System should update the Honoree/Notification Name based on the changes
        queryTribute = [SELECT Id, Honoree_Name__c FROM Tribute__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(queryCon[1].Name, queryTribute[0].Honoree_Name__c);

        //System should update the OCR based on the changes. Since Notification Recipient is the same as Primary, it will not create additional OCR
        queryOCR = [SELECT      Id,
                                ContactId,
                                Contact.Name,
                                OpportunityId,
                                IsPrimary,
                                Role
                    FROM OpportunityContactRole
                    WHERE       OpportunityId =:opp.Id
                    ORDER BY    ContactId];
        System.assertEquals(2, queryOCR.size());

        System.assertEquals(cons[0].Id, queryOCR[0].ContactId);
        System.assertEquals(true, queryOCR[0].IsPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_DONOR, queryOCR[0].Role);

        System.assertEquals(cons[1].Id, queryOCR[1].ContactId);
        System.assertEquals(false, queryOCR[1].IsPrimary);
        System.assertEquals(OPP_OpportunityContactRoles_TEST.OPPORTUNITY_CONTACT_ROLE_HONOREE, queryOCR[1].Role);

        queryTribute[0].Honoree_Contact__c = null;
        update queryTribute;

        queryTribute = [SELECT Id, Honoree_Name__c FROM Tribute__c WHERE Opportunity__c = :opp.Id];
        System.assert(String.isBlank(queryTribute[0].Honoree_Name__c));
    }

    /******************************************************************************************************
    * @description Test Filterable Fieldnames method
    ********************************************************************************************************/
    @isTest
    static void getFilterableFieldNamesMethod() {

        Set<String> oppFieldNames = TBU_OpportunityContactRoles_TDTM.getFilterableFieldNames('Opportunity');
        System.assertNotEquals(0, oppFieldNames.size(), 'Should be some fields present');
        System.assert(oppFieldNames.contains('id'), 'Id should be present');
        System.assert(oppFieldNames.contains('stagename'), 'StageName should be present');
    }
}