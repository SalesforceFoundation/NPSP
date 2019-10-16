public with sharing class GE_FormRendererService {
    public GE_FormRendererService() {

    }

    /**
     * This method queries the template sObject and gets the JSON and passes that to the front end.
     * @param  templateName The name of the template to get
     * @return              The JSON string that is stored on the template. 
     */
    public static FORM_Template getTemplateForRender(Id templateId) {
        FORM_Service formService = new FORM_Service();

        // Get the base template
        FORM_Template queriedTemplate = formService.retrieveFormTemplate(templateId);
        Set<String> dataImportFieldMappingDevNames = new Set<String>();
        Map<String, FORM_MappingWrapper> fieldMappingNameToMappingWrapper = new Map<String, FORM_MappingWrapper>();

        // Traverse through the template to find all the mappings necessary
        FORM_Layout formLayout = queriedTemplate.layout;
        List<FORM_Section> formSections = formLayout.sections;

        for (FORM_Section formSection : formSections) {
            List<FORM_Element> formElements = formSection.elements;
            
            for (FORM_Element formElement : formElements) {
                dataImportFieldMappingDevNames.addAll(formElement.dataImportFieldMappingDevNames);
            }
        }

        // Get the mappings
        List<Data_Import_Field_Mapping__mdt> fieldMappingCMTRecords = [SELECT Is_Deleted__c, Required__c, Source_Field_API_Name__c, 
                                                                            Target_Field_API_Name__c, Target_Object_Mapping__c,
                                                                            Target_Object_Mapping__r.Object_API_Name__c
                                                                        FROM Data_Import_Field_Mapping__mdt
                                                                        WHERE QualifiedApiName in: dataImportFieldMappingDevNames];

        // Create the mapping of Mapping Record name to wrapper class
        for (Data_Import_Field_Mapping__mdt fieldMappingCMTRecord : fieldMappingCMTRecords) {
            FORM_MappingWrapper mappingWrapper = new FORM_MappingWrapper(fieldMappingCMTRecord);

            fieldMappingNameToMappingWrapper.put(fieldMappingCMTRecord.QualifiedApiName, mappingWrapper);
        }



        // Add the wrapper class mapping into the form template
        queriedTemplate.fieldMappingNameToMappingWrapper = fieldMappingNameToMappingWrapper;
        


        return queriedTemplate;
    }
}
