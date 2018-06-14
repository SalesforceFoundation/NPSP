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
* @description Unit tests for UTIL_Where class
*/
@isTest(isParallel=true)
private class UTIL_Where_TEST {
    private static final String MOCK_ACCOUNT_ID = UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID;
    private static UTIL_Where.FieldExpression ACCOUNT_NAME_FIELD_EXP = new UTIL_Where.FieldExpression(Account.Name);
    private static UTIL_Where.FieldExpression WEBSITE_FIELD_EXP = new UTIL_Where.FieldExpression(Account.Website);
    private static UTIL_Where.FieldExpression ACCOUNT_ID_FIELD_EXP = new UTIL_Where.FieldExpression(Account.Id);

    /*******************************************************************************************************
    * @description Sets all test field expression to be filterable, ie use SOQL when WHERE is being constructed
    */
    static {
        ACCOUNT_NAME_FIELD_EXP.isFilterable = true;
        WEBSITE_FIELD_EXP.isFilterable = true;
        ACCOUNT_ID_FIELD_EXP.isFilterable = true;
    }
    
    /*******************************************************************************************************
    * @description Verifies equals() sets the operator and the value in the field expression
    */
    @isTest static void fieldExpEqualsSetsCorrectOperatorAndValue() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.equals('foo').toString();

