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
* @description Utility used to build the WHERE clause
*/
public class UTIL_Where {
    /** @description Exception class */
    public class CriteriaException extends Exception {}

    /** @description Filter operator options */
    public Enum Operator {
        EQUALS,
        NOT_EQUALS,
        IN_SET
    }
    
    /*********************************************************************************************************
    * @description Translates field expression operator to a String
    * @param operant The operator
    * @return String The string value of the operator
    */
    private static String operatorToString(Operator operant) {
        String result = null;

        if (operant == Operator.EQUALS) { result = '='; }
        else if (operant == Operator.NOT_EQUALS) { result = '!='; }
        else if (operant == Operator.IN_SET) { result = 'IN'; }

        return result;
    }

    /*********************************************************************************************************
    * @description Determines if the criteria is met for the match results and the operator
    * @param matchResult The field expression(s) match results
    * @param logicOperator The logic ooperator (AND/OR)
    * @return Boolean
    */
    public static Boolean meetsCriteria(List<Boolean> matchResult, String logicOperator) {
        if (matchResult == null || matchResult.isEmpty()) {
            return true;
        }

        if (logicOperator == AND_OPERATOR) {
            for (Boolean result : matchResult) {
                if (!result) {
                    return false;
                }
            }
            return true;

        } else {
            for (Boolean result : matchResult) {
                if (result) {
                    return true;
                }
            }
            return false;
        }
    }
    
    /** @description AND logic operator */
    public static final String AND_OPERATOR = 'AND';
    /** @description OR logic operator */
    public static final String OR_OPERATOR = 'OR';

    /** @description Group expressions contained in the WHERE clause */
    private List<GroupExpression> groups;
    /** @description Logic operator to connect the group expressions. AND operator is default */
    private String logicOperator = AND_OPERATOR;

    /** @description Indicates if the WHERE clause is filterable */
    @TestVisible private Boolean isFilterable {
        get {
            if (isFilterable == null) {
                isFilterable = true;
                for (GroupExpression groupExp : groups) {
                    if (!groupExp.isFilterable()) {
                        isFilterable = false;
                        break;
                    }
                }
            }
            return isFilterable;
        }
        set;
    }

    /** @description Indicates if all fields in the field expressions are Name fields (used for SOSL) */
    @TestVisible private Boolean isNameField {
        get {
            if (isNameField == null) {
                isNameField = determineIsNameField();
            }
            return isNameField;
        }
        set;
    }

    /*********************************************************************************************************
    * @description Constructor
    */
    public UTIL_Where() {
        groups = new List<GroupExpression>();
    }

    /*********************************************************************************************************
    * @description Adds the group expression into the WHERE clause
    * @param groupExp The group expression
    * @return UTIL_Where The object instance
    */
    public UTIL_Where add(GroupExpression groupExp) {
        groups.add(groupExp);

        return this;
    }

    /*********************************************************************************************************
    * @description Creates the new group expression containing the field expression only and adds it into the WHERE clause. 
    * @param fieldExp The field expression
    * @return UTIL_Where The object instance
    */
    public UTIL_Where add(FieldExpression fieldExp) {
        groups.add(new GroupExpression().add(fieldExp));

        return this;
    }

    /*********************************************************************************************************
    * @description Specifies the logic operator is OR
    * @return UTIL_Where The object instance
    */
    public UTIL_Where withOr() {
        logicOperator = OR_OPERATOR;
        return this;
    }

    /*********************************************************************************************************
    * @description Indicates if the WHERE clause is filterable (no field is encrypted)
    * @return Boolean
    */
    public Boolean isFilterable() {
        return isFilterable;
    }

    /*********************************************************************************************************
    * @description Indicates if the WHERE clause contains Name fields only
    * @return Boolean
    */
    public Boolean isNameField() {
        return isNameField;
    }

    /*********************************************************************************************************
    * @description Determines if the WHERE clause contains a Name field
    * @return Boolean
    */
    private Boolean determineIsNameField() {
        if (groups.isEmpty()) {
            return false; //IN ALL FIELDS should be the default for the SOSL
        }

        for (GroupExpression groupExp : groups) {
            if (!groupExp.isNameField()) {
                return false;
            }
        }

        return true;
    }

