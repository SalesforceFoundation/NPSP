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
        public String recordId;
        public String label;
        public String description;
        public Boolean isDeleted = false;
        public List<FilterRule> rules;

        public FilterGroup(String label) {
            this.label = label.trim();
            this.recordName = generateRecordName(this.label, false);
            this.rules = new List<FilterRule>();
        }

        public FilterGroup(Filter_Group__mdt groupRecord) {
            this.label = groupRecord.MasterLabel;
            this.recordName = groupRecord.DeveloperName;
            this.description = groupRecord.Description__c;
            this.rules = new List<FilterRule>();
            try {
                this.recordId = groupRecord.Id;
                this.isDeleted = groupRecord.Is_Deleted__c;
            } catch (Exception ex) {}
        }


        /******************************************************************************************************************
        * @description Adds rules to the Filter Group
        ******************************************************************************************************************/
        public FilterGroup withRules(List<Filter_Rule__mdt> ruleMdts) {
            for (Filter_Rule__mdt ruleMdt : ruleMdts) {
                FilterRule rule = new FilterRule(ruleMdt);
                this.rules.add(rule);
            }
            return this;
        }

        /**
         * @description Convert the wrapper class instance into a valid Metadata.CustomMetadata
         * instance for the Filter_Group.
         * @return Metadata.CustomMetadata instance for deployment
         */
        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = UTIL_Namespace.StrTokenNSPrefix(CRLP_RollupCMT.MetadataObject.Filter_Group.Name() + '__mdt');

            if (this.recordName == null) {
                this.recordName = generateRecordName(this.label, true);
            }

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.label = this.label.left(40);
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

        /**************************************************************************************************************
        * @description Determines if a Filter Group is computationally different from another Filter Group
        * changes in name or label or description are not considered different
        * filter rules are hashed because the sort order of the list is not guaranteed
        * @param other FilterGroup to compare against
        * @return boolean to indicate of the filter group is different
        **************************************************************************************************************/
        public Boolean isDifferent(FilterGroup other) {
            if (this.rules.size() != other.rules.size()) {
                return true;
            }

            Map<String, FilterRule> rulesByHash = new Map<String, FilterRule>();

            for (Integer i = 0; i < other.rules.size(); i++) {
                FilterRule otherRule = other.rules[i];
                rulesByHash.put(otherRule.generateHash(), other.rules[i]);
            }

            for (Integer i = 0; i < this.rules.size(); i++) {
                FilterRule currentRule = this.rules[i];
                if (!rulesByHash.containsKey(currentRule.generateHash())) {
                    return true;
                }
            }


            return false;
        }
    }

    /** ***************************************************************************************************
     * @description Wrapper Class for the Filter_Rule__mdt custom metadata type object. Includes a property
     * with a list of all attached Filter_Rule instances
     */
    public class FilterRule {
        public String recordName;
        public String recordId;
        public String label;
        public String filterGroupRecordName;
        public String objectName;
        public String objectLabel;
        public String fieldName;
        public String fieldLabel;
        public String operationName;
        public String operationLabel;
        public String value;
        public String valueLabel;
        public Boolean isDeleted = false;

        public FilterRule(String filterGroupRecordName, String label) {
            this.label = label.trim();
            this.recordName = generateRecordName(this.label, false);
            this.filterGroupRecordName = filterGroupRecordName;
        }

        public FilterRule(Filter_Rule__mdt filterRule) {
            this.label = filterRule.MasterLabel;
            this.recordName = filterRule.DeveloperName;
            this.filterGroupRecordName = filterRule.Filter_Group__r.DeveloperName;
            this.operationName = filterRule.Operator__c;
            this.objectName = filterRule.Object__r.QualifiedApiName;
            if (filterRule.Field__c != null && filterRule.Field__r.QualifiedApiName.contains('.')) {
                this.fieldName = parseObjectField(filterRule.Field__r.QualifiedApiName)[1];
            } else {
                this.fieldName = filterRule.Field__r.QualifiedApiName;
            }
            this.value = filterRule.Constant__c;
            this.recordId = filterRule.Id;

            try {
                // obfuscating "Partial Soft Credit" object; relabeling to simply "Soft Credit"
                this.objectLabel = filterRule.Object__r.QualifiedApiName == UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c') ? Schema.SObjectType.Contact.getLabel()+' '+System.Label.CRLP_SoftCredit : filterRule.Object__r.MasterLabel;
                this.fieldLabel = UTIL_Describe.getFieldLabel(filterRule.Object__r.QualifiedApiName, filterRule.Field__r.QualifiedApiName);
                this.operationLabel = this.operationName; // will need to be updated in the RollupUI logic
                this.isDeleted = filterRule.Is_Deleted__c;
            } catch (Exception ex) {}
        }

        /**
         * @description Convert the value label to a readable format based on the developer name for record types
         * or split with new lines
         */
        public void setValueLabel () {
            String label = this.value;

            if (fieldName == 'RecordTypeId') {
                List<String> rtLabels = new List<String>();
                SObjectType objType = UTIL_Describe.getSObjectType(objectName);
                Map<String,Schema.RecordTypeInfo> rtMapByDevName = objType.getDescribe().getRecordTypeInfosByDeveloperName();
                Map<String, String> rtDeveloperNameToLabel = new Map<String,String>();
                for (String devName : rtMapByDevName.keySet()) {
                    rtDeveloperNameToLabel.put(devName, rtMapByDevName.get(devName).getName());
                }
                for (String val : value.split(';')) {
                    //val is the RT dev name
                    rtLabels.add(rtDeveloperNameToLabel.get(val));
                }
                label = String.join(rtLabels,';');

            } else if (this.value != null) {

                DescribeFieldResult fld = UTIL_Describe.getFieldDescribe(objectName, fieldName);

                if (fld.getType() == DisplayType.BOOLEAN
                    || fld.getType() == DisplayType.PICKLIST
                    || fld.getType() == DisplayType.MULTIPICKLIST
                ) {
                    label = getPickistLabel();
                }
            }
            this.valueLabel = (label != null ? label.replace(';', ';\n') : null);
        }

        /**
         * @description Returns the correct picklist labels for the picklist api names, including translations,
         * and supporting semi-colon separated values
         * @return String translated/correct picklist label
         */
        private String getPickistLabel() {
            String label = this.value;
            if (this.value == 'True') {
                label = System.Label.labelBooleanTrue;

            } else if (this.value == 'False') {
                label = System.Label.labelBooleanFalse;

            } else if (this.value != null) {
                try {
                    // Wrapped in a Try-Catch on the off-chance the describe or lookup fails.
                    // The error is ignored though because the picklist label is still set
                    SObjectType objType = UTIL_Describe.getSObjectType(this.objectName);
                    SObjectField fldType = UTIL_Describe.getFieldDescribe(this.objectName, this.fieldName).getSobjectField();

                    List<String> translatedValues = new List<String>();
                    for (String v : this.value.split(';')) {
                        String lbl = UTIL_Describe.getTranslatedPicklistLabel(objType, fldType, v);
                        translatedValues.add(lbl);
                    }
                    if (!translatedValues.isEmpty()) {
                        label = String.join(translatedValues, ';');
                    }
                } catch (Exception ex) { }
            }
            return label;
        }

        /**
         * @description Convert the wrapper class instance into a valid Metadata.CustomMetadata
         * instance for the Filter_Rule.
         * @return Metadata.CustomMetadata instance for deployment
         */
        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = UTIL_Namespace.StrTokenNSPrefix(CRLP_RollupCMT.MetadataObject.Filter_Rule.Name() + '__mdt');

            if (this.label == null) {
                String prefix = abbreviateForSpace(this.filterGroupRecordName, true).replace('NPSP','').replace('_', '');
                this.label = abbreviateForSpace(prefix.left(8) + ' ' + this.objectName + '.' + this.fieldName +
                        ' ' + this.operationName + ' ' + this.value, false).left(40);
            }
            if (this.recordName == null) {
                this.recordName = generateRecordName(this.label, true);
            }

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.label = this.label.left(40);
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fldValues;
            if (this.isDeleted != true) {
                fldValues = new Map<String, Object>{
                    'Filter_Group__c' => filterGroupRecordName,
                    'Object__c' => this.objectName,
                    'Field__c' => combineObjectAndField(this.objectName, this.fieldName),
                    'Operator__c' => operationName,
                    'Constant__c' => value,
                    'Is_Deleted__c' => isDeleted
                };
            } else {
                fldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
            md = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fldValues);

            return md;
        }

    /******************************************************************************************************************
     * @description Generates a string as the concatenation of the important fields of the rule
     * @return string generated hash
     *****************************************************************************************************************/
        private String generateHash() {
            return this.isDeleted + '__' +
                + this.objectName + '__'
                + this.fieldName + '__' +
                + this.operationName + '__' +
                + this.value;
        }

    }

    /** ***************************************************************************************************
     * @description Wrapper Class for the Rollup__mdt custom metadata type object
     */
    public class Rollup {
        public String recordName;
        public String label;
        public String filterGroupRecordName;
        public String filterGroupLabel;
        public String description;
        public String operation;
        public String timeBoundOperationType;
        public String summaryObject;
        public String summaryObjectLabel;
        public String summaryField;
        public String summaryFieldLabel;
        public String detailObject;
        public String detailObjectLabel;
        public String detailField;
        public String detailFieldLabel;
        public String amountObject;
        public String amountObjectLabel;
        public String amountField;
        public String amountFieldLabel;
        public String dateObject;
        public String dateObjectLabel;
        public String dateFieldLabel;
        public String dateField;
        public Boolean useFiscalYear;
        public Integer intValue;
        public Boolean isActive;
        public Boolean isDeleted;

        public Rollup(String label) {
            //check to see if UDR; these need a unique name
            Boolean isUDR = (label.left(3) == 'UDR');
            this.label = label.replace('Number', 'Num').left(40).trim();
            this.recordName = generateRecordName(this.label, isUDR);
            this.useFiscalYear = false;
            this.isActive = true;
        }

        public Rollup(Rollup__mdt rlp) {
            this.label = rlp.MasterLabel;
            this.recordName = rlp.DeveloperName;
            this.filterGroupRecordName = rlp.Filter_Group__r.DeveloperName;
            this.description = rlp.Description__c;
            this.operation = rlp.Operation__c;
            this.timeBoundOperationType = rlp.Time_Bound_Operation_Type__c;
            this.summaryObject = rlp.Summary_Object__r.QualifiedApiName;
            this.detailObject = rlp.Detail_Object__r.QualifiedApiName;
            this.amountObject = rlp.Amount_Object__r.QualifiedApiName;
            this.dateObject = rlp.Date_Object__r.QualifiedApiName;

            if (rlp.Summary_Field__c != null && rlp.Summary_Field__r.QualifiedApiName.contains('.')) {
                this.summaryField = parseObjectField(rlp.Summary_Field__r.QualifiedApiName)[1];
            } else {
                this.summaryField = rlp.Summary_Field__r.QualifiedApiName;
            }
            if (rlp.Detail_Field__c != null && rlp.Detail_Field__r.QualifiedApiName.contains('.')) {
                this.detailField = parseObjectField(rlp.Detail_Field__r.QualifiedApiName)[1];
            } else {
                this.detailField = rlp.Detail_Field__r.QualifiedApiName;
            }
            if (rlp.Amount_Field__c != null && rlp.Amount_Field__r.QualifiedApiName.contains('.')) {
                this.amountField = parseObjectField(rlp.Amount_Field__r.QualifiedApiName)[1];
            } else {
                this.amountField = rlp.Amount_Field__r.QualifiedApiName;
            }
            if (rlp.Date_Field__c != null && rlp.Date_Field__r.QualifiedApiName.contains('.')) {
                this.dateField = parseObjectField(rlp.Date_Field__r.QualifiedApiName)[1];
            } else {
                this.dateField = rlp.Date_Field__r.QualifiedApiName;
            }

            this.useFiscalYear = rlp.Use_Fiscal_Year__c;
            this.intValue = (rlp.Integer__c != null ? rlp.Integer__c.intValue() : null);
            this.isDeleted = false;
            this.isActive = rlp.Active__c;

            try {
                this.filterGroupLabel = rlp.Filter_Group__c == null ? System.Label.CRLP_NoFilterGroupSelected : rlp.Filter_Group__r.MasterLabel;
                this.summaryObjectLabel = rlp.Summary_Object__r.Label;
                this.summaryFieldLabel = rlp.Summary_Field__r.Label;
                this.detailObjectLabel = rlp.Detail_Object__r.Label;
                this.detailFieldLabel = rlp.Detail_Field__c == null ? null : UTIL_Describe.getFieldLabel(rlp.Detail_Object__r.QualifiedApiName, rlp.Detail_Field__r.QualifiedApiName.toLowerCase());
                this.amountObjectLabel = rlp.Amount_Object__r.Label;
                this.amountFieldLabel = rlp.Amount_Field__r.Label;
                this.dateObjectLabel = rlp.Date_Object__r.Label;
                this.dateFieldLabel = rlp.Date_Field__r.Label;
            } catch (Exception ex) {}
        }

        /**
         * @description Convert the wrapper class instance into a valid Metadata.CustomMetadata
         * instance for the Rollup.
         * @return Metadata.CustomMetadata instance for deployment
         */
        public Metadata.CustomMetadata getMetadataRecord() {
            Metadata.CustomMetadata md = new Metadata.CustomMetadata();

            String mdTypeName = UTIL_Namespace.StrTokenNSPrefix(CRLP_RollupCMT.MetadataObject.Rollup.Name() + '__mdt');

            if (this.label.length() > 40) {
                this.label = abbreviateForSpace(this.label, false).left(40);
            }

            if (this.recordName == null) {
                this.recordName = generateRecordName(this.label, true);
            }

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.label = this.label.left(40);
            customMd.protected_x = IS_PROTECTED;

            // Convert an empty string ('') value into null for the entity reference to save properly.
            if (String.isEmpty(this.filterGroupRecordName)) {
                this.filterGroupRecordName = null;
            }

            Map<String, Object> fldValues;
            if (this.isDeleted != true) {
                fldValues = new Map<String, Object>{
                    'Filter_Group__c' => filterGroupRecordName,
                    'Description__c' => this.description,
                    'Operation__c' => operation,
                    'Time_Bound_Operation_Type__c' => timeBoundOperationType,
                    'Integer__c' => intValue,
                    'Use_Fiscal_Year__c' => useFiscalYear,
                    'Active__c' => isActive,
                    'Summary_Object__c' => summaryObject,
                    'Summary_Field__c' => combineObjectAndField(summaryObject, summaryField),
                    'Detail_Object__c' => detailObject,
                    'Amount_Object__c' => amountObject,
                    'Date_Object__c' => dateObject,
                    'Is_Deleted__c' => isDeleted
                };
                if (detailField != null) {
                    fldValues.put('Detail_Field__c', combineObjectAndField(detailObject, detailField));
                } else {
                    fldValues.put('Detail_Field__c', null);
                }
                if (amountField != null) {
                    fldValues.put('Amount_Field__c', combineObjectAndField(amountObject, amountField));
                } else {
                    fldValues.put('Amount_Field__c', null);
                }
                if (dateField != null) {
                    fldValues.put('Date_Field__c', combineObjectAndField(dateObject, dateField));
                } else {
                    fldValues.put('Date_Field__c', null);
                }
            } else {
                fldValues = new Map<String, Object>{
                    'Is_Deleted__c' => isDeleted,
                    'Active__c' => isActive,
                    'Description__c' => this.description
                };
            }
            md = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fldValues);

            return md;
        }

        /**************************************************************************************************************
        * @description Determines if a Rollup is computationally different from another Rollup
        * changes in name or label or description are not considered different
        * @param otherRollupMdt Rollup Mdt to compare against
        * @return boolean to indicate of the rollup is different
        **************************************************************************************************************/
        public Boolean isDifferent(Rollup__mdt otherRollupMdt) {
            CRLP_RollupCMT.Rollup otherRollup = new CRLP_RollupCMT.Rollup(otherRollupMdt);
            return isDifferent(otherRollup);
        }


        /**************************************************************************************************************
        * @description Determines if a Rollup is computationally different from another Rollup
        * changes in name or label or description are not considered different
        * @param other Rollup to compare against
        * @return boolean to indicate of the rollup is different
        **************************************************************************************************************/
        public Boolean isDifferent(CRLP_RollupCMT.Rollup other) {

            return other.filterGroupRecordName != this.filterGroupRecordName
            || other.operation != this.operation
            || ( (String.isBlank(other.timeBoundOperationType) ? null : other.timeBoundOperationType) !=
                 (String.isBlank(this.timeBoundOperationType) ? null : this.timeBoundOperationType) )
            || other.summaryObject != this.summaryObject
            || other.summaryField != this.summaryField
            || other.detailObject != this.detailObject
            || other.detailField != this.detailField
            || other.amountObject != this.amountObject
            || other.amountField != this.amountField
            || other.dateObject != this.dateObject
            || other.dateField != this.dateField
            || other.isActive != this.isActive
            || other.isDeleted != this.isDeleted
            || other.useFiscalYear != this.useFiscalYear
            || other.intValue != this.intValue;

        }


        /*******************************************************************************************************
        * @description Determines if the target rollup is a duplicate
        */
        public Boolean isDuplicate() {
            for (Rollup__mdt rlp : CRLP_Rollup_SEL.cachedRollups) {
                if (rlp.DeveloperName != this.recordName
                    && rlp.Active__c
                    && this.summaryObject == rlp.Summary_Object__r.QualifiedApiName
                    && this.summaryField == rlp.Summary_Field__r.QualifiedApiName
                    && !Test.isRunningTest()
                ) {
                    return true;
                }
            }

            return false;
        }

        /**************************************************************************************************************
        * @description Return the rollup type for a given rollup definition
        * @param Rollup__mdt CMT Record
        * @return CRLP_RollupProcessingOptions.RollupType
        **************************************************************************************************************/
        public CRLP_RollupProcessingOptions.RollupType getRollupType() {

            String accountApiName = String.valueOf(Account.getSObjectType());
            String contactApiName = String.valueOf(Contact.getSObjectType());
            String opportunityApiName = String.valueOf(Opportunity.getSObjectType());
            String paymentApiName = 'npe01__OppPayment__c';
            String recurringDonationsApiName = 'npe03__Recurring_Donation__c';
            String gauApiName = UTIL_Namespace.StrAllNSPrefix('General_Accounting_Unit__c');
            String partialSoftCreditApiName = UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c');
            String accountSoftCreditApiName = UTIL_Namespace.StrAllNSPrefix('Account_Soft_Credit__c');

            // work down from most specific
            if (this.summaryObject == recurringDonationsApiName) {
                return CRLP_RollupProcessingOptions.RollupType.RecurringDonations;
            }

            if (this.summaryObject == gauApiName) {
                return CRLP_RollupProcessingOptions.RollupType.GAU;
            }

            if (this.detailObject == partialSoftCreditApiName || this.amountObject == partialSoftCreditApiName) {
                if (this.summaryObject == accountApiName) {
                    return CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit;
                }
                if (this.summaryObject == contactApiName) {
                    return CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit;
                }
            }

            if (this.detailObject == accountSoftCreditApiName ||  this.amountObject == accountSoftCreditApiName) {
                return CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit;
            }

            if (this.detailObject == opportunityApiName || this.detailObject == paymentApiName) {
                if (this.summaryObject == accountApiName) {
                    return CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
                }
                if (this.summaryObject == contactApiName) {
                    return CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
                }
            }

            return null;
        }
    }

    /**
     * @description Utility to convert a Label into a valid 'DeveloperName' quality value (or unique GUID)
     * for the CMT record
     * @param label String
     * @return DeveloperName format string
     */
    public static String generateRecordName(String label, Boolean makeUnique) {

        // Shorten specific words
        String recordName = abbreviateForSpace(label, false);

        // replace all special characters and underscores
        recordName = abbreviateForSpace(recordName.replaceAll('[^\\w]+', '_').replaceAll('_', ''), true);

        if (makeUnique == true) {
            // Create a GUID format unique string
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            // force everything to have a 8-char random string at the end
            recordName = recordName.left(32) + h.left(8);
        } else {
            recordName = recordName.left(40);
        }
        return recordName;
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

    /**
     * @description Replace specific Object and other terms with shortened versions to deal with the 40 character
     * limitation for the CMT MasterLabel and DeveloperName fields.
     * @param txt Text to Shorten
     * @param forDeveloperName True if shortening for the DeveloperName - which can be much shorter.
     * @return Updated Text
     */
    private static String abbreviateForSpace(String txt, Boolean forDeveloperName) {

        txt = txt.replace('General Accounting Unit', 'GAU').
                replace('Recurring Donation', 'RD').
                replace('Opportunity', 'Opp').
                replace('Partial Soft Credit', 'PSC').
                replace('Partial_Soft_Credit', 'PSC').
                replace('ClosedWon', 'Won').
                replace('npsp__', '').replace('npe01__', '').replace('npe03__', '').replace('__c', '').
                replace(' of ', '');

        if (forDeveloperName) {
            txt = txt.replace('Opportunity', 'Opp').
                    replace('Account', 'Acct').
                    replace('Contact', 'Con').
                    replace('Payment', 'Pmt').
                    replace('Allocation', 'Allo').
                    replace('Allocations', 'Allo').
                    replace('Opportunities', 'Opps').
                    replace('Partial Soft Credit', 'PSC').
                    replace('Partial_Soft_Credit', 'PSC').
                    replace('Soft_Credit', 'sftCr').
                    replace('Hard_Credit', 'hrdCr').
                    replace('#', 'num').
                    replace('year', 'yr').
                    replace('Number', 'Num').
                    replace('Count', 'cnt').
                    replace('Equals', 'Eq');
        }
        return txt;
    }
}