        System.assertEquals('Name = \'foo\'', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies notEquals() sets the operator and the value in the field expression
    */
    @isTest static void fieldExpNotEqualsSetsCorrectOperatorAndValue() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.notEquals('foo').toString();

        System.assertEquals('Name != \'foo\'', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies inSet() sets the operator and the value in the field expression
    */
    @isTest static void fieldExpInSetSetsCorrectOperatorAndValue() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>{'foo', 'bar'}).toString();

        System.assertEquals('Name IN (\'foo\', \'bar\')', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies single quotes are escaped in the field expression's value
    */
    @isTest static void fieldExpToStringEscapesSingleQuotes() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.equals('foo\'s').toString();

        System.assertEquals('Name = \'foo\\\'s\'', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies toString() returns correct criteria when value is null
    */
    @isTest static void fieldExpToStringReturnsExpressionOnNullValueWhenValueIsNull() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.equals(null).toString();

        System.assertEquals('Name = null', fieldExp);
    }
    /*******************************************************************************************************
    * @description Verifies toString() returns correct criteria when value is an empty string
    */
    @isTest static void fieldExpToStringReturnsExpressionOnNullValueWhenValueIsEmptyString() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.equals('').toString();

        System.assertEquals('Name = null', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies toString() returns correct criteria when the field is an Id
    */
    @isTest static void fieldExpToStringReturnsExpressionOnId() {
        String fieldExp = ACCOUNT_ID_FIELD_EXP.equals(MOCK_ACCOUNT_ID).toString();

        System.assertEquals('Id = \'' + MOCK_ACCOUNT_ID + '\'', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies toString() returns correct criteria for the provided set
    */
    @isTest static void fieldExpInSetToStringReturnsCommaSeparatedElementsInQuotes() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>{'foo', 'bar'}).toString();

        System.assertEquals('Name IN (\'foo\', \'bar\')', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies toString() returns correct criteria for the provided set having one element
    */
    @isTest static void fieldExpInSetToStringReturnsValueWhenSetHasOneElement() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>{'foo'}).toString();

        System.assertEquals('Name IN (\'foo\')', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies toString() includes null and empty String in the Set
    */
    @isTest static void fieldExpInSetToStringIncludesNullsAndEmptyStrings() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>{'foo', null, '', 'bar'}).toString();

        System.assertEquals('Name IN (\'foo\', null, \'\', \'bar\')', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies toString() returns search query on the Id values
    */
    @isTest static void fieldExpInSetToStringReturnsIdValues() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<Id>{ MOCK_ACCOUNT_ID }).toString();

        System.assertEquals('Name IN (\'' + MOCK_ACCOUNT_ID + '\')', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies toString() throws an exception when IN Set is empty
    */
    @isTest static void fieldExpInSetToStringThrowsExceptionWhenSetIsEmpty() {
        UTIL_Where.FieldExpression fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>());

        Exception actual;
        try {
            String whereClause = fieldExp.toString();
        } catch (Exception e) {
            actual = e;
        }

        System.assertNotEquals(null, actual, 'An exception should have been thrown for the empty Set');
    }

    /*******************************************************************************************************
    * @description Verifies getSearchValue() returns an empty string when value is null
    */
    @isTest static void fieldExpGetSearchValueReturnsEmptyStringWhenValueIsNull() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.equals(null).getSearchValue();

        System.assertEquals('', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies getSearchValue() returns correct criteria for the provided value
    */
    @isTest static void fieldExpGetSearchValueReturnsValue() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.equals('foo').getSearchValue();

        System.assertEquals('foo', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies single quotes are escaped when the value is returned by the getSearchValue() 
    */
    @isTest static void fieldExpGetSearchValueEscapesSingleQuotes() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.equals('foo\'s').getSearchValue();

        System.assertEquals('foo\\\'s', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies getSearchValue() throws an exception when operator is not equals which
    *   is not applicable to the SOSL criteria in the FIND clause.
    */
    @isTest static void fieldExpGetSearchValueThrowsExceptionWhenOperatorIsNotEquals() {
        Exception actual;
        try {
            String fieldExp = ACCOUNT_NAME_FIELD_EXP.notEquals('foo\'s').getSearchValue();
            
        } catch (Exception e) {
            actual = e;
        }
        System.assertNotEquals(null, actual, 'An exception should be thrown');
    }

    /*******************************************************************************************************
    * @description Verifies getSearchValue() returns correct criteria for the provided set
    */
    @isTest static void fieldExpInSetGetSearchValueReturnsValuesConnectedWithOR() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>{'foo', 'bar'}).getSearchValue();

        System.assertEquals('(foo OR bar)', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies getSearchValue() returns correct criteria for the provided set having one element
    */
    @isTest static void fieldExpInSetGetSearchValueReturnsValueWhenSetHasOneElement() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>{'foo'}).getSearchValue();

        System.assertEquals('foo', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies getSearchValue() does not include null and empty String in the Set
    */
    @isTest static void fieldExpInSetGetSearchValueExcludesNullsAndEmptyStrings() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>{'foo', null, '', 'bar'}).getSearchValue();

        System.assertEquals('(foo OR bar)', fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies getSearchValue() returns search query on the Id values
    */
    @isTest static void fieldExpInSetGetSearchValueReturnsIdValues() {
        String fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<Id>{ MOCK_ACCOUNT_ID }).getSearchValue();

        System.assertEquals(MOCK_ACCOUNT_ID, fieldExp);
    }

    /*******************************************************************************************************
    * @description Verifies getSearchValue() throws an exception when IN Set is empty
    */
    @isTest static void fieldExpInSetGetSearchValueThrowsExceptionWhenSetIsEmpty() {
        UTIL_Where.FieldExpression fieldExp = ACCOUNT_NAME_FIELD_EXP.inSet(new Set<String>());

        Exception actual;
        try {
            String searchQuery = fieldExp.getSearchValue();
        } catch (Exception e) {
            actual = e;
        }

        System.assertNotEquals(null, actual, 'An exception should have been thrown for the empty Set');
    }


    /*******************************************************************************************************
    * @description Verifies group expression isFilterable() is true when all fields are filterable
    */
    @isTest static void groupExpIsFilterableReturnsTrueWhenAllFieldExpsAreFilterable() {
        Boolean isFilterable = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP)
            .add(WEBSITE_FIELD_EXP)
            .isFilterable();

        System.assert(isFilterable, 'The group expression should be filterable');
    }

    /*******************************************************************************************************
    * @description Verifies group expression isFilterable() is false when at least one field is not filterable
    */
    @isTest static void groupExpIsFilterableReturnsFalseWhenAtLeastOneFieldExpIsNotFilterable() {
        ACCOUNT_NAME_FIELD_EXP.isFilterable = false;

        Boolean isFilterable = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP)
            .add(WEBSITE_FIELD_EXP)
            .isFilterable();

        System.assert(!isFilterable, 'The group expression should not be filterable');
    }
    
    /*******************************************************************************************************
    * @description Verifies group expression toString() uses AND operator by default
    */
    @isTest static void groupExpToStringReturnsFieldExpsConnectedWithANDByDefault() {
        String groupExp = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP.equals('foo'))
            .add(WEBSITE_FIELD_EXP.equals('bar.com'))
            .toString();

        System.assertEquals('(Name = \'foo\' AND Website = \'bar.com\')', groupExp);
    }

    /*******************************************************************************************************
    * @description Verifies group expression toString() uses OR operator when specified
    */
    @isTest static void groupExpToStringReturnsFieldExpsConnectedWithOR() {
        String groupExp = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP.equals('foo'))
            .add(WEBSITE_FIELD_EXP.equals('bar.com'))
            .withOr()
            .toString();

        System.assertEquals('(Name = \'foo\' OR Website = \'bar.com\')', groupExp);
    }

    /*******************************************************************************************************
    * @description Verifies group expression toString() does not apply brackets when the group contains
    * one field expression only.
    */
    @isTest static void groupExpToStringDoesNotUseBracketsWhenHavingOneFieldExp() {
        String groupExp = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP.equals('foo'))
            .toString();

        System.assertEquals('Name = \'foo\'', groupExp);
    }

    /*******************************************************************************************************
    * @description Verifies group expression toString() returns empty string when the group has no field expression.
    */
    @isTest static void groupExpToStringReturnsEmptyStringWhenNoFieldExpIsProvided() {
        String groupExp = new UTIL_Where.GroupExpression().toString();

        System.assertEquals('', groupExp);
    }

    /*******************************************************************************************************
    * @description Verifies the group expression getSearchValue() uses AND operator by default
    */
    @isTest static void groupExpGetSearchValueReturnsFieldExpsConnectedWithANDByDefault() {
        String groupExp = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP.equals('foo'))
            .add(WEBSITE_FIELD_EXP.equals('bar.com'))
            .getSearchValue();

        System.assertEquals('(foo AND bar.com)', groupExp);
    }

