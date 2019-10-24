public with sharing class GE_FormRendererService {
    public GE_FormRendererService() {

    }

    @AuraEnabled
    public static FORM_RenderWrapper getRenderWrapperById(Id templateId) {
        FORM_Service formService = new FORM_Service();

        // Get the base template
        FORM_Template queriedTemplate = formService.retrieveFormTemplate(templateId);

        // Create the wrapper which will hold the template and field mapping set.
        FORM_RenderWrapper renderWrapper = wrapTemplate(queriedTemplate);

        return renderWrapper;
    }

    /**
     * This method creates a wrapper which contains the default template and a field mapping set.
     *
     * @return  A FORM_RenderWrapper containing the default template JSON.
     */
    public static FORM_RenderWrapper getDefaultRenderWrapper() {
        FORM_Service formService = new FORM_Service();

        FORM_Template defaultTemplate = formService.retrieveDefaultFormTemplate();

        FORM_RenderWrapper renderWrapper = wrapTemplate(defaultTemplate);

        return renderWrapper;
    }

    private static FORM_RenderWrapper wrapTemplate(FORM_Template template) {
        // Get the mapping service which will retrieve all the mappings
        BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance();

        // Create the wrapper which will hold the template and field mapping set.
        FORM_RenderWrapper renderWrapper = new FORM_RenderWrapper(template, mappingService.fieldMappingSet);

        return renderWrapper;
    }
}
