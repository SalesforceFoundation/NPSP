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
* @description Wrapper classes for the Customizable Rollups CustomMetadataType objects used to create the
* default CMT data as well as for updates through the Customizable Rollups UI.
*/
public class CRLP_RollupCMT {

    /**
     * @description When this is set to true, the CMT recordname (DeveloperName) value is auto-generated
     * as a unique random GUID format string. If false, the recordname (DeveloperName) is generated as a 
     * more friendly formatted string value using the label text. The later is ONLY used when generating
     * the default Filter Groups, Rules and Rollups. All customer created records will use the unique GUID.
     */
    public static Boolean useRandomGeneratedDeveloperName = true;

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

    /** ***************************************************************************************************
     * @description Wrapper Class for the Filter_Group__mdt custom metadata type object
     */
    public class FilterGroup {
        public String recordName;
        public String label;
        public String description;
        public Boolean isDeleted;
        public List<FilterRule> rules;

        public FilterGroup(String label) {
            this.label = label.trim();
            this.recordName = generateRecordName(this.label);
            this.rules = new List<FilterRule>();
        }

        public FilterGroup(Filter_Group__mdt groupRecord) {
            this.label = groupRecord.MasterLabel;
            this.recordName = groupRecord.DeveloperName;
            this.isDeleted = groupRecord.Is_Deleted__c;
            this.description = groupRecord.Description__c;
            this.rules = new List<FilterRule>();
        }

        /**
         * @description Convert the wrapper class instance into a valid Metadata.CustomMetadata
         * instance for the Filter_Group.
         * @return Metadata.CustomMetadata instance for deployment
         */
        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CRLP_RollupCMT.MetadataObject.Filter_Group.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
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
            md = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fldValues);

