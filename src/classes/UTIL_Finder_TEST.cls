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
@isTest
private class UTIL_Finder_TEST {
    /** @description Fields that should be used in the SOQL SELECT clause */
	private static final Set<String> SELECT_FIELDS = new Set<String>{ 'FirstName', 'LastName', 'Title' };


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
            .withOrderBy('LastName')
            .build();
			
		String expectedSosl = 'FIND \'foo*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title ORDER BY LastName)';
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
            .withOrderBy('LastName')
            .build();
			
		String expectedSosl = 'FIND \'foo* AND bar*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title ORDER BY LastName)';
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
		System.assertEquals(UTIL_Finder.SEARCH_CRITERIA_REQUIRED, actual.getMessage());
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
	
}