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
* @description Unit Tests for the Customizable Rollups Api Service class
*/
@IsTest(IsParallel=true)
private class CRLP_ApiService_TEST {

    /**
     * @description Validate the getRollupDefsForRollupType returns the expected collection of CRLP_Rollup instances
     */
    @IsTest
    static void validateGetRollupDefsForRollupTypeReturnValues() {
        // Call the mocking utilities to build a bunch of rollup definitions and filter groups/rules fo
        CRLP_RollupContact_TEST.mockRollupCMTValues();
        List<Rollup__mdt> contactHardCreditDefs = CRLP_Rollup_SEL.cachedRollups;
        CRLP_RollupAccount_TEST.mockRollupCMTValues();

        // Stuff these into the RollupSelector cache
        CRLP_Rollup_SEL.cachedRollups.addAll(contactHardCreditDefs);

        CRLP_ApiService crlpApiSvc = new CRLP_ApiService();

        Test.startTest();

        // These first three have mocked CMT's for rollup definitions
        List<CRLP_Rollup> rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit.name());
        System.assert(!rollups.isEmpty(), 'The collection of returned rollups should not be empty for AccountHardCredit');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit.name());
        System.assert(!rollups.isEmpty(), 'The collection of returned rollups should not be empty for ContactHardCredit');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit.name());
        System.assert(!rollups.isEmpty(), 'The collection of returned rollups should not be empty for AccountSoftCredit');

        // These do not and should all return a empty set
        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit.name());
        System.assert(rollups.isEmpty(), 'The collection of returned rollups should be empty for AccountContactSoftCredit');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit.name());
        System.assert(rollups.isEmpty(), 'The collection of returned rollups should be empty for ContactSoftCredit');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.RecurringDonations.name());
        System.assert(rollups.isEmpty(), 'The collection of returned rollups should be empty for RecurringDonations');

        rollups = crlpApiSvc.getRollupDefsForRollupType(CRLP_RollupProcessingOptions.RollupType.GAU.name());
        System.assert(rollups.isEmpty(), 'The collection of returned rollups should be empty for GAU');

    }

    /**
     * @description Validate the getRollupDefsForRollupType returns the expected collection of CRLP_Rollup instances
     */
    @IsTest
    static void validateGetRollupDefsForRollupTypeInvalidParameter() {
        CRLP_ApiService crlpApiSvc = new CRLP_ApiService();

        Test.startTest();
        try {
            crlpApiSvc.getRollupDefsForRollupType('NonExistentType');
            System.assert(false, 'This call should have failed due to an invalid parameter!');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase('parameter'), 'The error should contain the word "parameter": ' + ex.getMessage());
        }

        try {
            crlpApiSvc.getRollupDefsForRollupType(null);
            System.assert(false, 'This call should have failed due to an invalid parameter!');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase('parameter'), 'The error should contain the word "parameter": ' + ex.getMessage());
        }
    }

}