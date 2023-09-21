/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group HGE
* @group-content
* @description Controller for the geFormFieldLookup Lightning Web Component.
*/
public with sharing class GE_LookupController {

    static final Integer RESULTS_LIMIT = 50;

    /**
     * Search for an SObject by its name field.
     * Objects without Name fields (Case, Task, Event...) are not compatible with this component.
     *
     * @param searchValue   Value to search for
     * @param sObjectType   Type of SObject to Search
     *
     * @return              A List<LookupResult> containing records that match the search criteria.
     */

    /**
     * @description Search for RecordTypes for the given SObject
     *
     * @param searchValue   Value to search RecordType Names with
     * @param sObjectType   Parent SObject Type to search Record Types for
     *
     * @return              A List<LookupResult> containing Record Types that match the search criteria.
     */
    @AuraEnabled
    public static List<LookupResult> doSearchRecordType(String searchValue, String sObjectType) {
        String formattedValue = '%' + String.escapeSingleQuotes(searchValue) + '%';
        String queryTemplate = 'SELECT Id, Name FROM RecordType WHERE SObjectType = :sObjectType AND Name LIKE :formattedValue LIMIT {0}';
        List<String> args = new List<String> {String.valueOf(RESULTS_LIMIT)};
        String query = String.format(queryTemplate, args);

        List<LookupResult> results = new List<LookupResult>();
        for (SObject result : Database.query(query)) {
            results.add(new LookupResult(result));
        }

        return results;
    }

    /**
     * @description Search for an SObject by its name field using SOSL
     *     Objects without Name fields (Case, Task, Event...) are not compatible with this component.
     *
     * @param searchValue   Value to search for
     * @param sObjectType   Type of SObject to Search
     *
     * @return              A List<LookupResult> containing records that match the search criteria.
     */
    @TestVisible
    private static List<LookupResult> doSearchSOSL(String searchValue, String sObjectType) {
        String formattedValue = '\'' + String.escapeSingleQuotes(searchValue) + '\'';
        String searchTemplate = 'FIND {0} IN NAME FIELDS Returning {1} LIMIT {2}';
        List<String> args = new List<String>{formattedValue, sObjectType + '(Name)', String.valueOf(RESULTS_LIMIT)};
        String query = String.format(searchTemplate, args);

        List<LookupResult> results = new List<LookupResult>();
        for (List<SObject> queryResults : Search.query(query)) {
            for (SObject queryResult : queryResults) {
                results.add(new LookupResult(queryResult));
            }
        }
        return results;
    }

    /**
     * @description  Search for an SObject by its name field using SOQL
     *      Objects without Name fields (Case, Task, Event...) are not compatible with this component.
     *
     * @param searchValue   Value to search for
     * @param sObjectType   Type of SObject to Search
     *
     * @return              A List<LookupResult> containing records that match the search criteria.
     */
    @TestVisible
    private static List<LookupResult> doSearchSOQL(String searchValue, String sObjectType) {
        String formattedValue = '%' + searchValue + '%';
        String queryTemplate = 'SELECT Id, Name FROM {0} WHERE Name LIKE :formattedValue LIMIT {1}';
        List<String> args = new List<String>{sObjectType, String.valueOf(RESULTS_LIMIT)};
        String query = String.format(queryTemplate, args);

        List<LookupResult> results = new List<LookupResult>();
        for (SObject result : Database.query(query)) {
            results.add(new LookupResult(result));
        }

        return results;
    }


    /**
     * Class representing an option for a lookup search result in Gift Entry
     */
    public class LookupResult {
        @AuraEnabled public Id value;
        @AuraEnabled public String displayValue;

        public LookupResult(SObject result) {
            this.value = (Id)result.get('Id');
            this.displayValue = (String)result.get('Name');
        }
    }
}
