public with sharing class FORM_RenderWrapper {

    @AuraEnabled public FORM_Template formTemplate; 
    @AuraEnabled public BDI_FieldMappingSet fieldMappingSetWrapper;

    public FORM_RenderWrapper(FORM_Template formTemplate, BDI_FieldMappingSet fieldMappingSetWrapper) {
        this.formTemplate = formTemplate;
        this.fieldMappingSetWrapper = fieldMappingSetWrapper;
    }
}
