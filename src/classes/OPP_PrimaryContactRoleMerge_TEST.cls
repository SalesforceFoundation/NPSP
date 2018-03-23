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

    /*********************************************************************************************************
    * @description Given an Opportunity with multiple primary OCRs with Role != NPSP Settings Role 
    * when the batch runs, then an error log created, containing a link to the Opportunity.
    */
    @isTest static void test_LogErrorIfNoOCRsRoleDefinedInNPSPSettings() {
        String nonNPSPRole = 'NON_NPSP_ROLE';

        deactivateTriggers();

        Account account = new Account(Name = 'TEST_ACCOUNT');
        insert account;
        Opportunity opportunity = new Opportunity(
            Name = 'TEST_OPPORTUNITY',
            StageName = UTIL_UnitTestData_TEST.getOpenStage(),
            CloseDate = Date.today(),
            AccountId = account.Id
        );
        insert opportunity;

        Contact contact = new Contact(LastName = 'TEST_CONTACT');
        insert contact;

        List<OpportunityContactRole> primaryOCRs = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = nonNPSPRole
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = nonNPSPRole
            )
        };
        insert primaryOCRs;

        activateTriggers();
        
        Test.startTest();
        Database.executeBatch(new OPP_PrimaryContactRoleMerge_BATCH());
        Test.stopTest();

        List<Opportunity> expectedOpportunities = [
            SELECT Name, (
                SELECT OpportunityId, ContactId, IsPrimary, Role
                FROM OpportunityContactRoles
            )
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];
        // Opportunity and the related Opportunity Contact Roles should not change.
        System.assertEquals(1, expectedOpportunities.size());
        System.assertEquals(2, expectedOpportunities[0].OpportunityContactRoles.size());
        System.assertEquals(contact.Id, expectedOpportunities[0].OpportunityContactRoles[0].ContactId);
        System.assertEquals(true, expectedOpportunities[0].OpportunityContactRoles[0].IsPrimary);
        System.assertEquals(nonNPSPRole, expectedOpportunities[0].OpportunityContactRoles[0].Role);
        System.assertEquals(contact.Id, expectedOpportunities[0].OpportunityContactRoles[1].ContactId);
        System.assertEquals(true, expectedOpportunities[0].OpportunityContactRoles[1].IsPrimary);
        System.assertEquals(nonNPSPRole, expectedOpportunities[0].OpportunityContactRoles[1].Role);

        List<Error__c> errors = [
            SELECT Object_Type__c, Full_Message__c 
            FROM Error__c
        ];
        // An Error Log should be created.
        System.assertEquals(1, errors.size());
        System.assertEquals(String.format(OPP_PrimaryContactRoleMerge.ERROR_MESSAGE, new List<String>{opportunity.Id}), errors[0].Full_Message__c);
    }

    /*********************************************************************************************************
    * @description Given an Opportunity with multiple primary OCRs and the OCRs have Role equals to 
    * (NPSP Settings Role, blank, NOT “NPSP Settings Role”) when the Batch runs, then the primary OCRs
    * with blank role AND role not defined in NPSP Settings, should be deleted. The Opportunity should have 
    * only 1 primary OCR with role equals to the NPSP Settings Role. The Opportunity's field Primary Contact
    * should be equals to the Contact on the primary OCR.
    */
    @isTest static void test_SingleContact_DeleteBlankAndNonNPSPRole() {
        String npspRole = 'DONOR';
        String nonNPSPRole = 'NON_NPSP_ROLE';

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Opportunity_Contact_Role_Default_role__c = npspRole
        ));

        deactivateTriggers();
        Account account = new Account(Name = 'TEST_ACCOUNT');
        insert account;
        Opportunity opportunity = new Opportunity(
            Name = 'TEST_Opportunity',
            StageName = UTIL_UnitTestData_TEST.getOpenStage(),
            CloseDate = Date.today(),
            AccountId = account.Id
        );
        insert opportunity;

        Contact contact = new Contact(LastName = 'TEST_CONTACT');
        insert contact;

        List<OpportunityContactRole> primaryOCRs = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = npspRole
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = npspRole
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = nonNPSPRole
            ),
            new OpportunityContactRole(
                OpportunityId = opportunity.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = nonNPSPRole
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

        List<Opportunity> expectedOpportunities = [
            SELECT Name, (
                SELECT OpportunityId, ContactId, IsPrimary, Role
                FROM OpportunityContactRoles
            )
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];
        
        System.assertEquals(1, expectedOpportunities.size());
        System.assertEquals(6, expectedOpportunities[0].OpportunityContactRoles.size());
        for (OpportunityContactRole expectedOCR : expectedOpportunities[0].OpportunityContactRoles) {
            System.assertEquals(contact.Id, expectedOCR.ContactId);
            System.assertEquals(true, expectedOCR.IsPrimary);
        }

        Test.startTest();
        Database.executeBatch(new OPP_PrimaryContactRoleMerge_BATCH());
        Test.stopTest();

        expectedOpportunities = [
            SELECT Name, (
                SELECT OpportunityId, ContactId, IsPrimary, Role
                FROM OpportunityContactRoles
            )
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];
        
        // Opportunity should have only 1 primary OCR with role = NPSP Setting Role.
        System.assertEquals(1, expectedOpportunities.size());
        System.assertEquals(1, expectedOpportunities[0].OpportunityContactRoles.size());
        System.assert(contact.Id == expectedOpportunities[0].OpportunityContactRoles[0].ContactId);
        System.assert(npspRole == expectedOpportunities[0].OpportunityContactRoles[0].Role);
        System.assertEquals(true, expectedOpportunities[0].OpportunityContactRoles[0].IsPrimary);

        List<Error__c> errors = [
            SELECT Object_Type__c, Full_Message__c 
            FROM Error__c
        ];
        // No Error Log should be created.
        System.assertEquals(0, errors.size());
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
}