/**
* WARNING: DO NOT INCLUDE THIS CLASS IN THE MANAGED PACKAGE
* WARNING: DO NOT CALL THIS CLASS DIRECTLY TO LOG. USE THE PROVIDED SFDOINSTRUMENTATIONSERVICE IMPLEMENTATION INSTEAD.
*
* Support Instrumentation for Salesforce.org Managed Packages
* @author Salesforce.org
* @date 2021-06-21
*
* @description: Mock class is ONLY necessary when unmanaged code is deployed into an org without a namespace.
* - The method signatures in this class MUST match the core implementation of the "SfdoLogUtils" file-based apex class. 
* - The methods in this class mock the identical exposed methods in the core version of the class, however the core class is ONLY available to
*   managed code with the product namespace. 
* - By deploying this unmanaged class to the org BEFORE the rest of the product code is deployed, it will allow any package code that references
*   the SfdoLogUtils.log() methods to compile property by redirecting it to "this" mock class (which does nothing)
*
* Core Work Item: W-9167918
* Core Module: "sfdo"
* Core File-Based Apex Code: https://codesearch.data.sfdc.net/source/xref/app_main_core/app/main/core/sfdo/apex/
*/
public without sharing class SfdoLogUtils {

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param payload Map of additional content as context to include in the log (DO NOT INCLUDE PII or NON-GPDR COMPLIANT DATA)
     */
    public static void log(String featureName, String componentName, String actionName, Map<String, Object> payload) { }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param payload Map of additional content as context to include in the log (DO NOT INCLUDE PII or NON-GPDR COMPLIANT DATA)
     * @param value Duration or other value to include in the log
     */
    public static void log(String featureName, String componentName, String actionName, Map<String, Object> payload, Integer value) { }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param value Duration or other value to include in the log
     */
    public static void log(String featureName, String componentName, String actionName, Integer value) { }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     */
    public static void log(String featureName, String componentName, String actionName) { }

}