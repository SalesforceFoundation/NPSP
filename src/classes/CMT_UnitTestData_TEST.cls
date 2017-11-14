/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
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
                cmtType, recordId, labelName, labelName.replace(' ', '_')
        });

        // Append each field
        for (CMT_Field fld : fields) {
            record += fld.getFieldJSON() + ',';
        }

        // Remove the ending comma
        // Replace the '~!' and '!~' strings with curly brackets (needed to allow String.format() to work
        // Add the opening and closing curly brackets
        record = '{' + record.removeEnd(',').replaceAll('~!', '{').replaceAll('!~', '}') + '}';

        // Fix all field references for the npsp namespace.
        return UTIL_Namespace.StrAllNSPrefix(record);
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
                    this.fldName, theValue
            });

            // If there is a related object (ex: Opportunity.IsWon), then the 'field JSON' will need to include
            // the compound field data as well
            if ( this.fieldType == CMTFieldType.FldEntity || this.fieldType == CMTFieldType.FldField) {
                String entityType = (this.fieldType == CMTFieldType.FldEntity ? 'EntityDefinition' : 'FieldDefinition');

                // List<String>{ dummyId, fldName, objName, foreignFldName, entityType } // '000000','Field__r','Opportunity','IsWon'
                String compountFieldTemplate = '"{1}":~!"attributes":' +
                        '~!"type":"{4}","url":"/services/data/v40.0/sobjects/{4}/{2}.{3}"!~,' +
                        '"Id":"{0}",' +
                        '"DurableId":"{2}.{3}",' +
                        '"QualifiedApiName":"{3}"' +
                        '!~,';
                String dummyId = '000000000000000AAA';
                fldName = this.fldName.replace('__c', '__r');
                fieldJSON += ',' + String.format(compountFieldTemplate, new List<String>{
                        dummyId, this.fldName, this.relatedObject, (String)this.fldValue, entityType });
            }

            return fieldJSON.removeEnd(',');
        }
    }

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
        Boolean ocrBasedRule = false;
        if (objectName == 'OpportunityContactRole') {
            // If the Object is OCR, then change the object and field for the Filter_Rule__mdt record
            // and set the boolean flag to true to mimic how this type of data will actually be
            // stored in the MDT object (because OpportunityContactRole is not a supported object)
            ocrBasedRule = true;
            objectName = 'Opportunity';
            fieldName = 'Id';
        }
        return buildCMTObjectJSON('Filter_Rule__mdt', recordLabel, recordId,
                new List<CMT_Field>{
                    new CMT_Field('Filter_Group__c', CMTFieldType.FldText, filterGroupId),
                    new CMT_Field('Object__c', CMTFieldType.FldEntity, objectName),
                    new CMT_Field('Field__c', CMTFieldType.FldField, objectName + '.' + fieldName),
                    new CMT_Field('Operator__c', CMTFieldType.FldText, operator),
                    new CMT_Field('Constant__c', CMTFieldType.FldText, constant),
                    new CMT_Field('Field_OpportunityContactRole_Role__c', CMTFieldType.FldBoolean, ocrBasedRule)
                }
            );
    }

    /**
     * @description Helper to create a JSON string for a single Rollup__mdt record specifically for an Account
     * rollup from the Opportunity object.
     * @param recordLabel
     * @param filterGroupId
     * @param summaryObjectField
     * @param operation
     * @param detailObjectField
     * @param yearlyOperation
     * @param intValue
     *
     * @return
     */
    public static String createRollupRecordOppToAccount(String recordLabel, String filterGroupId,
                    String summaryObjectField, String operation, String detailObjectField,
                    String yearlyOperation, Integer intValue) {

        return createRollupRecord(recordLabel, filterGroupId, 'Account', summaryObjectField, operation,
            'Opportunity', detailObjectField, yearlyOperation, intValue);
    }

    /**
     * @description Helper to create a JSON string for a single Rollup__mdt record specifically for an Account
     * rollup from the Payment object.
     * @param recordLabel
     * @param filterGroupId
     * @param summaryObjectField
     * @param operation
     * @param detailObjectField
     * @param yearlyOperation
     * @param intValue
     *
     * @return
     */
    public static String createRollupRecordPaymentToAccount(String recordLabel, String filterGroupId,
            String summaryObjectField, String operation, String detailObjectField,
            String yearlyOperation, Integer intValue) {

        return createRollupRecord(recordLabel, filterGroupId, 'Account', summaryObjectField, operation,
                'npe01__OppPayment__c', detailObjectField, yearlyOperation, intValue);
    }

    public static String createRollupRecord(String recordLabel, String filterGroupId,
                    String summaryObjectName, String summaryObjectField, String operation,
                    String detailObjectName, String detailObjectField,
                    String yearlyOperation, Integer intValue) {

        String recordId = getNewRecordId();
        return buildCMTObjectJSON('Rollup__mdt', recordLabel, recordId,
                new List<CMT_Field>{
                    new CMT_Field('Filter_Group__c', CMTFieldType.FldText, filterGroupId),
                    new CMT_Field('Operation__c', CMTFieldType.FldText, operation),
                    new CMT_Field('Active__c', CMTFieldType.FldBoolean, True),
                    new CMT_Field('Use_Fiscal_Year__c', CMTFieldType.FldBoolean, False),
                    new CMT_Field('Yearly_Operation_Type__c', CMTFieldType.FldText, yearlyOperation),
                    new CMT_Field('Integer__c', CMTFieldType.FldNumber, intValue),
                    new CMT_Field('Summary_Object__c', CMTFieldType.FldEntity, summaryObjectName),
                    new CMT_Field('Summary_Field__c', CMTFieldType.FldField, summaryObjectName + '.' + summaryObjectField),
                    new CMT_Field('Detail_Object__c', CMTFieldType.FldEntity, detailObjectName),
                    new CMT_Field('Detail_Field__c', CMTFieldType.FldField, detailObjectName + '.' + detailObjectField),
                    new CMT_Field('Date_Object__c', CMTFieldType.FldEntity, 'Opportunity'),
                    new CMT_Field('Date_Field__c', CMTFieldType.FldField, 'Opportunity.CloseDate'),
                    new CMT_Field('Amount_Object__c', CMTFieldType.FldEntity, 'Opportunity'),
                    new CMT_Field('Amount_Field__c', CMTFieldType.FldField, 'Opportunity.Amount')
                }
        );
    }
}