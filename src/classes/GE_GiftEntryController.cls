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
* @description Controller for the Gift Entry lightning web components and processing
* form save.
*/
public with sharing class GE_GiftEntryController {

    public static final Integer TIMEOUT_STATUS_CODE = 408;
    public static final String TIMED_OUT = 'timed out';
    public static final String PURCHASE_CALL_TIMEOUT_MESSAGE = System.Label.geErrorRequestTimedout;
    private static final String BOOLEAN_DATA_TYPE = 'BOOLEAN';

    @AuraEnabled(cacheable=true)
    public static OrgDomainInfo getOrgDomainInfo() {
        String url = System.Url.getOrgDomainUrl().getHost();
        String[] urlParts = url.split('\\.');
        String podName = [SELECT InstanceName FROM Organization].InstanceName.toLowerCase();
        return new OrgDomainInfo (urlParts[0], podName);
    }

    /*******************************************************************************************************
    * @description Creates and posts an elevate purchase request
    *
    * @param requestBodyParameters: JSON containing parameters for the purchase call request body
    * @param dataImportRecordId: Record ID of the related Data Import
    *
    * @return String: http response wrapper
    */
    @AuraEnabled
    public static String sendPurchaseRequest(String requestBodyParameters, String dataImportRecordId) {
        try {
            GE_PaymentServices paymentServices = new GE_PaymentServices();
            paymentServices.setPurchaseCallBody(requestBodyParameters);
            GE_PaymentServices.ResponseWrapper response = paymentServices.createTransaction();

            return JSON.serialize(response);
        } catch (Exception ex) {
            Boolean isCalloutException = ex instanceof System.CalloutException;
            Boolean hasTimedOut = isCalloutException && ex.getMessage().contains(TIMED_OUT);

            if (hasTimedOut) {
                return getPurchaseCallTimeoutResponse(ex, dataImportRecordId);
            } else {
                String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(ex);
                throw returnDmlException(JSONExceptionData);
            }
        }
    }

    /*******************************************************************************************************
    * @description Creates an http request wrapper for a timeout
    *
    * @param ex: A timeout System.CalloutException
    * @param dataImportRecordId: Record ID of the related Data Import to include in our error logs
    *
    * @return String: http response wrapper
    */
    private static String getPurchaseCallTimeoutResponse(Exception ex, String dataImportRecordId) {
        GE_PaymentServices.ResponseWrapper response = new GE_PaymentServices.ResponseWrapper();
        response.statusCode = TIMEOUT_STATUS_CODE;
        response.status = ex.getMessage();
        response.body = JSON.serialize(new Map<String, String>{ 'message' => PURCHASE_CALL_TIMEOUT_MESSAGE });

        // Log NPSP Error record
        String objectAndRecordId = String.format(
            System.Label.stgErrorInvalidNameFormat,
            new String[] {
                Schema.SObjectType.DataImport__c.getLabel(),
                dataImportRecordId
            });
        ex.setMessage(PURCHASE_CALL_TIMEOUT_MESSAGE + ' ' + objectAndRecordId);
        ERR_Handler.processError(ex, ERR_Handler_API.Context.GE);

        return JSON.serialize(response);
    }

    /*******************************************************************************************************
    * @description Creates an AuraHandledException with the specified error message
    *
    * @param errorMsg contents of the exception error messagae
    *
    * @return AuraHandledException
    */
    public static AuraHandledException returnAuraException(String errorMsg) {
        AuraHandledException ex = new AuraHandledException(errorMsg);
        ex.setMessage(errorMsg);
        return ex;
    }

    /*******************************************************************************************************
    * @description Creates an DmlException with the specified error message
    *
    * @param errorMsg contents of the exception error messagae
    *
    * @return DmlException
    */
    public static DmlException returnDmlException(String errorMsg) {
        DmlException ex = new DmlException(errorMsg);
        ex.setMessage(errorMsg);
        return ex;
    }

    /*******************************************************************************************************
    * @description Saves the data import record, dry runs the record, and returns updated
    * totals with the new row.
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param dataImport: the NPSP_Data_Import__c record to update
    * @return String serialized DataImportModel
    */
    @AuraEnabled
    public static String saveAndDryRunDataImport(Id batchId, DataImport__c dataImport) {

        try {
            dataImport.Additional_Object_JSON__c =
                convertWidgetDataToObjectJSON(dataImport.Additional_Object_JSON__c);
            upsertDataImport(dataImport);
            return BGE_DataImportBatchEntry_CTRL.runSingleDryRun(dataImport.Id, batchId);

        } catch (Exception ex) {
            // create custom lwc exception and throw it
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(ex);

            throw returnDmlException(JSONExceptionData);
        }
    }

    /*******************************************************************************************************
    * @description Saves the data import record, dry runs the record, and returns updated
    * totals with the new row.
    * @param dataImport: the NPSP_Data_Import__c record to update
    * @param updateGift: If true, BDI will attempt to match to an existing opportunity/payment
    * @return String serialized DataImportModel
    */
    @AuraEnabled
    public static Id submitDataImportToBDI(DataImport__c dataImport, Boolean updateGift) {
        // Check for widget data and convert it to the correct format for processing
        dataImport.Additional_Object_JSON__c =
            convertWidgetDataToObjectJSON(dataImport.Additional_Object_JSON__c);

        // Run the BDI process on this new Data Import
        processDataImport(dataImport, false, updateGift);

        // Get the ID of the created Opportunity so we can return it
        Id oppId = getOpportunityIdFromImport(dataImport.Id);

        return oppId;
    }

    /*******************************************************************************************************
    * @description Set DataImport Settings that are important to Gift Entry matching
    * @return Data_Import_Settings__c diSettings object used to process gifts
    */
    private static Data_Import_Settings__c getGiftEntrySettings(Boolean updateGift) {
        Data_Import_Settings__c diSettings = Data_Import_Settings__c.getOrgDefaults();
        // If we are updating an existing gift, set the matching logic accordingly
        diSettings.Donation_Matching_Behavior__c = 
            updateGift ? BDI_DataImport_API.ExactMatchOrCreate : BDI_DataImport_API.DoNotMatch;
        return diSettings;
    }

    /*******************************************************************************************************
    * @description Takes a Data Import record and saves it to the database. If the id is already defined
    * update the record; otherwise, insert it.
    *
    * @param dataImport - The DataImport__c record, as filled in by the user.
    * @return The DataImport__c record that was saved
    */
    @AuraEnabled
    public static DataImport__c upsertDataImport(DataImport__c dataImport) {
        try {
            upsert dataImport Id;

            return dataImport;
        } catch (Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnDmlException(JSONExceptionData);
        }
    }

    /*******************************************************************************************************
    * @description Run the DataImport process on a single gift
    * @param dataImport DataImport record to be processed
    * @param isDryRun Boolean to set if the process should only return import results and not process
    * @param updateGift Boolean to determine our matching criteria.
    *                   true = "single match or create" and means we are updating
    *                   false = "do not match"
    */
    private static void processDataImport(DataImport__c dataImport, Boolean isDryRun, Boolean updateGift) {
        try {

            Data_Import_Settings__c diSettings = getGiftEntrySettings(updateGift);

            List<DataImport__c> listDI = new List<DataImport__c>{dataImport};

            BDI_DataImport_API.processDataImportRecords(diSettings, listDI, isDryRun);
        } catch (Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnDmlException(JSONExceptionData);
        }
    } 

    /*******************************************************************************************************
    * @description Return the imported Opportunity (Donation) from a DataImport process
    * @param dataImportId Id of DataImport object that created or matching this Opportunity
    * @return Id of the Opportunity
    */
    private static String getOpportunityIdFromImport(Id dataImportId) {
        try {
            DataImport__c di = [
                    SELECT DonationImported__c,
                            FailureInformation__c
                    FROM DataImport__c
                    WHERE Id = :dataImportId
            ];
            if(di.FailureInformation__c != null) {
                throw new BDIException(di.FailureInformation__c);
            }
            return di.DonationImported__c;
        } catch(Exception e) {

            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnAuraException(JSONExceptionData);
        }
    }

    @AuraEnabled
    public static Boolean isElevateCustomer() {
        try {
            return GE_PaymentServices.isElevateCustomer;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class OrgDomainInfo {
        @AuraEnabled public String orgDomain;
        @AuraEnabled public String podName;

        public OrgDomainInfo (String orgDomain, String podName) {
            this.orgDomain = orgDomain;
            this.podName = podName;
        }
    }

    /*******************************************************************************************************
    * @description Retrieves all open Opportunities, and Opportunities with unpaid Payments, for the
    * selected Donor (Account or Contact)
    * @return JSON stringified Map<String, List<SObject>> of all openOpportunities for the given donor
    */
    @AuraEnabled(cacheable=true)
    public static String getOpenDonations(Id donorId, String donorType) {
        if (donorId == null) {
            return null;
        }

        String relationshipField;
        if (donorType == SObjectType.Account.Name) {
            relationshipField = SObjectType.Opportunity.fields.AccountId.Name;
        } else if (donorType == SObjectType.Contact.Name) {
            relationshipField = SObjectType.Opportunity.fields.Primary_Contact__c.Name;
        }

        // Could eventually be used to display unpaid payments on the donation matching modal
        String paymentSOQL = 'SELECT Id, ' +
                'Name, ' +
                'npe01__Scheduled_Date__c, ' +
                'npe01__Opportunity__r.Name, ' +
                'npe01__Opportunity__c, ' +
                'npe01__Payment_Amount__c ' +
                'FROM npe01__OppPayment__c ' +
                'WHERE npe01__Opportunity__r.' + relationshipField + ' = :donorId ' +
                'AND npe01__Written_Off__c = false ' +
                'AND npe01__Paid__c = false ' +
                'WITH SECURITY_ENFORCED';

        try {
            // CRUD / FLS of this operation already verified by checkCRUDFLS()
            List<npe01__OppPayment__c> unpaidPayments = Database.query(paymentSOQL);
            Set<Id> oppIdsWithUnpaidPayments = new Set<Id>();
            for (npe01__OppPayment__c payment : unpaidPayments) {
                oppIdsWithUnpaidPayments.add(payment.npe01__Opportunity__c);
            }

            String opportunitySOQL = 'SELECT Id, ' +
                    'Name, ' +
                    'StageName, ' +
                    'CloseDate, ' +
                    'IsClosed, ' +
                    'Amount, ' +
                    'npe01__Number_of_Payments__c, ' +
                    '(SELECT Id, ' +
                    'Name, ' +
                    'npe01__Scheduled_Date__c, ' +
                    'npe01__Opportunity__r.Name, ' +
                    'npe01__Opportunity__c, ' +
                    'npe01__Payment_Amount__c,' +
                    'npe01__Paid__c, ' +
                    'npe01__Written_Off__c ' +
                    'FROM npe01__OppPayment__r ' +
                    'WHERE npe01__Written_Off__c = false ' +
                    'AND npe01__Paid__c = false)' +
                    'FROM Opportunity ' +
                    'WHERE ' + relationshipField + ' = :donorId ' +
                    'AND IsClosed = false ' +
                    'WITH SECURITY_ENFORCED ' +
                    'ORDER BY CloseDate ASC';

            // CRUD / FLS of this operation already verified by checkCRUDFLS()
            List<Opportunity> openOpportunities = Database.query(opportunitySOQL);

            List<OpportunityWrapper> opportunityWrappers = new List<OpportunityWrapper>();
            for (Opportunity opportunity : openOpportunities) {
                opportunityWrappers.add(new OpportunityWrapper(opportunity));
            }

            return JSON.serialize(opportunityWrappers);
        } catch (Exception ex){
            returnAuraException(ex.getMessage());
        }

        return null;
    }

    /**
    * @description Wrapper class used to hold only the information needed in the
    * component for each Opportunity.  The component does not need to store any of
    * the paid or written-off Payments for a donor, but it does need to know if the Donation
    * has related Payments that have not been written-off. In that case the User should not
    * be able to update the Opportunity in the BGE Donation Selector.
    */
    @TestVisible
    private class OpportunityWrapper {
        @TestVisible Opportunity opportunity {get; private set;}
        @TestVisible List<npe01__OppPayment__c> unpaidPayments {get; private set;}
        @TestVisible Boolean hasNonWrittenOffPayments {get; private set;}

        private OpportunityWrapper(Opportunity opportunity) {
            this.opportunity = opportunity;
            initialize();
        }

        private void initialize() {
            if (unpaidPayments == null) {
                unpaidPayments = new List<npe01__OppPayment__c>();
            }

            if (opportunity.npe01__OppPayment__r.isEmpty()) {
                hasNonWrittenOffPayments = false;
                return;
            }

            for (npe01__OppPayment__c oppPayment : opportunity.npe01__OppPayment__r) {
                if (hasNonWrittenOffPayments == null
                        && oppPayment.npe01__Written_Off__c == false) {
                    hasNonWrittenOffPayments = true;
                }

                if (isAvailableForUpdate(oppPayment)) {
                    unpaidPayments.add(oppPayment);
                } else {
                    continue;
                }
            }

            //If hasNonWrittenOffPayments is null after looping all of the Payments,
            //then all of the Opp's Payments are written-off, and hasNonWrittenOffPayments can
            //be set to false, as this Opp should be treated in the BGE Donation Selector UI
            //as if it has 0 Payments.
            if (hasNonWrittenOffPayments == null) {
                hasNonWrittenOffPayments = false;
            }
        }

        private Boolean isAvailableForUpdate(npe01__OppPayment__c oppPayment) {
            if (oppPayment.npe01__Paid__c || oppPayment.npe01__Written_Off__c) {
                return false;
            } else {
                return true;
            }
        }
    }

    @AuraEnabled
    public static RenderWrapper getRenderWrapperById(Id templateId) {
        // Get the base template
        FORM_Template queriedTemplate = FORM_ServiceGiftEntry.retrieveFormTemplateById(templateId);

        // Create the wrapper which will hold the template and field mapping set.
        RenderWrapper renderWrapper = wrapTemplate(queriedTemplate);

        return renderWrapper;
    }

    /**
     * This method creates a wrapper which contains the  template selected by name and a field mapping set.
     * If the template is not found, it returns a wrapper for the default template
     * @param String templateName
     * @return  A RenderWrapper containing the default template JSON.
     */
    public static RenderWrapper getRenderWrapper(String templateName) {
        FORM_Template template = FORM_ServiceGiftEntry.retrieveFormTemplateById(templateName);

        RenderWrapper renderWrapper = wrapTemplate(template);

        return renderWrapper;
    }

    /**
     * This method creates a wrapper which contains the default SGE template and a field mapping set.
     *
     * @return  A RenderWrapper containing the default template JSON.
     */
    public static RenderWrapper getDefaultSGERenderWrapper() {
        FORM_Template defaultTemplate = FORM_ServiceGiftEntry.retrieveDefaultSGEFormTemplate();

        RenderWrapper renderWrapper = wrapTemplate(defaultTemplate);

        return renderWrapper;
    }

    /**
     * This method builds the wrapper given the template and the field mapping set.
     *
     * @return  A RenderWrapper containing the default template JSON.
     */
    private static RenderWrapper wrapTemplate(FORM_Template template) {
        if (template != null) {
            Boolean includeUnmappedFields = true;
            // Get the mapping service which will retrieve all the mappings
            BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance(includeUnmappedFields);

            updateTemplateWithRequired(template, mappingService.fieldMappingSet);

            // Create the wrapper which will hold the template and field mapping set.
            RenderWrapper renderWrapper = new RenderWrapper(template, mappingService.fieldMappingSet);

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
        List<FORM_Template.Section> sectionList = template.layout.sections;

        for (FORM_Template.Section section : sectionList) {

            // Go through all the elements
            for (FORM_Template.Element element : section.elements) {
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
    @TestVisible
    private static String convertWidgetDataToObjectJSON(String widgetData) {

        if (String.isBlank(widgetData)) {
            return null;
        }

        BDI_MappingServiceAdvanced mappingService = BDI_MappingServiceAdvanced.getInstance();
        Map<String, BDI_DynamicSource> dynamicSourceByObjMappingDevName = new Map<String, BDI_DynamicSource>();
        BDI_DynamicSourceGroup dynSourceGroup = new BDI_DynamicSourceGroup();

        dynSourceGroup.name = DataImport__c.Additional_Object_JSON__c.getDescribe().getName();
        dynSourceGroup.dynamicSourceByObjMappingDevName = dynamicSourceByObjMappingDevName;

        Map<String, Object> objMappingDevNameToObjList;

        try {
            objMappingDevNameToObjList = (Map<String, Object>) JSON.deserializeUntyped(widgetData);
        } catch (Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnAuraException(JSONExceptionData);
        }

        // Create a map of sobject type to sobject list for processing
        for (String objMappingDevName : objMappingDevNameToObjList.keySet()) {
            Object objList = objMappingDevNameToObjList.get(objMappingDevName);

            BDI_ObjectMapping objMapping = mappingService.objectMappingByDevName.get(objMappingDevName);

            BDI_FieldMapping[] fieldMappings = mappingService.fieldMappingsByObjMappingDevName.get(objMappingDevName);

            String[] tempObjStrings = new String[]{
            };

            //Reserializing the object strings to resolve platform issue with deserializing SObjects
            for (Object obj : (List<Object>) objMappingDevNameToObjList.get(objMappingDevName)) {
                tempObjStrings.add(JSON.serialize(obj));
            }

            if (tempObjStrings != null && tempObjStrings.size() > 0) {

                Integer i = 0;
                //Loop through the sObjects and construct DI records to hold the data in the expected fields
                for (String objString : tempObjStrings) {

                    SObject sObj = (SObject) JSON.deserialize(objString, Sobject.class);

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

                    dynamicSourceByObjMappingDevName.put(dynSource.objectMappingDevName, dynSource);
                }
            }
        }

        if (dynSourceGroup.dynamicSourceByObjMappingDevName.size() > 0) {
            String dynSourceGroupString = JSON.serialize(dynSourceGroup);
            return dynSourceGroupString;
        }
        return null;
    }

    /**
     * @description Returns a render wrapper containing the Advanced Mapping field and
     * object mappings and a Gift Entry form template, which is either the default
     * or the one whose Id is passed in as templateId.
     *
     * @param templateId Id of the target Form_Template__c.
     *
     * @return The render wrapper containing the target template or the default
     * template if templateId is null.
     */
    @AuraEnabled(cacheable=true)
    public static RenderWrapper getFormRenderWrapper(Id templateId) {
        try {
            if (templateId != null) {
                return getRenderWrapperById(templateId);
            } else {
                return getDefaultSGERenderWrapper();
            }
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.initCause(e);
            throw ex;
        }
    }

    /**
     * @description Retrieves the default SGE render wrapper for gift entry.
     * @return      A render wrapper containing a template and information about the object/field mappings.
     */
    @AuraEnabled
    public static RenderWrapper retrieveDefaultSGERenderWrapper() {
        return GE_GiftEntryController.getDefaultSGERenderWrapper();
    }

    public class RenderWrapper {

        @AuraEnabled public FORM_Template formTemplate;
        @AuraEnabled public BDI_FieldMappingSet fieldMappingSetWrapper;

        public RenderWrapper(FORM_Template formTemplate, BDI_FieldMappingSet fieldMappingSetWrapper) {
            this.formTemplate = formTemplate;
            this.fieldMappingSetWrapper = fieldMappingSetWrapper;
        }
    }

    private class BDIException extends Exception {}
}
