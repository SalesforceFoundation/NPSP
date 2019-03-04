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
* @description Test Coverage for OPP_StageMappingUtil class
*/
@isTest(isParallel=true)
private class OPP_StageMappingUtil_TEST {

    private static final String OPP_MAPPING_STAGETOSTATE_ACTION = 'OPP.MapStageToState';

    /******************************************************************************************************
    * @description Test values used to test determineStateFromOppStage
    */
    private static final List<String> TEST_OPP_STAGE_VALS = new List<String> {
            'Negotiation/Review',
            'Closed Won',
            null,
            'CLOSED WON  ',
            ' CLOSED WON',
            '  CLOSED WON  ',
            'Finalized'
    };


    /******************************************************************************************************
    * @description Expected return values for tests of determineStateFromOppStage
    */
    private static final List<String> RESULTS = new List<String> {
        OPP_StageMappingUtil.UNCOMMITTED_STATE_VAL,
        OPP_StageMappingUtil.COMMITTED_STATE_VAL,
        OPP_StageMappingUtil.UNCOMMITTED_STATE_VAL,
        OPP_StageMappingUtil.COMMITTED_STATE_VAL,
        OPP_StageMappingUtil.COMMITTED_STATE_VAL,
        OPP_StageMappingUtil.COMMITTED_STATE_VAL,
        OPP_StageMappingUtil.FINALIZED_STATE_VAL
    };

    /*********************************************************************************************************
    * @description Tests the determineOppStateFromOppStage Method with Stages Defined in Settings
    * verifies that it returns the appropriate values
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testdetermineOppStateFromOppStageWithSettingsMethod() {

        for (Integer i = 0; i < TEST_OPP_STAGE_VALS.size(); i++) {
            String testVal = TEST_OPP_STAGE_VALS[i];
            String resultVal = RESULTS[i];

            System.assertEquals (resultVal, OPP_StageMappingUtil.determineOppStateFromOppStage(testVal), 'Expected ' + resultVal + ' for ' + testVal);
        }
    }
   /*******************************************************************************************************
    * @description verify invocation of Opportunity Mapping Stage to State API as Method of Callable API
    ********************************************************************************************************/
    @IsTest
    private static void testCallableAPISupport() {
        Test.startTest();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();

        for (Integer i = 0; i < TEST_OPP_STAGE_VALS.size(); i++) {
            String testVal = TEST_OPP_STAGE_VALS[i];
            String resultVal = RESULTS[i];

            Map<String, Object> npspApiParams = new Map<String, Object> {
                'OpportunityStage' => testVal
            };

            Object callResult = npspApi.call(OPP_MAPPING_STAGETOSTATE_ACTION, npspApiParams);

            String callResultVal = (String) callResult;

            System.assertEquals (resultVal, callResultVal, 'Expected ' + resultVal + ' for ' + testVal);
        }
    }

}