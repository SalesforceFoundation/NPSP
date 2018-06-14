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
* @group Custom Metadata Types
* @description Because CMT objects cannot be instantiated or inserted in a Unit Test, the methods in this
* class build a JSON String in the format of the specified MDT Object with all necessary field values and references.
*/
@isTest
public class CMT_UnitTestData_TEST {

    /**
     * @description Supported CMT Field Types
     */
    public Enum CMTFieldType {
        FldText,
        FldBoolean,
        FldNumber,
        FldEntity,      // Ex: Opportunity
        FldField        // Ex: Opportunity.Amount
    }

    /**
     * @description Generate a 'unique' record Id to use for the CMT record. Doesn't really need to valid.
     */
    private static Integer idCounter = 0;
    public static String getNewRecordId() {
        return '00000000000000A' + ('000' + (idCounter++).format()).right(3);
    }

    /**
     * @description Builds a JSON formatted string to represent a Custom Metadata Type record using the data provided.
     * This method also handles namespace requirements when building the JSON.
     * @param cmtType String of the CMT object name
     * @param labelName String of the unique record label and developerName for this record
     * @param recordId A generated record Id to use for this record
     * @param fields A collection of CMT_Field objects to use for each 'field' in the CMT record
     * @return A JSON formatted string to represent a single record of the CMT object.
     */
    public static String buildCMTObjectJSON(String cmtType, String labelName, String recordId, List<CMT_Field> fields) {

        // Build the initial part of the record structure
        String templateString = '"attributes":~!"type":"{0}"!~,' +
                '"Id":"{1}","MasterLabel":"{2}","DeveloperName":"{3}",';

        String record = String.format(templateString, new List<String>{
                UTIL_Namespace.StrAllNSPrefix(cmtType), recordId, labelName, labelName.replace(' ', '_')
        });

        // Append each field
        for (CMT_Field fld : fields) {
            record += fld.getFieldJSON() + ',';
        }

        // Remove the ending comma
        // Replace the '~!' and '!~' strings with curly brackets (needed to allow String.format() to work
        // Add the opening and closing curly brackets
        record = '{' + record.removeEnd(',').replaceAll('~!', '{').replaceAll('!~', '}') + '}';

        return record;
    }

    /**
     * @description Inner class to capture details about each CMT field being added.
     */
    public class CMT_Field {
        private String fldName;
        private String relatedObject;
        private String relationshipType;
        private Object fldValue;
        private CMTFieldType fieldType;

        /**
         * @description Constructor method
         * @param fldName The API name of the field
         * @param fldType The supported Enum of the field type (Text, Boolean, Number, Entity, Field)
         * @param fldValue An object of the field value
         * *
         * Examples:
         * - Field__c, FieldType.FldField, 'Opportunity.IsWon'
         * - Object__c, FieldType.FldEntity, 'Opportunity'
         * - Other__c, FieldType.FldText, 'Some Value'
         * - Other__c, FieldType.FldBoolean, False
        */
        public CMT_Field(String fldName, CMTFieldType fldType, Object fldValue) {

            this.fldName = fldName;
            this.fieldType = fldType;
            if (fldType == CMTFieldType.FldField) {
                String val = (String) fldValue;
                // split the field into an object and field if it's in dot notation
                this.relatedObject = val.split('\\.')[0];
                this.fldValue = val.split('\\.')[1];

            } else if (fldType == CMTFieldType.FldEntity) {
                String val = (String) fldValue;
                this.relatedObject = val;
                this.fldValue = val;

            } else if (fldType == CMTFieldType.FldText) {
                this.fldValue = (String)fldValue;

            } else {
                // Boolean or Number
                this.fldValue = fldValue;
            }
        }

