/*******************************************************************************************************
* @description a class to retrieve and save the required information for the Batch Data Import component.
*/
public class GiftBatchView {
    @AuraEnabled public Id id;
    @AuraEnabled public List<GiftView> dataImportRows;
    @AuraEnabled public List<Column> columns;
    @AuraEnabled public Boolean isNamespaced;
    @AuraEnabled public Map<String, String> labels;
    @AuraEnabled public Integer totalCountOfRows;
    @AuraEnabled public Decimal totalRowAmount;
    @AuraEnabled public Decimal batchTotalRowAmount;
    @AuraEnabled public List<UTIL_LightningComponentSupport.Notice> notices =
            new List<UTIL_LightningComponentSupport.Notice>();

    /*******************************************************************************************************
    * @description Retrieves the related list of columns for the BGE interface
    * @return list of Columns to use in BGE_DataImportBatchEntry table
    */
    public void setColumns() {
        List<Column> columns = new List<Column>();

        columns.addAll(getUserDefinedColumns());

        //add derived matched record column
        Column linkCol = new Column();
        linkCol.label = Label.bdiDonation;
        linkCol.fieldName = 'matchedRecordUrl';
        linkCol.readOnly = true;
        linkCol.type = 'url';
        linkCol.typeAttributes = '{"label":{"fieldName":"matchedRecordLabel"},"target":"_blank"}';
        columns.add(linkCol);

        //status of the DI record
        Column statusCol = new Column();
        statusCol.label = Schema.SObjectType.DataImport__c.fields.Status__c.getLabel();
        statusCol.fieldName = Schema.SObjectType.DataImport__c.fields.Status__c.getName();
        statusCol.readOnly = true;
        statusCol.type = 'text';
        columns.add(statusCol);

        this.columns = columns;
    }


