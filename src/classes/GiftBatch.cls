/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Batch entity class in NPSP.
*/

public inherited sharing class GiftBatch {

    private Id batchId;
    private DataImportBatch__c batch;

    private GE_Template.Template formTemplate {
        get {
            if (formTemplate == null) {
                formTemplate =
                    (GE_Template.Template) JSON.deserialize(
                        batch.Form_Template__r.Template_JSON__c,
                        GE_Template.Template.class);
            }
            return formTemplate;
        }
        set;
    }

    private Gifts gifts {
        get {
            if (gifts == null) {
                gifts = new Gifts(giftSelector.getGiftsFor(this.batchId));
            }
            return gifts;
        }
        set;
    }

    private GiftBatchSelector giftBatchSelector {
        get {
            if (giftBatchSelector == null) {
                giftBatchSelector = new GiftBatchSelector();
            }
            return giftBatchSelector;
        }
        set;
    }

    private GiftSelector giftSelector {
        get {
            if (giftSelector == null) {
                giftSelector = new GiftSelector();
            }
            return giftSelector;
        }
        set;
    }

    @TestVisible
    private ElevateBatchService elevateBatchService {
        get {
            if (elevateBatchService == null) {
                elevateBatchService = new ElevateBatchService();
            }
            return elevateBatchService;
        }
        set;
    }

    @TestVisible
    private GiftBatch(Gifts gifts) {
        this.gifts = gifts;
    }

    public GiftBatch(Id batchId) {
        this.batchId = batchId;
        this.batch = giftBatchSelector.selectGiftBatchById(this.batchId);
    }

    public Boolean hasElevateWidget() {
        Boolean hasWidget = false;
        for (GE_Template.Section section : formTemplate.layout.sections) {
            for (GE_Template.Element element : section.elements) {
                if (isElevateWidget(element)) {
                    hasWidget = true;
                }
            }
        }
        return hasWidget;
    }

    private Boolean isElevateWidget(GE_Template.Element element) {
        return element.componentName != null
            && element.componentName == 'geFormWidgetTokenizeCard';
    }

    public void captureAuthorizedGifts() {
        elevateBatchService.enqueuePaymentCaptureJobFor(
            batchId, gifts?.elevateBatchIds());
        gifts.authorizedToPaymentProcessingStatus();
    }

    public void failGiftsWithReason(Map<String, String> failReasonByElevateBatchId) {
        gifts.failGiftsByElevateBatchIdWithReason(failReasonByElevateBatchId);
    }

    public void processGifts() {
        gifts.giftsToProcessingStatus();
        captureAuthorizedGifts();
        BDI_DataImport_API.processDataImportBatches(new List<Id>{batchId});
    }

    public void updateRecords() {
        gifts.updateRecords();
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c fields the Batch Gift Entry UI needs in SOQL
    * @param batchId the batch for which to get all fields for soql
    * @param includeRelationshipFields whether to include relationship fields in the returned list
    * @return List<String> list of DataImport__c field api names
    */
    public List<String> getDataImportFields(Boolean includeRelationshipFields) {
        List<String> fieldApiNames = new List<String>();
        List<String> dataImportCoreFields = getCoreDataImportFields(includeRelationshipFields);

        // Query the Batch to determine which set of fields will be needed.
        // Batches created using BGE_DataImportBatchEntry store fields used by its Data
        // Import records in Active_Fields__c, while Batches created in GE_GiftEntry
        // use fields included in the Form_Template__c record related to the Batch.
        DataImportBatch__c batch = getDataImportBatch(batchId);

        if (!isNewBatchGiftEntryVersion(batch)) {
            fieldApiNames.addAll(getActiveFieldNamesFromBatch(batchId));
            fieldApiNames.addAll(dataImportCoreFields);

            return fieldApiNames;
        }

        fieldApiNames.addAll(getDataImportElevateFields(batchId));
        fieldApiNames.add(getNewBatchGiftEntryVersionFields());

        for (String field : dataImportCoreFields) {
            fieldApiNames.add(field.toLowerCase());
        }

        // Must explicitly use BDI_MappingServiceAdvanced here (as opposed to
        // BDI_DataImportService.getDefaultMappingService()) because of the need
        // to reference the fieldMappingByDevName property.
        fieldApiNames.addAll(getTemplateFields(batch, fieldApiNames));
        return fieldApiNames;
    }

    private String getNewBatchGiftEntryVersionFields() {
        return DataImport__c.Additional_Object_JSON__c.getDescribe().getName();
    }

    private Boolean isNewBatchGiftEntryVersion(DataImportBatch__c batch) {
        return batch.Batch_Gift_Entry_Version__c >= 2.0;
    }

    private DataImportBatch__c getDataImportBatch(Id batchId) {
        DataImportBatch__c batch = [
                SELECT Batch_Gift_Entry_Version__c,
                        Form_Template__r.Template_JSON__c
                FROM DataImportBatch__c
                WHERE Id = :batchId
        ];
        return batch;
    }

    /*******************************************************************************************************
    * @description Returns the subset of DataImport__c fields that are part of every batch
    * @param includeRelationshipFields whether to include relationship fields in the returned list
    * @return List<String>
    */
    private List<String> getCoreDataImportFields(Boolean includeRelationshipFields) {
        List<String> fields = new List<String> {
                'Id',
                'Account1Imported__c',
                'Contact1Imported__c',
                'Donation_Donor__c',
                'DonationImported__c',
                'DonationImportStatus__c',
                'FailureInformation__c',
                'NPSP_Data_Import_Batch__c',
                'PaymentImported__c',
                'PaymentImportStatus__c',
                'Payment_Status__c',
                'Status__c'
        };

        if (includeRelationshipFields) {
            fields.addAll(new List<String> {
                    'Account1Imported__r.Name',
                    'Contact1Imported__r.Name',
                    'DonationImported__r.Name',
                    'PaymentImported__r.Name'
            });
        }

        // Maybe create new method in UTIL_Namespace for lists
        Set<String> namespacedFields = new Set<String>();
        for (String fieldName : fields) {
            namespacedFields.add(UTIL_Namespace.StrAllNSPrefix(fieldName));
        }

        return new List<String> (namespacedFields);
    }

    /*******************************************************************************************************
   * @description parses Active_Fields__c for the list of user-defined fields included in the batch config
   * @param batchId: ID of the NPSP_Data_Import_Batch__c
   * @return list of field api names
   */
    public static List<String> getActiveFieldNamesFromBatch(Id batchId) {
        DataImportBatch__c batch = [SELECT Active_Fields__c FROM DataImportBatch__c WHERE Id = :batchId];
        String activeFieldsJSON = batch.Active_Fields__c;
        List<String> activeFieldNames = new List<String>();

        if (activeFieldsJSON != null) {
            List<BGE_ConfigurationWizard_CTRL.BGEField> activeFields =
                    (List<BGE_ConfigurationWizard_CTRL.BGEField>)JSON.deserialize(
                            activeFieldsJSON,
                            List<BGE_ConfigurationWizard_CTRL.BGEField>.class
                    );
            for (BGE_ConfigurationWizard_CTRL.BGEField field : activeFields) {
                activeFieldNames.add(field.name);
                if (field.type == 'reference') {
                    DescribeFieldResult lookupDFR = UTIL_Describe.getFieldDescribe(
                            UTIL_Namespace.StrTokenNSPrefix('DataImport__c'),
                            field.name.toLowerCase()
                    );
                    String referencedObjectName = lookupDFR.getReferenceTo()[0].getDescribe().name;
                    activeFieldNames.add(field.name.substringBefore('__c') + '__r.' + UTIL_Describe.getNameField(referencedObjectName));
                }
            }
        }

        return activeFieldNames;
    }

    @TestVisible
    private static List<String> getDataImportElevateFields(Id batchId) {
        List<String> elevateFieldApiNames = new List<String>();
        if (GE_PaymentServices.getInstance().isElevateCustomer()
                && hasElevateWidgetOnTemplate(batchId)) {

            elevateFieldApiNames = new List<String>{
                    String.valueOf(DataImport__c.Payment_Declined_Reason__c),
                    String.valueOf(DataImport__c.Elevate_Payment_Status__c)
            };
        }

        return elevateFieldApiNames;
    }

    @TestVisible
    private static GiftBatch giftBatch;

    private static Boolean hasElevateWidgetOnTemplate(Id batchId) {
        if (giftBatch == null) {
            giftBatch = new GiftBatch(batchId);
        }
        return giftBatch.hasElevateWidget();
    }

    private List<String> getTemplateFields(DataImportBatch__c batch, List<String> fieldApiNames) {
        List<String> templateFields = new List<String>();

        BDI_MappingServiceAdvanced mappingService =
                BDI_MappingServiceAdvanced.getInstance();

        Map<String, BDI_FieldMapping> fieldMappingByDevName =
                mappingService.fieldMappingByDevName;

        for (GE_Template.Section formSection : deserializeTemplate(batch).layout.sections) {
            for (GE_Template.Element formElement : formSection.elements) {
                if (formElement.dataImportFieldMappingDevNames == null) {
                    continue;
                }
                // Get the field mappings, used to reference the source fields
                for (String fieldMappingName :
                        formElement.dataImportFieldMappingDevNames) {

                    BDI_FieldMapping fieldMapping =
                            fieldMappingByDevName.get(fieldMappingName);

                    Boolean isObjectMappedLookup = mappingService
                            .importedRecordFieldNames.contains(
                            fieldMappingName.toLowerCase());

                    if (fieldMapping == null && !isObjectMappedLookup) {
                        continue;
                    }
                    String sourceFieldName = fieldMapping != null ?
                            fieldMapping.Source_Field_API_Name :
                            isObjectMappedLookup ?
                                    fieldMappingName : null;
                    SObjectField field = DataImport__c.SObjectType.getDescribe()
                            .fields.getMap().get(sourceFieldName);

                    // Add the source fields used in the Template but only if the source field name is valid
                    if (!fieldApiNames.contains(sourceFieldName.toLowerCase()) && field != null) {
                        templateFields.add(sourceFieldName.toLowerCase());
                    }

                    // Add the Name fields on the related object(s) for all Lookup fields,
                    // used as display value(s) for Lookup fields loaded in the Form UI
                    if ((fieldMapping != null &&
                            fieldMapping.Source_Field_Data_Type == 'REFERENCE')
                            || isObjectMappedLookup) {

                        if (field != null) {
                            String relatedObjNameField =
                                    UTIL_Describe.getReferenceObjectNameField(field);

                            if (relatedObjNameField != null &&
                                    !fieldApiNames.contains(
                                            relatedObjNameField.toLowerCase())) {
                                templateFields.add(relatedObjNameField.toLowerCase());
                            }
                        }
                    }
                }
            }
        }
        return templateFields;
    }

    private static GE_Template.Template deserializeTemplate(DataImportBatch__c batch) {
        GE_Template.Template template = (GE_Template.Template) JSON.deserialize(
                batch.Form_Template__r.Template_JSON__c,
                GE_Template.Template.class
        );
        return template;
    }
}