    /*********************************************************************************************************
    * @description Builds the WHERE clause
    * @return String The WHERE clause to be used in a SOQL or SOSL query
    */
    public String build() { 
        List<String> result = new List<String>();
        Boolean isFilterable = isFilterable();

        if (isFilterable) {//SOQL
            for (GroupExpression groupExp : groups) {
                result.add(groupExp.toString());
            }
        } else {//SOSL
            for (GroupExpression groupExp : groups) {
                result.add(groupExp.getSearchValue());
            }
        }

        return String.join(result, ' ' + logicOperator + ' ');
    }

    /*********************************************************************************************************
    * @description Filters out records that do not meet WHERE clause criteria
    * @param records The sObjects to filter through
    * @return List<sObject> The sObjects that meet criteria 
    */
    public List<sObject> filter(List<sObject> records) {
        List<sObject> result = new List<sObject>();
        for (sObject record : records) {
            if (meetsCriteria(record)) {
                result.add(record);
            }
        }

        return result;
    }

    /*********************************************************************************************************
    * @description Returns names of fields in the WHERE clause
    * @return Set<String> Field Names
    */
    public Set<String> getFields() {
        Set<String> result = new Set<String>();
        for (GroupExpression groupExp : groups) {
            result.addAll(groupExp.getFields());
        }

        return result;
    }

    /*********************************************************************************************************
    * @description Determines if the record meets the WHERE clause criteria
    * @param record The sObject to verify
    * @return Boolean
    */
    @TestVisible 
    private Boolean meetsCriteria(sObject record) {
        List<Boolean> matchResult = new List<Boolean>();

        for (GroupExpression groupExp : groups) {
            matchResult.add(groupExp.meetsCriteria(record));
        }

        return meetsCriteria(matchResult, logicOperator);
    }





    /*********************************************************************************************************
    * @description Creates a group expression with AND logic operator
    * @return GroupExpression The new group expression instance
    */
    public static GroupExpression AndGroup() {
        return new GroupExpression();
    }

    /*********************************************************************************************************
    * @description Creates a group expression with OR logic operator
    * @return GroupExpression The new group expression instance
    */
    public static GroupExpression OrGroup() {
        return new GroupExpression().withOr();
    }

    /** @description Group of field expressions */
    public class GroupExpression { 
        /** @description Field expressions */
        private List<FieldExpression> fieldExpressions;
        /** @description The logic operator. The default operator is AND */
        private String logicOperator = AND_OPERATOR;
        /** @description Specifies if the group expression is filterable (fields are not encrypted) */
        private Boolean isFilterable {
            get {
                if (isFilterable == null) {
                    isFilterable = true;
                    for (FieldExpression fieldExp : fieldExpressions) {
                        if (!fieldExp.isFilterable()) {
                            isFilterable = false;
                            break;
                        }
                    }
                }
                return isFilterable;
            }
            set;
        }
        /** @description Specifies if all fields in the field expressions are Name fields */
        private Boolean isNameField {
            get {
                if (isNameField == null) {
                    isNameField = true;
                    for (FieldExpression fieldExp : fieldExpressions) {
                        if (!fieldExp.isNameField) {
                            isNameField = false;
                            break;
                        }
                    }
                }
                return isNameField;
            }
            set;
        }

        /*********************************************************************************************************
        * @description Constructor
        */
        public GroupExpression() {
            fieldExpressions = new List<FieldExpression>();
        }

        /*********************************************************************************************************
        * @description Sets OR operator
        * @return GroupExpression The object instance
        */
        public GroupExpression withOr() {
            logicOperator = OR_OPERATOR;
            return this;
        }

        /*********************************************************************************************************
        * @description Adds the field expression into the group
        * @param field The field expression
        * @return GroupExpression The object instance
        */
        public GroupExpression add(FieldExpression fieldExp) {
            fieldExpressions.add(fieldExp);

            return this;
        }

        /*********************************************************************************************************
        * @description Indicates if the group expression is filterable
        * @return Boolean
        */
        public Boolean isFilterable() {
            return isFilterable;
        }

        /*********************************************************************************************************
        * @description Indicates if all fields in the group are Name fields
        * @return Boolean
        */
        public Boolean isNameField() {
            return isNameField;
        }

        /*********************************************************************************************************
        * @description Creates SOQL group expression String
        * @return String
        */
        public override String toString() {
            List<String> result = new List<String>();

            for (FieldExpression fieldExp : fieldExpressions) {
                result.add(fieldExp.toString());
            }
            
            if (result.isEmpty()) {
                return '';
            }

            return result.size() == 1
                ? result[0] 
                : '(' + String.join(result, ' ' + logicOperator + ' ') + ')';
        }

