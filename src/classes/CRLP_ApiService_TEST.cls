/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group API
* @description Unit Tests for the Customizable Rollups Api Service classes
*/
@IsTest(IsParallel=true)
private class CRLP_ApiService_TEST {

    /**
    * @description Validate the getRollupDefinitions returns the expected collection of CRLP_Rollup instances.
    * Calls the mocking utilities to build a bunch of rollup definitions and filter groups/rules fo
    */
    @IsTest
    private static void shouldReturnRollupDefinitionsWhenParameterIsValid() {
        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        CRLP_ApiService service = new CRLP_ApiService();

        Test.startTest();
        for (CRLP_RollupProcessingOptions.RollupType rollupType : CRLP_RollupProcessingOptions.RollupType.values()) {
            List<CRLP_Rollup> rollups = service.getRollupDefinitions(rollupType.name());
            System.assertEquals(1, rollups.size(),
                'The collection of returned rollups should contain exactly 1 instance for ' + rollupType.name());
            System.assertEquals(2, rollups[0].rollupsMdt.size(),
                'There should be two Rollup__mdt records associated with the CRLP_Rollup instance');
        }
    }

    /**
    * @description Validate the getRollupDefinitions returns an exception if the RollupType is null or invalid
    */
    @IsTest
    private static void shouldThrowExceptionWhenParameterIsInvalid() {
        CRLP_ApiService service = new CRLP_ApiService();

        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        Test.startTest();
        for (String param : new String[] { null, 'NonExistentType' }) {
            Exception actualException = null;
            try {
                service.getRollupDefinitions(param);
            } catch (Exception e) {
                actualException = e;
            }
            System.assertNotEquals(null, actualException,
                'An exception should be thrown for invalid param: ' + param);
            System.assert(actualException.getMessage().containsIgnoreCase(CallableApiParameters.PARAM_ROLLUP_TYPE),
                'Message should contain "' + CallableApiParameters.PARAM_ROLLUP_TYPE + '" param: ' + actualException.getMessage());
        }
    }

    /**
    * @description Validate the getRollupDefinitions returns an empty list<> when CRLP is not enabled
    */
    @IsTest
    private static void shouldReturnEmptyListWhenCRLPNotEnabled() {
        CRLP_ApiService service = new CRLP_ApiService();

        System.assert(service.getRollupDefinitions(null).isEmpty(),
            'When CRLP is disabled, then call to getRollupDefinitions should return an empty list');
    }

