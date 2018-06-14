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
* @description The SObject Finder use to query, filter, sort and limit number of records by using SOQL or SOSL
*/
public virtual class UTIL_Finder {
    /** @description Search exception class */
    public class SoslException extends Exception {}

    /** @description Message to indicate the Search is constructed incorrectly when sObjectType is not provided */
    @TestVIsible private static final String SOBJECT_TYPE_REQUIRED = 'sObjectType is required for the search';
    /** @description Message to indicate the Search is constructed incorrectly when no value is specified in FIND clause */
    @TestVIsible private static final String SEARCH_QUERY_REQUIRED = 'Search query is required for the search';
    /** @description Message to indicate the Search is constructed incorrectly when no sObject field is specified */
    @TestVIsible private static final String FIELDS_REQUIRED = 'At least one field required to be returned from the search';

    /** @description The sObjectType to query/search */
    private sObjectType sObjType;
    /** @description Fields to return from the query/search */
    @TestVisible private Set<String> selectFields {
        get {
            if (selectFields == null) {
                selectFields = new Set<String>{ 'Id' };
            }
            return selectFields;
        }
        set;
    }
    /** @description The WHERE clause */
    @TestVisible private UTIL_Where criteria;
    /** @description The ORDER BY segment */
    @TestVisible private UTIL_OrderBy orderBy;
    /** @description The LIMIT segment */
    private Integer limitRows;
    /** @description The search query applicable only when executeSearch() is to be applied */
    private String searchQuery;
    /** @description If true, the wildcard is added to searchQuery when executeSearch() is executed */
    private Boolean isWildcardSearch = false;

    /*******************************************************************************************************************
    * @description The constructor for the provided sObjectType
    */
    public UTIL_Finder(sObjectType sObjType) {
        this.sObjType = sObjType;
        this.orderBy = new UTIL_OrderBy();
        this.criteria = new UTIL_Where();
    }

    /*********************************************************************************************************
    * @description Sets SELECT fields in the SOQL or RETURNING fields in the SOSL
    * @param sObjFields Fields on the sObject (note: reference fields (Lookups/M-Ds) are not handled by this method)
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withSelectFields(Set<Schema.sObjectField> sObjFields) {
        for (Schema.sObjectField sObjField : sObjFields) {
            selectFields.add(String.valueOf(sObjField));
        }

        return this;
    }

    /*********************************************************************************************************
    * @description Sets SELECT fields in the SOQL or RETURNING fields in the SOSL
    * @param fieldNames Field names (include reference field names)
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withSelectFields(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            selectFields.add(fieldName);
        }

        return this;
    }

    /*********************************************************************************************************
    * @description Sets SELECT fields in the SOQL or RETURNING fields in the SOSL
    * @param fieldSet The Field Set fields
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withSelectFields(List<FieldSetMember> fieldSet) {
        for (FieldSetMember member : fieldSet) {
            selectFields.add(member.getFieldPath());
        }

        return this;
    }

    /*********************************************************************************************************
    * @description Adds the field expression to the WHERE clause
    * @param fieldExp The field expression
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withWhere(UTIL_Where.FieldExpression fieldExp) {
        criteria.add(fieldExp);

        return this;
    }

    /*********************************************************************************************************
    * @description Sets the WHERE clause
    * @param criteria The WHERE clause
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withWhere(UTIL_Where criteria) {
        this.criteria = criteria;

        return this;
    }
    
    /*********************************************************************************************************
    * @description Adds the field to the ORDER BY clause
    * @param sObjField The field
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withOrderBy(Schema.sObjectField sObjField) {
        return withOrderBy(new List<Schema.sObjectField>{ sObjField });
    }

    /*********************************************************************************************************
    * @description Adds fields to the ORDER BY clause
    * @param sObjFields Fields
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withOrderBy(List<Schema.sObjectField> sObjFields) {
        for (Schema.sObjectField sObjField : sObjFields) {
            orderBy.add(new UTIL_OrderBy.FieldExpression(sObjField));
        }

        return this;
    }

    /*********************************************************************************************************
    * @description Adds the field expression to the ORDER BY clause
    * @param fieldExp The field expression
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withOrderBy(UTIL_OrderBy.FieldExpression fieldExp) {
        orderBy.add(fieldExp);

        return this;
    }

    /*********************************************************************************************************
    * @description Sets max number of records to be returned
    * @param limitRows The max number of records to return
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withLimit(Integer limitRows) {
        this.limitRows = limitRows;

        return this;
    }

    /*********************************************************************************************************
    * @description Sets search query applicable only when executeSearch() is being called
    * @param searchQuery The search query
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withSearchQuery(String searchQuery) {
        this.searchQuery = searchQuery;

        return this;
    }

    /*********************************************************************************************************
    * @description Specifies if the wildcard should be added at the end of the search query.
    * It is applicable only when executeSearch() is being called.
    * @return UTIL_Finder The object instance
    */
    public UTIL_Finder withWildcard() {
        isWildcardSearch = true;

        return this;
    }

    /*********************************************************************************************************
    * @description Determines if the SOQL will be used to query for records
    * @return Boolean
    */
    public Boolean isSoql() {
        return criteria.isFilterable();
    }

    /*********************************************************************************************************
    * @description Queries records, filters them (where applicable) and applies post sorting (if applicable)
    * @return List<sObject>
    */
    public List<sObject> find() {
        prepSelectFields();

        if (isSoql()) {
            String soql = queryBuilder().build();
            return orderBy.sort(queryRecords(soql));

        } else {
            String sosl = searchBuilder().build();
            return executeSearch(sosl);
        }
    }

    /*********************************************************************************************************
    * @description Adds WHERE and ORDER BY fields into SELECT fields for potential post filtering and sorting
    * @return void
    */
    private void prepSelectFields() {
        selectFields.addAll(criteria.getFields());
        selectFields.addAll(orderBy.getFields());
    }

    /*********************************************************************************************************
    * @description Returns SOQL builder
    * @return UTIL_Query
    */
    @TestVisible private UTIL_Query queryBuilder() {
        return new UTIL_Query()
            .withFrom(sObjType)
            .withSelectFields(selectFields)
            .withWhere(criteria.build())
            .withOrderBy(orderBy.build())
            .withLimit(limitRows);
    }

    /*********************************************************************************************************
    * @description Returns search (SOSL) builder
    * @return SearchBuilder
    */
    @TestVisible private SearchBuilder searchBuilder() {
        return new SearchBuilder()
            .withFind(criteria.build())
            .withSearchGroup(criteria.isNameField() ? 'NAME' : 'ALL')
            .withReturning(sObjType)
            .withFields(selectFields)
            .withOrderBy(orderBy.build());
    }

    /*********************************************************************************************************
    * @description Searches for records based on the specified searchQuery
    * @return List<sObject>
    */
    public List<sObject> executeSearch() {
        String searchText = String.escapeSingleQuotes(searchQuery) + (isWildcardSearch ? '*' : '');

        prepSelectFields();

        String sosl = new SearchBuilder()
            .withFind(searchText)
            .withSearchGroup('ALL')
            .withReturning(sObjType)
            .withFields(selectFields)
            .withOrderBy(orderBy.build())
            .build();

        return executeSearch(sosl);
    }

    /*********************************************************************************************************
    * @description Executes the SOSL, filters, sorts and limit number of returned records
    * @param sosl The SOSL
    * @return List<sObject>
    */
    private List<sObject> executeSearch(String sosl) {
        List<sObject> records = criteria.filter(searchRecords(sosl));
        records = orderBy.sort(records);
        return getLimitRows(records);
    }

    /*********************************************************************************************************
    * @description Queries database based on the provided SOQL string
    * @param soql The query string
    * @return List<sObject>
    */
    public virtual List<sObject> queryRecords(String soql) {
        return Database.query(soql);
    }

    /*********************************************************************************************************
    * @description Searches database based on the provided SOSL string
    * @param sosl The search string
    * @return List<sObject>
    */
    public virtual List<sObject> searchRecords(String sosl) {
        return Search.query(sosl)[0];
    }

    /*********************************************************************************************************
    * @description Returns LIMIT number of records
    * @param records The sObjects 
    * @return List<sObject>
    */
    private List<sObject> getLimitRows(List<sObject> records) {
        if (limitRows == null || limitRows <= 0 || limitRows >= records.size()) {
            return records;
        }

        List<sObject> result = new List<sObject>();
        for (Integer i = 0; i < limitRows && i < records.size(); i++) {
            result.add(records[i]);
        }
        return result;
    }





    /** @description The search (SOSL) builder class */
    @TestVisible private class SearchBuilder {
        /** @description The search query used in FIND clause */
        private String searchQuery;
        /** @description The search group: search in all fields or just Name fields */
        private String searchGroup;
        /** @description The sObjectType to search on */
        private sObjectType sObjType;
        /** @description Fields to return */
        private Set<String> fields;
        /** @description The ORDER BY clause */
        private String orderBy;

        /*********************************************************************************************************
        * @description Constructor
        */
        @TestVisible private SearchBuilder() {
            fields = new Set<String>();
            searchGroup = 'ALL';
        }

        /*********************************************************************************************************
        * @description Sets the search query to the SOSL
        * @param searchQuery The search query to be used in the FIND clause
        * @return SearchBuilder The object instance
        */
        @TestVisible private SearchBuilder withFind(String searchQuery) {
            this.searchQuery = searchQuery;
            return this;
        }

        /*********************************************************************************************************
        * @description Sets the search group
        * @param searchGroup The value indicating if ALL or just Name fields will be searched
        * @return SearchBuilder The object instance
        */
        @TestVisible private SearchBuilder withSearchGroup(String searchGroup) {
            this.searchGroup = searchGroup;
            return this;
        }

        /*********************************************************************************************************
        * @description Sets the sObjectType to search
        * @param sObjType The sObjectType
        * @return SearchBuilder The object instance
        */
        @TestVisible private SearchBuilder withReturning(sObjectType sObjType) {
            this.sObjType = sObjType;
            return this;
        }

        /*********************************************************************************************************
        * @description Sets fields to return from the search
        * @param fields The set of fields to return in the SOSL
        * @return SearchBuilder The object instance
        */
        @TestVisible private SearchBuilder withFields(Set<String> fields) {
            this.fields = buildSelectFields(fields);
            return this;
        }
        
        /*********************************************************************************************************
        * @description Validates SELECT fields and removes duplicates
        * @return Set<String> Set of field names.
        */
        private Set<String> buildSelectFields(Set<String> fields) {
            Set<String> result = new Set<String>();    
            Set<String> uniqueFields = new Set<String>();
            
            for (String fieldName : fields) {
                if (String.isBlank(fieldName)) {
                    continue;
                } 
                
                if (uniqueFields.contains(fieldName.toLowerCase())) {
                    continue;
                }
    
                result.add(fieldName);
                uniqueFields.add(fieldName.toLowerCase());
            }
    
            return result;
        }

        /*********************************************************************************************************
        * @description Sets the ORDER BY clause
        * @param orderBy The ORDE BY clause
        * @return SearchBuilder The object instance
        */
        @TestVisible private SearchBuilder withOrderBy(String orderBy) {
            this.orderBy = orderBy;
            return this;
        }

        /*********************************************************************************************************
        * @description Builds the SOSL query
        * @return String
        */
        @TestVisible private String build() {
            validate();

            return String.format(
                'FIND \'\'{0}\'\' IN {1} FIELDS RETURNING {2}({3}{4})',
                new String[] { 
                    searchQuery,
                    searchGroup,
                    String.valueOf(sObjType), 
                    String.join(new List<String>(fields), ', '), 
                    buildOrderBy()
                }
            );
        }

        /*********************************************************************************************************
        * @description Validates the SOSL
        * @return void
        */
        private void validate() {
            if (sObjType == null) {
                throw new SoslException(SOBJECT_TYPE_REQUIRED);
            }
            if (String.isBlank(searchQuery)) {
                throw new SoslException(SEARCH_QUERY_REQUIRED);
            }
            if (fields == null || fields.isEmpty()) {
                throw new SoslException(FIELDS_REQUIRED);
            }
        }

        /*********************************************************************************************************
        * @description Builds the ORDER BY clause (if any)
        * @return String
        */
        private String buildOrderBy() {
            return String.isBlank(orderBy) ? '' : ' ORDER BY ' + orderBy;
        }
    }
}