        /*********************************************************************************************************
        * @description Returns field paths of fields in the group
        * @return Set<String>
        */
        public Set<String> getFields() {
            Set<String> result = new Set<String>();
            for (FieldExpression fieldExp : fieldExpressions) {
                result.add(fieldExp.getFieldPath());
            }

            return result;
        }

        /*********************************************************************************************************
        * @description Creates search (SOSL) group expression String
        * @return String
        */
        public String getSearchValue() {
            List<String> result = new List<String>();

            for (FieldExpression fieldExp : fieldExpressions) {
                String searchValue = fieldExp.getSearchValue();

                if (String.isNotBlank(searchValue)) {
                    result.add(searchValue);
                }
            }

            if (result.isEmpty()) {
                return '';
            }

            return result.size() == 1
                ? result[0] + '*'
                : '(' + String.join(result, ' ' + logicOperator + ' ') + ')';
        }

        /*********************************************************************************************************
        * @description Determines if the record meets the group criteria
        * @param record The sObject to verify
        * @return Boolean
        */
        public Boolean meetsCriteria(sObject record) {
            List<Boolean> matchResult = new List<Boolean>();
            for (FieldExpression fieldExp : fieldExpressions) {
                matchResult.add(fieldExp.meetsCriteria(record));
            }

            return meetsCriteria(matchResult, logicOperator);
        }
    }




    /** @description Field expression */
    public class FieldExpression {
        /** @description The field */
        private Schema.sObjectField sObjField;
        /** @description The reference field (if any) */
        private Schema.sObjectField referenceField;
        /** @description Operator on the field */
        private Operator operant;
        /** @description Value to compare the field to */
        private Object value;
        /** @description Values set of lower case values to filter records on */
        Set<String> values;

        /** @description Specifies if the field is filterable (the field is not encrypted) */
        @TestVisible private Boolean isFilterable {
            get {
                if (isFilterable == null) {
                    isFilterable = sObjField.getDescribe().isFilterable();
                }
                return isFilterable;
            }
            set;
        }
        /** @description Specifies if the field is a Name field */
        @TestVisible private Boolean isNameField {
            get {
                if (isNameField == null) {
                    isNameField = sObjField.getDescribe().isNameField();
                }
                return isNameField;
            }
            set;
        }

        /*********************************************************************************************************
        * @description Constructor
        * @param sObjField The field
        */
        public FieldExpression(Schema.SObjectField sObjField) {
            this.sObjField = sObjField;
        }

        /*********************************************************************************************************
        * @description Sets the reference field
        * @param referenceField The reference field (Lookup/M-D)
        * @return FieldExpression The object instance
        */
        public FieldExpression fromRelationship(Schema.sObjectField referenceField) {
            this.referenceField = referenceField;

            return this;
        }
        
        /*********************************************************************************************************
        * @description Indicates if the field is filterable
        * @return Boolean
        */
        public Boolean isFilterable() {
            return isFilterable;
        }

        /*********************************************************************************************************
        * @description Indicates if the field is a Name field
        * @return Boolean
        */
        public Boolean isNameField() {
            return isNameField;
        }

        /*********************************************************************************************************
        * @description Sets the field expression to use EQUALS operator on the value
        * @param value The value to compare the field to
        * @return FieldExpression The object instance
        */
        public FieldExpression equals(Object value) {
            operant = Operator.EQUALS;
            this.value = value;
            return this; 
        }

        /*********************************************************************************************************
        * @description Sets the field expression to use NOT_EQUALS operator on the value
        * @param value The value to compare the field to
        * @return FieldExpression The object instance
        */
        public FieldExpression notEquals(Object value) {
            operant = Operator.NOT_EQUALS;
            this.value = value;
            return this; 
        }

        /*********************************************************************************************************
        * @description Sets the field expression to use IN_SET operator on the value
        * @param value The values to filter the records on
        * @return FieldExpression The object instance
        */
        public FieldExpression inSet(Object value) {
            if (!(value instanceof Set<String> || value instanceof Set<Id>)) {
                return this;
            }

            values = new Set<String>();
            System.debug('value: ' + value);
            for (String val : (Set<String>) value) {
                if (String.isNotBlank(val)) {
                    values.add(val.toLowerCase());
                }
            }
            operant = Operator.IN_SET;
            this.value = value;
            System.debug('values: ' + values);
            return this;
        }

