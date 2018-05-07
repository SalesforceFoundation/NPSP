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
* @group Opportunity Contact Role
* @description Test Class for the deletion of the duplicate primary OCRs.
*/

@isTest
private class OPP_PrimaryContactRoleMerge_TEST {

    private final static String NPSP_ROLE = 'NPSP_ROLE';
    private final static String NON_NPSP_ROLE = 'NON_NPSP_ROLE';

    /*********************************************************************************************************
    * @description Given a Non Organizational Opportunity with duplicate primary OCRs, AND all the primary OCRs 
    * Role != NPSP Settings Role when the batch runs, then an error log is created, with a link to the Opportunity.
    */
    @isTest static void test_NonOrganizational_LogErrorIf_NoPrimaryOCRsWithRoleDefinedInNPSPSettings() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Opportunity_Contact_Role_Default_role__c = NPSP_ROLE
        ));

        Account account = new Account(
            Name = 'TEST_ACCOUNT',
            npe01__SYSTEMIsIndividual__c = true
        );

        executeTest_LogErrorIf_NoPrimaryOCRsWithRoleDefinedInNPSPSettings(account);
    }

    /*********************************************************************************************************
    * @description Given an Organizational Opportunity with duplicate primary OCRs, AND all the primary OCRs 
    * Role != NPSP Settings Role when the batch runs, then an error log is created, with a link to the Opportunity.
    */
    @isTest static void test_Organization_LogErrorIf_NoPrimaryOCRsWithRoleDefinedInNPSPSettings() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
            Contact_Role_for_Organizational_Opps__c = NPSP_ROLE
        ));

        Account account = new Account(
            Name = 'TEST_ACCOUNT',
            npe01__SYSTEMIsIndividual__c = false
        );

        executeTest_LogErrorIf_NoPrimaryOCRsWithRoleDefinedInNPSPSettings(account);
    }

    /*********************************************************************************************************
    * @description Given a Non Organizational Opportunity with duplicate primary OCRs, and the primary OCRs 
    * have Role equals to (NPSP Settings Role, blank, NOT “NPSP Settings Role”) when the Batch runs, then 
    * the primary OCRs with blank role AND role not defined in NPSP Settings should be deleted. The Opportunity 
    * should have only 1 primary OCR with role equals to the NPSP Settings Role.
    */
    @isTest static void test_NonOrganizational_DeleteBlankAndNonNPSPRole() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Opportunity_Contact_Role_Default_role__c = NPSP_ROLE
        ));

        Account account = new Account(
            Name = 'TEST_ACCOUNT',
            npe01__SYSTEMIsIndividual__c = true
        );

        executeTest_DeleteBlankAndNonNPSPRole(account);        
    }

    /*********************************************************************************************************
    * @description Given a Non Organizational Opportunity with duplicate primary OCRs, and the primary OCRs 
    * have Role equals to (NPSP Settings Role, blank, NOT “NPSP Settings Role”) when the Batch runs, then 
    * the primary OCRs with blank role AND role not defined in NPSP Settings should be deleted. The Opportunity 
    * should have only 1 primary OCR with role equals to the NPSP Settings Role.
    */
    @isTest static void test_Organizational_DeleteBlankAndNonNPSPRole() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
            Contact_Role_for_Organizational_Opps__c = NPSP_ROLE
        ));

        Account account = new Account(
            Name = 'TEST_ACCOUNT',
            npe01__SYSTEMIsIndividual__c = false
        );

        executeTest_DeleteBlankAndNonNPSPRole(account); 
    }

    /*******************************************************************************************************
    * @description Executes the Log Error test scenario.
    * @return void.
    ********************************************************************************************************/
    private static void executeTest_LogErrorIf_NoPrimaryOCRsWithRoleDefinedInNPSPSettings(Account account) {
        deactivateTriggers();
        
        insert account;

        Contact contact = new Contact(LastName = 'TEST_CONTACT');
        insert contact;

        Opportunity opportunity = new Opportunity(
            Name = 'TEST_OPPORTUNITY',
            StageName = UTIL_UnitTestData_TEST.getOpenStage(),
            CloseDate = Date.today(),
            AccountId = account.Id
        );
        insert opportunity;

        List<OpportunityContactRole> primaryOCRs = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = NON_NPSP_ROLE
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = NON_NPSP_ROLE
            )
        };
        insert primaryOCRs;

        activateTriggers();

        Opportunity createdOpportunity = loadOpportunityWithOCRs(opportunity.Id);
        System.assertEquals(2, createdOpportunity.OpportunityContactRoles.size());
        for (OpportunityContactRole expectedOCR : createdOpportunity.OpportunityContactRoles) {
            System.assert(
                expectedOCR.ContactId == contact.Id && 
                expectedOCR.Role == NON_NPSP_ROLE && 
                expectedOCR.IsPrimary
            );
        }
        
        Test.startTest();
        Database.executeBatch(new OPP_PrimaryContactRoleMerge_BATCH());
        Test.stopTest();

        Opportunity expectedOpportunity = loadOpportunityWithPrimaryOCRs(createdOpportunity.Id);
        // Opportunity and the related Opportunity Contact Roles should not change.
        System.assertEquals(2, expectedOpportunity.OpportunityContactRoles.size());
        System.assertEquals(2, createdOpportunity.OpportunityContactRoles.size());
        for (OpportunityContactRole expectedOCR : expectedOpportunity.OpportunityContactRoles) {
            System.assert(
                expectedOCR.ContactId == contact.Id && 
                expectedOCR.Role == NON_NPSP_ROLE && 
                expectedOCR.IsPrimary
            );
        }

        List<Error__c> errors = [
            SELECT Object_Type__c, Full_Message__c, Record_URL__c, Context_Type__c
            FROM Error__c
        ];
        System.assertEquals(1, errors.size(), 'An Error Log should be created');
        System.assertEquals(String.format(OPP_PrimaryContactRoleMerge.ERROR_MESSAGE, new List<String>{opportunity.Name}), errors[0].Full_Message__c);
        System.assertEquals(OPP_PrimaryContactRoleMerge.ERROR_CONTEXT, errors[0].Context_Type__c);
        System.assertEquals(OPP_PrimaryContactRoleMerge.ERROR_SOBJECT, errors[0].Object_Type__c);
        System.assertEquals(URL.getSalesforceBaseUrl().toExternalForm() + '/' + expectedOpportunity.Id, errors[0].Record_URL__c);
    }

    /*******************************************************************************************************
    * @description Executes the Remove Duplicates (delete blank and non NPSP Roles) test scenario.
    * @return void.
    ********************************************************************************************************/
    private static void executeTest_DeleteBlankAndNonNPSPRole(Account account) {
        deactivateTriggers();

        insert account;

        Contact contact = new Contact(LastName = 'TEST_CONTACT');
        insert contact;

        Opportunity opportunity = new Opportunity(
            Name = 'TEST_OPPORTUNITY',
            StageName = UTIL_UnitTestData_TEST.getOpenStage(),
            CloseDate = Date.today(),
            AccountId = account.Id,
            Primary_Contact__c = null
        );
        insert opportunity;

        List<OpportunityContactRole> primaryOCRs = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = NPSP_ROLE
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = NPSP_ROLE
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = NON_NPSP_ROLE
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = NON_NPSP_ROLE
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = ''
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = ''
            )
        };
        insert primaryOCRs;
        activateTriggers();

        Opportunity createdOpportunity = loadOpportunityWithOCRs(opportunity.Id);
        System.assertEquals(6, createdOpportunity.OpportunityContactRoles.size());
        for (OpportunityContactRole expectedOCR : createdOpportunity.OpportunityContactRoles) {
            System.assertEquals(contact.Id, expectedOCR.ContactId);
            System.assertEquals(true, expectedOCR.IsPrimary);
        }

        Test.startTest();
        Database.executeBatch(new OPP_PrimaryContactRoleMerge_BATCH());
        Test.stopTest();

        Opportunity expectedOpportunity = loadOpportunityWithPrimaryOCRs(createdOpportunity.Id);
        // Opportunity should have only 1 primary OCR with role = NPSP Setting Role.
        System.assertEquals(1, expectedOpportunity.OpportunityContactRoles.size());
        System.assert(contact.Id == expectedOpportunity.OpportunityContactRoles[0].ContactId);
        System.assert(NPSP_ROLE == expectedOpportunity.OpportunityContactRoles[0].Role);

        List<Error__c> errors = [
            SELECT Object_Type__c, Full_Message__c 
            FROM Error__c
        ];
        System.assertEquals(0, errors.size(), 'No Error Log should be created.');
    }

    /*******************************************************************************************************
    * @description Deactivates all the Triggers.
    * @return void.
    ********************************************************************************************************/
    private static void deactivateTriggers() {
        for (Trigger_Handler__c triggerHandler : TDTM_Config_API.getCachedRecords()) {
            triggerHandler.Active__c = false;
        }
    }

    /*******************************************************************************************************
    * @description Activates all the Triggers.
    * @return void.
    ********************************************************************************************************/
    private static void activateTriggers() {
        for (Trigger_Handler__c triggerHandler : TDTM_Config_API.getCachedRecords()) {
            triggerHandler.Active__c = true;
        }
    }

    /*******************************************************************************************************
    * @description Get Opportunity with the related Primary OCRs.
    * @param Id. The Id of the Opportunity to load.
    * @return Opportunity. The Opportunity with the related Primary OCRs.
    ********************************************************************************************************/
    private static Opportunity loadOpportunityWithPrimaryOCRs(Id opportunityId) {
        List<Opportunity> result = [
            SELECT Name, (
                SELECT OpportunityId, ContactId, IsPrimary, Role
                FROM OpportunityContactRoles
                WHERE IsPrimary = true
            )
            FROM Opportunity
            WHERE Id = :opportunityId
        ];
        System.assertEquals(1, result.size());
        return result[0];
    }

    /*******************************************************************************************************
    * @description Get the Opportunity with the related OCRs.
    * @param Id. The Id of the Opportunity to load.
    * @return Opportunity. The Opportunity with the related OCRs.
    ********************************************************************************************************/
    private static Opportunity loadOpportunityWithOCRs(Id opportunityId) {
        List<Opportunity> result = [
            SELECT Name, (
                SELECT OpportunityId, ContactId, IsPrimary, Role
                FROM OpportunityContactRoles
            )
            FROM Opportunity
            WHERE Id = :opportunityId
        ];
        System.assertEquals(1, result.size());
        return result[0];
    }
}