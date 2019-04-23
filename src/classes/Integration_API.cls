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
* @group-content ../../ApexDocContent/API.htm
* @description Integration from NPSP to defined external API's.
*/
public with sharing class Integration_API {
    @TestVisible
    private static final String DSO_BRIDGE_GET_ROLLUP_STATE_ACTION = 'dso.getRollupStateForRecords';

    @TestVisible
    private UTIL_IntegrationConfig dsoNpspPackage {
        get {
            if (dsoNpspPackage == null) {
                dsoNpspPackage = new UTIL_IntegrationConfig.DsoNpspPackage();
            }
            return dsoNpspPackage;
        }
        set;
    }

    /**
    * @description Confirms if Rollup State is enabled by checking if the DSO-NPSP bridge is installed
    * @return Boolean
    */
    public Boolean isRollupStateEnabled() {
        return dsoNpspPackage.isInstalled();
    }

    /**
    * @description Confirms if Rollup State is enabled by checking if the DSO-NPSP bridge is installed
    * @param recordIds Ids of records that you want to retrieve archived rollup data for
    * @param rollupType The rollup type that you want to retrieve archived rollup data for
    * @return Map<Id, List<CRLP_Rollup>> List of CRLP_Rollup data for each specified record Id
    */
    public Map<Id, List<CRLP_Rollup>> getBaseRollupStateForRecords(Set<Id> recordIds, CRLP_RollupProcessingOptions.RollupType rollupType) {
        String result = (String) dsoNpspPackage.getCallableApi().call(
            DSO_BRIDGE_GET_ROLLUP_STATE_ACTION,
            new Map<String, Object> {
                'RecordIds' => recordIds,
                'RollupType' => rollupType.name()
            }
        );
        return (Map<Id, List<CRLP_Rollup>>) JSON.deserialize(result, Map<Id, List<CRLP_Rollup>>.class);
    }
}