    /*******************************************************************************************************
    * @description Retrieves the related list of columns defined by users in the Batch record Active_Fields__c
    * @return list of Columns to use in BGE_DataImportBatchEntry table
    */
    //todo: maybe dont need for bge?
    private List<Column> getUserDefinedColumns() {
        List<Column> columns = new List<Column>();

        DataImportBatch__c batch = [SELECT Active_Fields__c FROM DataImportBatch__c
        WHERE Id = :id];
        String activeFieldsJSON = batch.Active_Fields__c;
        if (activeFieldsJSON != null) {
            List<BGE_ConfigurationWizard_CTRL.BGEField> activeFields =
                    (List<BGE_ConfigurationWizard_CTRL.BGEField>)JSON.deserialize(
                            activeFieldsJSON,
                            List<BGE_ConfigurationWizard_CTRL.BGEField>.class
                    );

            Map<String, Schema.DescribeFieldResult> fieldMap = UTIL_Describe.getAllFieldsDescribe(
                    UTIL_Namespace.StrTokenNSPrefix('DataImport__c')
            );

            List<DescribeFieldResult> unpermittedFields = new List<DescribeFieldResult>();
            Set<String> unmappedFields = new Set<String>();

            for (BGE_ConfigurationWizard_CTRL.BGEField field : activeFields) {
                Schema.DescribeFieldResult dataImportDFR = fieldMap.get(field.name.toLowerCase());
                if (dataImportDFR != null) {

                    if (UTIL_Permissions.canUpdate(dataImportDFR, false)) {

                        String targetObject = '';
                        String targetField = '';
                        BDI_TargetFields targetFields =
                                targetFieldsBySourceField.get(
                                        dataImportDFR.getSObjectField());

                        if (targetFields == null) {
                            if (unmappedFields == null) {
                                unmappedFields = new Set<String>();
                            }
                            unmappedFields.add(field.name);
                            continue;
                        }

                        Map<SObjectType, Set<SObjectField>> targetFieldsByTargetObject =
                                targetFields.getTargetFieldsByTargetObject();

                        // One DI field can be mapped to multiple target fields although it will be rare
                        // and presents some issues with picklists; here we will return info for the first
                        // match
                        for (Schema.SObjectType targetSObjType: targetFieldsByTargetObject.keySet()) {
                            String aTargetObjectName = targetSObjType.getDescribe().getName();
                            if (objectGroupNameByAllowedObjects.containsKey(
                                    aTargetObjectName)) {

                                targetObject = aTargetObjectName;
                                List<SObjectField> mappedTargetFields =
                                        new List<SObjectField> (targetFieldsByTargetObject.get(targetSObjType));
                                if(mappedTargetFields.size() > 0) {
                                    targetField = mappedTargetFields[0].getDescribe().getName();
                                }
                            }
                        }
                        DescribeFieldResult targetDFR = UTIL_Describe.getFieldDescribe(targetObject, targetField);

                        Column col = new Column();

                        col.label = dataImportDFR.label;
                        col.fieldName = dataImportDFR.name;
                        col.defaultValue = field.defaultValue;
                        col.required = field.requiredInEntryForm;
                        col.hide = field.hide;
                        col.type = UTIL_LightningComponentSupport.getLightningDataTableDataType(dataImportDFR.type);
                        // lookups aren't editable in the grid since we don't have lookup support there
                        col.readOnly = col.type == 'reference' ? true : false;
                        col.typeAttributes = '{}';
                        col.options = getPicklistOptions(col.fieldName);

                        if (dataImportDFR.type == Schema.DisplayType.Reference) {
                            if (targetDFR.getReferenceTo() == dataImportDFR.getReferenceTo()) {
                                // manually construct EXTRA column for lookup link
                                Column linkCol = new Column();
                                linkCol.label = dataImportDFR.getLabel();
                                String fieldLabel = dataImportDFR.name + '_label';
                                String fieldName = dataImportDFR.name + '_link';
                                linkCol.fieldName = fieldName;
                                linkCol.readOnly = true;
                                linkCol.required = field.requiredInEntryForm;
                                linkCol.type = 'url';
                                linkCol.typeAttributes = '{"label":{"fieldName":"' + fieldLabel + '"},"target":"_blank"}';

                                columns.add(linkCol);
                                columns.add(col);
                            }
                        } else {
                            columns.add(col);
                        }

                        if (!UTIL_Permissions.canUpdate(targetDFR, false)) {
                            unpermittedFields.add(targetDFR);
                        }
                    } else {
                        unpermittedFields.add(dataImportDFR);
                    }

                }
            }

            GiftBatchService giftBatchService = new GiftBatchService();
            giftBatchService.handleMissingPermissions(unpermittedFields);

            if (!unmappedFields.isEmpty()) {
                notices.add(new UnmappedFieldsNotice(unmappedFields));
            }
        }

        return columns;
    }

    /*******************************************************************************************************
* @description a class to retrieve information related to Active and Available fields.
*/
    public class Column {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean readOnly;
        @AuraEnabled public String type;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean hide;
        @AuraEnabled public String typeAttributes;
        @AuraEnabled public List<Map<String, String>> options;
    }
    /**
    * @description The Notice displayed to the User when fields that are selected for
    * display on the Batch do not have field mappings configured in the Advanced Mapping
    * settings.
    */
    @TestVisible
    private class UnmappedFieldsNotice extends UTIL_LightningComponentSupport.Notice {
        private Set<String> unmappedFieldNames = new Set<String>();

        public UnmappedFieldsNotice(Set<String> unmappedFieldNames) {
            this.unmappedFieldNames = unmappedFieldNames;
            this.header = Label.bgeUnmappedFieldsNoticeHeader;
            this.title = Label.bgeUnmappedFieldsNoticeTitle;
            this.message = getMessage();
            setVariant(UTIL_LightningComponentSupport.Variant.WARNING);
        }

