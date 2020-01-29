public with sharing class GE_FormRendererService {

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
                        element.required = element.required || fieldMapping.Source_Field_Required;
                    }
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Takes a Data Import record from the Gift Entry form and saves it to the database.
    * @param diRecord - The DataImport__c record, as filled in by the user.
    * @return The Id of the new Opportunity record, created from the Data Import
    */
    @AuraEnabled
    public static Id saveAndProcessSingleGift(DataImport__c diRecord, String widgetData, Boolean updateGift) {

        // Check for widget data and convert it to the correct format for processing
        String additionalObjectJSON = convertWidgetDataToObjectJSON(widgetData);
        diRecord.Additional_Object_JSON__c = additionalObjectJSON;

        // Save the Data Import record to the Database
        diRecord = saveDataImport(diRecord);

        // Run the BDI process on this new Data Import
        runGiftProcess(diRecord, false, updateGift);

        // Get the ID of the created Opportunity so we can return it
        Id oppId = getOpportunityIdFromImport(diRecord.Id);

        return oppId;

    }

    private static String convertWidgetDataToObjectJSON(String widgetData) {
        // System.debug('widgetData: '); 
        // System.debug(widgetData); 

        if(String.isBlank(widgetData)){
            return null;
        }

        Map<String, Object> objNameToObjList;
        List<SObject> thisList;
        try {
            objNameToObjList = (Map<String, Object>)JSON.deserializeUntyped(widgetData);
        } catch(Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);
            
            throw returnAuraException(JSONExceptionData);
        }

        // Create a map of sobject type to sobject list for processing
        for(String widgetKey : objNameToObjList.keySet()) {
            Object objList = objNameToObjList.get(widgetKey);
            if(objList != null) {
                String objListString = JSON.serialize(objList);

                // System.debug(widgetKey); 
                // System.debug(objListString); 

                // TODO: Depending on how data gets passed, this will change
                //Type listType = Type.forName('List<' + objName + '>');
                //thisList = (List<SObject>)JSON.deserialize(objListString, listType);
                
                // Might not need this, could be provided by N-object logic?
                // String lookupField = opportunityLookupMap.get(objName);
                // for(SObject relObj : thisList){
                //     relObj.put(lookupField, oppId);
                // }
            }
        }

        // TODO: Fit widget data into a series of Data Import records, and prepare them for Additional_Object_JSON__c
        // See BDI_AdditionalObjectService_TEST for an example of this process (dynamicParentAdditionalObjectsShouldBeCreated)
        
        // String additionalObjJSONFieldName = UTIL_Namespace.alignSchemaNSWithEnvironment('npsp__Additional_Object_JSON__c');
        // Create BDI_DynamicSourceGroup
        // Map of <String,BDI_DynamicSource>
        // JSON.serialize(dynSourceGroupA);

        return null;
    }

    /*******************************************************************************************************
    * @description Takes a Data Import record and saves it to the database.
    * @param diRecord - The DataImport__c record, as filled in by the user.
    * @return The DataImport__c record that was saved
    */
    private static DataImport__c saveDataImport(DataImport__c diRecord) {
        try {
            insert diRecord;
            return diRecord;
        } catch(Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnAuraException(JSONExceptionData);
        }
    }

    /*******************************************************************************************************
    * @description Run the DataImport process on a single gift
    * @param @param diRecord DataImport record to be processed
    * @param isDryRun Boolean to set if the process should only return import results and not process
    * @return void
    */
    public static void runGiftProcess(DataImport__c diRecord, Boolean isDryRun, Boolean updateGift) {
        Id diRecordId = diRecord.Id;

        Data_Import_Settings__c diSettings = getGiftEntrySettings(updateGift);

        List<DataImport__c> listDI = new List<DataImport__c>{diRecord};

        BDI_DataImport_API.processDataImportRecords(diSettings, listDI, isDryRun);
    }

    /*******************************************************************************************************
    * @description Return the imported Opportunity (Donation) from a DataImport process
    * @param diObjId Id of DataImport object that created or matching this Opportunity
    * @return Id of the Opportunity
    */
    private static String getOpportunityIdFromImport(Id diRecordId) {
        try {
            DataImport__c di = [
                    SELECT DonationImported__c,
                            FailureInformation__c
                    FROM DataImport__c
                    WHERE Id = :diRecordId
            ];
            if(di.FailureInformation__c != null) {
                String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(di.FailureInformation__c);

                throw returnAuraException(JSONExceptionData);
            }
            return di.DonationImported__c;
        } catch(Exception e) {
            String JSONExceptionData = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            throw returnAuraException(JSONExceptionData);
        }
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

    private static AuraHandledException returnAuraException(String errorMsg) {
        AuraHandledException ex = new AuraHandledException(errorMsg);
        ex.setMessage(errorMsg);
        return ex;
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
        if (donorType == 'account') {
            relationshipField = 'AccountId';
        } else if (donorType == 'contact') {
            relationshipField = 'npsp__Primary_Contact__c';
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
                                'AND npe01__Paid__c = false';

        try {
            // CRUD / FLS of this operation already verified by checkCRUDFLS()
            List<npe01__OppPayment__c> unpaidPayments = Database.query(paymentSOQL);
            System.debug('unpaidPayments: ' + unpaidPayments.size());
            Set<Id> oppIdsWithUnpaidPayments = new Set<Id>();
            for (npe01__OppPayment__c payment : unpaidPayments) {
                oppIdsWithUnpaidPayments.add(payment.npe01__Opportunity__c);
            }

            // We want to include Open Opportunities, as well as Closed Opportunities with unpaid payments
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
                'AND (IsClosed = false OR Id in :oppIdsWithUnpaidPayments) ' +
                'ORDER BY CloseDate ASC ';

            // CRUD / FLS of this operation already verified by checkCRUDFLS()
            List<Opportunity> openOpportunities = Database.query(opportunitySOQL);

            List<OpportunityWrapper> opportunityWrappers = new List<OpportunityWrapper>();
            for (Opportunity opportunity : openOpportunities) {
                opportunityWrappers.add(new OpportunityWrapper(opportunity));
            }

            return JSON.serialize(opportunityWrappers);
        } catch (Exception ex){
            //throw new AuraHandledException(System.Label.Error + ': ' + ex.getMessage());
            System.debug(ex.getMessage());
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

}
