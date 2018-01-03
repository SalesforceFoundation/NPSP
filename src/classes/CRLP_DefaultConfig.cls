public class CRLP_DefaultConfig {   // RENAME THIS TO CRLP_ConfigBuilder

    private static final Boolean IS_PROTECTED = false;

    public class FilterGroup {
        public String groupName;
        public String description;
        public Boolean isDeleted;
        public List<FilterRule> rules;

        public FilterGroup(String groupName) {
            this.groupName = groupName;
            this.rules = new List<FilterRule>();
        }

        public String getRecordName() {
            return createValidRecordName(this.groupName);
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CMT_MetadataAPI.MetadataObject.Filter_Group.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + getRecordName();
            customMd.label = this.groupName;
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fldValues = new Map<String, Object>{
                    'Description__c' => this.description,
                    'Is_Deleted__c' => isDeleted
            };
            md = CMT_MetadataAPI.addFieldsToMedataObject(customMd, fldValues);

            return md;
        }

        public List<Metadata.CustomMetadata> getRuleMetadataRecords() {
            List<Metadata.CustomMetadata> rulesMDT = new List<Metadata.CustomMetadata>();
            for (FilterRule fr : rules) {
                rulesMDT.add(fr.getMetadataRecord());
            }
            return rulesMDT;
        }
    }

    public class FilterRule {
        public String groupName;
        public String ruleName;
        public String objectData;   // Object.Field
        public CMT_FilterRule.FilterOperation operation;
        public String value;
        public Boolean isDeleted;

        public FilterRule(String groupName, String ruleName) {
            this.groupName = groupName;
            this.ruleName = ruleName;
        }

        public String getRecordName() {
            return createValidRecordName(this.ruleName);
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CMT_MetadataAPI.MetadataObject.Filter_Rule.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + getRecordName();
            customMd.label = this.ruleName;
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fldValues = new Map<String, Object>{
                    'Filter_Group__c' => createValidRecordName(this.groupName),
                    'Object__c' => parseObjectField(objectData)[0],
                    'Field__c' => objectData,
                    'Operator__c' => operation.name(),
                    'Constant__c' => value,
                    'Is_Deleted__c' => isDeleted
            };
            md = CMT_MetadataAPI.addFieldsToMedataObject(customMd, fldValues);

            return md;
        }
    }

    public class Rollup {
        public String rollupName;
        public String filterGroupName;
        public String description;
        public CRLP_Operation.RollupType operation;
        public CRLP_Operation.YearlyOperationType yearlyOperationType;
        public String summaryData;  // Object.Field
        public String detailData;   // Object.Field
        public String amountData;   // Object.Field
        public String dateData;     // Object.Field
        public Boolean isActive;
        public Boolean isDeleted;
        public Boolean useFiscalYear;
        public Integer intValue;

        public Rollup(String rollupName) {
            this.rollupName = rollupName;
            this.yearlyOperationType = CRLP_Operation.YearlyOperationType.ALL_TIME;
            this.useFiscalYear = false;
            this.isActive = true;
        }

        public String getRecordName() {
            return createValidRecordName(this.rollupName);
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CMT_MetadataAPI.MetadataObject.Rollup.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + getRecordName();
            customMd.label = this.rollupName;
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fldValues = new Map<String, Object>{
                    'Filter_Group__c' => createValidRecordName(this.filterGroupName),
                    'Description__c' => this.description,
                    'Operation__c' => operation.name(),
                    'Yearly_Operation_Type__c' => yearlyOperationType.name(),
                    'Integer__c' => intValue,
                    'Use_Fiscal_Year__c' => useFiscalYear,
                    'Active__c' => isActive,
                    'Deleted__c' => isDeleted,
                    'Summary_Object__c' => parseObjectField(summaryData)[0],
                    'Summary_Field__c' => summaryData,
                    'Detail_Object__c' => parseObjectField(detailData)[0],
                    'Detail_Field__c' => detailData,
                    'Amount_Object__c' => parseObjectField(amountData)[0],
                    'Amount_Field__c' => amountData,
                    'Date_Object__c' => parseObjectField(dateData)[0],
                    'Date_Field__c' => dateData
            };
            md = CMT_MetadataAPI.addFieldsToMedataObject(customMd, fldValues);

            return md;
        }
    }

    public static String createValidRecordName(String label) {
        // replace all special characters and double underscores
        String recordName = label.replaceAll('[^\\w]+', '_').replaceAll('_+', '_');

        //remove leading underscores
        recordName = recordName.left(1) == '_' ? recordName.substring(1) : recordName;

        //remove trailing underscores
        recordName = recordName.right(1) == '_' ? recordName.substring(0,recordName.length()-1) : recordName;

        return recordName;
    }

    public static List<String> parseObjectField(String objField) {
        List<String> parsedValues = new List<String>{ null, null };
        if (objField == null) {
            // return blank values
        } if (objField.contains('.')) {
            parsedValues[0] = objField.split('\\.')[0];
            parsedValues[1] = objField.split('\\.')[1];
        } else {
            parsedValues[0] = objField;
        }
        return parsedValues;
    }

    public static void updateRollupMetadata(List<CMT_MetadataAPI.MetadataObject> cmtData, Object callbackClass) {

    }
}