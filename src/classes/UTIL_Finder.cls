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
* @description SObject Finder
*/
public with sharing class UTIL_Finder implements UTIL_QueryApi.Finder {
    public class SoslException extends Exception {}

    @TestVIsible private static final String SOBJECT_TYPE_REQUIRED = 'sObjectType is required for the search';
    @TestVIsible private static final String SEARCH_CRITERIA_REQUIRED = 'Search criteria is required for the search';
    @TestVIsible private static final String FIELDS_REQUIRED = 'At least one field required to be returned from the search';

    private sObjectType sObjType;
    private Set<String> selectFields {
        get {
            if (selectFields == null) {
                selectFields = new Set<String>{ 'Id' };
            }
            return selectFields;
        }
        set;
    }
    private UTIL_Where criteria;
    private UTIL_OrderBy orderBy;
    private Integer limitRows;

    /*******************************************************************************************************************
    * @description UTIL_Finder constructor for the provided sObject Type
    */
    public UTIL_Finder(sObjectType sObjType) {
        this.sObjType = sObjType;
        this.orderBy = new UTIL_OrderBy();
        this.criteria = new UTIL_Where();
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with all passed in select fields
    */
    public UTIL_Finder withSelectFields(Set<Schema.sObjectField> sObjFields, Schema.SObjectField referenceField) {
        for (Schema.sObjectField sObjField : sObjFields) {
            selectFields.add(referenceField.getDescribe().getRelationshipName() + '.' + String.valueOf(sObjField));
        }

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with all passed in select fields
    */
    public UTIL_Finder withSelectFields(Set<Schema.sObjectField> sObjFields) {
        for (Schema.sObjectField sObjField : sObjFields) {
            selectFields.add(String.valueOf(sObjField));
        }

        return this;
    }

    public UTIL_Finder withSelectFields(List<FieldSetMember> fieldSet) {
        for (FieldSetMember member : fieldSet) {
            selectFields.add(member.getFieldPath());
        }

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with where condition
    */
    public UTIL_Finder withWhere(UTIL_Where.FieldExpression fieldExp) {
        criteria.add(fieldExp);

        return this;
    }

    public UTIL_Finder withWhere(UTIL_Where criteria) {
        this.criteria = criteria;

        return this;
    }
    

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with passed in order by field
    */
    public UTIL_Finder withOrderBy(Schema.sObjectField sObjField) {
        return withOrderBy(new List<Schema.sObjectField>{ sObjField });
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with passed in order by fields
    */
    public UTIL_Finder withOrderBy(List<Schema.sObjectField> sObjFields) {
        for (Schema.sObjectField sObjField : sObjFields) {
            orderBy.add(new UTIL_OrderBy.FieldExpression(sObjField));
        }

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with passed in order by field
    */
    public UTIL_Finder withOrderBy(UTIL_OrderBy.FieldExpression field) {
        orderBy.add(field);

        return this;
    }

    /*******************************************************************************************************************
    * @description Returns UTIL_Finder with passed in limit number
    */
    public UTIL_Finder withLimit(Integer limitRows) {
        this.limitRows = limitRows;

        return this;
    }

    public Boolean isSoql() {
        return criteria.isFilterable();
    }

    /*******************************************************************************************************************
    * @description Returns all sObjects for this sObject Type
    */
    public List<sObject> find() {
        List<sObject> records;

        if (orderBy.isPostSort()) {
            selectFields.addAll(orderBy.getFields());
        }

        if (isSoql() ) {
            records = Database.query(buildQuery());
            return orderBy.sort(records);

        } else {
            selectFields.addAll(criteria.getFields());
            records = criteria.filter(Search.query(buildSearch())[0]);
            records = orderBy.sort(records);
            return getLimitRows(records);
        }
    }

    private String buildQuery() {
        return new UTIL_Query()
            .withFrom(sObjType)
            .withSelectFields(selectFields)
            .withWhere(criteria.build())
            .withOrderBy(orderBy.build())
            .withLimit(limitRows)
            .build();
    }

    private String buildSearch() {
        return new SearchBuilder()
            .withFind(criteria.build())
            .withSearchGroup(criteria.isNameField() ? 'NAME' : 'ALL')
            .withReturning(sObjType)
            .withFields(selectFields)
            .withOrderBy(orderBy.build())
            .build();
    }

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

    @TestVisible private with sharing class SearchBuilder {
        private String searchCriteria;
        private String searchGroup;
        private sObjectType sObjType;
        private Set<String> fields;
        private String orderBy;
        private Integer limitRows;

        @TestVisible private SearchBuilder() {
            fields = new Set<String>();
            searchGroup = 'ALL';
        }

        @TestVisible private SearchBuilder withFind(String searchCriteria) {
            this.searchCriteria = searchCriteria;
            return this;
        }

        @TestVisible private SearchBuilder withSearchGroup(String searchGroup) {
            this.searchGroup = searchGroup;
            return this;
        }

        @TestVisible private SearchBuilder withReturning(sObjectType sObjType) {
            this.sObjType = sObjType;
            return this;
        }

        @TestVisible private SearchBuilder withFields(Set<String> fields) {
            this.fields = fields;
            return this;
        }

        @TestVisible private SearchBuilder withOrderBy(String orderBy) {
            this.orderBy = orderBy;
            return this;
        }

        @TestVisible private SearchBuilder withLimit(Integer limitRows) {
            this.limitRows = limitRows;
            return this;
        }

        @TestVisible private String build() {
            validate();

            return String.format(
                'FIND \'\'{0}\'\' IN {1} FIELDS RETURNING {2}({3}{4}{5})',
                new String[] { 
                    searchCriteria,
                    searchGroup,
                    String.valueOf(sObjType), 
                    String.join(new List<String>(fields), ', '), 
                    buildOrderBy(), 
                    buildLimit() 
                }
            );
        }

        private void validate() {
            if (sObjType == null) {
                throw new SoslException(SOBJECT_TYPE_REQUIRED);
            }
            if (String.isBlank(searchCriteria)) {
                throw new SoslException(SEARCH_CRITERIA_REQUIRED);
            }
            if (fields == null || fields.isEmpty()) {
                throw new SoslException(FIELDS_REQUIRED);
            }
        }

        private String buildOrderBy() {
            return String.isBlank(orderBy) ? '' : ' ORDER BY ' + orderBy;
        }

        @TestVisible private String buildLimit() {
            return limitRows == null || limitRows <= 0 || limitRows >= 2000
                ? ''
                : ' LIMIT ' + limitRows;
        }


    }
}