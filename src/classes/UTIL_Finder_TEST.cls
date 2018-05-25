@isTest
private class UTIL_Finder_TEST {
	private static final Set<String> SELECT_FIELDS = new Set<String>{ 'FirstName', 'LastName', 'Title' };

    @TestSetup
    private static void setup() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

	@isTest static private void searchBuildReturnsSoslWithAllElements() {
		String sosl = new UTIL_Finder.SearchBuilder()
			.withFind('foo*')
			.withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .withOrderBy('LastName')
            .withLimit(100)
            .build();
			
		String expectedSosl = 'FIND \'foo*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title ORDER BY LastName LIMIT 100)';
		assertSearch(expectedSosl, sosl);
	}

	@isTest static private void searchBuildReturnsSoslWhenOrderByIsNotProvided() {
		String sosl = new UTIL_Finder.SearchBuilder()
			.withFind('foo*')
			.withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .withLimit(100)
            .build();
			
		String expectedSosl = 'FIND \'foo*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title LIMIT 100)';
		assertSearch(expectedSosl, sosl);
	}

	@isTest static private void searchBuildReturnsSoslWhenLimitIsNotProvided() {
		String sosl = new UTIL_Finder.SearchBuilder()
			.withFind('foo*')
			.withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .withOrderBy('LastName')
            .build();
			
		String expectedSosl = 'FIND \'foo*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title ORDER BY LastName)';
		assertSearch(expectedSosl, sosl);
	}

	@isTest static private void searchBuildReturnsSoslWhenOrderByAndLimitAreNotProvided() {
		String sosl = new UTIL_Finder.SearchBuilder()
			.withFind('foo*')
			.withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .build();
			
		String expectedSosl = 'FIND \'foo*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title)';
		assertSearch(expectedSosl, sosl);
	}

	@isTest static private void searchBuildReturnsSoslWithLogicOperatorsInTheFind() {
		String sosl = new UTIL_Finder.SearchBuilder()
			.withFind('foo* AND bar*')
			.withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .withOrderBy('LastName')
            .withLimit(100)
            .build();
			
		String expectedSosl = 'FIND \'foo* AND bar*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title ORDER BY LastName LIMIT 100)';
		assertSearch(expectedSosl, sosl);
	}

	@isTest static private void soslWithBracketsAndLogicOperatorsInTheFindExecutesSuccessfully() {
		String sosl = new UTIL_Finder.SearchBuilder()
			.withFind('foo* AND bar.com*')
			.withReturning(Contact.sObjectType)
            .withFields(SELECT_FIELDS)
            .withOrderBy('LastName')
            .withLimit(100)
            .build();
			
		String expectedSosl = 'FIND \'foo* AND bar.com*\' IN ALL FIELDS RETURNING Contact(FirstName, LastName, Title ORDER BY LastName LIMIT 100)';// TODO Test this more at the Execute Anonymous!
		assertSearch(expectedSosl, sosl);
	}

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

	@isTest static private void searchBuildLimitReturnsEmptyStringWhenLimitRowsIsOutOfBoundary() {
		UTIL_Finder.SearchBuilder utilSearch = new UTIL_Finder.SearchBuilder();

		for (Integer limitRows : new List<Integer>{ null, 0, 2000, 2001 }) {
			utilSearch.withLimit(limitRows);

			System.assertEquals('', utilSearch.buildLimit(), 'The search limit should be empty for: ' + String.valueOf(limitRows));
		}
	}

	@isTest static private void searchBuildLimitReturnsTheUpperBoundary() {
		final Integer maxRows = 1999;

		UTIL_Finder.SearchBuilder utilSearch = new UTIL_Finder.SearchBuilder();
		utilSearch.withLimit(maxRows);
		
		System.assertEquals(' LIMIT ' + maxRows, utilSearch.buildLimit(), 'The search limit contain upper boundary: ' + String.valueOf(maxRows));
	}

	// Helpers
	////////////

	private static Id getContactId() {
		return [SELECT Id FROM Contact LIMIT 1].Id;
	}

	private static void assertSearch(String expectedSosl, String sosl) {
		System.assertEquals(expectedSosl, sosl);

	    Test.setFixedSearchResults(new List<Id>{ getContactId() });
	    List<List<SObject>> result = Search.query(sosl);

		System.assert(result != null, 'Search should return data');
		System.assertEquals(1, result[0].size(), 'One record should be returned from the search');
	}

	
	
}