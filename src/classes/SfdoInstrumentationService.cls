public inherited sharing class SfdoInstrumentationService {
    public SfdoInstrumentationService() { }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param payload Map of additional content as context to include in the log (DO NOT INCLUDE PII or NON-GPDR COMPLIANT DATA)
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SfdoInstrumentationEnum.Component componentName, SfdoInstrumentationEnum.Action actionName, Map<String, Object> payload) { 
        SfdoLogUtils.log(featureName.name(), componentName.name(), actionName.name(), payload);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param payload Map of additional content as context to include in the log (DO NOT INCLUDE PII or NON-GPDR COMPLIANT DATA)
     * @param value Duration or other value to include in the log
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SfdoInstrumentationEnum.Component componentName, SfdoInstrumentationEnum.Action actionName, Map<String, Object> payload, Integer value) { 
        SfdoLogUtils.log(featureName.name(), componentName.name(), actionName.name(), payload, value);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     * @param value Duration or other value to include in the log
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SfdoInstrumentationEnum.Component componentName, SfdoInstrumentationEnum.Action actionName, Integer value) { 
        SfdoLogUtils.log(featureName.name(), componentName.name(), actionName.name(), value);
    }

    /**
     * @param featureName - Feature name within the product the log is for
     * @param componentName String - defines the underlying component within the feature
     * @param actionName String - define the action of the feature or component
     */
    public void log(SfdoInstrumentationEnum.Feature featureName, SfdoInstrumentationEnum.Component componentName, SfdoInstrumentationEnum.Action actionName) {
        SfdoLogUtils.log(featureName.name(), componentName.name(), actionName.name());
    }

}
