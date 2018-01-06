/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Wrapper classes for the Customizable Rollups CustomMetadataType objects
*/
public class CRLP_RollupCMT {

    /**
     * @description Enum of the supported MetadataType objects (without the __mdt suffix)
     */
    public enum MetadataObject {
        Rollup,
        Filter_Group,
        Filter_Rule
    }

    /** @description Default value for the Protected_x property when inserting new Custom Metadata Type records */
    private static final Boolean IS_PROTECTED = false;

    public class FilterGroup {
        public String recordName;
        public String label;
        public String description;
        public Boolean isDeleted;
        public List<FilterRule> rules;

        public FilterGroup(String label) {
            this.label = label.trim();
            this.recordName = createValidRecordName(this.label);
            this.rules = new List<FilterRule>();
        }

        public FilterGroup(Filter_Group__mdt groupRecord) {
            this.label = groupRecord.MasterLabel;
            this.recordName = groupRecord.DeveloperName;
            this.isDeleted = groupRecord.Is_Deleted__c;
            this.description = groupRecord.Description__c;
            this.rules = new List<FilterRule>();
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CRLP_RollupCMT.MetadataObject.Filter_Group.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName;
            customMd.label = this.label;
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fldValues;
            if (this.isDeleted != true) {
                fldValues = new Map<String, Object>{
                        'Description__c' => this.description,
                        'Is_Deleted__c' => isDeleted
                };
            } else {
                fldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
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
        public String recordName;
        public String label;
        public String filterGroupRecordName;
        public String objectData;   // Object.Field
        public String operation;
        public String value;
        public Boolean isDeleted;

        public FilterRule(String filterGroupRecordName, String label) {
            this.label = label.trim();
            this.recordName = createValidRecordName(this.label);
            this.filterGroupRecordName = filterGroupRecordName;
        }

        public FilterRule(Filter_Rule__mdt filterRule) {
            this.label = filterRule.MasterLabel;
            this.recordName = filterRule.DeveloperName;
            this.filterGroupRecordName = filterRule.Filter_Group__r.DeveloperName;
            this.operation = filterRule.Operator__c;
            this.objectData = filterRule.Field__c;
            this.value = filterRule.Constant__c;
            this.isDeleted = filterRule.Is_Deleted__c;
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CRLP_RollupCMT.MetadataObject.Filter_Rule.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName;
            customMd.label = this.label;
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fldValues;
            if (this.isDeleted != true) {
                fldValues = new Map<String, Object>{
                    'Filter_Group__c' => filterGroupRecordName,
                    'Object__c' => parseObjectField(objectData)[0],
                    'Field__c' => objectData,
                    'Operator__c' => operation,
                    'Constant__c' => value,
                    'Is_Deleted__c' => isDeleted
                };
            } else {
                fldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
            md = CMT_MetadataAPI.addFieldsToMedataObject(customMd, fldValues);

            return md;
        }
    }

    public class Rollup {
        public String recordName;
        public String label;
        public String filterGroupRecordName;
        public String description;
        public String operation;
        public String yearlyOperationType;
        public String summaryData;  // Object.Field
        public String detailData;   // Object.Field
        public String amountData;   // Object.Field
        public String dateData;     // Object.Field
        public Boolean isActive;
        public Boolean isDeleted;
        public Boolean useFiscalYear;
        public Integer intValue;

        public Rollup(String label) {
            this.label = label.trim();
            this.recordName = createValidRecordName(this.label);
            this.useFiscalYear = false;
            this.isActive = true;
        }

        public Rollup(Rollup__mdt rlp) {
            this.label = rlp.MasterLabel;
            this.recordName = rlp.DeveloperName;
            this.filterGroupRecordName = rlp.Filter_Group__r.DeveloperName;
            this.description = rlp.Description__c;
            this.operation = rlp.Operation__c;
            this.yearlyOperationType = rlp.Yearly_Operation_Type__c;
            this.summaryData = (rlp.Summary_Field__c != null ? rlp.Summary_Field__r.QualifiedApiName : rlp.Summary_Object__r.QualifiedApiName);
            this.detailData = (rlp.Detail_Field__c != null ? rlp.Detail_Field__r.QualifiedApiName : rlp.Detail_Object__r.QualifiedApiName);
            this.amountData = (rlp.Amount_Field__c != null ? rlp.Amount_Field__r.QualifiedApiName : rlp.Amount_Object__r.QualifiedApiName);
            this.dateData = (rlp.Date_Field__c != null ? rlp.Date_Field__r.QualifiedApiName : rlp.Date_Object__r.QualifiedApiName);
            this.useFiscalYear = rlp.Use_Fiscal_Year__c;
            this.intValue = (rlp.Integer__c != null ? rlp.Integer__c.intValue() : null);
            this.isDeleted = false;
            this.isActive = rlp.Active__c;
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CRLP_RollupCMT.MetadataObject.Rollup.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName;
            customMd.label = this.label;
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fldValues;
            if (this.isDeleted != true) {
                fldValues = new Map<String, Object>{
                    'Filter_Group__c' => filterGroupRecordName,
                    'Description__c' => this.description,
                    'Operation__c' => operation,
                    'Yearly_Operation_Type__c' => yearlyOperationType,
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
            } else {
                fldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
            md = CMT_MetadataAPI.addFieldsToMedataObject(customMd, fldValues);

            return md;
        }
    }

    /**
     * @description Utility to convert a Label into a valid 'DeveloperName' quality value for the CMT record
     * @param label String
     * @return DeveloperName format string
     */
    private static String createValidRecordName(String label) {
        // replace all special characters and double underscores
        String recordName = label.replaceAll('[^\\w]+', '_').replaceAll('_+', '_');

        //remove leading underscores
        recordName = recordName.left(1) == '_' ? recordName.substring(1) : recordName;

        //remove trailing underscores
        recordName = recordName.right(1) == '_' ? recordName.substring(0,recordName.length()-1) : recordName;

        return recordName;
    }

    /**
     * @description Convert an Object.Field format string into two values List<String>{Object,Field}
     * @param objField Object.Field format string
     * @return List<String>{Object,Field}
     */
    private static List<String> parseObjectField(String objField) {
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

    // IS THIS NEED?
    /*public static void updateRollupMetadata(List<CMT_MetadataAPI.MetadataObject> cmtData, Object callbackClass) {

    }*/
}