        /**
         * @description Builds the JSON formatted structure for the field in this instance of the CMTField object
         */
        public String getFieldJSON() {
            String fldTemplate;
            String theValue;
            String fixedFieldName = UTIL_Namespace.StrAllNSPrefix(this.fldName);

            // Handle the basic field conversion
            if (this.fieldType == CMTFieldType.FldText || this.fieldType == CMTFieldType.FldEntity || this.fieldType == CMTFieldType.FldField) {
                fldTemplate = '"{0}":"{1}"';
                theValue = (String)this.fldValue;
            } else if (this.fieldType == CMTFieldType.FldBoolean) {
                fldTemplate = '"{0}":{1}';
                theValue = ((Boolean)fldValue == true ? 'true' : 'false');
            } else {
                fldTemplate = '"{0}":{1}';
                theValue = ((Double)fldValue).format();
            }
            String fieldJSON = String.format(fldTemplate, new List<String>{
                fixedFieldName, theValue
            });

            // If there is a related object (ex: Opportunity.IsWon), then the 'field JSON' will need to include
            // the compound field data as well
            if ( this.fieldType == CMTFieldType.FldEntity || this.fieldType == CMTFieldType.FldField) {
                String entityType = (this.fieldType == CMTFieldType.FldEntity ? 'EntityDefinition' : 'FieldDefinition');

                String fixedObjectName = UTIL_Namespace.StrAllNSPrefix(this.relatedObject);
                fixedFieldName = fixedFieldName.replace('__c', '__r');

                // List<String>{ dummyId, fldName, objName, foreignFldName, entityType } // '000000','Field__r','Opportunity','IsWon'
                String compountFieldTemplate = '"{1}":~!"attributes":' +
                        '~!"type":"{4}","url":"/services/data/v40.0/sobjects/{4}/{2}.{3}"!~,' +
                        '"Id":"{0}",' +
                        '"DurableId":"{2}.{3}",' +
                        '"QualifiedApiName":"{3}"' +
                        '!~,';
                String dummyId = '000000000000000AAA';
                fieldJSON += ',' + String.format(compountFieldTemplate, new List<String>{
                        dummyId, fixedFieldName, fixedObjectName, (String)this.fldValue, entityType });
            }

            return fieldJSON.removeEnd(',');
        }
    }

    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FILTER_GROUP__MDT CREATION METHODS
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
     * @description Helper to create a JSON string for a single Filter_Group__mdt record
     * @param recordId
     * @param recordLabel
     * @return Filter_Group__mdt serialized JSON
     */
    public static String createFilterGroupRecord(String recordId, String recordLabel) {
        if (recordId == null) {
            recordId = getNewRecordId();
        }
        return buildCMTObjectJSON('Filter_Group__mdt', recordLabel, recordId,
                new List<CMT_Field>{new CMT_Field('Is_Deleted__c', CMTFieldType.FldBoolean, False)}
            );
    }

    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FILTER_RULE__MDT CREATION METHODS
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
     * @description Helper to create a JSON string for a single Filter_Rule__mdt record
     * @param recordId
     * @param groupId
     * @param recordLabel
     * @param objectName
     * @param fieldName
     * @param operator
     * @param constant
     * @return Filter_Rule__mdt serialized JSON
     */
    public static String createFilterRuleRecord(String recordId, String filterGroupId, String recordLabel,
                                                String objectName, String fieldName, String operator, String constant) {
        if (recordId == null) {
            recordId = getNewRecordId();
        }
        return buildCMTObjectJSON('Filter_Rule__mdt', recordLabel, recordId,
                new List<CMT_Field>{
                    new CMT_Field('Filter_Group__c', CMTFieldType.FldText, filterGroupId),
                    new CMT_Field('Object__c', CMTFieldType.FldEntity, UTIL_Namespace.StrAllNSPrefix(objectName)),
                    new CMT_Field('Field__c', CMTFieldType.FldField, UTIL_Namespace.StrAllNSPrefix(objectName) + '.' + UTIL_Namespace.StrAllNSPrefix(fieldName)),
                    new CMT_Field('Operator__c', CMTFieldType.FldText, operator),
                    new CMT_Field('Constant__c', CMTFieldType.FldText, constant)
                }
            );
    }

    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // ROLLUP__MDT CREATION METHODS
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
     * @description Enum of the supported rollup types to simplify creating the test records. By using an Enum
     * such as OppToAccount, the call to create the Rollup__mdt record doesn't need to pass the Summary and
     * Detail object names since they're automatically set based on the RollupRecordType enum.
     */
    public Enum RollupRecordType {
        OppToAcct, OppToContact, PmtToAcct, PmtToContact, GAU, SoftCreditToContact, ContactSoftCreditToAccount, OppToRD, AccountSoftCreditToAccount
    }
    /**
     * @description Convert the Enum to a Summary Object name
     */
    private static final Map<RollupRecordType, String> getSummaryObject = new Map<CMT_UnitTestData_TEST.RollupRecordType, String>{
            RollupRecordType.OppToAcct => 'Account',
            RollupRecordType.OppToContact => 'Contact',
            RollupRecordType.PmtToAcct => 'Account',
            RollupRecordType.PmtToContact => 'Contact',
            RollupRecordType.GAU => 'General_Accounting_Unit__c',
            RollupRecordType.SoftCreditToContact => 'Contact',
            RollupRecordType.ContactSoftCreditToAccount => 'Account',
            RollupRecordType.OppToRD => 'npe03__Recurring_Donation__c',
            RollupRecordType.AccountSoftCreditToAccount => 'Account'
    };
    /**
     * @description Convert the Enum to a Detail Object name
     */
    private static final Map<RollupRecordType, String> getDetailObject = new Map<CMT_UnitTestData_TEST.RollupRecordType, String>{
            RollupRecordType.OppToAcct => 'Opportunity',
            RollupRecordType.OppToContact => 'Opportunity',
            RollupRecordType.PmtToAcct => 'npe01__OppPayment__c',
            RollupRecordType.PmtToContact => 'npe01__OppPayment__c',
            RollupRecordType.GAU => 'Allocation__c',
            RollupRecordType.SoftCreditToContact => 'Partial_Soft_Credit__c',
            RollupRecordType.ContactSoftCreditToAccount => 'Partial_Soft_Credit__c',
            RollupRecordType.OppToRD => 'Opportunity',
            RollupRecordType.AccountSoftCreditToAccount => 'Account_Soft_Credit__c'

    };