    /*******************************************************************************************************
    * @description Verifies the group expression getSearchValue() uses OR operator when specified
    */
    @isTest static void groupExpGetSearchValueReturnsFieldExpsConnectedWithOR() {
        String groupExp = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP.equals('foo'))
            .add(WEBSITE_FIELD_EXP.equals('bar.com'))
            .withOr()
            .getSearchValue();

        System.assertEquals('(foo OR bar.com)', groupExp);
    }

    /*******************************************************************************************************
    * @description Verifies the group expression getSearchValue() returns an empty string 
    * when the group has no field expression.
    */
    @isTest static void groupExpGetSearchValueReturnsEmptyStringWhenNoFieldExpIsProvided() {
        String groupExp = new UTIL_Where.GroupExpression().getSearchValue();

        System.assertEquals('', groupExp);
    }

    /*******************************************************************************************************
    * @description Verifies WHERE isFilterable() returns true when WHERE clause contains no expression
    */
    @isTest static void whereIsFilterableReturnsTrueWhenWhereClauseIsEmpty() {
        Boolean isFilterable = new UTIL_Where().isFilterable();

        System.assert(isFilterable, 'The empty WHERE clause should be filterable');
    }

    /*******************************************************************************************************
    * @description Verifies WHERE isFilterable() returns true when all groups are filterable
    */
    @isTest static void whereIsFilterableReturnsTrueWhenAllGroupExpsAreFilterable() {
        Boolean isFilterable = new UTIL_Where()
            .add(new UTIL_Where.GroupExpression().add(ACCOUNT_NAME_FIELD_EXP))
            .add(new UTIL_Where.GroupExpression().add(WEBSITE_FIELD_EXP))
            .isFilterable();

        System.assert(isFilterable, 'The WHERE clause should be filterable');
    }

    /*******************************************************************************************************
    * @description Verifies WHERE isFilterable() returns false when at least one group is not filterable
    */
    @isTest static void whereIsFilterableReturnsFalseWhenAtLeastOneGroupExpIsNotFilterable() {
        WEBSITE_FIELD_EXP.isFilterable = false;

        Boolean isFilterable = new UTIL_Where()
            .add(new UTIL_Where.GroupExpression().add(ACCOUNT_NAME_FIELD_EXP))
            .add(new UTIL_Where.GroupExpression().add(WEBSITE_FIELD_EXP))
            .isFilterable();

        System.assert(!isFilterable, 'The WHERE clause should not be filterable');
    }

    /*******************************************************************************************************
    * @description Verifies WHERE build() returns a SOQL using AND operator by default
    */
    @isTest static void whereBuildReturnsSoqlWhenAllGroupExpsAreFilterable() {
        WEBSITE_FIELD_EXP.isFilterable = true;

        String soql = new UTIL_Where()
            .add(new UTIL_Where.GroupExpression().add(ACCOUNT_NAME_FIELD_EXP.equals('foo')))
            .add(new UTIL_Where.GroupExpression().add(WEBSITE_FIELD_EXP.equals('bar.com')))
            .build();

        System.assertEquals('Name = \'foo\' AND Website = \'bar.com\'', soql);
    }

    /*******************************************************************************************************
    * @description Verifies WHERE build() returns a SOQL using OR operator when specified
    */
    @isTest static void whereBuildUsesOROperatorWhenItIsSet() {
        String soql = new UTIL_Where()
            .add(new UTIL_Where.GroupExpression()
                .add(ACCOUNT_NAME_FIELD_EXP.equals('foo'))
                .add(ACCOUNT_ID_FIELD_EXP.equals(MOCK_ACCOUNT_ID)))
            .add(new UTIL_Where.GroupExpression().add(WEBSITE_FIELD_EXP.equals('bar.com')))
            .withOr()
            .build();

        System.assertEquals('(Name = \'foo\' AND Id = \'' + MOCK_ACCOUNT_ID + '\') OR Website = \'bar.com\'', soql);
    }

    /*******************************************************************************************************
    * @description Verifies field expression meets criteria when the value is matched
    */
    @isTest static void fieldExpMeetsCriteriaShouldReturnTrueWhenValueIsMatched() {
		UTIL_Where.FieldExpression fieldExp = ACCOUNT_NAME_FIELD_EXP.equals('foo');
		
		System.assert(!fieldExp.meetsCriteria(new Account()), 'Should not match account with no Name');
		System.assert(!fieldExp.meetsCriteria(new Account(Name = '')), 'Should not match account with empty Name');
		System.assert(!fieldExp.meetsCriteria(new Account(Name = 'bar')), 'Should not match account with different Name');
		System.assert(!fieldExp.meetsCriteria(new Account(Name = 'foo test')), 'Should not match account with different Name');
		System.assert(fieldExp.meetsCriteria(new Account(Name = 'FOO')), 'Should match account with capital case letter Name');
		System.assert(fieldExp.meetsCriteria(new Account(Name = 'foo')), 'Should match account with the same Name');
	}

    /*******************************************************************************************************
    * @description Verifies reference field expression meets criteria when the value is matched
    */
	@isTest static void fieldExpMeetsCriteriaShouldReturnTrueWhenReferenceFieldValueIsMatched() {
		UTIL_Where.FieldExpression fieldExp = new UTIL_Where.FieldExpression(Contact.LastName)
            .fromRelationship(Opportunity.Primary_Contact__c)
			.equals('foo');
		
		System.assert(!fieldExp.meetsCriteria(new Opportunity()), 'Should not match opp with no Primary Contact');
		System.assert(!fieldExp.meetsCriteria(new Opportunity(Primary_Contact__r = (new Contact(LastName = '')))), 'Should not match opp with empty Contact Name');
		System.assert(!fieldExp.meetsCriteria(new Opportunity(Primary_Contact__r = (new Contact(LastName = 'bar')))), 'Should not match opp with different Contact Name');
		System.assert(!fieldExp.meetsCriteria(new Opportunity(Primary_Contact__r = (new Contact(LastName = 'foo test')))), 'Should not match opp with different Contact Name');
		System.assert(fieldExp.meetsCriteria(new Opportunity(Primary_Contact__r = (new Contact(LastName = 'FOO')))), 'Should match opp with capital case letter Contact Name');
		System.assert(fieldExp.meetsCriteria(new Opportunity(Primary_Contact__r = (new Contact(LastName = 'foo')))), 'Should match opp with the same Contact Name');
	}

    /*******************************************************************************************************
    * @description Verifies field expression meets criteria when the value is not matched for NOT_EQUALS operator
    */
    @isTest static void fieldExpMeetsCriteriaShouldReturnTrueWhenOperatorIsNotEqualsAndValueIsTheSame() {
		UTIL_Where.FieldExpression fieldExp = ACCOUNT_NAME_FIELD_EXP.notEquals('foo');
		
		System.assert(fieldExp.meetsCriteria(new Account()), 'Should match account with no Name');
		System.assert(fieldExp.meetsCriteria(new Account(Name = '')), 'Should match account with empty Name');
		System.assert(fieldExp.meetsCriteria(new Account(Name = 'bar')), 'Should match account with different Name');
		System.assert(fieldExp.meetsCriteria(new Account(Name = 'foo test')), 'Should match account with different Name');
		System.assert(!fieldExp.meetsCriteria(new Account(Name = 'FOO')), 'Should not match account with the same Name');
		System.assert(!fieldExp.meetsCriteria(new Account(Name = 'foo')), 'Should not match account with the same Name');
	}

    /*******************************************************************************************************
    * @description Verifies field expression meets criteria when the null value is matched
    */
    @isTest static void fieldExpMeetsCriteriaShouldReturnTrueWhenMatchingOnNull() {
		UTIL_Where.FieldExpression fieldExp = ACCOUNT_NAME_FIELD_EXP.equals(null);
		
		System.assert(fieldExp.meetsCriteria(new Account()), 'Should match account with no Name');
		System.assert(fieldExp.meetsCriteria(new Account(Name = '')), 'Should match account with empty Name');
		System.assert(!fieldExp.meetsCriteria(new Account(Name = 'bar')), 'Should not match account with a Name');
	}
	
    /*******************************************************************************************************
    * @description Verifies group expression meets criteria when all field expressions 
    * evaluate to true for the AND operator
    */
	@isTest static void groupExpMeetsCriteriaShouldReturnTrueWhenAllValuesAreMatchedForANDOper() {
        UTIL_Where.GroupExpression groupExp = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP.equals('foo'))
            .add(WEBSITE_FIELD_EXP.equals('bar.com'));
		
		System.assert(!groupExp.meetsCriteria(new Account()), 'Should not match account with no Name');
		System.assert(!groupExp.meetsCriteria(new Account(Website = 'bar.com')), 'Should not match account with no Name and the same Website');
		System.assert(!groupExp.meetsCriteria(new Account(name = 'no match', Website = 'bar.com')), 'Should not match account with different Name');
		System.assert(!groupExp.meetsCriteria(new Account(name = 'foo')), 'Should not match account with no Website');
		System.assert(!groupExp.meetsCriteria(new Account(name = 'foo', Website = '')), 'Should not match account with empty Website');
		System.assert(!groupExp.meetsCriteria(new Account(name = 'foo', Website = 'nomatch.com')), 'Should not match account with different Website');
		System.assert(groupExp.meetsCriteria(new Account(name = 'foo', Website = 'bar.com')), 'Should match account with same Name and Website');
	}

    /*******************************************************************************************************
    * @description Verifies group expression meets criteria when at least one field expression
    * evaluates to true for the OR operator
    */
	@isTest static void groupExpMeetsCriteriaShouldReturnTrueWhenEitherValueMatchForOROper() {
        UTIL_Where.GroupExpression groupExp = new UTIL_Where.GroupExpression()
            .add(ACCOUNT_NAME_FIELD_EXP.equals('foo'))
            .add(WEBSITE_FIELD_EXP.equals('bar.com'))
			.withOr();
		
		System.assert(!groupExp.meetsCriteria(new Account()), 'Should not match account with no Name and no Website');
		System.assert(!groupExp.meetsCriteria(new Account(Website = 'nomatch.com')), 'Should not match account with no Name and different Website');
		System.assert(groupExp.meetsCriteria(new Account(Website = 'bar.com')), 'Should match account with no Name and the same Website');
		System.assert(groupExp.meetsCriteria(new Account(name = 'no match', Website = 'bar.com')), 'Should match account with different Name and the same Website');
		System.assert(groupExp.meetsCriteria(new Account(name = 'foo')), 'Should match account with the same Name and no Website');
		System.assert(groupExp.meetsCriteria(new Account(name = 'foo', Website = '')), 'Should match account with the same Name and empty Website');
		System.assert(groupExp.meetsCriteria(new Account(name = 'foo', Website = 'nomatch.com')), 'Should match account with the same Name and different Website');
		System.assert(groupExp.meetsCriteria(new Account(name = 'foo', Website = 'bar.com')), 'Should match account with same Name and Website');
	}

    /*******************************************************************************************************
    * @description Verifies WHERE clause meets criteria when all group expressions 
    * evaluate to true for the AND operator
    */
	@isTest static void whereMeetsCriteriaShouldReturnTrueWhenAllValuesAreMatchedForANDOper() {
		UTIL_Where utilWhere = new UTIL_Where()
            .add(new UTIL_Where.GroupExpression().add(ACCOUNT_NAME_FIELD_EXP.equals('foo')))
            .add(new UTIL_Where.GroupExpression().add(WEBSITE_FIELD_EXP.equals('bar.com')));

		System.assert(!utilWhere.meetsCriteria(new Account()), 'Should not match account with no Name');
		System.assert(!utilWhere.meetsCriteria(new Account(Website = 'bar.com')), 'Should not match account with no Name and the same Website');
		System.assert(!utilWhere.meetsCriteria(new Account(name = 'no match', Website = 'bar.com')), 'Should not match account with different Name');
		System.assert(!utilWhere.meetsCriteria(new Account(name = 'foo')), 'Should not match account with no Website');
		System.assert(!utilWhere.meetsCriteria(new Account(name = 'foo', Website = '')), 'Should not match account with empty Website');
		System.assert(!utilWhere.meetsCriteria(new Account(name = 'foo', Website = 'nomatch.com')), 'Should not match account with different Website');
		System.assert(utilWhere.meetsCriteria(new Account(name = 'foo', Website = 'bar.com')), 'Should match account with same Name and Website');
	}

    /*******************************************************************************************************
    * @description Verifies WHERE clause meets criteria when at least one group expression
    * evaluates to true for the OR operator
    */
	@isTest static void whereMeetsCriteriaShouldReturnTrueWhenAllValuesAreMatchedForOROper() {
		UTIL_Where utilWhere = new UTIL_Where()
            .add(new UTIL_Where.GroupExpression().add(ACCOUNT_NAME_FIELD_EXP.equals('foo')))
            .add(new UTIL_Where.GroupExpression().add(WEBSITE_FIELD_EXP.equals('bar.com')))
			.withOr();

		System.assert(!utilWhere.meetsCriteria(new Account()), 'Should not match account with no Name and no Website');
		System.assert(!utilWhere.meetsCriteria(new Account(Website = 'nomatch.com')), 'Should not match account with no Name and different Website');
		System.assert(utilWhere.meetsCriteria(new Account(Website = 'bar.com')), 'Should match account with no Name and the same Website');
		System.assert(utilWhere.meetsCriteria(new Account(name = 'no match', Website = 'bar.com')), 'Should match account with different Name and the same Website');
		System.assert(utilWhere.meetsCriteria(new Account(name = 'foo')), 'Should match account with the same Name and no Website');
		System.assert(utilWhere.meetsCriteria(new Account(name = 'foo', Website = '')), 'Should match account with the same Name and empty Website');
		System.assert(utilWhere.meetsCriteria(new Account(name = 'foo', Website = 'nomatch.com')), 'Should match account with the same Name and different Website');
		System.assert(utilWhere.meetsCriteria(new Account(name = 'foo', Website = 'bar.com')), 'Should match account with same Name and Website');
	}

    /*******************************************************************************************************
    * @description Verifies WHERE clause returns true when it contains no group expression
    */
	@isTest static void whereMeetsCriteriaShouldReturnTrueWhenItHasNoGroupExpression() {
		UTIL_Where utilWhere = new UTIL_Where();

		System.assert(utilWhere.meetsCriteria(new Account(name = 'foo')), 'Should match account when WHERE clause is empty since there is no criteria');
	}	

    /*******************************************************************************************************
    * @description Verifies getFields() returns path of fields in all field expressions
    */
    @isTest static void whereGetFieldsReturnsAllFieldNames() {
        UTIL_Where utilWhere = new UTIL_Where()
            .add(new UTIL_Where.GroupExpression()
                .add(ACCOUNT_NAME_FIELD_EXP.fromRelationship(Contact.AccountId).equals('foo'))
                .add(new UTIL_Where.FieldExpression(Contact.FirstName).equals('Jane')))
            .add(new UTIL_Where.FieldExpression(Contact.LastName).equals('Smith'))
			.withOr();
		
		Set<String> fields = utilWhere.getFields();
		System.assertEquals(3, fields.size());

		for (String fieldName : new String[] { 'Account.Name', 'LastName', 'FirstName' }) {
			System.assert(fields.contains(fieldName), fieldName + ' should be returned: ' + fields);
		}
	}

}