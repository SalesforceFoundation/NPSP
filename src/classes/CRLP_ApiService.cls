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
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Service methods for the Customizable Rollups API
*/
public inherited sharing class CRLP_ApiService {

    public static final String PARAM_ROLLUPTYPE = 'RollupType';
    public static final String PARAM_ROLLUPDEFS = 'RollupDefinitions';

    @TestVisible
    private static final String ACTION_ARCHIVE_BRIDGE_GET_ROLLUP_STATE = 'dso.getRollupStateForRecords';

    @TestVisible
    private UTIL_IntegrationConfig archiveBridgeConfig {
        get {
            if (archiveBridgeConfig == null) {
                archiveBridgeConfig = UTIL_IntegrationConfig.getConfig(UTIL_IntegrationConfig.Integration.ArchiveBridge);
            }
            return archiveBridgeConfig;
        }
        set;
    }

    /**
    * @description Generates the list of Rollup Definitions for the specified rollup type
    * @param rollupTypeName String representation of the Rollup Type enum
    * @return List<CRLP_Rollup>
    */
    public List<CRLP_Rollup> getRollupDefinitions(String rollupTypeName) {

        if (!CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            return new List<CRLP_Rollup>();
        }

        CRLP_RollupProcessingOptions.RollupType rollupType;
        try {
            rollupType = CRLP_RollupProcessingOptions.rollupTypeByName.get((String) rollupTypeName.toLowerCase());
        } catch (Exception ex) { }

        if (rollupType == null) {
            throw new ApiException(String.format( System.Label.CallableApiParameterError, new List<String>{PARAM_ROLLUPTYPE} ));
        }

        CRLP_VRollupHandler handler = new CRLP_VRollupHandler();
        handler.buildGroupedRollups(rollupType);

        return handler.getRollupsList();
    }


    /**
    * @description Confirms if Rollup State is enabled by checking if the DSO-NPSP bridge is installed
    * @return Boolean
    */
    public Boolean isRollupStateEnabled() {
        return archiveBridgeConfig.isInstalled();
    }

    /**
    * @description Confirms if Rollup State is enabled by checking if the DSO-NPSP bridge is installed
    * @param recordIds Ids of records that you want to retrieve archived rollup data for
    * @param rollupType The rollup type that you want to retrieve archived rollup data for
    * @return Map<Id, List<CRLP_Rollup>> List of CRLP_Rollup data for each specified record Id
    */
    public Map<Id, List<CRLP_Rollup>> getBaseRollupStateForRecords(Set<Id> recordIds, CRLP_RollupProcessingOptions.RollupType rollupType) {
        if (!isRollupStateEnabled()) {
            return new Map<Id, List<CRLP_Rollup>>();
        }

        String result = (String) archiveBridgeConfig.getCallableApi().call(
            ACTION_ARCHIVE_BRIDGE_GET_ROLLUP_STATE,
            new Map<String, Object> {
                'RecordIds' => recordIds,
                'RollupType' => rollupType.name()
            }
        );
        return (Map<Id, List<CRLP_Rollup>>) JSON.deserialize(result, Map<Id, List<CRLP_Rollup>>.class);
    }

    /**
    * @description Exception class for Parameter Parsing
    */
    public class ApiException extends Exception {}

}