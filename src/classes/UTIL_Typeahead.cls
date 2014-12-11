/*
    Copyright (c) 2011, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this List of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this List of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @group Utilities
* @description Controller class for the Force.com Typeahead component
*/
public with sharing class UTIL_Typeahead {

    @RemoteAction
    public static list<sObject> searchRecords( String queryString, String objectName, 
	    list<String> fieldNames, String fieldsToSearch, String filterClause, String orderBy, Integer recordLimit ) {
	
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
	    
	    // can't escape the filter clause
	    String sWhere = (filterClause == null || filterClause == '') ? '' : 
	        ( ' WHERE ' + filterClause );
	
	    list<list<sObject>> results = Search.query(
	        'FIND \'' + sQuery + '*\'' + sInFields + 
	            ' RETURNING ' + sObjectName + '( ' + sFields + sWhere + sOrder + sLimit + ' )'
	    );
	    
	    return results[0];
    }  
}