    /**
    * @description Validate that the ExecuteRollups() call throws an exception if the RollupType
    * parameter is null
    */
    @IsTest
    private static void shouldThrowExceptionOnInvalidMissingRollupType() {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));
        CRLP_Rollup_SEL.cachedRollups = new List<Rollup__mdt>(); // be sure this is clear

        String rollupType = CRLP_RollupProcessingOptions.RollupType.AccountHardCredit.name();
        Id parentId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);

        Test.startTest();

        CRLP_ApiService service = new CRLP_ApiService();

        // Should fail for an invalid RollupType
        try {
            service.executeRollups(null, null, null, null, false);
            System.assert(false, 'An exception should have been thrown for invalid parameters');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase(CallableApiParameters.PARAM_ROLLUP_TYPE),
                'Message should contain "' + CallableApiParameters.PARAM_ROLLUP_TYPE + '" param: ' + ex.getMessage());
        }

        // Should succeed, but return an empty collection because no active rollups
        // Even though the Rollup Definitions are null or Empty.
        System.assert(service.executeRollups(parentId, rollupType, null, null, false).isEmpty(),
            'The call should have succeeded, even with missing data, but returned an empty collection because there are no active rollups for this type.');
    }

    /**
    * @description Validate that the ExecuteRollups() call throws an exception if the RollupData
    * parameter is null or empty
    */
    @IsTest
    private static void shouldThrowExceptionOnMissingRollupData() {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));
        CRLP_Rollup_SEL.cachedRollups = new List<Rollup__mdt>(); // be sure this is clear

        List<CRLP_Rollup> rollupDefs = new List<CRLP_Rollup>();
        String rollupType = CRLP_RollupProcessingOptions.RollupType.AccountHardCredit.name();
        Id parentId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);

        Test.startTest();

        CRLP_ApiService service = new CRLP_ApiService();

        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        rollupDefs = service.getRollupDefinitions(rollupType);
        System.assertEquals(1, rollupDefs.size(), 'There should be rollup definitions now');
        System.assertEquals(2, rollupDefs[0].rollupsMdt.size(), 'There should be rollup definitions now');

        // Should fail for an null RollupData collection.
        try {
            service.executeRollups(parentId, rollupType, rollupDefs, null, false);
            System.assert(false, 'An exception should have been thrown for invalid parameters');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase(CallableApiParameters.PARAM_ROLLUP_DATA),
                'Message should contain "' + CallableApiParameters.PARAM_ROLLUP_DATA + '" param: ' + ex.getMessage());
        }

        // Should fail for an empty RollupData collection
        Map<Id, Map<SObjectType, List<SObject>>> rollupData = new Map<Id, Map<SObjectType, List<SObject>>>();
        try {
            service.executeRollups(parentId, rollupType, rollupDefs, rollupData, false);
            System.assert(false, 'An exception should have been thrown for invalid parameters');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase(CallableApiParameters.PARAM_ROLLUP_DATA),
                'Message should contain "' + CallableApiParameters.PARAM_ROLLUP_DATA + '" param: ' + ex.getMessage());
        }
    }

    /**
    * @description Validate that the ExecuteRollups() call throws an exception if the ParentId
    * parameter is not provided or the matching record cannot be queried
    */
    @IsTest
    private static void shouldThrowExceptionOnInvalidParentId() {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        String rollupType = CRLP_RollupProcessingOptions.RollupType.AccountHardCredit.name();
        Id parentId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);
        Map<Id, Map<SObjectType, List<SObject>>> rollupData = buildMockRollupData(parentId, 100);

        Test.startTest();

        CRLP_ApiService service = new CRLP_ApiService();

        List<CRLP_Rollup> rollupDefs = service.getRollupDefinitions(rollupType);

        // Should fail for a null parentId
        try {
            service.executeRollups(null, rollupType, rollupDefs, rollupData, false);
            System.assert(false, 'An exception should have been thrown for invalid parameters');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase(CallableApiParameters.PARAM_ROLLUP_PARENTID),
                'Message should contain "' + CallableApiParameters.PARAM_ROLLUP_PARENTID + '" param: ' + ex.getMessage());
        }

        // Should fail because the specified ParentId cannot be queried
        try {
            service.executeRollups(parentId, rollupType, rollupDefs, rollupData, false);
            System.assert(false, 'An exception should have been thrown for invalid parameters');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase(CallableApiParameters.PARAM_ROLLUP_PARENTID),
                'Message should contain "' + CallableApiParameters.PARAM_ROLLUP_PARENTID + '" param: ' + ex.getMessage());
        }
    }

    /**
    * @description Verify that the call to executeRollups() successfully completes a rollup and that
    * the target (summary) record is not updated as a result.
    */
    @IsTest
    private static void shouldCompleteExecuteRollupsForAccount() {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true
        ));

        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        String rollupType = CRLP_RollupProcessingOptions.RollupType.AccountHardCredit.name();
        Double oppAmount = 100;

        Account acct = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null)[0];
        insert acct;
        acct = (Account)getRecord(acct.Id, Account.SObjectType, 'npo02__NumberOfClosedOpps__c');
        Double acctCountOfOppsValue = acct.npo02__NumberOfClosedOpps__c;

        Map<Id, Map<SObjectType, List<SObject>>> rollupData = buildMockRollupData(acct.Id, oppAmount);

        Test.startTest();

        CRLP_ApiService service = new CRLP_ApiService();

        List<CRLP_Rollup> rollupDefs = service.getRollupDefinitions(rollupType);

        rollupDefs = service.executeRollups(acct.Id, rollupType, rollupDefs, rollupData, false);

        System.assertEquals(1, rollupDefs[0].theCount,
            'The Rollup Definition counter var should be set to 1');
        System.assertEquals(oppAmount, rollupDefs[0].theSum,
            'The Rollup Definition sum var should be set to ' + oppAmount);

        acct = (Account)getRecord(acct.Id, Account.SObjectType, 'npo02__NumberOfClosedOpps__c');
        System.assertEquals(acctCountOfOppsValue, acct.npo02__NumberOfClosedOpps__c,
            'The Parent Account should not have been updated');
    }

    // **************************** HELPER METHODS ****************************

    /**
    * @description Build a mock RollupData Map with a single Opportunity and no related records to use
    * for in test methods.
    * @return Map<Id, Map<SObjectType, List<SObject>>>
    */
    private static Map<Id, Map<SObjectType, List<SObject>>> buildMockRollupData(Id parentId, Decimal amt) {
        Id oppId = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType);
        return new Map<Id, Map<SObjectType, List<SObject>>>{
            oppId => new Map<SObjectType, List<SObject>>{
                Opportunity.SObjectType => new List<SObject>{
                    new Opportunity(Id = oppId,
                        AccountId = parentId,
                        Name = 'XYZ',
                        Amount = amt,
                        CloseDate=Date.today())
                }
            }
        };
    }

    /**
    * @description Queries a single record with the specified field
    */
    private static SObject getRecord(Id recordId, SObjectType objType, String field) {
        String soql = 'SELECT Id, ' + field +
            ' FROM ' + objType.getDescribe().getName() +
            ' WHERE Id = :recordId' +
            ' LIMIT 1';
        return Database.query(soql);
    }
}