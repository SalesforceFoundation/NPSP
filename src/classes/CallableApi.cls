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
* @description API class that exposes a callable class for users
*/
global class CallableApi implements System.Callable {

    /*******************************************************************************************************
    * @description Exception class for Malformed Method Invocations
    ********************************************************************************************************/
    global class MalformedMethodInvocationException extends Exception {}

    /*******************************************************************************************************
    * @description Map of valid actions used to action text
    ********************************************************************************************************/
    private static Map<String, String> validActionsMap = new Map<String, String> {
        'tdtm.disablealltriggers' => 'TDTM.disableAllTriggers'
    };

    /*******************************************************************************************************
    * @description call function implementation of the callable Interface will dispatch to the appropriate
    * action handler based on the action text
    * @param action string of the target action
    * @param args name value map of arguments
    * @return Object returned will depend on the results of the target function
    ********************************************************************************************************/
    global Object call(String action, Map<String, Object> args) {
       
        CallableApiInfo actionInfo = validateAction(action, args);
        
        if (actionInfo == null) {
            throw new MalformedMethodInvocationException(action + ' is not valid');
        }

       return dispatchAction(actionInfo); 
    }

    /*******************************************************************************************************
    * @description Helper class to keep track of the information needed for actions
    ********************************************************************************************************/
    public class CallableApiInfo {
        public Map<String, Object> args;
        public String action;
        public String errorCode;
        public String function;
        public String message; 
        public String module;

        /*******************************************************************************************************
        * @description Constructor for helper class
        ********************************************************************************************************/
        public CallableApiInfo(String action, String module, String function, Map<String, Object> args) {
            this.action = action;
            this.module = module;
            this.function = function;
            this.args = args;
        }
    }

    /*******************************************************************************************************
    * @description Validate that the action string is the correct format
    * @param action string of the target action
    * @param args name value map of the arguments
    * @return CallableApiInfo object with parameters of the target action
    ********************************************************************************************************/
    private CallableApiInfo validateAction(String action, Map<String, Object> args) {
        if (String.isBlank(action)) {
            return null;
        }

        String validAction = validActionsMap.get(action.toLowerCase());
        if (String.isBlank(validAction)) {
            return null;
        }

        List<String> actionParams = validAction.split('\\.');
        if (actionParams.size() == 2) {
            return new CallableApiInfo(action, actionParams[0], actionParams[1], args);
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Dispatch the action to the appropriate action handlers
    * @param actionInfo contains the information needed to execute the action
    * @return Object that can vary depending on the action handler
    ********************************************************************************************************/
    private Object dispatchAction(CallableApiInfo actionInfo) {
        switch on actionInfo.action {
            when 'TDTM.disableAllTriggers' {
                TDTM_Config_API.disableAllTriggers();
            }
            when else {
                throw new MalformedMethodInvocationException(actionInfo.action + ' is not implemented');
            }
        }

        return generateResponse(actionInfo);
    }

    /*******************************************************************************************************
    * @description Generate a generic response to the call for actions that do not have an explicit response
    ********************************************************************************************************/
    private Map<String, Object> generateResponse(CallableApiInfo actionInfo) {
        return new Map<String, Object> {
            'action' => actionInfo.action,
            'errorCode' => actionInfo.errorCode,
            'message' => actionInfo.message
        };
    }

}