            return md;
        }

        /**
         * @description Retrieve a List of Metadata.CustomMetadata for each attached FilterRule instance
         * @return List<Metadata.CustomMetadata> with one instance per Filter Rule for deployment
         */
        public List<Metadata.CustomMetadata> getRuleMetadataRecords() {
            List<Metadata.CustomMetadata> rulesMDT = new List<Metadata.CustomMetadata>();
            for (FilterRule fr : rules) {
                rulesMDT.add(fr.getMetadataRecord());
            }
            return rulesMDT;
        }
    }

    /** ***************************************************************************************************
     * @description Wrapper Class for the Filter_Rule__mdt custom metadata type object. Includes a property
     * with a list of all attached Filter_Rule instances
     */
    public class FilterRule {
        public String recordName;
        public String label;
        public String filterGroupRecordName;
        public String objectName;
        public String fieldName;
        public String operation;
        public String value;
        public Boolean isDeleted;

        public FilterRule(String filterGroupRecordName, String label) {
            this.label = label.trim();
            this.recordName = generateRecordName(this.label);
            this.filterGroupRecordName = filterGroupRecordName;
        }

        public FilterRule(Filter_Rule__mdt filterRule) {
            this.label = filterRule.MasterLabel;
            this.recordName = filterRule.DeveloperName;
            this.filterGroupRecordName = filterRule.Filter_Group__r.DeveloperName;
            this.operation = filterRule.Operator__c;
            this.objectName = filterRule.Object__r.QualifiedApiName;
            this.fieldName = parseObjectField(filterRule.Field__r.QualifiedApiName)[1];
            this.value = filterRule.Constant__c;
            this.isDeleted = filterRule.Is_Deleted__c;
        }

        /**
         * @description Convert the wrapper class instance into a valid Metadata.CustomMetadata
         * instance for the Filter_Rule.
         * @return Metadata.CustomMetadata instance for deployment
         */
        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CRLP_RollupCMT.MetadataObject.Filter_Rule.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.label = this.label;
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fldValues;
            if (this.isDeleted != true) {
                fldValues = new Map<String, Object>{
                    'Filter_Group__c' => filterGroupRecordName,
                    'Object__c' => this.objectName,
                    'Field__c' => combineObjectAndField(this.objectName, this.fieldName),
                    'Operator__c' => operation,
                    'Constant__c' => value,
                    'Is_Deleted__c' => isDeleted
                };
            } else {
                fldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
            md = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fldValues);

            return md;
        }
    }

    /** ***************************************************************************************************
     * @description Wrapper Class for the Rollup__mdt custom metadata type object
     */
    public class Rollup {
        public String recordName;
        public String label;
        public String filterGroupRecordName;
        public String description;
        public String operation;
        public String yearlyOperationType;
        public String summaryObject;
        public String summaryField;
        public String detailObject;
        public String detailField;
        public String amountObject;
        public String amountField;
        public String dateObject;
        public String dateField;
        public Boolean isActive;
        public Boolean isDeleted;
        public Boolean useFiscalYear;
        public Integer intValue;

        public Rollup(String label) {
            this.label = label.trim();
            this.recordName = generateRecordName(this.label);
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
            this.summaryObject = rlp.Summary_Object__r.QualifiedApiName;
            this.summaryField = parseObjectField(rlp.Summary_Field__r.QualifiedApiName)[1];
            this.detailObject = rlp.Detail_Object__r.QualifiedApiName;
            this.detailField = parseObjectField(rlp.Detail_Field__r.QualifiedApiName)[1];
            this.amountObject = rlp.Amount_Object__r.QualifiedApiName;
            this.amountField = parseObjectField(rlp.Amount_Field__r.QualifiedApiName)[1];
            this.dateObject = rlp.Date_Object__r.QualifiedApiName;
            this.dateField = parseObjectField(rlp.Date_Field__r.QualifiedApiName)[1];
            this.useFiscalYear = rlp.Use_Fiscal_Year__c;
            this.intValue = (rlp.Integer__c != null ? rlp.Integer__c.intValue() : null);
            this.isDeleted = false;
            this.isActive = rlp.Active__c;
        }

        /**
         * @description Convert the wrapper class instance into a valid Metadata.CustomMetadata
         * instance for the Rollup.
         * @return Metadata.CustomMetadata instance for deployment
         */
        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = CRLP_RollupCMT.MetadataObject.Rollup.Name() + '__mdt';

            // Setup custom metadata to be created or udpated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
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
                    'Summary_Object__c' => summaryObject,
                    'Summary_Field__c' => combineObjectAndField(summaryObject, summaryField),
                    'Detail_Object__c' => detailObject,
                    'Amount_Object__c' => amountObject,
                    'Date_Object__c' => dateObject
                };
                if (detailField != null) {
                    fldValues.put('Detail_Field__c', combineObjectAndField(detailObject, detailField));
                }
                if (amountField != null) {
                    fldValues.put('Amount_Field__c', combineObjectAndField(amountObject, amountField));
                }
                if (dateField != null) {
                    fldValues.put('Date_Field__c', combineObjectAndField(dateObject, dateField));
                }
            } else {
                fldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
            md = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fldValues);

            return md;
        }
    }

    /**
     * @description Utility to convert a Label into a valid 'DeveloperName' quality value (or unique GUID)
     * for the CMT record
     * @param label String
     * @return DeveloperName format string
     */
    private static String generateRecordName(String label) {

        if (useRandomGeneratedDeveloperName == false) {
            // replace all special characters and double underscores
            String recordName = label.replaceAll('[^\\w]+', '_').replaceAll('_+', '_');

            //remove leading underscores
            recordName = recordName.left(1) == '_' ? recordName.substring(1) : recordName;

            //remove trailing underscores
            recordName = recordName.right(1) == '_' ? recordName.substring(0, recordName.length() - 1) : recordName;

            return recordName;
        } else {
            // Create a GUID format unique string
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            return 'C' + UserInfo.getUserId().left(15).right(6).toUpperCase() + '_' + h.SubString(8,12) + '_' +
                    h.SubString(12,16) + '_' + h.SubString(16,20) + '_' + h.substring(20);
        }
    }

    /**
     * @description Convert an Object.Field format string into two values List<String>{Object,Field}
     * @param objField Object.Field format string
     * @return List<String>{Object,Field} ; Field may be null if the string only contains an Object name
     */
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

    /**
     * @description Combine an object and a field into a single Object.Field string value; handling the
     * scenario with field is null.
     * @param objName
     * @param fieldName
     * @return Object.Field format string (unless field is null in which case it just returns object)
     */
    private static String combineObjectAndField(String objName, String fieldName) {
        return objName + (fieldName != null ? '.' + fieldName : '');
    }
}