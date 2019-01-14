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
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Test Coverage for OPP_StageToStateMappingService class
*/
@isTest
private class OPP_StageToStateMappingService_TEST {

    /******************************************************************************************************
    * @description Test value used to test "convertToSet" method with alternate separator
    */
    private static final String TEST_CONVERT_1_VAL = '1~ 2 ~3~4 ~a~B';
    /******************************************************************************************************
    * @description Test value used to test "convertToSet" method
    */
    private static final String TEST_CONVERT_2_VAL = '1; 2 ;3;4 ;a;B';

    /******************************************************************************************************
    * @description Expected values to be found in set after calling "convertToSet" method.
    */
    private static final List<String> RESULT_CONVERT_VALS = new List<String> {'1', '2', '3', '4', 'a', 'b'};

    /******************************************************************************************************
    * @description Test values used to test determineStateFromOppStage
    */
    private static final List<String> TEST_OPP_STAGE_VALS = new List<String> {
            'Prospecting',
            'Qualification',
            'Needs Analysis',
            'Value Proposition',
            'Id. Decision Makers',
            'Perception Analysis',
            'Proposal/Price Quote',
            'Negotiation/Review',
            'Closed Won',
            'Closed Lost',
            'Pledged',
            'PLEDGED',
            'CLOSED WON',
            null
    };

    /******************************************************************************************************
    * @description Test Setting for Committed Stages to be used when testing determineStateFromOppStage
    * with settings present/populated
    */
    private static final String COMMITTED_STAGES_VAL = 'Pledged; Closed Won; Proposal/Price Quote';

    /******************************************************************************************************
    * @description Test Setting for Finalized Stages to be used when testing determineStateFromOppStage
    * with settings present/populated
    */
    private static final String FINALIZED_STAGES_VAL = 'Closed Won; Closed Lost;';

    /******************************************************************************************************
    * @description Expected return values for tests of determineStateFromOppStage when Settings are not
    * populated.
    */
    private static final List<OPP_StageToStateMappingService.OPPORTUNITY_STATE> RESULT_NO_SETTINGS = new List<OPP_StageToStateMappingService.OPPORTUNITY_STATE> {
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED

    };

    /******************************************************************************************************
    * @description Expected return values for tests of determineStateFromOppStage when Settings are
    * populated.
    */
    private static final List<OPP_StageToStateMappingService.OPPORTUNITY_STATE> RESULT_WITH_SETTINGS = new List<OPP_StageToStateMappingService.OPPORTUNITY_STATE> {
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.COMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.FINALIZED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.FINALIZED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.COMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.COMMITTED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.FINALIZED,
        OPP_StageToStateMappingService.OPPORTUNITY_STATE.UNCOMMITTED
    };

    /*********************************************************************************************************
    * @description Tests the convert to Set Method
    * verifies that it properly splits values in Sets passing a separator String.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testConvertToSetMethod() {
        System.assertEquals (true, OPP_StageToStateMappingService.convertToSet(null, '~', true).isEmpty());
        System.assertEquals (true, OPP_StageToStateMappingService.convertToSet(' ', '~', true).isEmpty());

        Set<String> testVals = OPP_StageToStateMappingService.convertToSet(TEST_CONVERT_1_VAL, '~', true);
        System.assertEquals(6, testVals.size());
        for (String resultVal : RESULT_CONVERT_VALS) {
            System.assertEquals(true, testVals.contains(resultVal), 'Expected ' + resultVal + ' to be in testVals');
        }

        // Will use ; as the default because one was not supplied.
        testVals = OPP_StageToStateMappingService.convertToSet(TEST_CONVERT_2_VAL, null, true);
        System.assertEquals(6, testVals.size());
        for (String resultVal : RESULT_CONVERT_VALS) {
            System.assertEquals(true, testVals.contains(resultVal), 'Expected ' + resultVal + ' to be in testVals');
        }

        // Will use ; as the default
        testVals = OPP_StageToStateMappingService.convertToSet(TEST_CONVERT_2_VAL);
        System.assertEquals(6, testVals.size());
        for (String resultVal : RESULT_CONVERT_VALS) {
            System.assertEquals(true, testVals.contains(resultVal), 'Expected ' + resultVal + ' to be in testVals');
        }
    }

    /*********************************************************************************************************
    * @description Tests the determineOppStateFromOppStage Method with No Stages Defined in Settings
    * verifies that it only returns UNCOMMITTED as a value.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testdetermineOppStateFromOppStageNoSettingsMethod() {
        // Check when Committed and Finalized Stage are not mapped in settings...
        for (Integer i = 0; i < TEST_OPP_STAGE_VALS.size(); i++) {
            String testVal = TEST_OPP_STAGE_VALS[i];
            OPP_StageToStateMappingService.OPPORTUNITY_STATE resultVal = RESULT_NO_SETTINGS[i];

            System.assertEquals (resultVal, OPP_StageToStateMappingService.determineOppStateFromOppStage(testVal), 'Expected ' + resultVal + ' for ' + testVal);
        }
    }


    /*********************************************************************************************************
    * @description Tests the determineOppStateFromOppStage Method with Stages Defined in Settings
    * verifies that it returns the appropriate values
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testdetermineOppStateFromOppStageWithSettingsMethod() {
        // Check when Committed and Finalized Stage are mapped in settings...
        npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c(
                Opportunity_Committed_Stages__c = COMMITTED_STAGES_VAL,
                Opportunity_Finalized_Stages__c = FINALIZED_STAGES_VAL
            )
        );

        for (Integer i = 0; i < TEST_OPP_STAGE_VALS.size(); i++) {
            String testVal = TEST_OPP_STAGE_VALS[i];
            OPP_StageToStateMappingService.OPPORTUNITY_STATE resultVal = RESULT_WITH_SETTINGS[i];

            System.assertEquals (resultVal, OPP_StageToStateMappingService.determineOppStateFromOppStage(testVal), 'Expected ' + resultVal + ' for ' + testVal);
        }
    }

    /*********************************************************************************************************
    * @description Tests the getCommittedStages Method
    * verifies that it returns the appropriate values
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testGetCommittedStagesMethod() {
        // Check when Committed and Finalized Stage are mapped in settings...
        npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c(
                Opportunity_Committed_Stages__c = COMMITTED_STAGES_VAL,
                Opportunity_Finalized_Stages__c = FINALIZED_STAGES_VAL
            )
        );

        Set<String> committedStages = OPP_StageToStateMappingService.getCommittedStages(false);

        System.assertEquals (3, committedStages.size());

        System.assert(true, committedStages.contains('Pledged'));
        System.assert(true, committedStages.contains('Closed Won'));
        System.assert(true, committedStages.contains('Proposal/Price Quote'));
    }

    /*********************************************************************************************************
    * @description Tests the getFinalizedtages Method
    * verifies that it returns the appropriate values
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testGetFinalizedStagesMethod() {
        // Check when Committed and Finalized Stage are mapped in settings...
        npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c(
                Opportunity_Committed_Stages__c = COMMITTED_STAGES_VAL,
                Opportunity_Finalized_Stages__c = FINALIZED_STAGES_VAL
            )
        );

        Set<String> committedStages = OPP_StageToStateMappingService.getFinalizedStages(false);

        System.assertEquals (2, committedStages.size());

        System.assert(true, committedStages.contains('Closed Won'));
        System.assert(true, committedStages.contains('Closed Lost'));
    }

}