    /**
     * @description Create a Rollup__mdt record. Simplest method passing only the necessary information
     * @param recordLabel
     * @param filterGroupId
     * @param rollupType
     * @param summField
     * @param operation
     * @param detailField
     * @return JSON String for a Rollup__mdt record
     */
    public static String createRollupRecord(String recordLabel, String filterGroupId, RollupRecordType rollupType,
            String summField, CRLP_Operation.RollupType operation, String detailField) {

        return createRollupRecord(recordLabel, filterGroupId, rollupType, new Map<String, Object>{
                'Operation' => operation,
                'Summary' => getSummaryObject.get(rollupType) + '.' + summField,
                'Detail' => getDetailObject.get(rollupType) + (!String.isEmpty(detailField) ? '.' + detailField : '')
            }
        );
    }

    /**
     * @description Create a Rollup__mdt record. Simplest method passing only the necessary information
     * @param recordLabel
     * @param filterGroupId
     * @param rollupType
     * @param summField
     * @param operation
     * @param detailField
     * @param amtField
     * @return JSON String for a Rollup__mdt record
     */
    public static String createRollupRecord(String recordLabel, String filterGroupId, RollupRecordType rollupType,
            String summField, CRLP_Operation.RollupType operation, String detailField, String amtField) {

        return createRollupRecord(recordLabel, filterGroupId, rollupType, new Map<String, Object>{
                'Operation' => operation,
                'Summary' => getSummaryObject.get(rollupType) + '.' + summField,
                'Detail' => getDetailObject.get(rollupType) + (!String.isEmpty(detailField) ? '.' + detailField : ''),
                'Amount' => getDetailObject.get(rollupType) + (!String.isEmpty(amtField) ? '.' + amtField : '')
            }
        );
    }

    /**
     * @description Create a Rollup__mdt record. Overload to include a Yearly Operation Type
     * @return JSON String for a Rollup__mdt record
     */
    public static String createRollupRecord(String recordLabel, String filterGroupId, RollupRecordType rollupType,
            String summField, CRLP_Operation.RollupType operation, String detailField,
            CRLP_Operation.TimeBoundOperationType timeBoundOperation, Integer intValue) {

        return createRollupRecord(recordLabel, filterGroupId, rollupType, new Map<String, Object>{
                'Operation' => operation,
                'Summary' => getSummaryObject.get(rollupType) + '.' + summField,
                'Detail' => getDetailObject.get(rollupType) + (!String.isEmpty(detailField) ? '.' + detailField : ''),
                'Yearly' => timeBoundOperation,
                'Integer' => intValue
            }
        );
    }

