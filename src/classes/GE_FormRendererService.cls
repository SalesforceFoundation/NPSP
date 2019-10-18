public with sharing class GE_FormRendererService {
    public GE_FormRendererService() {

    }

    /**
     * This method creates a wrapper which contains the template and a field mapping set. 
     * @param  templateName The name of the template to get
     * @return              The JSON string that is stored on the template. 
     */
    public static FORM_RenderWrapper getRenderWrapper(Id templateId) {
        FORM_Service formService = new FORM_Service();

        // Get the base template
        FORM_Template queriedTemplate = formService.retrieveFormTemplate(templateId);
        
        // Get the mapping service which will retrieve all the mappings
        BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance();
        
        // Create the wrapper which will hold the template and field mapping set. 
        FORM_RenderWrapper renderWrapper = new FORM_RenderWrapper(queriedTemplate, mappingService.fieldMappingSet);

        return renderWrapper;
    }
}
