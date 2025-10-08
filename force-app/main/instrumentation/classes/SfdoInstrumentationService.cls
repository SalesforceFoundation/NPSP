/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @group Product Instrumentation
* @description Primary class to enable product instrumentation for adoption and usage aggregation
* See DOC_LINK_TBD for more information properly using Instrumentation Services
*
*/
public inherited sharing class SfdoInstrumentationService {

    public SfdoInstrumentationService() { }

    @TestVisible
    private static SfdoInstrumentationService instance;

    @TestVisible
    private static LastCallData lastCallData;

    @TestVisible
    private static String requestQuiddity = getRequestQuiddity();
    
    class LastCallData {        
        public String lastFeatureName;
        public String lastComponentName;
        public String lastActionName;
        public Integer lastValue;
        public Map<String, Object> lastContext;
        
        // Default constructor
        public LastCallData(String featureName, String componentName) {
            this.lastFeatureName = featureName;
            this.lastComponentName = componentName;
        }
        
        // Constructor with feature, component, action, and value
        public LastCallData(String featureName, String componentName, String actionName, Integer value) {
            this.lastFeatureName = featureName;
            this.lastComponentName = componentName;
            this.lastActionName = actionName;
            this.lastValue = value;
        }
        
        // Constructor with feature, component, action, and context
        public LastCallData(String featureName, String componentName, String actionName, Map<String, Object> context, Integer value) {
            this.lastFeatureName = featureName;
            this.lastComponentName = componentName;
            this.lastActionName = actionName;
            this.lastContext = context;
            this.lastValue = value;
        }
        
        // Constructor with feature, component, action, and context
        public LastCallData(String featureName, String componentName, String actionName, Map<String, Object> context) {
            this.lastFeatureName = featureName;
            this.lastComponentName = componentName;
            this.lastActionName = actionName;
            this.lastContext = context;
        }
        
        // Constructor with feature, component, and action only
        public LastCallData(String featureName, String componentName, String actionName) {
            this.lastFeatureName = featureName;
            this.lastComponentName = componentName;
            this.lastActionName = actionName;
        }
    }

    /**
     * @description Return a singleton instance of this class
     */
    public static SfdoInstrumentationService getInstance() {
        if (instance == null) {
            instance = new SfdoInstrumentationService();
        }
        return instance;
    }
    
    // =============================================================================================================================
    // Primary Logging signatures that accept only valid defined Enums for Feature/Component/Action
    // =============================================================================================================================

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param context Map of additional content as context to include in the log (DO NOT INCLUDE PII or NON-GPDR COMPLIANT DATA)
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SfdoInstrumentationEnum.Component componentName, SfdoInstrumentationEnum.Action actionName, Map<String, Object> context) { 
        context = applyRequestQuiddity(context);
        SfdoLogUtils.log(featureName?.name(), componentName?.name(), actionName?.name(), context);
        lastCallData = new LastCallData(featureName?.name(), componentName?.name(), actionName?.name(), context);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param context Map of additional content as context to include in the log (DO NOT INCLUDE PII or NON-GPDR COMPLIANT DATA)
     * @param value Duration or other value to include in the log
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SfdoInstrumentationEnum.Component componentName, SfdoInstrumentationEnum.Action actionName, Map<String, Object> context, Integer value) { 
        context = applyRequestQuiddity(context);
        SfdoLogUtils.log(featureName?.name(), componentName?.name(), actionName?.name(), context, value);
        lastCallData = new LastCallData(featureName?.name(), componentName?.name(), actionName?.name(), context, value);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param value Duration or other value to include in the log
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SfdoInstrumentationEnum.Component componentName, SfdoInstrumentationEnum.Action actionName, Integer value) { 
        Map<String, Object> context = applyRequestQuiddity(null);
        SfdoLogUtils.log(featureName?.name(), componentName?.name(), actionName?.name(), context, value);
        lastCallData = new LastCallData(featureName?.name(), componentName?.name(), actionName?.name(), context, value);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SfdoInstrumentationEnum.Component componentName, SfdoInstrumentationEnum.Action actionName) {
        Map<String, Object> context = applyRequestQuiddity(null);
        SfdoLogUtils.log(featureName?.name(), componentName?.name(), actionName?.name(), context);
        lastCallData = new LastCallData(featureName?.name(), componentName?.name(), actionName?.name(), context);
    }

    // =============================================================================================================================
    // Alternative Signatures that support passing an SobjectType as the Component
    // =============================================================================================================================

    /**
     * @param featureName - Feature name within the product the log is for
     * @param objType SObjectType - define the SObject as the Component for this log entry
     * @param actionName String - define the action of the feature or component
     * @param context Map of additional content as context to include in the log (DO NOT INCLUDE PII or NON-GPDR COMPLIANT DATA)
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SObjectType objType, SfdoInstrumentationEnum.Action actionName, Map<String, Object> context) { 
        context = applyRequestQuiddity(context);
        SfdoLogUtils.log(featureName?.name(), String.valueOf(objType), actionName?.name(), context);
        lastCallData = new LastCallData(featureName?.name(), String.valueOf(objType), actionName?.name(), context);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param objType SObjectType - define the SObject as the Component for this log entry
     * @param actionName String - define the action of the feature or component
     * @param context Map of additional content as context to include in the log (DO NOT INCLUDE PII or NON-GPDR COMPLIANT DATA)
     * @param value Duration or other value to include in the log
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SObjectType objType, SfdoInstrumentationEnum.Action actionName, Map<String, Object> context, Integer value) { 
        context = applyRequestQuiddity(context);
        SfdoLogUtils.log(featureName?.name(), String.valueOf(objType), actionName?.name(), context, value);
        lastCallData = new LastCallData(featureName?.name(), String.valueOf(objType), actionName?.name(), context, value);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param objType SObjectType - define the SObject as the Component for this log entry
     * @param actionName String - define the action of the feature or component
     * @param value Duration or other value to include in the log
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SObjectType objType, SfdoInstrumentationEnum.Action actionName, Integer value) { 
        Map<String, Object> context = applyRequestQuiddity(null);
        SfdoLogUtils.log(featureName?.name(), String.valueOf(objType), actionName?.name(), context, value);
        lastCallData = new LastCallData(featureName?.name(), String.valueOf(objType), actionName?.name(), context, value);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param objType SObjectType - define the SObject as the Component for this log entry
     * @param actionName String - define the action of the feature or component
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SObjectType objType, SfdoInstrumentationEnum.Action actionName) {
        Map<String, Object> context = applyRequestQuiddity(null);
        SfdoLogUtils.log(featureName?.name(), String.valueOf(objType), actionName?.name(), context);
        lastCallData = new LastCallData(featureName?.name(), String.valueOf(objType), actionName?.name(), context);
    }

    // =============================================================================================================================
    // Helper Methods
    // =============================================================================================================================

    /**
     * @description Retrieve the Quiddity of the current request
     * @return String
     */
    private static String getRequestQuiddity() {
        try {
            Request reqInfo = Request.getCurrent();
            String currentRequestId = reqInfo.getRequestId();
            Quiddity currentType = reqInfo.getQuiddity();
            return currentType.name();
        } catch (Exception e) {
            return '(error)';
        }
    }

    /**
     * @description Always add the Request Quiddity to the context map
     * @return Map<String, Object>
     */
    private static Map<String, Object> applyRequestQuiddity(Map<String, Object> context) {
        try {
            if (context == null) {
                context = new Map<String, Object>();
            } else {
                context = new Map<String, Object>(context);
            }
            context.put('RequestQuiddity', requestQuiddity);
        } catch (Exception e) {
        }
        return context;
    }
    /**
     * @description Retrieve the Action Enum for a specific TriggerHandler Event Type
     * @param  thisAction thisAction
     * @return Action enum
     */
    public static SfdoInstrumentationEnum.Action getActionFromTriggerEvent(TDTM_Runnable.Action thisAction) {
        String val = thisAction.name();

        for (SfdoInstrumentationEnum.Action a : SfdoInstrumentationEnum.Action.values()) {
            if (a.name() == val) {
                return a;
            }
        }
        return null;
    }
}
