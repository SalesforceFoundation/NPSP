/*
    Copyright (c) 2011, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this List of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this List of conditions and the following disclaimer in the
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
* @date 2014
* @group Utilities
* @description Controller class for the Force.com Typeahead component
*/
public with sharing class UTIL_Typeahead {

    /*******************************************************************************************************
    * @description Allow-list pattern for filterClause: one or more "field operator literal" comparisons
    * joined by AND/OR. Quoted literals cannot contain a single quote, so a caller cannot break out of the
    * literal to inject additional SOSL/SOQL syntax.
    ********************************************************************************************************/
    private static final Pattern FILTER_CLAUSE_PATTERN = Pattern.compile(
        '(?i)^\\s*[a-z_][a-z0-9_]*\\s*(=|!=|<>|<=|>=|<|>|like)\\s*(\'[^\']*\'|-?\\d+(\\.\\d+)?|true|false|null)' +
        '(\\s+(and|or)\\s+[a-z_][a-z0-9_]*\\s*(=|!=|<>|<=|>=|<|>|like)\\s*(\'[^\']*\'|-?\\d+(\\.\\d+)?|true|false|null))*\\s*$'
    );

    private static final Pattern FILTER_CLAUSE_SPLIT = Pattern.compile('(?i)\\s+(?:and|or)\\s+');
    private static final Pattern FILTER_FIELD_TOKEN = Pattern.compile('(?i)^\\s*([a-z_][a-z0-9_]*)\\s*(?:=|!=|<>|<=|>=|<|>|like)');

    public class InvalidFilterClauseException extends Exception {}

    /*******************************************************************************************************
    * @description Confirms every field referenced in an already syntax-validated filterClause actually
    * exists on sObjectName, using the same describe-driven validation UTIL_Where/UTIL_Describe use
    * elsewhere for dynamic SOQL. Guards against field names that are syntactically valid but bogus.
    ********************************************************************************************************/
    private static Boolean allFilterClauseFieldsAreValid(String filterClause, String sObjectName) {
        for (String clause : FILTER_CLAUSE_SPLIT.split(filterClause)) {
            Matcher fieldMatcher = FILTER_FIELD_TOKEN.matcher(clause);
            if (!fieldMatcher.find() || !UTIL_Describe.isValidField(sObjectName, fieldMatcher.group(1))) {
                return false;
            }
        }
        return true;
    }

    /*******************************************************************************************************
    * @description Searches the database (using SOSL) for the records that meet the criteria.
    * @param queryString (SearchQuery) The word of phrase to search for.
    * @param objectName (FieldSpec - ObjectTypeName) The SObjects for search. If not specified, Contact will be used.
    * @param fieldNames (FieldSpec - FieldList) The information (fields) that is returned in the text search result. 
    * @param fieldsToSearch (SearchGroup) The types of fields to search.
    * @param filterClause (DivisionFilter) Results filder.
    * @param orderBy Sorting order.
    * @param recordLimit Maximum number of rows returned in the text query. 
    * @return List<SObject> The records that meet the criteria.
    */
    @RemoteAction
    public static list<sObject> searchRecords(String queryString, String objectName, 
	    list<String> fieldNames, String fieldsToSearch, String filterClause, String orderBy, Integer recordLimit) {
	
	    if (queryString == null) return null;
	
	    String sQuery = String.escapeSingleQuotes( queryString );
	    if (sQuery.length() == 0) return null;
	
	    String sObjectName = (objectName == null) ? 'Contact' : String.escapeSingleQuotes( objectName );
	
	    String sInFields = 
	        (fieldsToSearch == null || fieldsToSearch == '' || fieldsToSearch.toUpperCase() == 'ALL') ? '' : 
	            ( ' IN ' + String.escapeSingleQuotes(fieldsToSearch) + ' FIELDS' );
	    
	    String sFields = (fieldNames == null || fieldNames.isEmpty()) ? 'Id, Name' : 
	        String.escapeSingleQuotes( String.join( fieldNames, ', ' ) );  
	    
	    String sOrder = ' ORDER BY ' + ( (orderBy == null || orderBy == '') ? 'Name' : String.escapeSingleQuotes(orderBy) ); 
	    
	    String sLimit = (recordLimit == null || recordLimit == 0 || recordLimit >= 2000) ? '' : 
	        ( ' LIMIT ' + String.valueOf(recordLimit));
	    
	    String sWhere = '';
	    if (filterClause != null && filterClause != '') {
	        if (!FILTER_CLAUSE_PATTERN.matcher(filterClause).matches() ||
	            !allFilterClauseFieldsAreValid(filterClause, sObjectName)) {
	            throw new InvalidFilterClauseException('Invalid filterClause.');
	        }
	        sWhere = ' WHERE ' + filterClause;
	    }
	
	    list<list<sObject>> results = Search.query(
	        'FIND \'' + sQuery + '*\'' + sInFields + 
	            ' RETURNING ' + sObjectName + '( ' + sFields + sWhere + sOrder + sLimit + ' )'
	    );
	    
	    return results[0];
    }  
}