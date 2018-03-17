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
* @group Customizable Rollups Operations Services
* @description Unit Test for the Rollup Operation Services Classes
*/
@isTest(IsParallel=true)
private class CRLP_Operation_TEST {

    /**
     * @description Test the static utility methods in the CRLP_Operation class
     */
    static testMethod void test_static_methods() {
        System.assertNotEquals(0, CRLP_Operation.getRollupOperationTypes().size(),
            'There should be whole bunch of Rollup Operations');
        System.assertEquals(1, CRLP_Operation.getAvailableTimeBoundOperationTypes(CRLP_Operation.RollupType.BEST_YEAR.name()).size(),
            'Only AllTime should be valid for a BestYear operation');
        System.assertEquals(3, CRLP_Operation.getAvailableTimeBoundOperationTypes(CRLP_Operation.RollupType.SUM.name()).size(),
                'All Time Bound Operation types should be valid for a Sum operation');
        System.assertEquals(1, CRLP_Operation.getAvailableFieldTypesForDetailField(CRLP_Operation.RollupType.SUM).size(),
                'The Sum Operation Type is only valid for Double type fields');
        System.assertEquals(1, CRLP_Operation.getAvailableFieldTypesForDetailField(CRLP_Operation.RollupType.YEARS_DONATED).size(),
                'The YearsDonated Operation Type is only valid for Date type fields');
        System.assertEquals(1, CRLP_Operation.getAvailableFieldTypesForDetailField(CRLP_Operation.RollupType.YEARS_DONATED).size(),
                'The YearsDonated Operation Type is only valid for Date type fields');
        System.assertEquals(CRLP_Operation.RollupType.SUM, CRLP_Operation.getRollupTypeFromString('Sum'));
    }

}