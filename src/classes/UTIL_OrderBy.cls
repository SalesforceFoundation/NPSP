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
* @group Utilities
* @description Utility used to build the SOQL Order By clause
*/
public with sharing class UTIL_OrderBy {

    public enum SortingOrder { ASCENDING, DESCENDING }
    public enum NullsOrder { FIRST, LAST }

    private static final Integer SORT_SAME = 0;
    private static final Integer SORT_GREATER = 1;
    private static final Integer SORT_LESS = -1;

    private List<FieldExpression> fieldExpressions;
    @TestVisible private Boolean isPostSort {
        get {
            if (isPostSort == null) {
                isPostSort = false;
                for (FieldExpression field : fieldExpressions) {
                    if (!field.isSortable()) {
                        isPostSort = true;
                        break;
                    }
                }
            }
            return isPostSort;
        }
        set;
    }

    /*********************************************************************************************************
    * @description Constructor
    */
    public UTIL_OrderBy() {
        fieldExpressions = new List<FieldExpression>();
    }

    /*********************************************************************************************************
    * @description Adds the field into the Order By fieldExpressions
    * @param field The field expression
    * @return UTIL_OrderBy The object instance
    */
    public UTIL_OrderBy add(FieldExpression field) {
        fieldExpressions.add(field);
        return this;
    }

    /*********************************************************************************************************
    * @description Builds the SOQL Order By clause
    * @return String The Order By clause
    */
    public String build() {
        List<String> orderBy = new List<String>();

        if (fieldExpressions.isEmpty() || isPostSort) {
            return '';
        }

        for (FieldExpression field : fieldExpressions) {
            orderBy.add(field.toString());
        }

        return String.join(orderBy, ', ');
    }

    public Set<String> getFields() {
        Set<String> result = new Set<String>();
        for (FieldExpression field : fieldExpressions) {
            result.add(field.getFieldPath());
        }

        return result;
    }

    public Boolean isPostSort() {
        return isPostSort;
    }

    /*********************************************************************************************************
    * @description Sorts records by the order by fieldExpressions
    * @param records Records to sort
    * @return List<sObject> Sorted records
    */
    public List<sObject> sort(List<sObject> records) {
        if (!isPostSort) {
            return records;
        }

        List<sObject> sortedRecords = new List<sObject>();
        for (Integer i = fieldExpressions.size() - 1; i >= 0; i--) {
            sortedRecords = sort(sortedRecords.isEmpty() ? records : sortedRecords, fieldExpressions[i]);
        }

        return sortedRecords;
    }

    /*********************************************************************************************************
    * @description Sorts records by the field value
    * @param records Records to sort
    * @param field Order By field expression
    * @return List<sObject> Sorted records
    */
    private List<sObject> sort(List<sObject> records, FieldExpression field) {
        List<SortableRecord> sortableRecords = new List<SortableRecord>();
        for (sObject record : records) {
            sortableRecords.add(new SortableRecord(record, field));
        }

        sortableRecords.sort();

        List<sObject> sortedRecords = new List<sObject>();
        for (SortableRecord sortedRecord : sortableRecords) {
            sortedRecords.add(sortedRecord.getRecord());
        }

        return sortedRecords;
    }


    /*********************************************************************************************************
    * @description The sObject wrapper used to sort records in the list
    */
    public class SortableRecord implements Comparable {
        private sObject record;
        private FieldExpression field;
        private String value;

        /*********************************************************************************************************
        * @description Constructor
        * @param record The sObject to be sorted
        * @param field The Order By field expression
        */
        public SortableRecord(sObject record, FieldExpression field) {
            this.record = record;
            this.field = field;
            this.value = field.getValue(record);
        }

        /*********************************************************************************************************
        * @description Returns the sObject
        * @return sObject 
        */
        public sObject getRecord() {
            return record;
        }

        /*********************************************************************************************************
        * @description Compares the record with another record based on the field value
        * @param other The Lookup/M-D field on the sObject
        * @return Integer The integer  (0, <0, >0) representing the order with regards to the "other" sObject
        */
        public Integer compareTo(Object other) {
            String otherValue = ((SortableRecord) other).value;

            if (String.isBlank(value) && String.isBlank(otherValue)) {
                return SORT_SAME;
            }

            if (String.isBlank(otherValue)) {
                return field.isNullsLast() ? SORT_LESS : SORT_GREATER;
            }

            if (String.isBlank(value)) {
                return field.isNullsLast() ? SORT_GREATER : SORT_LESS;
            }

            Integer result = value.compareTo(otherValue);

            return (field.isSortDesc() ? -1 : 1) * result;
        }
    }


    /*********************************************************************************************************
    * @description The composite field used in the Order By clause
    */
    public class FieldExpression {
        Schema.sObjectField sObjField;
        Schema.sObjectField referenceField;
        SortingOrder sortOrder;
        NullsOrder nullOrder;
        String fieldName;
        Boolean isSortDesc;
        Boolean isNullsLast;

        @TestVisible private Boolean isSortable {
            get {
                if (isSortable == null) {
                    isSortable = sObjField.getDescribe().isSortable();
                }
                return isSortable;
            }
            set;
        }

        /*********************************************************************************************************
        * @description Constructor
        * @param sObjField The field
        */
        public FieldExpression(Schema.sObjectField sObjField) {
            this(sObjField, null);
        }

        /*********************************************************************************************************
        * @description Constructor
        * @param sObjField The field
        * @param sortOrder Sorting order
        */
        public FieldExpression(Schema.sObjectField sObjField, SortingOrder sortOrder) {
            this(sObjField, sortOrder, null);
        }

        /*********************************************************************************************************
        * @description Constructor
        * @param sObjField The field
        * @param sortOrder Sorting order
        * @param nullOrder The null order
        */
        public FieldExpression(Schema.sObjectField sObjField, SortingOrder sortOrder, NullsOrder nullOrder) {
            this.sObjField = sObjField;
            this.sortOrder = sortOrder;
            this.nullOrder = nullOrder;

            this.fieldName = String.valueOf(this.sObjField);
            this.isSortDesc = sortOrder == SortingOrder.DESCENDING;
            this.isNullsLast = nullOrder == NullsOrder.LAST;
        }

        /*********************************************************************************************************
        * @description Sets field name to include the relationship name
        * @param referenceField The Lookup/M-D field on the sObject
        * @return Field The object instance 
        */
        public FieldExpression fromRelationship(Schema.sObjectField referenceField) {
            this.referenceField = referenceField;

            return this;
        }

        /*********************************************************************************************************
        * @description Returns if the field is sortable. If the field is encrypted, the return is "false".
        * @return Boolean
        */
        public Boolean isSortable() {
            return isSortable;
        }

        /*********************************************************************************************************
        * @description Returns true for descending sorting
        * @return Boolean
        */
        public Boolean isSortDesc() {
            return isSortDesc;
        }

        /*********************************************************************************************************
        * @description Returns true for NULLS LAST value
        * @return Boolean
        */
        public Boolean isNullsLast() {
            return isNullsLast;
        }

        /*********************************************************************************************************
        * @description Returns the field name taking into the account the relationship name (if any) and namespace
        * @return String The field name
        */
        public String getFieldName() {
            return fieldName;
        }

        public String getFieldPath() {
            return (isRelationshipField() ? referenceField.getDescribe().getRelationshipName() + '.' : '') + fieldName;
        }

        private Boolean isRelationshipField() {
            return referenceField != null;
        }

        private String getRelationshipName() {
            return referenceField != null ? referenceField.getDescribe().getRelationshipName() : '';
        }

        public String getValue(sObject record) {
            if (isRelationshipField()) {
                sObject referenceSObject = record.getSObject(getRelationshipName());
                return referenceSObject == null 
                    ? null
                    : (String) referenceSObject.get(getFieldName());
            } 
            
            return (String) record.get(getFieldName());
        }

        /*********************************************************************************************************
        * @description Builds order by segment for the field
        * @return String The order by 
        */
        public override String toString() {
            String fieldNameStatement = getFieldPath();
            String sortStatement = sortOrder == SortingOrder.DESCENDING ? ' DESC ' : ' ';
            String nullStatement = nullOrder == NullsOrder.LAST ? 'NULLS LAST' : '';

            return String.format('{0}{1}{2}', new String[]{ fieldNameStatement, sortStatement, nullStatement }).trim(); 
        }
    }

}