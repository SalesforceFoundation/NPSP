/*
    Copyright (c) 2018 Salesforce.org
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
* @description Unit tests for UTIL_Finder class
*/
@isTest(isParallel=true)
private class UTIL_Finder_TEST {
    /** @description Fields that should be used in the SOQL SELECT clause */
    private static final Set<String> SELECT_FIELDS = new Set<String>{ 'FirstName', 'LastName', 'Title' };
    private static final Set<Schema.sObjectField> SOBJECT_FIELDS = new Set<Schema.sObjectField>{ Contact.FirstName, Contact.LastName, Contact.Title };


    /*********************************************************************************************************
    * @description Creates a Contact
    * @return void
    */
    @TestSetup
    private static void setup() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /*******************************************************************************************************
    * @description Verifies a SOSL with all possible segments is built
    */
    @isTest static private void searchBuildReturnsSoslWithAllElements() {
        String sosl = new UTIL_Finder.SearchBuilder()
            .withFind('foo*')
            .withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .withOrderBy('Department')
            .build();
            
        String expectedSosl = 'FIND \'foo*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title ORDER BY Department)';
        assertSearch(expectedSosl, sosl);
    }

    /*******************************************************************************************************
    * @description Verifies a SOSL is built correctly when ORDER BY is empty string
    */
    @isTest static private void searchBuildReturnsSoslWhenOrderByIsNotProvided() {
        String sosl = new UTIL_Finder.SearchBuilder()
            .withFind('foo*')
            .withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .build();
            
        String expectedSosl = 'FIND \'foo*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title)';
        assertSearch(expectedSosl, sosl);
    }

    /*******************************************************************************************************
    * @description Verifies a SOSL is built correctly when the FIND clause is a complex search criteria
    */
    @isTest static private void searchBuildReturnsSoslWithLogicOperatorsInTheFind() {
        String sosl = new UTIL_Finder.SearchBuilder()
            .withFind('foo* AND bar*')
            .withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .withOrderBy('Department')
            .build();
            
        String expectedSosl = 'FIND \'foo* AND bar*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title ORDER BY Department)';
        assertSearch(expectedSosl, sosl);
    }

    /*******************************************************************************************************
    * @description Verifies build() throws an exception when search criteria is not provided
    */
    @isTest static private void searchBuildThrowsAnExceptionWhenSearchCriteriaIsNotProvided() {
        UTIL_Finder.SearchBuilder utilSearch = new UTIL_Finder.SearchBuilder()
            .withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS);
            
        Exception actual;
        try {
            utilSearch.build();
        } catch(Exception e) {
            actual = e;
        }