        /*********************************************************************************************************
        * @description Indicates if the field is a relationship field (Lookup/M-D)
        * @return Boolean
        */
        private Boolean isRelationshipField() {
            return referenceField != null;
        }

        /*********************************************************************************************************
        * @description Returns the relationship field name (if any)
        * @return String
        */
        public String getRelationshipName() {
            return referenceField != null ? referenceField.getDescribe().getRelationshipName() : '';
        }

        /*********************************************************************************************************
        * @description Returns the field path including the relationship name and the namespace
        * @return String
        */
        public String getFieldPath() {
            return (isRelationshipField() ? getRelationshipName() + '.' : '') + String.valueOf(sObjField);
        }

        /*********************************************************************************************************
        * @description Returns the field expression to be used in the search query (SOSL)
        * @return String
        */
        public String getSearchValue() {
            String skipSearchValue = '';

            if (value == null) {
                return skipSearchValue;
            }

            if (value instanceof String || value instanceof Id) {
                if (String.isBlank(String.valueOf(value))) {
                    return skipSearchValue;
                }

                if (operant == Operator.NOT_EQUALS) {
                    throw new CriteriaException('Search cannot be done for != operator');
                }
               
                return String.escapeSingleQuotes((String) value);
            }

            if (value instanceof Set<String> || value instanceof Set<Id>) {
                if (values.isEmpty()) {
                    return skipSearchValue;
                }

                return '(' + String.escapeSingleQuotes(String.join(new List<String>(values), ' OR ')) + ')';
            }

            throw new CriteriaException('Invalid data type for: ' + value);
        }

        /*********************************************************************************************************
        * @description Returns the field expression to be used in the SOQL
        * @return String
        */
        public override String toString() {
            if (operant == null) {
                throw new CriteriaException('Field Expression Operator is required');
            }

            return getFieldPath() + ' ' + operatorToString(operant) + ' ' + toLiteral(value);
        }
        
        /*********************************************************************************************************
        * @description Returns the value as String
        * @return String
        */
        private String toLiteral(Object value) {
            if (value == null) {
                return 'null';
            }

            if (value instanceof Set<String> || value instanceof Set<Id>) {
                if (values.isEmpty()) {
                    return 'null';
                }

                List<String> escapedValues = new List<String>();
                for (String val : values) {
                    escapedValues.add(escape(val));
                }

                return '(' + String.join(escapedValues, ', ') + ')';
            }

            if (value instanceof String || value instanceof Id) {
                return String.isBlank(String.valueOf(value)) 
                    ? 'null' 
                    : escape(String.valueOf(value));
            }

            throw new CriteriaException('Invalid data type for: ' + value);
        }

        /*********************************************************************************************************
        * @description Returns the escaped String value
        * @return String
        */
        private String escape(String value) {
            return '\'' + String.escapeSingleQuotes((String) value) + '\'';
        }

        /*********************************************************************************************************
        * @description Determines if the record meets the field expression criteria
        * @param record The sObject to verify
        * @return Boolean
        */
        public Boolean meetsCriteria(sObject record) {
            if (isRelationshipField()) {
                sObject referenceSObject = record.getSObject(getRelationshipName());

                return referenceSObject == null 
                    ? false
                    : isMatching(referenceSObject.get(String.valueOf(sObjField)));

            }
            
            return isMatching(record.get(String.valueOf(sObjField)));
        }

        /*********************************************************************************************************
        * @description Determines if the record value matches the field expression value
        * @param fieldValue The sObject field value to compare to
        * @return Boolean
        */
        @TestVisible private Boolean isMatching(Object fieldValue) {
            if (operant == Operator.EQUALS) {
                return value == null 
                    ? String.isBlank(String.valueOf(fieldValue))
                    : String.valueOf(value).equalsIgnoreCase(String.valueOf(fieldValue));

            } else if (operant == Operator.NOT_EQUALS) {
                return value == null 
                    ? String.isNotBlank(String.valueOf(fieldValue))
                    : !String.valueOf(value).equalsIgnoreCase(String.valueOf(fieldValue));
                
            } else if (operant == Operator.IN_SET) {
                return values.contains(String.valueOf(fieldValue).toLowerCase());
            }
            else {
                throw new CriteriaException('Invalid operator: ' + operant.name());
            }
        }
    }

}