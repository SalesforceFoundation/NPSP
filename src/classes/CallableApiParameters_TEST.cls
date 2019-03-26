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
* @description Unit Tests for the CallableApiParameters class
*/
@IsTest(IsParallel=true)
private class CallableApiParameters_TEST {

    /**
     * @description Validate that a deserialized set of rollup definitions is returned
     */
    @IsTest
    private static void shouldReturnListRollupDefinitions() {
        List<CRLP_Rollup> rollups = new List<CRLP_Rollup>{ new CRLP_Rollup( new Rollup__mdt() ) };

        String rollupJson = JSON.serialize(rollups);

        Map<String, Object> params = new Map<String, Object>{
                CallableApiParameters.PARAM_ROLLUP_DEFS => rollupJson
        };

        CallableApiParameters service = new CallableApiParameters(params);
        System.assertEquals(1, service.getRollupDefinitions(CallableApiParameters.PARAM_ROLLUP_DEFS).size());
    }

    /**
     * @description Validate that an invalid rollups defintions json throws an exception
     */
    @IsTest
    private static void shouldThrowExceptionOnBadRollupDefsJson() {
        String rollupJson = JSON.serialize( new List<String>{ 'StringList' });

        Map<String, Object> params = new Map<String, Object>{
                CallableApiParameters.PARAM_ROLLUP_DEFS => rollupJson
        };

        CallableApiParameters service = new CallableApiParameters(params);
        try {
            service.getRollupDefinitions(CallableApiParameters.PARAM_ROLLUP_DEFS);
            System.assert(false, 'An exception should have been thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(CallableApiParameters.PARAM_ROLLUP_DEFS),
                'An exception should have been thrown referencing the rollup defintions');
        }
    }

    /**
     * @description Validate that each of the service methods returns the expected data type
     */
    @IsTest
    private static void shouldCastParametersAsSpecifiedDataTypes() {

        Map<String, Object> params = new Map<String, Object>{
                'String' => 'String',
                'BooleanTrue' => true,
                'BooleanFalse' => false,
                'ListString' => new List<String>{ 'Value1' },
                'SetString' => new Set<String>{ 'Value1' },
                'ListSObject' => new List<SObject>{ new Opportunity(Name = 'Opportunity') }
        };

        CallableApiParameters service = new CallableApiParameters(params);
        String rtnString = service.getString('String');
        System.assertEquals('String', rtnString);

        Boolean rtnBoolean = service.getBoolean('BooleanTrue');
        System.assertEquals(true, rtnBoolean);

        rtnBoolean = service.getBoolean('BooleanFalse');
        System.assertEquals(false, rtnBoolean);

        List<String> rtnListString = service.getListString('ListString');
        System.assertEquals(1, rtnListString.size());
        System.assertEquals('Value1', rtnListString[0]);

        Set<String> rtnSetString = service.getSetString('SetString');
        System.assertEquals(1, rtnSetString.size());
        System.assertEquals(true, rtnSetString.contains('Value1'));

        List<SObject> rtnListSObject = service.getSObjects('ListSObject');
        System.assertEquals(1, rtnListSObject.size());
        System.assertEquals(Opportunity.SObjectType, rtnListSObject[0].getSObjectType());
        System.assertEquals('Opportunity', rtnListSObject[0].get('Name'));
    }

}