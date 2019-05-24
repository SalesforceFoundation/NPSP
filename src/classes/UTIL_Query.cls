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
* @group Utilities
* @description SOQL Builder
*/
public with sharing class UTIL_Query {
    /** @description Exception raised by the Query builder */
    public class UTIL_QueryException extends Exception {} 

    /** @description Error message when no SELECT field is provided */
    private static final String SELECT_FIELDS_REQUIRED = 'At least one SELECT field is required.';
    /** @description Error message when provided SELECT field is empty or null */
    private static final String SELECT_FIELD_CANNOT_BE_EMPTY = 'SELECT field cannot be empty or null.';
    /** @description Error message when FROM value is not provided */
    private static final String FROM_ENTITY_REQUIRED = 'The FROM value is required.';

    /** @description Operator AND used in the WHERE clause */
    private static final String AND_OPERATOR = ' AND ';

    /** @description Contains field names used in the SOQL' SELECT segment */
    private String[] selectFields = new String[0];
    /** @description An Sobject name or a relationship name used in the SOQL's FROM segment */
    private String entity = null;
    /** @description WHERE clauses used in the SOQL's WHERE segment */ 
    private String[] whereClauses = new String[0];
    /** @description ORDER BY clauses used in the SOQL's ORDER BY segment */ 
    private String orderBy;
    /** @description LIMIT statement used in the SOQL's LIMIT segment */ 
    private Integer limitRows;
    /** @description Indicates if toLabel() should be used on the Salutation field  */ 
    private Boolean isToLabelSalutation = false;

    /*********************************************************************************************************
    * @description The constructor
    */
    public UTIL_Query() {
    }

    /*********************************************************************************************************
    * @description Registers SELECT fields
    * @param fieldNames Set of field names
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withSelectFields(Set<String> fieldNames) {
        return withSelectFields(new List<String>(fieldNames));     
    } 
    
    /*********************************************************************************************************
    * @description Registers SELECT fields
    * @param fieldNames List of field names
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withSelectFields(String[] fieldNames) {
        selectFields.addAll(fieldNames);            
        return this;
    }

    /*********************************************************************************************************
    * @description Registers ORDER BY Field
    * @param orderBy the field expression to order by
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withOrderBy(String orderBy) {
        this.orderBy = orderBy;
        return this;
    }

    /*********************************************************************************************************
    * @description Registers LIMIT rows
    * @param limitRows The maximum number of rows to return
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withLimit(Integer limitRows) {
        this.limitRows = limitRows;
        return this;
    }

    /*********************************************************************************************************
    * @description Indicates to use toLabel() on the Salutation field
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withToLabelSalutation() {
        isToLabelSalutation = true;
        return this;
    }     
    
    /*********************************************************************************************************
    * @description Registers the FROM Sobject
    * @param sobjectType Type of the Sobject
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withFrom(Schema.SObjectType sObjectType) {           
        return withFrom(String.valueOf(sObjectType));
    }
    
    /*********************************************************************************************************
    * @description Registers FROM entity
    * @param entity An Sobject name or a relationship name
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withFrom(String entity) {
        this.entity = entity;            
        return this;
    }        
    
    /*********************************************************************************************************
    * @description Registers a clause to be used in the SOQL's WHERE clause
    * @param whereClause A WHERE clause
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withWhere(String whereClause) {
        if (String.isNotEmpty(whereClause)) {
            whereClauses.add(whereClause);
        }
        return this;
    }
    
    /*********************************************************************************************************
    * @description Registers WHERE clauses
    * @param whereClauses A list of WHERE clauses
    * @return UTIL_Query The instance of the Query builder
    */
    public UTIL_Query withWhere(String[] whereClauses) {
        if (whereClauses != null && !whereClauses.isEmpty()) {
            this.whereClauses.addAll(whereClauses);    
        }
        return this;
    } 
    
    /*********************************************************************************************************
    * @description Validates and builds a SOQL 
    * @return String The SOQL
    */
    public String build() {
        if (String.isBlank(entity)) {
            throw new UTIL_QueryException(FROM_ENTITY_REQUIRED);
        }

        String[] uniqueSelectFields = buildSelectFields();
        if (uniqueSelectFields.isEmpty()) {
            throw new UTIL_QueryException(SELECT_FIELDS_REQUIRED);
        }

        return String.format(
            'SELECT {0} FROM {1}{2}{3}{4}',
            new String[] {
                String.join(uniqueSelectFields, ', '),
                entity, 
                buildWhereClause(),
                buildOrderByClause(),
                buildLimitClause()
            }
        ).trim();
    }

    /*********************************************************************************************************
    * @description Validates SELECT fields and removes duplicates
    * @return String[] List of field names.
    */
    private String[] buildSelectFields() {
        String[] fields = new String[0];

        Set<String> collectedFields = new Set<String>();
        for (String fieldName : selectFields) {
            if (String.isBlank(fieldName)) {
                throw new UTIL_QueryException(SELECT_FIELD_CANNOT_BE_EMPTY);
            } 
            
            if (collectedFields.contains(fieldName.toLowerCase())) {
                continue;
            }

            fields.add(buildField(fieldName));
            collectedFields.add(fieldName.toLowerCase());
        }

        return fields;
    }

    /*********************************************************************************************************
    * @description Prepares a field to be used in the SOQL's SELECT segment
    * @param fieldName A field name
    * @return String The field name
    */
    private String buildField(String fieldName) {
        if (isToLabelSalutation && fieldName.equalsIgnoreCase('Salutation')) {
            return String.format('toLabel({0})', new String[] { fieldName });
        }

        return fieldName;
    }           

    /*********************************************************************************************************
    * @description Validates and builds the WHERE clause
    * @return String The WHERE clause
    */
    private String buildWhereClause() {
        if (whereClauses.isEmpty()) {
            return '';
        }
        
        String soqlWhere = ''; 
        
        for (String clause : whereClauses) {
            soqlWhere += String.isBlank(soqlWhere) ? '' : AND_OPERATOR;
            soqlWhere += clause;
        }
        
        return String.isBlank(soqlWhere) ? '' : ' WHERE ' + soqlWhere;
    }

    /*********************************************************************************************************
    * @description Builds the ORDER BY
    * @return String The ORDER BY
    */
    private String buildOrderByClause() {
        if (String.isEmpty(orderBy)) {
            return '';
        }

        return ' ORDER BY ' + orderBy;
    }

    /*********************************************************************************************************
    * @description Builds the LIMIT clause
    * @return String The LIMIT clause
    */
    private String buildLimitClause() {
        if (limitRows == null || limitRows <= 0) {
            return '';
        }

        return ' LIMIT ' + limitRows;
    }
}