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
* @description Utility used to build the ORDER BY clause
*/
public class UTIL_OrderBy {

    /** @description Sorting Order options */
    public enum SortingOrder { ASCENDING, DESCENDING }
    /** @description SOQL NULLS options */
    public enum NullsOrder { FIRST, LAST }

    /** @description Used in a class implementing Comparable to indicate objects have the same values */
    private static final Integer SORT_SAME = 0;
    /** @description The object is greater than the "other" object being compared to */
    private static final Integer SORT_GREATER = 1;
    /** @description The object is less than the "other" object being compared to */
    private static final Integer SORT_LESS = -1;

    /** @description Contains field expressions in the ORDER BY segment */
    private List<FieldExpression> fieldExpressions;
    /** @description Indicates if a manual post sort is required once records are retrieved */
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
    * @description Adds the field expression
    * @param field The field expression
    * @return UTIL_OrderBy The object instance
    */
    public UTIL_OrderBy add(FieldExpression field) {
        fieldExpressions.add(field);
        return this;
    }

    /*********************************************************************************************************
    * @description Builds the SOQL ORDER BY clause
    * @return String The ORDER BY clause
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

    /*********************************************************************************************************
    * @description Returns field names (including relationship if any) from all ORDER BY field expressions
    * @return Set<String> The Set of field names
    */
    public Set<String> getFields() {
        Set<String> result = new Set<String>();
        for (FieldExpression field : fieldExpressions) {
            result.add(field.getFieldPath());
        }

        return result;
    }

    /*********************************************************************************************************
    * @description Indicates if the manual sorting (outside of SOQL/SOSL) should be done after records retrieval
    * @return Boolean
    */
    public Boolean isPostSort() {
        return isPostSort;
    }

    /*********************************************************************************************************
    * @description Sorts records based on the ORDER BY field expressions
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
    * @param fieldExp ORDER BY field expression
    * @return List<sObject> Sorted records
    */
    private List<sObject> sort(List<sObject> records, FieldExpression fieldExp) {
        List<SortableRecord> sortableRecords = new List<SortableRecord>();
        for (sObject record : records) {
            sortableRecords.add(new SortableRecord(record, fieldExp));
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
        /** @description The sObject */
        private sObject record;
        /** @description An ORDER BY field expression */
        private FieldExpression fieldExp;
        /** @description The sObject field value */
        private String value;

        /*********************************************************************************************************
        * @description Constructor
        * @param record The sObject to be sorted
        * @param fieldExp The ORDER BY field expression
        */
        public SortableRecord(sObject record, FieldExpression fieldExp) {
            this.record = record;
            this.fieldExp = fieldExp;
            this.value = fieldExp.getValue(record);
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
        * @param other The other sortable record to compare to
        * @return Integer The integer  (0, <0, >0) representing the order with regards to the "other" sObject
        */
        public Integer compareTo(Object other) {
            String otherValue = ((SortableRecord) other).value;

            if (String.isBlank(value) && String.isBlank(otherValue)) {
                return SORT_SAME;
            }

            if (String.isBlank(otherValue)) {
                return fieldExp.isNullsLast() ? SORT_LESS : SORT_GREATER;
            }

            if (String.isBlank(value)) {
                return fieldExp.isNullsLast() ? SORT_GREATER : SORT_LESS;
            }

            //Sorting is case insensitive.
            Integer result = value.toLowerCase().compareTo(otherValue.toLowerCase());

            return (fieldExp.isSortDesc() ? -1 : 1) * result;
        }
    }


    /*********************************************************************************************************
    * @description A field expression used in the ORDER BY clause
    */
    public class FieldExpression {
        /** @description The sObject field to ORDER BY */
        Schema.sObjectField sObjField;
        /** @description The sObject reference field */
        Schema.sObjectField referenceField;
        /** @description The sorting order */
        SortingOrder sortOrder;
        /** @description The NULLS order */
        NullsOrder nullOrder;
        /** @description The field name */
        String fieldName;
        /** @description Indicates if sorting is DESC*/
        Boolean isSortDesc;
        /** @description Indicate if NULLS LAST is the order */
        Boolean isNullsLast;

        /** @description Indicates if the field is sortable (ie not encrypted) */
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
        * @param nullOrder The null value order
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
        * @description Indicates the field is a relationship field
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
        * @description Returns true if the order is NULLS LAST 
        * @return Boolean
        */
        public Boolean isNullsLast() {
            return isNullsLast;
        }

        /*********************************************************************************************************
        * @description Returns the field name including the namespace
        * @return String The field name
        */
        public String getFieldName() {
            return fieldName;
        }

        /*********************************************************************************************************
        * @description Returns the field name incorporating the relationship name (if any) and a namespace
        * @return String The field path
        */
        public String getFieldPath() {
            return (isRelationshipField() ? referenceField.getDescribe().getRelationshipName() + '.' : '') + fieldName;
        }

        /*********************************************************************************************************
        * @description Indicates if the field is a relationship field
        * @return Boolean
        */
        private Boolean isRelationshipField() {
            return referenceField != null;
        }

        /*********************************************************************************************************
        * @description Returns the relationship name or empty string if none
        * @return String The relationship name
        */
        private String getRelationshipName() {
            return referenceField != null ? referenceField.getDescribe().getRelationshipName() : '';
        }

        /*********************************************************************************************************
        * @description Returns the field value on the sObject
        * @return String The field value
        */
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
        * @description Builds ORDER BY segment for this field expression
        * @return String The field's ORDER BY
        */
        public override String toString() {
            String fieldNameStatement = getFieldPath();
            String sortStatement = isSortDesc ? ' DESC ' : ' ';
            String nullStatement = isNullsLast ? 'NULLS LAST' : '';

            return String.format('{0}{1}{2}', new String[]{ fieldNameStatement, sortStatement, nullStatement }).trim(); 
        }
    }

}