    /**
     * @description Create a Rollup__mdt record. Overload to include a Yearly Operation Type and UseFiscalYear val
     * @return JSON String for a Rollup__mdt record
     */
    public static String createRollupRecord(String recordLabel, String filterGroupId, RollupRecordType rollupType,
            String summField, CRLP_Operation.RollupType operation, String detailField,
            CRLP_Operation.TimeBoundOperationType timeBoundOperation, Integer intValue, Boolean useFiscalYear) {

        return createRollupRecord(recordLabel, filterGroupId, rollupType, new Map<String, Object>{
                'Operation' => operation,
                'Summary' => getSummaryObject.get(rollupType) + '.' + summField,
                'Detail' => getDetailObject.get(rollupType) + (!String.isEmpty(detailField) ? '.' + detailField : ''),
                'Yearly' => timeBoundOperation,
                'Integer' => intValue,
                'UseFiscal' => useFiscalYear
            }
        );
    }

    /*
    ====== Parameter Map Structure =====
    new Map<String, Object>{
        'Operation' => SUM                  // Required as a CRLP_Operation.RollupType
        'Summary' => 'Account.Field',       // Required as Object.Field
        'Detail' => 'Opportunity[.Field]',  // The Object portion is required, the field portion is optional
        'Amount' => 'Opportunity.Amount',   // Defaults to Opportunity.Amount if not provided
        'Date' => 'Opportunity.CloseDate',  // Defaults to Opportunity.CloseDAte if not provided
        'UseFiscal' => False,               // Optional, defaults to false
        'Integer' => 0,                     // Optional, defaults to null
        'Yearly' = YEARS_AGO                // Optional, defaults to null
    };
    */

