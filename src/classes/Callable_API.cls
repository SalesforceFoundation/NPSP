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
* @description Global API class that exposes a System.Callable interface for external
* applications and customers to leverage for future NPSP api's
*/
global with sharing class Callable_API implements System.Callable {

    /*******************************************************************************************************
    * @description Exception class for Malformed Method Invocations
    ********************************************************************************************************/
    public class MalformedMethodInvocationException extends Exception {}

    /*******************************************************************************************************
    * @description call function implementation of the callable Interface will dispatch to the appropriate
    * action handler based on the action text
    * @param action string of the target action
    * @param args name value map of arguments
    * @return Object returned will depend on the results of the target function otherwise it returns true
    ********************************************************************************************************/
    global Object call(String action, Map<String, Object> params) {
        String cleanActionText = (String.isBlank(action) ? '' : action.toLowerCase());

        switch on (cleanActionText) {
            when 'tdtm.disablealltriggers' {
                TDTM_Config_API.disableAllTriggers();

            } when 'opp.mapstagetostate' {
                return OPP_StageMappingUtil.determineOppStateFromOppStage((String) params.get('OpportunityStage'));

            } when 'crlp.getdefinitionsforrolluptype' {
                CRLP_ApiService crlpApiSvc = new CRLP_ApiService();
                List<CRLP_Rollup> response = crlpApiSvc.getRollupDefinitions((String) params.get(CRLP_ApiService.PARAM_ROLLUPTYPE));
                return JSON.serialize(response, true);

            } when 'crlp.executerollups' {  // PLACEHOLDER CODE ONLY
                return params.get(CRLP_ApiService.PARAM_ROLLUPDEFS);

            } when else {
                throw new MalformedMethodInvocationException(
                    String.format(System.Label.CallableApiMethodNotImplemented, new List<String> { action })
                );
            }
        }

        // if the action does not return a value then return success
        return true;

    }

}