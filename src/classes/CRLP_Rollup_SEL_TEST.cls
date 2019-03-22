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
* @group Selectors
* @description Unit Test for the Rollup Definition Custom Metadata Type object selector
*/
@isTest(IsParallel=True)
public class CRLP_Rollup_SEL_TEST {

    /**
     * @description Because unit tests cannot actually insert Custom Metadata Types and there's no real way to know
     * exactly what's in the CMT objects, we can use this method to mock the contents of the cached MDT queries
     * for the unit tests
     */
    public static void mockRollupCMTValues() {

        // Create a single Filter Group (no need for filter rules here)
        String filterGroupId = CMT_UnitTestData_TEST.getNewRecordId();
        String filterGroupsJSON = '[' + CMT_UnitTestData_TEST.createFilterGroupRecord(filterGroupId, 'TestFilterGroup') + ']';
        CMT_FilterRule_SEL.cachedFilterGroups = (List<Filter_Group__mdt>)JSON.deserialize(filterGroupsJSON, List<Filter_Group__mdt>.class);

        // Create a single Rollup that uses the above Filter Group
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.buildCMTObjectJSON('Rollup__mdt', 'Household Total Donations All Time',
                    CMT_UnitTestData_TEST.getNewRecordId(), new List<CMT_UnitTestData_TEST.CMT_Field>{
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Description__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldText, 
                            'Household Total Donations All Time'
                        ),
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Filter_Group__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldText, 
                            filterGroupId
                        ),
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Active__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldBoolean, 
                            True
                        ),
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Summary_Object__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 
                            'Account'
                        ),
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Summary_Field__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldField, 
                            'Account.AnnualRevenue'
                        ),
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Detail_Object__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 
                            'Opportunity'
                        ),
                    /*
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Detail_Field__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldField, 
                            'Opportunity.AccountId'
                        ),
                    */
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Date_Object__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 
                            'Opportunity'
                        ),
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Date_Field__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldField, 
                            'Opportunity.CloseDate'
                        ),
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Amount_Object__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldEntity, 
                            'Opportunity'
                        ),
                        new CMT_UnitTestData_TEST.CMT_Field(
                            'Amount_Field__c', 
                            CMT_UnitTestData_TEST.CMTFieldType.FldField, 
                            'Opportunity.Amount'
                        )
                }) + ']';
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(
            rollupsJSON, 
            List<Rollup__mdt>.class
        );
    }

    /**
     * @description Test the Rollup selector methods. Relies on hardcoded JSON deserialized
     * MDT data for these tests.
     */
    @IsTest
    static void test_Rollup_Selectors() {

        mockRollupCMTValues();

        System.AssertEquals(1, CRLP_Rollup_SEL.getRollupDefinitions().size(), 'There should be 1 rollup definition');

        System.AssertEquals(1, CRLP_Rollup_SEL.getRollupsByDetailType().get(Opportunity.SObjectType).size(),
                'There should be 1 rollup for the Opportunity detail object');
        System.AssertEquals(1, CRLP_Rollup_SEL.getRollupsBySummaryType().get(Account.SObjectType).size(),
                'There should be 1 rollup for the Account summary object');
        System.AssertEquals(1, CRLP_Rollup_SEL.getRollupsByFilterGroup().size(),
                'There should be 1 filter group that has rollups');

        Integer expectedFldCount = 2;   // the 2 fields above PLUS the AccountID and PrimaryContactId fields
        if (UserInfo.isMultiCurrencyOrganization()) {
            expectedFldCount++;
        }
        System.AssertEquals(expectedFldCount, CRLP_Rollup_SEL.getReferencedFieldsByObject(Opportunity.SObjectType).size(),
                'There should be ' + expectedFldCount + ' Opportunity fields referenced across the rollup\n' +
                CRLP_Rollup_SEL.getReferencedFieldsByObjectAsString(Opportunity.SObjectType));

        // Test that a list of fields to query is returned
        String queryFields = CRLP_Rollup_SEL.getReferencedFieldsByObjectAsString(Opportunity.SObjectType);
        System.Assert(String.isNotEmpty(queryFields),
                'There should be at least one referenced field for the Opportunity object in Rollup__mdt');

        // Test that a query can be built and executed, though it's likely there will be zero rows returned
        // so don't attempt to validate the result.
        String soql = 'SELECT Id,' + queryFields + ' FROM Opportunity LIMIT 1';
        List<SObject> test = database.query(soql);
    }

    /**
     * @description Useful when needing to set SObject's relationship values without querying
     * @param sObjectTypeName Name of SObjectType to be returned
     * @param fields Map: Field Name -> Field Value of SObject's Fields.  May include Relationships.
     * @return JSON deserailziation of an SObject for sObjectTypeName with fields
     */
    public static SObject getSObject(
		String sObjectTypeName,  
		Map<String, Object> fields
	) {
		Map<String, Object> jsonFields = new Map<String, Object> ();
		
        // Set fields
		if(fields != null) {
			jsonFields.putAll(fields);
		}

		// Set attributes
        jsonFields.put(
            'attributes', 
            new Map<String, Object> {
                'type' => sObjectTypeName
            }
        );
		
		return (SObject) JSON.deserialize(JSON.serialize(jsonFields), SObject.class);
	}

    /**
     * @description Shortcut to set Metadata Relationships when using getSObject(...)
     * @param  sObjectTypeName  SObjectType's Name Metadata Relationship is pointing to
     * @param  qualifiedApiName QualifiedApiName
     * @return SObject for sObjectTypeName and fields mapping QualifiedApiName to qualifiedApiName
     */
	public static SObject getMetadataRelationship(String sObjectTypeName, String qualifiedApiName) {
		return getSObject(
			sObjectTypeName, 
			new Map<String, Object> {
				'QualifiedApiName' => qualifiedApiName
			}
		);
	}

    /**
     * @description Shortcut to set EntityDefinition Metadata Relationships when using getSObject(...)
     * @param  qualifiedApiName QualifiedApiName
     * @return getMetadataRelationship for EntityDefinition's SObjecType's Name and qualifiedApiName
     */
	public static SObject getEntityMetadataRelationship(String qualifiedApiName) {
		return getMetadataRelationship(
            Schema.SObjectType.EntityDefinition.getName(), 
            qualifiedApiName
        );
	}

    /**
     * @description Shortcut to set FieldDefinition Metadata Relationships when using getSObject(...)
     * @param  qualifiedApiName QualifiedApiName
     * @return getMetadataRelationship for FieldDefinition's SObjecType's Name and qualifiedApiName
     */
	public static SObject getFieldMetadataRelationship(String qualifiedApiName) {
		return getMetadataRelationship(
            Schema.SObjectType.FieldDefinition.getName(), 
            qualifiedApiName
        );
	}

    /**
     * @description Provide a descriptive message in System.assertEquals(...)
     * @param  format format used when returning String.format(format, ...)
     * @param  title  First parameter in String.format, i.e. {0}
     * @param  values If values is not null, adds a message of 'key: "value"'' for all values.   Then joins Strings by '; '.  This is the second paramter in String.format, i.e. {1}
     * @return String.format(format, new List<String> { title, String.join(messages, '; ')})
     */
    public static String getAssertMessage(String format, String title, Map<String, Object> values) {
        final List<String> messages = new List<String> ();
        if (values != null) {
            for(String field : values.keySet()) {
                messages.add('\n' + field + ': "' + values.get(field) + '"');
            }
            messages.add('\n\n');
        }
         
        return String.format(
            format, 
            new List<String> {
                title, 
                String.join(messages, '; ')
            }
        );
    }

    /**
     * @description Provides a descriptive message in System.assertEquals(...) when testing if a method should never throw an Exception when called
     * @param  methodName Passes methodName as getAssertMessage(...)'s title
     * @param values Map: Value Name -> Value to be passed in as getAssertMessage(...)'s values
     * @return getAssertMessage for '{0} should never throw an Exception', methodName, and values
     */
    public static String getNeverExpectExceptionMessage(String methodName, Map<String, Object> values) {
        return getAssertMessage(
            '{0} should never throw an Exception.  {1}', 
            methodName, 
            values
        );
    }

    /**
     * @description Provides a descriptive message in System.assertEquals(...) when testing if a method should never throw an Exception when called
     * @param  methodName Passes methodName as getAssertMessage(...)'s title
     * @return getNeverExpectExceptionMessage for methodName, and (Map<String, Object>) null
     */
    public static String getNeverExpectExceptionMessage(String methodName) {
        return getNeverExpectExceptionMessage(methodName, (Map<String, Object>) null);
    }
    
    /**
     * @description Provides a descriptive message in System.assertEquals(...) when testing expected equals actual
     * @param  methodName Passes methodName as getAssertMessage(...)'s title
     * @param values Map: Value Name -> Value to be passed in as getAssertMessage(...)'s values
     * @return getAssertMessage for 'Unexpected value of {0}', methodName, and values
     */
    public static String getUnexpectedValueMessage(String methodName, Map<String, Object> values) {
        return getAssertMessage(
            'Unexpected value of {0}.  {1}', 
            methodName, 
            values
        );
    }

    /**
     * @description Provides a descriptive message in System.assertEquals(...) when testing expected equals actual
     * @param  methodName Passes methodName as getAssertMessage(...)'s title
     * @return getUnexpectedValueMessage for methodName and (Map<String, Object>) null
     */
    public static String getUnexpectedValueMessage(String methodName) {
        return getUnexpectedValueMessage(methodName, (Map<String, Object>) null);
    }

    /**
     * @description Tests CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD is set as expected.
     */
    @IsTest
    private static void testUnsupportedOperationsByRollupField() {

        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // Map<SObjectField, Set<String>> UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD
            {
                // Assert map's values
                System.assertEquals(
                    new Map<Schema.SObjectField, Set<String>> {
                        Schema.Rollup__mdt.Date_Field__c => new Set<String> {}, // All Operations Supported
                        Schema.Rollup__mdt.Amount_Field__c => new Set<String> {
                            CRLP_Operation.RollupType.Count.name(), 
                            CRLP_Operation.RollupType.First.name(), 
                            CRLP_Operation.RollupType.Last.name()
                        }, // All Operations Supported
                        Schema.Rollup__mdt.Detail_Field__c => new Set<String> {
                            CRLP_Operation.RollupType.Sum.name(), 
                            CRLP_Operation.RollupType.Count.name(), 
                            CRLP_Operation.RollupType.Average.name(), 
                            CRLP_Operation.RollupType.Years_Donated.name(), 
                            CRLP_Operation.RollupType.Donor_Streak.name(), 
                            CRLP_Operation.RollupType.Best_Year.name(), 
                            CRLP_Operation.RollupType.Best_Year_Total.name()
                        }
                    }, 
                    CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD, 
                    'CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD has unexpected values'
                );
            }
        }
    }

    /**
     * @description Tests all secenarios for CRLP_Rollup_SEL.isRollupFieldNeededInQuery(Rollup__mdt rollup, SObjectField metadataRelationship)
     * isRollupFieldNeededInQuery(...) returns true if rollup.Operation__c is not null and not in the blacklist
     * CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD.
     * If rollup.Operation__c is not null and metadataRelationship is not a key in 
     * CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD, isRollupFieldNeededInQuery(...) should throw an
     * Exception.
     */
    @IsTest
    private static void testisRollupFieldNeededInQuery() {
        // Data
        final List<Rollup__mdt> rollups = new List<Rollup__mdt> {
            new Rollup__mdt() // Operation is null
        };
        for (Schema.PicklistEntry picklist : Schema.SObjectType.Rollup__mdt.fields.Operation__c.getPicklistValues()) {
            rollups.add(new Rollup__mdt(
                Operation__c = picklist.getValue()
            ));
        }

        final List<Schema.SObjectField> metadataRelationships = new List<Schema.SObjectField> {
            null, 
            Schema.Rollup__mdt.Id
        };
        {
            metadataRelationships.addAll(CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD.keySet());
        }

        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // Boolean isRollupFieldNeededInQuery(Rollup__mdt rollup, SObjectField metadataRelationship)
            {
                // Used in Exception messages
                final String METHOD_NAME = 'CRLP_Rollup_SEL.isRollupFieldNeededInQuery(Rollup__mdt rollup, Schema.SObjectField metadataRelationship)';
                final String BLACKLIST_NAME = 'CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD';

                // Test
                for (Rollup__mdt rollup : rollups) {
                    for (Schema.SObjectField metadataRelationship : metadataRelationships) {
                        // Expected
                        Exception expectedException;
                        try {
                            if (rollup.Operation__c != null) {
                                // This never gets called when rollup.Operation__c is null
                                CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD.get(metadataRelationship).contains(rollup.Operation__c);
                            }
                        } catch(Exception whoops) {
                            expectedException = whoops;
                        }
                        final Boolean expected = 
                            rollup.Operation__c != null 
                            && CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD.get(metadataRelationship) != null
                            && !CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD
                                .get(metadataRelationship)
                                .contains(rollup.Operation__c);
                        
                        // Test
                        Exception e;
                        Boolean actual;

                        try {
                            actual = CRLP_Rollup_SEL.isRollupFieldNeededInQuery(rollup, metadataRelationship);
                        } catch (Exception whoops) {
                            e = whoops;
                        }

                        // Expected Exception
                        if (expectedException == null) {
                            System.assertEquals(
                                null, 
                                e, 
                                BLACKLIST_NAME + ' is expected to support ' + metadataRelationship
                            );

                            System.assertEquals(
                                expected, 
                                actual,
                                getUnexpectedValueMessage(
                                    METHOD_NAME, 
                                    new Map<String, Object> {
                                        'rollup' => rollup, 
                                        'metadataRelationship' => metadataRelationship, 
                                        'CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD' => CRLP_Rollup_SEL.UNSUPPORTED_OPERATIONS_BY_ROLLUP_FIELD
                                    }
                                )
                            );
                        } else {
                            System.assertNotEquals(
                                null, 
                                e, 
                                BLACKLIST_NAME + ' is expected to NOT support ' + metadataRelationship
                            );
                            System.assertEquals(
                                expectedException.getTypeName(), 
                                e.getTypeName(), 
                                BLACKLIST_NAME + ' does not support ' + metadataRelationship + ' but throws an Exception in an unexpected way'
                            );

                            System.assertEquals(
                                null, 
                                actual,
                                METHOD_NAME + ' threw an Exception, so actual should be null'
                            );
                        }
                    }
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @description Container for each scenario to test CRLP_Rollup_SEL.getReferencedFieldsByObject(SObjectType objType)
     */
    private with sharing class GetReferencedFieldsByObjectTestData {
        final SObjectType sObjectType;
        final Rollup__mdt rollup;
        final List<Schema.DescribeFieldResult> expected;
        final String expectation, rollupMessage;

        private GetReferencedFieldsByObjectTestData(
            Schema.SObjectType objType, 
            Rollup__mdt rollup, 
            List<DescribeFieldResult> expected, 
            String expectation
        ) {
            this.sObjectType = objType;
            this.rollup = rollup;
            this.expected = expected;
            this.expectation = expectation;
            this.rollupMessage = getAssertMessage(
                '{1}', 
                '', 
                new Map<String, Object> {
                    '\tbase fields' => this.getRollup(), 
                    '\tSummary_Object__r' => this.getRollup().Summary_Object__r, 
                    '\tSummary_Field__r' => this.getRollup().Summary_Field__r, 
                    '\tDate_Object__r' => this.getRollup().Date_Object__r, 
                    '\tDate_Field__r' => this.getRollup().Date_Field__r, 
                    '\tAmount_Object__r' => this.getRollup().Amount_Object__r, 
                    '\tAmount_Field__r' => this.getRollup().Amount_Field__r, 
                    '\tDetail_Object__r' => this.getRollup().Detail_Object__r, 
                    '\tDetail_Field__r' => this.getRollup().Detail_Field__r
                }
            );
        }

        /**
         * @return objType to pass into CRLP_Rollup_SEL.getReferencedFieldsByObject(SObjectType objType)
         */
        private SObjectType getSObjectType() {
            return this.sObjectType;
        }

        /**
         * @return Rollup__mdt to set as CRLP_Rollup_SEL.cachedRollups
         */
        private Rollup__mdt getRollup() {
            return this.rollup;
        }

        /**
         * @return Value to set as Rollup__mdt to set as CRLP_Rollup_SEL.cachedRollups before running test
         */
        private List<Rollup__mdt> getCachedRollups() {
            return new List<Rollup__mdt> {
                this.getRollup()
            };
        }

        /**
         * @return Expected value of CRLP_Rollup_SEL.getReferencedFieldsByObject(SObjectType objType)
         */
        private List<Schema.DescribeFieldResult> getExpected() {
            return this.expected;
        }

        /**
         * @return Description of what this test scenario expects
         */
        private String getExpectation() {
            return this.expectation;
        }

        /**
         * @return Name of method tested; used in System.assert messages for debugging
         */
        private String getMethodName() {
            return 'List<Schema.DescribeFieldResult> CRLP_Rollup_SEL.getReferencedFieldsByObject(SObjectType objType)';
        }

        /**
         * @return Message describing the value of Rollup ; used in System.assert messages for debugging
         */
        private String getRollupMessage() {
            return this.rollupMessage;
        }

        /**
         * @description Tests CRLP_Rollup_SEL.getReferencedFieldsByObject(SObjectType objType) for this scenario.
         * Sets CRLP_Rollup_SEL.cachedRollups as Cached Rollups.
         * Asserts CRLP_Rollup_SEL.getReferencedFieldsByObject(SObjectType objType) for SObjectType equals Expected
         * and no Exceptions are thrown.
         */
        private void assertGetReferencedFieldsByObject() {
            final SObjectType objType = this.getSObjectType();

            final List<Schema.DescribeFieldResult> expected = this.getExpected();

            Exception e;
            List<Schema.DescribeFieldResult> actual;

            // Setup
            {
                CRLP_Rollup_SEL.cachedRollups = this.getCachedRollups();
            }

            try {
                actual = CRLP_Rollup_SEL.getReferencedFieldsByObject(objType);
            } catch (Exception whoops) {
                e = whoops;
            }

            // Expected Exception
            System.assertEquals(
                null, 
                e, 
                getNeverExpectExceptionMessage(
                    this.getMethodName(), 
                    new Map<String, Object> {
                        'Expectation' => this.getExpectation(), 
                        'rollup' => this.getRollupMessage(), 
                        'objType' => objType, 
                        'Stack Trace' => e == null ? '' : '\n' + e.getStackTraceString()
                    }
                )
            );
            
            System.assertEquals(
                expected, 
                actual,
                getUnexpectedValueMessage(
                    this.getMethodName(), 
                    new Map<String, Object> {
                        'Expectation' => this.getExpectation(), 
                        'rollup' => this.getRollupMessage(), 
                        'objType' => objType
                    }
                )
            );
        }
    }

    /**
     * @description Returns describe's relationship name.
     * DescribeFieldResult.getRelationshipName() doesn't return the expected value for Metadata Relationships.
     * @param  describe Relationship Field
     * @return If describe is custom, returns describe's name after removing ending '__c' + '__r'.
     * Else, describe's name
     */
    private static String toRelationshipName(Schema.DescribeFieldResult describe) {
        return describe.isCustom() ? describe.getName().removeEnd('__c') + '__r' : describe.getName();
    }

    /**
     * @description Tests all secenarios for CRLP_Rollup_SEL.getReferencedFieldsByObject(SObjectType objType) 
     * by storing each scenario in a GetReferencedFieldsByObjectTestData.
     * Scenario Types:
     *      Returns empty list: null objType
     *      Returns special Fields if Opportunity/CurrencyIsoCode: objType doesn't match or no active cachedRollups
     *      Returns special Fields if Opportunity/CurrencyIsoCode/Cached Rollup: single Rollup Relationship
     *      Returns special Fields if Opportunity/CurrencyIsoCode/Cached Rollup: all Rollup Relationships and no duplicates
     */
    @IsTest
    private static void testGetReferencedFieldsByObject() {
        final List<GetReferencedFieldsByObjectTestData> allTestData = new List<GetReferencedFieldsByObjectTestData>();
        {
            final String ROLLUP_SOBJECT_NAME = Schema.SObjectType.Rollup__mdt.getName();
            final String ROLLUP_OPERATION_FIELD = Schema.SObjectType.Rollup__mdt.fields.Operation__c.getName();
            final String ROLLUP_ACTIVE_FIELD = Schema.SObjectType.Rollup__mdt.fields.Active__c.getName();
            
            final Map<String, SObjectField> ROLLUP_SOBJECTFIELD_BY_RELATIONSHIP = new Map<String, SObjectField>();

            final String ROLLUP_SUMMARY_OBJECT_RELATIONSHIP = toRelationshipName(Schema.SObjectType.Rollup__mdt.fields.Summary_Object__c);
            final String ROLLUP_SUMMARY_FIELD_RELATIONSHIP = toRelationshipName(Schema.SObjectType.Rollup__mdt.fields.Summary_Field__c);
            ROLLUP_SOBJECTFIELD_BY_RELATIONSHIP.put(
                ROLLUP_SUMMARY_FIELD_RELATIONSHIP, 
                Schema.Rollup__mdt.Summary_Field__c
            );

            final String ROLLUP_DATE_OBJECT_RELATIONSHIP = toRelationshipName(Schema.SObjectType.Rollup__mdt.fields.Date_Object__c);
            final String ROLLUP_DATE_FIELD_RELATIONSHIP = toRelationshipName(Schema.SObjectType.Rollup__mdt.fields.Date_Field__c);
            ROLLUP_SOBJECTFIELD_BY_RELATIONSHIP.put(
                ROLLUP_DATE_FIELD_RELATIONSHIP, 
                Schema.Rollup__mdt.Date_Field__c
            );

            final String ROLLUP_AMOUNT_OBJECT_RELATIONSHIP = toRelationshipName(Schema.SObjectType.Rollup__mdt.fields.Amount_Object__c);
            final String ROLLUP_AMOUNT_FIELD_RELATIONSHIP = toRelationshipName(Schema.SObjectType.Rollup__mdt.fields.Amount_Field__c);
            ROLLUP_SOBJECTFIELD_BY_RELATIONSHIP.put(
                ROLLUP_AMOUNT_FIELD_RELATIONSHIP, 
                Schema.Rollup__mdt.Amount_Field__c
            );

            final String ROLLUP_DETAIL_OBJECT_RELATIONSHIP = toRelationshipName(Schema.SObjectType.Rollup__mdt.fields.Detail_Object__c);
            final String ROLLUP_DETAIL_FIELD_RELATIONSHIP = toRelationshipName(Schema.SObjectType.Rollup__mdt.fields.Detail_Field__c);
            ROLLUP_SOBJECTFIELD_BY_RELATIONSHIP.put(
                ROLLUP_DETAIL_FIELD_RELATIONSHIP, 
                Schema.Rollup__mdt.Detail_Field__c
            );

            final Map<String, String> ROLLUP_FIELDS_BY_OBJECT = new Map<String, String> {
                ROLLUP_SUMMARY_OBJECT_RELATIONSHIP => ROLLUP_SUMMARY_FIELD_RELATIONSHIP, 
                ROLLUP_DATE_OBJECT_RELATIONSHIP => ROLLUP_DATE_FIELD_RELATIONSHIP, 
                ROLLUP_AMOUNT_OBJECT_RELATIONSHIP => ROLLUP_AMOUNT_FIELD_RELATIONSHIP, 
                ROLLUP_DETAIL_OBJECT_RELATIONSHIP => ROLLUP_DETAIL_FIELD_RELATIONSHIP
            };

            final List<Boolean> actives = new List<Boolean> {
                true, 
                false
            };
            
            final Set<String> OPERATIONS = new Set<String> {
                null
            };
            for (Schema.PicklistEntry picklist : Schema.SObjectType.Rollup__mdt.fields.Operation__c.getPicklistValues()) {
                OPERATIONS.add(picklist.getValue());
            }

            // Returns empty list: null objType
            {
                final Schema.SObjectType objType = null;
                final List<Schema.DescribeFieldResult> expected = new List<Schema.DescribeFieldResult>();

                final Object entityDefinition = getEntityMetadataRelationship(Schema.SObjectType.Opportunity.getName());
                final Object fieldDefinition = getFieldMetadataRelationship(Schema.SObjectType.Opportunity.fields.Amount.getName());

                final Map<String, Object> rollupFields = new Map<String, Object> {
                    // ROLLUP_ACTIVE_FIELD
                    ROLLUP_SUMMARY_OBJECT_RELATIONSHIP => entityDefinition, 
                    ROLLUP_SUMMARY_FIELD_RELATIONSHIP => fieldDefinition, 
                    ROLLUP_DATE_OBJECT_RELATIONSHIP => entityDefinition, 
                    ROLLUP_DATE_FIELD_RELATIONSHIP => fieldDefinition, 
                    ROLLUP_AMOUNT_OBJECT_RELATIONSHIP => entityDefinition, 
                    ROLLUP_AMOUNT_FIELD_RELATIONSHIP => fieldDefinition, 
                    ROLLUP_DETAIL_OBJECT_RELATIONSHIP => entityDefinition, 
                    ROLLUP_DETAIL_FIELD_RELATIONSHIP => fieldDefinition
                };

                // Each possible Operation
                for (Boolean active : new List<Boolean> {
                    true, 
                    false
                }) {
                    for (String operation : OPERATIONS) {
                        {
                            rollupFields.put(ROLLUP_ACTIVE_FIELD, active);
                            rollupFields.put(ROLLUP_OPERATION_FIELD, operation);
                        }
                        allTestData.add(new GetReferencedFieldsByObjectTestData(
                            objType, 
                            (Rollup__mdt) getSObject(
                                ROLLUP_SOBJECT_NAME, 
                                rollupFields
                            ), 
                            expected, 
                            'Returns empty list: null objType'
                        ));
                    }
                }
            }

            // Returns special Fields if Opportunity/CurrencyIsoCode: objType doesn't match or no active cachedRollups
            {
                final Map<String, Object> activeRollupFields = new Map<String, Object>();
                {
                    final Object entityDefinition = getEntityMetadataRelationship(Schema.SObjectType.Contact.getName());
                    final Object fieldDefinition = getFieldMetadataRelationship(Schema.SObjectType.Contact.fields.npo02__Best_Gift_Year_Total__c.getName());

                    activeRollupFields.put(ROLLUP_ACTIVE_FIELD, true);
                    activeRollupFields.put(ROLLUP_SUMMARY_OBJECT_RELATIONSHIP, entityDefinition);
                    activeRollupFields.put(ROLLUP_SUMMARY_FIELD_RELATIONSHIP, fieldDefinition);
                    activeRollupFields.put(ROLLUP_DATE_OBJECT_RELATIONSHIP, entityDefinition);
                    activeRollupFields.put(ROLLUP_DATE_FIELD_RELATIONSHIP, fieldDefinition);
                    activeRollupFields.put(ROLLUP_AMOUNT_OBJECT_RELATIONSHIP, entityDefinition);
                    activeRollupFields.put(ROLLUP_AMOUNT_FIELD_RELATIONSHIP, fieldDefinition);
                    activeRollupFields.put(ROLLUP_DETAIL_OBJECT_RELATIONSHIP, entityDefinition);
                    activeRollupFields.put(ROLLUP_DETAIL_FIELD_RELATIONSHIP, fieldDefinition);
                }

                for (Schema.DescribeSObjectResult describe : new List<Schema.DescribeSObjectResult> {
                    Schema.SObjectType.Lead, 
                    Schema.SObjectType.Opportunity
                }) {
                    final Schema.SObjectType objType = describe.getSObjectType();
                    final List<Schema.DescribeFieldResult> expected = new List<Schema.DescribeFieldResult>();
                    
                    // Special Opportunity Fields
                    if(objType == Schema.Opportunity.SObjectType) {
                        expected.add(Schema.SObjectType.Opportunity.fields.AccountId);
                        expected.add(Schema.SObjectType.Opportunity.fields.Primary_Contact__c);
                    }

                    // CurrencyIsoCode
                    if (
                        UserInfo.isMultiCurrencyOrganization()
                        && describe.fields.getMap().get('CurrencyIsoCode') != null
                    ) {
                        expected.add(describe.fields.getMap().get('CurrencyIsoCode').getDescribe());
                    }

                    final Map<String, Object> inactiveRollupFields = new Map<String, Object>();
                    {
                        // Same objType but Rollup is not active
                        final Object entity = getEntityMetadataRelationship(describe.getName());
                        final Object field = getFieldMetadataRelationship(describe.fields.getMap().get('Id').getDescribe().getName());

                        inactiveRollupFields.put(ROLLUP_ACTIVE_FIELD, false);
                        inactiveRollupFields.put(ROLLUP_SUMMARY_OBJECT_RELATIONSHIP, entity);
                        inactiveRollupFields.put(ROLLUP_SUMMARY_FIELD_RELATIONSHIP, field);
                        inactiveRollupFields.put(ROLLUP_DATE_OBJECT_RELATIONSHIP, entity);
                        inactiveRollupFields.put(ROLLUP_DATE_FIELD_RELATIONSHIP, field);
                        inactiveRollupFields.put(ROLLUP_AMOUNT_OBJECT_RELATIONSHIP, entity);
                        inactiveRollupFields.put(ROLLUP_AMOUNT_FIELD_RELATIONSHIP, field);
                        inactiveRollupFields.put(ROLLUP_DETAIL_OBJECT_RELATIONSHIP, entity);
                        inactiveRollupFields.put(ROLLUP_DETAIL_FIELD_RELATIONSHIP, field);
                    }

                    // Each possible Operation
                    for (Map<String, Object> rollupFields : new List<Map<String,Object>> {
                        activeRollupFields, 
                        inactiveRollupFields
                    }) {
                        for (String operation : OPERATIONS) {
                            {
                                rollupFields.put(ROLLUP_OPERATION_FIELD, operation);
                            }
                            allTestData.add(new GetReferencedFieldsByObjectTestData(
                                objType, 
                                (Rollup__mdt) getSObject(
                                    ROLLUP_SOBJECT_NAME, 
                                    rollupFields
                                ), 
                                expected, 
                                'Returns special Fields if Opportunity/CurrencyIsoCode: objType doesn\'t match or no active cachedRollups'
                            ));
                        }
                    }
                }
            }

            // Returns special Fields if Opportunity/CurrencyIsoCode/Cached Rollup: single/all Rollup Relationship(s)
            for (Schema.DescribeSObjectResult describe : new List<Schema.DescribeSObjectResult> {
                Schema.SObjectType.Lead, 
                Schema.SObjectType.Opportunity
            }) {
                final Schema.SObjectType objType = describe.getSObjectType();
                final List<Schema.DescribeFieldResult> baseExpected = new List<Schema.DescribeFieldResult>();
                {
                    // Special Opportunity Fields
                    if(objType == Schema.Opportunity.SObjectType) {
                        baseExpected.add(Schema.SObjectType.Opportunity.fields.AccountId);
                        baseExpected.add(Schema.SObjectType.Opportunity.fields.Primary_Contact__c);
                    }

                    // CurrencyIsoCode
                    if (
                        UserInfo.isMultiCurrencyOrganization()
                        && describe.fields.getMap().get('CurrencyIsoCode') != null
                    ) {
                        baseExpected.add(describe.fields.getMap().get('CurrencyIsoCode').getDescribe());
                    }
                }

                // Expected result for Relationship
                final DescribeFieldResult fieldDescribe = describe.fields.getMap().get('Id').getDescribe();

                // Rollup Relationships for QualifiedApiName
                final Object entityDefinition = getEntityMetadataRelationship(describe.getName());
                final Object fieldDefinition = getFieldMetadataRelationship(fieldDescribe.getName());

                // Each possible Operation
                for (String operation : OPERATIONS) {
                    final Map<String, Object> rollupFieldsWithAllRelationships = new Map<String, Object> {
                        ROLLUP_ACTIVE_FIELD => true, 
                        ROLLUP_OPERATION_FIELD => operation
                    };

                    final List<Schema.DescribeFieldResult> expectedWithAllRelationships = new List<Schema.DescribeFieldResult>();
                    {
                        expectedWithAllRelationships.addAll(baseExpected);
                        expectedWithAllRelationships.add(fieldDescribe); // Summary always included if objType matches
                    }

                    for (String sObjectRelationship : ROLLUP_FIELDS_BY_OBJECT.keySet()) {
                        final String fieldRelationship = ROLLUP_FIELDS_BY_OBJECT.get(sObjectRelationship);

                        {
                            rollupFieldsWithAllRelationships.put(sObjectRelationship, entityDefinition);
                            rollupFieldsWithAllRelationships.put(fieldRelationship, fieldDefinition);
                        }

                        Rollup__mdt rollupWithSingleRelationship;
                        {
                            final Map<String, Object> rollupFieldsWithSingleRelationship = new Map<String, Object>();
                            {
                                rollupFieldsWithSingleRelationship.put(ROLLUP_ACTIVE_FIELD, true);
                                rollupFieldsWithSingleRelationship.put(sObjectRelationship, entityDefinition);
                                rollupFieldsWithSingleRelationship.put(fieldRelationship, fieldDefinition);
                                rollupFieldsWithSingleRelationship.put(ROLLUP_OPERATION_FIELD, operation);
                            }
                            rollupWithSingleRelationship = (Rollup__mdt) getSObject(
                                ROLLUP_SOBJECT_NAME, 
                                rollupFieldsWithSingleRelationship
                            );
                        }

                        final List<Schema.DescribeFieldResult> expectedWithSingleRelationship = new List<Schema.DescribeFieldResult>();
                        {
                            expectedWithSingleRelationship.addAll(baseExpected);
                        }
                        if (
                            fieldRelationship == ROLLUP_SUMMARY_FIELD_RELATIONSHIP // no isRollupFieldNeededInQuery check
                            || CRLP_Rollup_SEL.isRollupFieldNeededInQuery(
                                rollupWithSingleRelationship, 
                                ROLLUP_SOBJECTFIELD_BY_RELATIONSHIP.get(fieldRelationship)
                            )
                        ) {
                            expectedWithSingleRelationship.add(fieldDescribe);
                        }

                        allTestData.add(new GetReferencedFieldsByObjectTestData(
                            objType, 
                            rollupWithSingleRelationship, 
                            expectedWithSingleRelationship, 
                            'Returns special Fields if Opportunity/CurrencyIsoCode/Cached Rollup: single Rollup Relationship'
                        ));
                    }

                    final Rollup__mdt rollupWithAllRelationships = (Rollup__mdt) getSObject(
                        ROLLUP_SOBJECT_NAME, 
                        rollupFieldsWithAllRelationships
                    );

                    allTestData.add(new GetReferencedFieldsByObjectTestData(
                        objType, 
                        rollupWithAllRelationships, 
                        expectedWithAllRelationships, 
                        'Returns special Fields if Opportunity/CurrencyIsoCode/Cached Rollup: all Rollup Relationships and no duplicates'
                    ));
                }
            }
        }
        
        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // List<Schema.DescribeFieldResult> getReferencedFieldsByObject(SObjectType objType)
            for (GetReferencedFieldsByObjectTestData testData : allTestData) {
                testData.assertGetReferencedFieldsByObject();
            }
        }

        Test.stopTest();
    }
}