    /**
     * @description Internal method to build a Rollup__mdt record
     *
     * @param recordLabel
     * @param filterGroupId
     * @param parms
     * @return
     */
    private static String createRollupRecord(String recordLabel, String filterGroupId, RollupRecordType rollupType, Map<String, Object> parms) {

        // If the Rollup Type is from Payment, then shift the objects to the Payment object rather than date
        if (rollupType == RollupRecordType.PmtToContact || rollupType == RollupRecordType.PmtToAcct) {
            String detailField;
            if (((String)parms.get('Detail')).contains('.')) {
                detailField = ((String)parms.get('Detail')).split('\\.')[1];
            } else {
                detailField = 'npe01__Payment_Amount__c';
            }
            parms.put('Amount', getDetailObject.get(rollupType) + '.' + detailField);
            parms.put('Date', getDetailObject.get(rollupType) + '.npe01__Payment_Date__c');
            parms.put('Detail', getDetailObject.get(rollupType));

        } else if (rollupType == RollupRecordType.GAU) {
            String detailField;
            if (((String)parms.get('Detail')).contains('.')) {
                detailField = ((String)parms.get('Detail')).split('\\.')[1];
            } else {
                detailField = 'Amount__c';
            }
            parms.put('Amount', getDetailObject.get(rollupType) + '.' + detailField);
            parms.put('Detail', getDetailObject.get(rollupType) + '.' + detailField);

        } else if (rollupType == RollupRecordType.ContactSoftCreditToAccount ||
                rollupType == RollupRecordType.SoftCreditToContact ||
                rollupType == RollupRecordType.AccountSoftCreditToAccount) {

            String detailField;
            if (((String)parms.get('Detail')).contains('.')) {
                detailField = ((String)parms.get('Detail')).split('\\.')[1];
            } else {
                detailField = 'Amount__c';
            }

            if (detailField == 'CloseDate') {
                parms.put('Detail', 'Opportunity.CloseDate');
            }
            parms.put('Amount', getDetailObject.get(rollupType) + '.Amount__c');
        }

        String recordId = getNewRecordId();
        String summaryObjectName = ((String)parms.get('Summary')).split('\\.')[0];
        String summaryObjectField = ((String)parms.get('Summary')).split('\\.')[1];
        String detailObjectName = ((String)parms.get('Detail')).split('\\.')[0];
        CRLP_Operation.RollupType operation = (CRLP_Operation.RollupType)parms.get('Operation');
        List<CMT_Field> fields = new List<CMT_Field>{
                new CMT_Field('Filter_Group__c', CMTFieldType.FldText, filterGroupId),
                new CMT_Field('Operation__c', CMTFieldType.FldText, operation.name()),
                new CMT_Field('Active__c', CMTFieldType.FldBoolean, True),
                new CMT_Field('Summary_Object__c', CMTFieldType.FldEntity, UTIL_Namespace.StrAllNSPrefix(summaryObjectName)),
                new CMT_Field('Summary_Field__c', CMTFieldType.FldField, UTIL_Namespace.StrAllNSPrefix(summaryObjectName) + '.' + UTIL_Namespace.StrAllNSPrefix(summaryObjectField)),
                new CMT_Field('Detail_Object__c', CMTFieldType.FldEntity, UTIL_Namespace.StrAllNSPrefix(detailObjectName))
        };

        if (((String)parms.get('Detail')).contains('.')) {
            String detailObjectField = ((String)parms.get('Detail')).split('\\.')[1];
            fields.add(new CMT_Field('Detail_Field__c', CMTFieldType.FldField, UTIL_Namespace.StrAllNSPrefix(detailObjectName) + '.' + UTIL_Namespace.StrAllNSPrefix(detailObjectField)));
        }
        if (parms.get('Amount') != null) {
            String amtObjectName = ((String)parms.get('Amount')).split('\\.')[0];
            String amtObjectField = ((String)parms.get('Amount')).split('\\.')[1];
            fields.add(new CMT_Field('Amount_Object__c', CMTFieldType.FldEntity, UTIL_Namespace.StrAllNSPrefix(amtObjectName)));
            fields.add(new CMT_Field('Amount_Field__c', CMTFieldType.FldField, UTIL_Namespace.StrAllNSPrefix(amtObjectName) + '.' + UTIL_Namespace.StrAllNSPrefix(amtObjectField)));
        } else {
            fields.add(new CMT_Field('Amount_Object__c', CMTFieldType.FldEntity, 'Opportunity'));
            fields.add(new CMT_Field('Amount_Field__c', CMTFieldType.FldField, 'Opportunity.Amount'));
        }
        if (parms.get('Date') != null) {
            String dateObjectName = ((String)parms.get('Date')).split('\\.')[0];
            String dateObjectField = ((String)parms.get('Date')).split('\\.')[1];
            fields.add(new CMT_Field('Date_Object__c', CMTFieldType.FldEntity, UTIL_Namespace.StrAllNSPrefix(dateObjectName)));
            fields.add(new CMT_Field('Date_Field__c', CMTFieldType.FldField, UTIL_Namespace.StrAllNSPrefix(dateObjectName) + '.' + UTIL_Namespace.StrAllNSPrefix(dateObjectField)));
        } else {
            fields.add(new CMT_Field('Date_Object__c', CMTFieldType.FldEntity, 'Opportunity'));
            fields.add(new CMT_Field('Date_Field__c', CMTFieldType.FldField, 'Opportunity.CloseDate'));
        }
        if (parms.get('Yearly') != null) {
            fields.add(new CMT_Field('Time_Bound_Operation_Type__c', CMTFieldType.FldText, ((CRLP_Operation.TimeBoundOperationType)parms.get('Yearly')).name()));
            fields.add(new CMT_Field('Integer__c', CMTFieldType.FldNumber, parms.get('Integer')));
        }
        if (parms.get('UseFiscal') != null) {
            fields.add(new CMT_Field('Use_Fiscal_Year__c', CMTFieldType.FldBoolean, (Boolean)parms.get('UseFiscal')));
        }

        return buildCMTObjectJSON('Rollup__mdt', recordLabel, recordId, fields);
    }
}