        System.assertNotEquals(null, actual, 'An exception should be thrown');
        System.assertEquals(UTIL_Finder.SEARCH_QUERY_REQUIRED, actual.getMessage());
    }

    /*******************************************************************************************************
    * @description Verifies build() throws an exception when the sObjectType is not provided
    */
    @isTest static private void searchBuildThrowsAnExceptionWhenSObjectTypeIsNotProvided() {
        UTIL_Finder.SearchBuilder utilSearch = new UTIL_Finder.SearchBuilder()
            .withFind('foo*')
            .withFields(SELECT_FIELDS);

        Exception actual;
        try {
            utilSearch.build();
        } catch(Exception e) {
            actual = e;
        }

        System.assertNotEquals(null, actual, 'An exception should be thrown');
        System.assertEquals(UTIL_Finder.SOBJECT_TYPE_REQUIRED, actual.getMessage());
    }

    /*******************************************************************************************************
    * @description Verifies build() throws an exception when returning fields are not provided
    */
    @isTest static private void searchBuildThrowsAnExceptionWhenFieldsAreNotProvided() {
        UTIL_Finder.SearchBuilder utilSearch = new UTIL_Finder.SearchBuilder()
            .withFind('foo*')
            .withReturning(Contact.sObjectType);
            
        Exception actual;
        try {
            utilSearch.build();
        } catch(Exception e) {
            actual = e;
        }

        System.assertNotEquals(null, actual, 'An exception should be thrown');
        System.assertEquals(UTIL_Finder.FIELDS_REQUIRED, actual.getMessage());
    }

    /*******************************************************************************************************
    * @description Verifies find() when query having empty
    * WHERE and ORDER BY clauses returns no record.
    */
    @isTest static private void findSucceedsWhenQueryReturnsEmptyList() {
        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType);

        List<sObject> actual = finder.find();
        System.assertEquals(0, actual.size());

        System.assert(finder.isSoql(), 'SOQL should be executed since WHERE clause is empty');
    }

    /*******************************************************************************************************
    * @description Verifies find() when query having WHERE, ORDER BY and LIMIT clauses returns no record.
    */
    @isTest static private void findSucceedsWhenCompleteQueryReturnsEmptyList() {
        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(new UTIL_Where.FieldExpression(Contact.Department).equals('Sales'))
            .withOrderBy(Contact.Department)
            .withLimit(100);

        List<sObject> actual = finder.find();
        System.assertEquals(0, actual.size());

        System.assert(finder.isSoql(), 'SOQL should be executed since WHERE does not contain an encrypted field');
    }

    /*******************************************************************************************************
    * @description Verifies find() when query applies post sorting on empty record list.
    */
    @isTest static private void findSucceedsWhenQueryReturnsEmptyListForPostSorting() {
        UTIL_OrderBy.FieldExpression orderByField = new UTIL_OrderBy.FieldExpression(Contact.LastName);
        orderByField.isSortable = false;

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(new UTIL_Where.FieldExpression(Contact.Department).equals('Sales'))
            .withOrderBy(orderByField)
            .withLimit(100);

        List<sObject> actual = finder.find();
        System.assertEquals(0, actual.size());

        System.assert(finder.isSoql(), 'SOQL should be executed since WHERE does not contain an encrypted field');
        System.assert(finder.orderBy.isPostSort(), 'Post sort should be applied');
    }

    /*******************************************************************************************************
    * @description Verifies find() returns minimum of LIMIT and returned records size.
    */
    @isTest static private void findReturnsMinLimitAndRecordSizeRecords() {
        List<sObject> records = getTestContacts();
        Integer limitRows = records.size() + 1;

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withLimit(limitRows);

        finder.returnQueryRecords(records);
        List<sObject> actual = finder.find();

        System.assertEquals(records.size(), actual.size());
    }

    /*******************************************************************************************************
    * @description Verifies find() when query having empty
    * WHERE and ORDER BY clauses returns list of records.
    */
    @isTest static private void findSucceedsWhenCriteriaAndOrderByClausesAreEmpty() {
        List<sObject> records = getTestContacts();

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS);

        finder.returnQueryRecords(records);
        List<sObject> actual = finder.find();

        System.assert(finder.isSoql(), 'SOQL should be executed since WHERE clause is empty');

        System.assertEquals(records.size(), actual.size());
        for (Integer i = 0; i < records.size(); i++) {
            System.assertEquals((String) records[i].get('LastName'), (String) actual[i].get('LastName'));
            System.assertEquals((String) records[i].get('FirstName'), (String) actual[i].get('FirstName'));
            System.assertEquals((String) records[i].get('Title'), (String) actual[i].get('Title'));
        }
    }

    /*******************************************************************************************************
    * @description Verifies find() when query applies post sorting on returned records.
    */
    @isTest static private void findQueryIntegrationTestWithPostSorting() {
        List<sObject> records = getTestContacts();
        insert records;

        UTIL_OrderBy.FieldExpression orderByField = new UTIL_OrderBy.FieldExpression(Contact.LastName);
        orderByField.isSortable = false;

        UTIL_Finder finder = new UTIL_Finder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(new UTIL_Where.FieldExpression(Contact.Department).equals('Sales'))
            .withOrderBy(orderByField)
            .withLimit(100);

        List<sObject> actual = finder.find();

        System.assert(finder.isSoql(), 'SOQL should be executed since WHERE does not contain an encrypted field');
        System.assert(finder.orderBy.isPostSort(), 'Post sort should be applied');

        List<sObject> expectedRecords = new List<sObject>{
            records[1], records[5], records[4]
        };
        System.assertEquals(expectedRecords.size(), actual.size());

        for (Integer i = 0; i < actual.size(); i++) {
            System.assertEquals('Sales', (String) actual[i].get('Department'));
            System.assertEquals((String) expectedRecords[i].get('LastName'), (String) actual[i].get('LastName'));
        }
    }

    /*******************************************************************************************************
    * @description Verifies find() when query does not post sort returned records.
    */
    @isTest static private void findQueryIntegrationTest() {
        List<sObject> records = getTestContacts();
        insert records;

        UTIL_Finder finder = new UTIL_Finder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(new UTIL_Where.FieldExpression(Contact.Department).equals('Sales'))
            .withOrderBy(Contact.Department)
            .withLimit(100);

        List<sObject> actual = finder.find();

        System.assert(finder.isSoql(), 'SOQL should be executed since WHERE does not contain an encrypted field');
        System.assert(!finder.orderBy.isPostSort(), 'Post sort should not be applied');

        List<sObject> expectedRecords = new List<sObject>{
            records[1], records[5], records[4]
        };
        System.assertEquals(expectedRecords.size(), actual.size());

        for (Integer i = 0; i < actual.size(); i++) {
            System.assertEquals('Sales', (String) actual[i].get('Department'));
        }
    }

    /*******************************************************************************************************
    * @description Verifies find() when search returns no record.
    */
    @isTest static private void findSucceedsWhenSearchReturnsEmptyList() {
        UTIL_Where.FieldExpression whereExp = new UTIL_Where.FieldExpression(Contact.Department).equals('Sales');
        whereExp.isFilterable = false;

        UTIL_OrderBy.FieldExpression orderByField = new UTIL_OrderBy.FieldExpression(Contact.LastName);
        orderByField.isSortable = false;

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(whereExp)
            .withOrderBy(orderByField)
            .withLimit(100);

        List<sObject> actual = finder.find();
        System.assertEquals(0, actual.size());

        System.assert(!finder.isSoql(), 'SOSL should be executed');
        System.assert(finder.orderBy.isPostSort(), 'Post sort should be applied');
        System.assertEquals('FIND \'Sales*\' IN ALL FIELDS RETURNING Contact(Id, FirstName, LastName, Title, Department)', finder.sosl);
    }    

    /*******************************************************************************************************
    * @description Verifies find() when search returns records and then applies post filtering and sorting.
    */
    @isTest static private void findSucceedsWhenSearchReturnsRecordsForPostFilteringAndSorting() {
        UTIL_Where.FieldExpression whereExp = new UTIL_Where.FieldExpression(Contact.Department).equals('Sales');
        whereExp.isFilterable = false;

        UTIL_OrderBy.FieldExpression orderByField = new UTIL_OrderBy.FieldExpression(Contact.LastName);
        orderByField.isSortable = false;

        List<sObject> records = getTestContacts();

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(whereExp)
            .withOrderBy(orderByField)
            .withLimit(100);

        finder.returnSearchRecords(records);
        List<sObject> actual = finder.find();

        System.assert(!finder.isSoql(), 'SOSL should be executed since WHERE contains an encrypted field');
        System.assert(finder.orderBy.isPostSort(), 'Post sort should be applied');

        List<sObject> expectedRecords = new List<sObject>{
            records[1], records[5], records[4]
        };
        System.assertEquals(expectedRecords.size(), actual.size());

        for (Integer i = 0; i < actual.size(); i++) {
            System.assertEquals('Sales', (String) actual[i].get('Department'));
            System.assertEquals((String) expectedRecords[i].get('LastName'), (String) actual[i].get('LastName'));
        }

        System.assertEquals('FIND \'Sales*\' IN ALL FIELDS RETURNING Contact(Id, FirstName, LastName, Title, Department)', finder.sosl);
    }

    /*******************************************************************************************************
    * @description Verifies find() when search returns sorted records and then applies post filtering.
    */
    @isTest static private void findSucceedsWhenSearchReturnsRecordsForPostFiltering() {
        UTIL_Where.FieldExpression whereExp = new UTIL_Where.FieldExpression(Contact.LastName).equals('Clark');
        whereExp.isFilterable = false;

        List<sObject> recordsSortedByDept = new List<sObject>{
            new Contact(LastName = 'Clark', FirstName = 'Abby', Title = 'Executive'),
            new Contact(LastName = 'Smith', FirstName = 'Jane', Title = 'Business Manager', Department = 'Business'),
            new Contact(LastName = 'Smith', FirstName = 'John', Title = 'Administrator', Department = 'IT'),
            new Contact(LastName = 'Clark', FirstName = 'Kent', Title = 'Business Manager', Department = 'Sales'),
            new Contact(LastName = 'Roberston', Title = 'Director', Department = 'Sales'),
            new Contact(LastName = 'Jackson', FirstName = 'Ben', Department = 'Sales'),
            new Contact(LastName = 'Clark', FirstName = 'Kent', Title = 'Administrator', Department = 'Support')
        };

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(whereExp)
            .withOrderBy(new UTIL_OrderBy.FieldExpression(Contact.Department))
            .withLimit(100);

        finder.returnSearchRecords(recordsSortedByDept);
        List<sObject> actual = finder.find();

        System.assert(!finder.isSoql(), 'SOSL should be executed since WHERE contains an encrypted field');
        System.assert(!finder.orderBy.isPostSort(), 'Post sort should not be applied');

        List<sObject> expectedRecords = new List<sObject>{
            recordsSortedByDept[0], recordsSortedByDept[3], recordsSortedByDept[6]
        };
        System.assertEquals(expectedRecords.size(), actual.size());

        for (Integer i = 0; i < actual.size(); i++) {
            System.assertEquals((String) expectedRecords[i].get('LastName'), (String) actual[i].get('LastName'));
        }

        System.assertEquals('FIND \'Clark*\' IN ALL FIELDS RETURNING Contact(Id, FirstName, LastName, Title, Department ORDER BY Department)', finder.sosl);
    }

    /*******************************************************************************************************
    * @description Verifies find() when search is applied on the Set values
    */
    @isTest static private void findSucceedsWhenSearchingForValuesInTheSet() {        
        UTIL_Where.FieldExpression whereExp = new UTIL_Where.FieldExpression(Contact.LastName)
            .inSet(new Set<String>{ 'Smith', 'CLARK' });
        whereExp.isFilterable = false;

        List<sObject> records = getTestContacts();
        insert records;

        UTIL_Finder finder = new UTIL_Finder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(whereExp);
        
        UTIL_UnitTestData_TEST.setFixedSearchResults(records);
        List<sObject> actual = finder.find();

        System.assert(!finder.isSoql(), 'SOSL should be executed since WHERE contains an encrypted field');

        List<sObject> expectedRecords = new List<sObject>{
            records[0], records[1], records[2], records[3], records[6]
        };
        System.assertEquals(expectedRecords.size(), actual.size());

        for (Integer i = 0; i < actual.size(); i++) {
            System.assertEquals((String) expectedRecords[i].get('LastName'), (String) actual[i].get('LastName'));
        }

        System.assertEquals('FIND \'(smith OR clark)\' IN ALL FIELDS RETURNING Contact(Id, FirstName, LastName, Title)', finder.searchBuilder().build());
    }

    /*******************************************************************************************************
    * @description Verifies find() when complex post filtering is applied on the Set values
    */
    @isTest static private void findSucceedsWhenPostFilteringIsAppliedOnOnTheInSetSearch() { 
        List<sObject> records = getTestContacts();
        insert records;

        UTIL_Where.FieldExpression lastNameExp = new UTIL_Where.FieldExpression(Contact.LastName)
            .inSet(new Set<String>{ 'Smith', 'CLARK', 'Roberston' });
        lastNameExp.isFilterable = false;

        UTIL_Finder finder = new UTIL_Finder(Contact.SObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(new UTIL_Where().add(UTIL_Where.AndGroup()
                .add(lastNameExp)
                .add(new UTIL_Where.FieldExpression(Contact.FirstName).inSet(new Set<String>{ 'Jane', null }))
            ));
        
        UTIL_UnitTestData_TEST.setFixedSearchResults(records);
        List<sObject> actual = finder.find();

        System.assert(!finder.isSoql(), 'SOSL should be executed since WHERE contains an encrypted field');

        List<sObject> expectedRecords = new List<sObject>{
            records[2], records[4]
        };
        System.assertEquals(expectedRecords.size(), actual.size());

        for (Integer i = 0; i < actual.size(); i++) {
            System.assertEquals((String) expectedRecords[i].get('LastName'), (String) actual[i].get('LastName'));
            System.assertEquals((String) expectedRecords[i].get('FirstName'), (String) actual[i].get('FirstName'));
        }

        System.assertEquals('FIND \'((smith OR clark OR roberston) AND jane)\' IN ALL FIELDS RETURNING Contact(Id, FirstName, LastName, Title)', finder.searchBuilder().build());
    }

    /*******************************************************************************************************
    * @description Verifies find() when search query contains special characters
    */
    @isTest static private void findSucceedsWhenSearchQueryContainsSpecialCharacters() { 
        List<sObject> records = new List<sObject>{
            new Contact(LastName = 'Smith\\ Clark* &Garcia', FirstName = 'John', Title = 'Administrator', Department = 'IT'),
            new Contact(LastName = 'Clark? J{}nes [] (Jackson!)', FirstName = 'Kent', Title = 'Business Manager', Department = 'Sales'),
            new Contact(LastName = 'Smith | Clark?', FirstName = 'Jane', Title = 'Business Manager', Department = 'Business'),
            new Contact(LastName = '^Clark~Richards: "Johnson"', FirstName = 'Abby', Title = 'Executive'),
            new Contact(LastName = 'Roberston+Williams', Title = 'Director', Department = 'Sales'),
            new Contact(LastName = 'Jackson-Clark', FirstName = 'Ben', Department = 'Sales'),
            new Contact(LastName = 'Clark', FirstName = 'Kent', Title = 'Administrator', Department = 'Support')
        };
        insert records;

        Set<String> lastNames = new Set<String>();
        List<sObject> expectedRecords = new List<sObject>();

        for (Integer i = 0; i < records.size() -1; i++) {
            lastNames.add((String) records[i].get('LastName'));
            expectedRecords.add(records[i]);
        }

        UTIL_Where.FieldExpression lastNameExp = new UTIL_Where.FieldExpression(Contact.LastName).inSet(lastNames);
        lastNameExp.isFilterable = false;

        UTIL_Finder finder = new UTIL_Finder(Contact.SObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(lastNameExp);
        
        UTIL_UnitTestData_TEST.setFixedSearchResults(records);
        List<sObject> actual = finder.find();

        System.assert(!finder.isSoql(), 'SOSL should be executed since WHERE contains an encrypted field');

        System.assertEquals(expectedRecords.size(), actual.size());

        for (Integer i = 0; i < actual.size(); i++) {
            System.assertEquals((String) expectedRecords[i].get('LastName'), (String) actual[i].get('LastName'));
        }
    }


    /*******************************************************************************************************
    * @description Verifies find() when search returns LIMIT number of records
    */
    @isTest static private void findSucceedsWhenSearchReturnsLimitNumberOfRecords() {
        UTIL_Where.FieldExpression whereExp = new UTIL_Where.FieldExpression(Contact.LastName).equals('Clark');
        whereExp.isFilterable = false;

        List<sObject> recordsSortedByDept = getTestContacts();

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(SOBJECT_FIELDS)
            .withWhere(whereExp)
            .withOrderBy(new UTIL_OrderBy.FieldExpression(Contact.Department))
            .withLimit(1);

        finder.returnSearchRecords(recordsSortedByDept);
        List<sObject> actual = finder.find();

        System.assert(!finder.isSoql(), 'SOSL should be executed since WHERE contains an encrypted field');

        System.assertEquals(1, actual.size());
        System.assertEquals('Clark', (String) actual[0].get('LastName'));
    }

	/*******************************************************************************************************
    * @description Verifies SOQL is built using unique fields when SELECT method has duplicate passed in
    */
    @isTest static private void findReturnsUniqueFieldsInSoql() {
        List<String> fields = new List<String>{ 'firstname', 'FirstName', 'lastName', 'LastName' };
        UTIL_Finder finder = new UTIL_Finder(Contact.sObjectType)
            .withSelectFields(fields);

        List<sObject> actual = finder.find();

        System.assert(finder.isSoql(), 'SOQL should be executed since we do not have the WHERE clause');
        System.assertEquals(1, actual.size());
    }

    /*******************************************************************************************************
    * @description Verifies SOSL is built using unique fields when SELECT method has duplicate passed in
    */
    @isTest static private void findReturnsUniqueFieldsInSosl() {
        List<String> fields = new List<String>{ 'firstname', 'FirstName', 'lastName', 'LastName' };

        List<Contact> contacts = [SELECT Id, Name, FirstName, LastName FROM Contact];

        UTIL_Where.FieldExpression whereExp = new UTIL_Where.FieldExpression(Contact.LastName).equals(contacts[0].LastName);
        whereExp.isFilterable = false;

        UTIL_Finder finder = new UTIL_Finder(Contact.sObjectType)
            .withSelectFields(fields)
            .withWhere(whereExp);

        UTIL_UnitTestData_TEST.setFixedSearchResults(contacts);
        List<sObject> actual = finder.find();

        System.assert(!finder.isSoql(), 'SOSL should be executed since we the WHERE clause is on the encrypted field');
        System.assertEquals(1, actual.size());
    }

    /*******************************************************************************************************
    * @description Verifies search returns records and applies post sort when 
	* the ORDER BY field is not sortable (the field is encrypted).
    */
    @isTest static private void executeSearchAppliesPostSortingWhenOrderByFieldIsNotSortable() {
        List<sObject> records = getTestContacts();

        UTIL_OrderBy.FieldExpression orderByField = new UTIL_OrderBy.FieldExpression(Contact.LastName);
        orderByField.isSortable = false;

        String searchQuery = 'foo';

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(new List<String>(SELECT_FIELDS))
            .withSearchQuery(searchQuery)
            .withWildcard()
            .withOrderBy(orderByField)
            .withLimit(records.size());

        finder.returnSearchRecords(records);
        List<sObject> actual = finder.executeSearch();

        List<sObject> expectedRecords = new List<sObject>{
            records[1], records[3], records[6], records[5], records[4], records[0], records[2]
        };
        System.assertEquals(expectedRecords.size(), actual.size());

        for (Integer i = 0; i < actual.size(); i++) {
            System.assertEquals((String) expectedRecords[i].get('LastName'), (String) actual[i].get('LastName'));
        }

        System.assert(finder.orderBy.isPostSort(), 'Post sort should be applied');
        System.assertEquals('FIND \'foo*\' IN ALL FIELDS RETURNING Contact(Id, FirstName, LastName, Title)', finder.sosl);
	}

    /*******************************************************************************************************
    * @description Verifies search returns records and does not apply post sort when 
	* the ORDER BY field is sortable (the field is not encrypted).
    */
    @isTest static private void executeSearchDoesNotApplyPostSortingsWhenOrderByFieldIsSortable() {
        List<sObject> records = getTestContacts();

        String searchQuery = 'O\'Foo';

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(new List<String>(SELECT_FIELDS))
            .withSearchQuery(searchQuery)
            .withWildcard()
            .withOrderBy(Contact.Department)
            .withLimit(records.size());

        finder.returnSearchRecords(records);
        List<sObject> actual = finder.executeSearch();

        System.assertEquals(records.size(), actual.size());

        System.assert(!finder.orderBy.isPostSort(), 'Post sort should not be applied');
        System.assertEquals('FIND \'O\\\'Foo*\' IN ALL FIELDS RETURNING Contact(Id, FirstName, LastName, Title, Department ORDER BY Department)', finder.sosl);
	}

    /*******************************************************************************************************
    * @description Verifies search returns LIMIT number of records
    */
    @isTest static private void executeSearchReturnsLimitNumberOfRecords() {
        List<sObject> records = getTestContacts();

        String searchQuery = 'foo';
        Integer limitRows = records.size() - 1;

        MockFinder finder = (MockFinder) new MockFinder(Contact.sObjectType)
            .withSelectFields(new List<String>(SELECT_FIELDS))
            .withSearchQuery(searchQuery)
            .withWildcard()
            .withOrderBy(Contact.Department)
            .withLimit(limitRows);

        finder.returnSearchRecords(records);
        List<sObject> actual = finder.executeSearch();

        System.assertEquals(limitRows, actual.size());
	}

    /*******************************************************************************************************
    * @description Verifies search runs successfully when the search query contains special characters
    */
    @isTest static private void executeSearchWhenSearchQueryContainsSpecialCharacters() { 
        List<sObject> records = getTestContacts();
        insert records;

        String searchQuery = '^Smith\\ Clark* &Garcia : | ~Clark? J{}nes [] - (Jackson!) + "Johnson"';

        UTIL_Finder finder = new UTIL_Finder(Contact.SObjectType)
            .withSelectFields(new List<String>(SELECT_FIELDS))
            .withSearchQuery(searchQuery);
        
        UTIL_UnitTestData_TEST.setFixedSearchResults(records);
        List<sObject> actual = finder.executeSearch();

        System.assertEquals(records.size(), actual.size());
    }

    

    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Asserts the SOSL is correct
    * @param expectedSosl The expected SOSL String 
    * @param sosl The actual SOSL String 
    * @return void
    */
    private static void assertSearch(String expectedSosl, String sosl) {
        System.assertEquals(expectedSosl, sosl);

        Test.setFixedSearchResults(new List<Id>{ getContactId() });
        List<List<SObject>> result = Search.query(sosl);

        System.assert(result != null, 'Search should return data');
        System.assertEquals(1, result[0].size(), 'One record should be returned from the search');
    }

    /*********************************************************************************************************
    * @description Returns the Id of an existing Contact 
    * @return Id
    */
    private static Id getContactId() {
        return [SELECT Id FROM Contact LIMIT 1].Id;
    }

    /*********************************************************************************************************
    * @description Returns Contact records that do not exist in DB
    * @return List<sObject>
    */
    private static List<sObject> getTestContacts() {
        return new List<sObject>{
            new Contact(LastName = 'Smith', FirstName = 'John', Title = 'Administrator', Department = 'IT'),
            new Contact(LastName = 'Clark', FirstName = 'Kent', Title = 'Business Manager', Department = 'Sales'),
            new Contact(LastName = 'Smith', FirstName = 'Jane', Title = 'Business Manager', Department = 'Business'),
            new Contact(LastName = 'Clark', FirstName = 'Abby', Title = 'Executive'),
            new Contact(LastName = 'Roberston', Title = 'Director', Department = 'Sales'),
            new Contact(LastName = 'Jackson', FirstName = 'Ben', Department = 'Sales'),
            new Contact(LastName = 'Clark', FirstName = 'Kent', Title = 'Administrator', Department = 'Support')
        };
    }

    /*********************************************************************************************************
    * @description Mock Finder class used to mock query and search returned records
    */
    public class MockFinder extends UTIL_Finder {
        public String soql;
        public String sosl;
        private List<sObject> queryRecords = new List<sObject>();
        private List<sObject> searchRecords = new List<sObject>();

        public MockFinder(sObjectType sObjType) {
            super(sObjType);
        }

        public MockFinder returnQueryRecords(List<sObject> records) {
            this.queryRecords = records;
            return this;
        }

        public MockFinder returnSearchRecords(List<sObject> records) {
            this.searchRecords = records;
            return this;
        }

        public override List<sObject> queryRecords(String soql) {
            this.soql = soql;
            return queryRecords;
        }

        public override List<sObject> searchRecords(String sosl) {
            this.sosl = sosl;
            return searchRecords;
        }
    }
    
}