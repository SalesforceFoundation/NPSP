/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group HGE
* @group-content
* @description Controller for the Gift Entry Form
*/
public with sharing class GE_FormRendererService {

    private static final String BOOLEAN_DATA_TYPE = 'BOOLEAN';

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
     * This method creates a wrapper which contains the  template selected by name and a field mapping set.
     * If the template is not found, it returns a wrapper for the default template
     * @param String templateName
     * @return  A FORM_RenderWrapper containing the default template JSON.
     */
    public static FORM_RenderWrapper getRenderWrapper(String templateName) {
        FORM_Service formService = new FORM_Service();

        FORM_Template template = formService.retrieveFormTemplate(templateName);

        FORM_RenderWrapper renderWrapper = wrapTemplate(template);

        return renderWrapper;
    }

    /**
     * This method creates a wrapper which contains the default SGE template and a field mapping set.
     *
     * @return  A FORM_RenderWrapper containing the default template JSON.
     */
    public static FORM_RenderWrapper getDefaultSGERenderWrapper() {
        FORM_Service formService = new FORM_Service();

        FORM_Template defaultTemplate = formService.retrieveDefaultSGEFormTemplate();

        FORM_RenderWrapper renderWrapper = wrapTemplate(defaultTemplate);

        return renderWrapper;
    }

    /**
     * This method builds the wrapper given the template and the field mapping set. 
     *
     * @return  A FORM_RenderWrapper containing the default template JSON.
     */
    private static FORM_RenderWrapper wrapTemplate(FORM_Template template) {
        if (template != null) {
            Boolean includeUnmappedFields = true;
            // Get the mapping service which will retrieve all the mappings
            BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance(includeUnmappedFields);

            updateTemplateWithRequired(template, mappingService.fieldMappingSet);

            // Create the wrapper which will hold the template and field mapping set.
            FORM_RenderWrapper renderWrapper = new FORM_RenderWrapper(template, mappingService.fieldMappingSet);

            return renderWrapper;
        } else {
            return null;
        }
    }

    /**
     * Get Allocations settings. Used to determine the default GAU, and if the default GAU is enabled.
     * This result cannot be cached as there is the potential for an upsert operation when no allocation settings exist.
     * @return An Allocation_Settings__c custom setting record
     */
    @AuraEnabled
    public static Allocations_Settings__c getAllocationsSettings() {
        return UTIL_CustomSettingsFacade.getAllocationsSettings();
    }

    /*******************************************************************************************************
    * @description Takes the template and field mappings and updates the template so that the required fields are set
    * as required. 
    * @param template - The deserailized template that is stored. 
    * @param fieldMappingSet The field mapping set which determines what DI field is mapped to what target field. 
    */
    private static void updateTemplateWithRequired(FORM_Template template, BDI_FieldMappingSet fieldMappingSet) {
        List<FORM_Section> sectionList = template.layout.sections;

        for (FORM_Section section : sectionList) {
    
            // Go through all the elements
            for (FORM_Element element : section.elements) {
                if (element.dataImportFieldMappingDevNames != null 
                    && !element.dataImportFieldMappingDevNames.isEmpty()) {
                    
                    if (fieldMappingSet.fieldMappingByDevName.containsKey(element.dataImportFieldMappingDevNames[0])) {
                        BDI_FieldMapping fieldMapping = fieldMappingSet.fieldMappingByDevName.get(element.dataImportFieldMappingDevNames[0]);

                        // Update the element's required by doing an OR between the element's required, DI source field, target field
                        // Update the element's required to make sure we are respecting the source/target/template builder's required
                        // with the most up to date information. 
                        element.required = element.required || 
                            (fieldMapping.Source_Field_Required &&
                                     fieldMapping.Source_Field_Data_Type != BOOLEAN_DATA_TYPE);
                    }
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Work in Progress to deliver widget behaviors
    * @return Widget data
    */
    public static String convertWidgetDataToObjectJSON(String widgetData) {

        if (String.isBlank(widgetData)) {
            return null;
        }

        BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance();
        Map<String,BDI_DynamicSource> dynamicSourceByObjMappingDevName = new Map<String,BDI_DynamicSource>();
        BDI_DynamicSourceGroup dynSourceGroup = new BDI_DynamicSourceGroup();

        dynSourceGroup.name = DataImport__c.Additional_Object_JSON__c.getDescribe().getName();
        dynSourceGroup.dynamicSourceByObjMappingDevName = dynamicSourceByObjMappingDevName;

        Map<String, Object> objMappingDevNameToObjList;

        try {
            objMappingDevNameToObjList = (Map<String, Object>)JSON.deserializeUntyped(widgetData);
        } catch(Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);
            
            throw GE_GiftEntryController.returnAuraException(JSONExceptionData);
        }

        // Create a map of sobject type to sobject list for processing
        for (String objMappingDevName : objMappingDevNameToObjList.keySet()) {
            Object objList = objMappingDevNameToObjList.get(objMappingDevName);

            BDI_ObjectMapping objMapping = mappingService.objectMappingByDevName.get(objMappingDevName);

            BDI_FieldMapping[] fieldMappings = mappingService.fieldMappingsByObjMappingDevName.get(objMappingDevName);

            String[] tempObjStrings = new String[]{};

            //Reserializing the object strings to resolve platform issue with deserializing SObjects
            for (Object obj : (List<Object>)objMappingDevNameToObjList.get(objMappingDevName)){
                tempObjStrings.add(JSON.serialize(obj));
            }

            if(tempObjStrings != null && tempObjStrings.size() > 0) {

                Integer i = 0;
                //Loop through the sObjects and construct DI records to hold the data in the expected fields
                for (String objString : tempObjStrings) {

                    SObject sObj = (SObject)JSON.deserialize(objString, Sobject.class);

                    i++;
                    DataImport__c tempDI = new DataImport__c();

                    //Reverse mapping the fields back onto a tempDI Record that respresents the source obj.
                    for (BDI_FieldMapping fieldMapping : fieldMappings) {
                        Object value = sObj.get(fieldMapping.Target_Field_API_Name);
                        tempDI.put(fieldMapping.Source_Field_API_Name, value);
                    }

                    BDI_DynamicSource dynSource = new BDI_DynamicSource();
                    dynSource.objectMappingDevName = objMapping.DeveloperName + 'temp' + i;
                    dynSource.objectMappingTemplateDevName = objMapping.DeveloperName;
                    dynSource.fieldMappingSetDevName = mappingService.fieldMappingSetName;
                    dynSource.sourceObj = tempDI;

                    dynamicSourceByObjMappingDevName.put(dynSource.objectMappingDevName,dynSource);
                }
            }
        }

        if (dynSourceGroup.dynamicSourceByObjMappingDevName.size() > 0) {
            String dynSourceGroupString = JSON.serialize(dynSourceGroup);
            return dynSourceGroupString;
        }
        return null;
    }

}