        private String getMessage() {
            String fieldNames = String.join(new List<String>(unmappedFieldNames), ', ');
            String unmappedFieldsTemplate = '';
            String fieldMappingMethod =
                    UTIL_CustomSettingsFacade.getDataImportSettings().Field_Mapping_Method__c;

            if (fieldMappingMethod == BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING) {
                unmappedFieldsTemplate =
                        Label.bgeUnmappedFieldsNoticeMessageAdvancedMapping;
            } else if (fieldMappingMethod == BDI_DataImportService.FM_HELP_TEXT) {
                unmappedFieldsTemplate =
                        Label.bgeUnmappedFieldsNoticeMessageHelpTextMapping;
            }

            return String.format(
                    unmappedFieldsTemplate, new List<String>{
                            fieldNames
                    });
        }
    }

    /*******************************************************************************************************
    * @description Provides field mapping configuration used by BGE
    */
    public static Map<SObjectField, BDI_TargetFields> targetFieldsBySourceField =
            BDI_DataImportService.getDefaultMappingService().getTargetFieldsBySourceField();

    /*******************************************************************************************************
    * @description Currently limit the set of allowed objects, and point to their BDI-defined
    *  Object group name
    */
    public static Map<String, String> objectGroupNameByAllowedObjects = new Map<String,
            String> {
            'Opportunity' => 'Opportunity',
            'npe01__OppPayment__c' => 'Payment'
    };
    /*******************************************************************************************************
     * @description Returns the source field's options formatted for lightning:select if the source field is a picklist
     * or the target field's options if the source field is a string and the target field is a picklist.
     * Returns an empty map if neither case applies.
     */

    public static List<Map<String, String>> getPicklistOptions(String dataImportField){
        List<Map<String, String>> options = new List<Map<String, String>>();

        String dataImportObject = UTIL_Namespace.StrTokenNSPrefix('DataImport__c');

        Schema.DisplayType rawSourceFieldType = UTIL_Describe.getFieldDisplaytype(
                dataImportObject, dataImportField.toLowerCase());

        Schema.DescribeFieldResult sourceFieldDFR = UTIL_Describe.getFieldDescribe(
                dataImportObject, dataImportField.toLowerCase());

        if (rawSourceFieldType == Schema.DisplayType.Picklist) {
            options = UTIL_Describe.getLightningSelectOptions(dataImportObject, dataImportField);

        } else if (rawSourceFieldType == Schema.DisplayType.String) {

            if (targetFieldsBySourceField.containsKey(sourceFieldDFR.getSObjectField())) {
                BDI_TargetFields targetFields = targetFieldsBySourceField.get(sourceFieldDFR.getSObjectField());
                Map<SObjectType, Set<SObjectField>> targetFieldsByTargetObject =
                        targetFields.getTargetFieldsByTargetObject();

                String targetObject = '';
                String targetField = '';

                // One DI field can be mapped to multiple target fields although it will be rare and presents some
                // issues with picklists; here we will return info for the first match
                for (Schema.SObjectType targetSObjType: targetFieldsByTargetObject.keySet()) {
                    String aTargetObjectName = targetSObjType.getDescribe().getName();
                    if (objectGroupNameByAllowedObjects.containsKey(aTargetObjectName)) {
                        targetObject = aTargetObjectName;
                        List<SObjectField> mappedTargetFields =
                                new List<SObjectField> (targetFieldsByTargetObject.get(targetSObjType));
                        if(mappedTargetFields.size() > 0) {
                            targetField = mappedTargetFields[0].getDescribe().getName();
                        }
                    }
                }

                Schema.DisplayType targetFieldType = UTIL_Describe.getFieldDisplaytype(targetObject, targetField);

                if (targetFieldType == Schema.DisplayType.PICKLIST) {
                    options = UTIL_Describe.getLightningSelectOptions(targetObject, targetField);
                } else if (targetField == 'RecordTypeId') {
                    options = UTIL_RecordTypes.getStringRecordTypesForLightningSelect(
                            UTIL_Describe.getSObjectType(targetObject));
                }
            }
        }
        return options;
    }
}
