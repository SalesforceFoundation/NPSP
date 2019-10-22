public with sharing class GE_FormRendererService {
    public GE_FormRendererService() {

    }

    @AuraEnabled
    public static FORM_RenderWrapper getRenderWrapperById(Id templateId) {
        FORM_Service formService = new FORM_Service();

        // Get the base template
        FORM_Template queriedTemplate = formService.retrieveFormTemplate(templateId);
        
        // Get the mapping service which will retrieve all the mappings
        BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance();
        
        // Create the wrapper which will hold the template and field mapping set. 
        FORM_RenderWrapper renderWrapper = new FORM_RenderWrapper(queriedTemplate, mappingService.fieldMappingSet);

        return renderWrapper;
    }

    @AuraEnabled
    public static FORM_RenderWrapper getDefaultRenderWrapper() {
        FORM_Service formService = new FORM_Service();

        // Get the base template
        FORM_Template queriedTemplate = formService.retrieveDefaultFormTemplate();

        // Get the mapping service which will retrieve all the mappings
        BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance();
        
        // Create the wrapper which will hold the template and field mapping set. 
        FORM_RenderWrapper renderWrapper = new FORM_RenderWrapper(queriedTemplate, mappingService.fieldMappingSet);

        return renderWrapper;
    }
}
