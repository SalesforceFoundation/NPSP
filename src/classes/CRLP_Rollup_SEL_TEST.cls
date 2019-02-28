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
    //@IsTest
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
     * @description           Useful when needing to set SObject's relationship values without querying
     * @param sObjectTypeName Name of SObjectType to be returned
     * @param fields          Map:Field Name -> Field Value of SObject's Fields.  May include Relationships.
     * @return                JSON deserailziation of an SObject for sObjectTypeName with fields
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
     * @description             Shortcut to set Metadata Relationships when using getSObject(...)
     * @param  sObjectTypeName  SObjectType's Name Metadata Relationship is pointing to
     * @param  qualifiedApiName QualifiedApiName
     * @return                  SObject for sObjectTypeName and fields mapping QualifiedApiName to qualifiedApiName
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
     * @description             Shortcut to set EntityDefinition Metadata Relationships when using getSObject(...)
     * @param  qualifiedApiName QualifiedApiName
     * @return                  getMetadataRelationship for EntityDefinition's SObjecType's Name and qualifiedApiName
     */
	public static SObject getEntityMetadataRelationship(String qualifiedApiName) {
		return getMetadataRelationship(
            Schema.SObjectType.EntityDefinition.getName(), 
            qualifiedApiName
        );
	}

    /**
     * @description             Shortcut to set FieldDefinition Metadata Relationships when using getSObject(...)
     * @param  qualifiedApiName QualifiedApiName
     * @return                  getMetadataRelationship for FieldDefinition's SObjecType's Name and qualifiedApiName
     */
	public static SObject getFieldMetadataRelationship(String qualifiedApiName) {
		return getMetadataRelationship(
            Schema.SObjectType.FieldDefinition.getName(), 
            qualifiedApiName
        );
	}

    /**
     * @description This test loops through all combinations of CRLP_Rollup_SEL's getQualifiedApiName(SObject metadata, SObjectField metadataRelationship) inputs -- both good and bad inputs.
     */
    @IsTest
    private static void testGetQualifiedApiName() {
        // Data
        final List<SObjectField> metadataRelationships = new List<SObjectField>();
        final Map<SObjectField, List<Rollup__mdt>> rollupsByMetadataRelationship = new Map<SObjectField, List<Rollup__mdt>>();

        // SObjectFields that are not Metadata Relationships
        for (SObjectField lookup : new List<SObjectField> {
            null, 
            Schema.Rollup__mdt.Id
        }) {
            metadataRelationships.add(lookup);
            rollupsByMetadataRelationship.put(
                lookup, 
                new List<Rollup__mdt> {
                    null, 
                    new Rollup__mdt()
                }
            );
        }

        // Lookups that are Metadata Relationships.  Taken from RollupFields' Lookups
        {
            final List<String> qualifiedApiNames = new List<String> {
                null, 
                'Opportunity__c'
            };
        
            for (CRLP_Rollup_SEL.RollupField rollupField : CRLP_Rollup_SEL.getRollupFields()) {
                for (SObjectField metadataRelationship : new List<SObjectField> {
                    rollupField.getSObjectLookup(), 
                    rollupFIeld.getFieldLookup()
                }) {
                    System.assertNotEquals(
                        null, 
                        metadataRelationship, 
                        'getSObjectLookup() and getFieldLookup() should not return null for all CRLP_Rollup_SEL.RollupFields returned in CRLP_Rollup_SEL.getRollupFields()'
                    );

                    metadataRelationships.add(metadataRelationship);
                    rollupsByMetadataRelationship.put(
                        metadataRelationship, 
                        new List<Rollup__mdt> {
                            null, 
                            new Rollup__mdt()
                        }
                    );

                    // Add Rollups who has an SObject for lookup
                    {
                        final String relationshipName = metadataRelationship.getDescribe().getName().removeEnd('__c') + '__r';

                        for (String qualifiedApiName : qualifiedApiNames) {
                            rollupsByMetadataRelationship.get(metadataRelationship).add((Rollup__mdt) getSObject(
                                Schema.SObjectType.Rollup__mdt.getName(), 
                                new Map<String, Object> {
                                    relationshipName => getFieldMetadataRelationship(qualifiedApiName)
                                }
                            ));
                        }
                    }
                }
            }
        }

        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // String getQualifiedApiName(SObject metadata, SObjectField metadataRelationship)
            {
                Boolean isExceptionThrownEveryTest = true;

                for (SObjectField metadataRelationship : metadataRelationships) {
                    for (SObject metadata : rollupsByMetadataRelationship.get(metadataRelationship)) {
                        Boolean isExceptionThrown;
                        {
                            try {
                                String actual = (String) metadata.getSObject(metadataRelationship).get('QualifiedApiName');
                                isExceptionThrown = false;
                                isExceptionThrownEveryTest = false;
                            }
                            catch (Exception e) {
                                isExceptionThrown = true;
                            }
                        }

                        final String expected = isExceptionThrown ? null : (String) metadata.getSObject(metadataRelationship).get('QualifiedApiName');

                        Exception e;
                        String actual;

                        try {
                            actual = CRLP_Rollup_SEL.getQualifiedApiName(metadata, metadataRelationship);
                        }
                        catch(Exception whoops) {
                            e = whoops;
                        }

                        System.assertEquals(
                            null, 
                            e, 
                            'CRLP_Rollup_SEL.getQualifiedApiName(...) should never throw an Exception'
                        );
                        
                        System.assertEquals(
                            expected, 
                            actual, 
                            String.format(
                                'CRLP_Rollup_SEL.getQualifiedApiName(metadata, metadataRelationship) is returning an unexpected value.  metadataRelationship: "{0}"; metadata: "{1}"', 
                                new List<String> {
                                    String.valueOf(metadataRelationship), 
                                    String.valueOf(metadata)
                                }
                            )
                        );
                    }
                }

                System.assertEquals(
                    false, 
                    isExceptionThrownEveryTest, 
                    'CRLP_Rollup_SEL.getQualifiedApiName(...): All test data threw an Exception when testing (String) metadata.getSObject(lookup).get(\'QualifiedApiName\').   Update the test data so getQualifiedApiName(...) can be tested with at least one positive test.'
                );
            }
        }

        Test.stopTest();
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
                messages.add(field + ': "' + values.get(field) + '"');
            }
        }
         
        return String.format(
            format, 
            new List<String> {
                title, 
                String.join(messages, ': ')
            }
        );
    }

    /**
     * @description Provide a descriptive message in System.assertEquals(...) when testing if a method should never throw an Exception when called
     * @param  methodName Passes methodName as getAssertMessage(...)'s title
     * @return getAssertMessage('{0' should never throw an Exception, methodName, (Map<String, Object>) null)
     */
    public static String getNeverExpectExceptionMessage(String methodName) {
        return getAssertMessage(
            '{0} should never throw an Exception', 
            methodName, 
            (Map<String, Object>) null
        );
    }
    
    /**
     * @description Provide a descriptive message in System.assertEquals(...) when testing expected equals actual
     * @param  methodName Passes methodName as getAssertMessage(...)'s title
     * @return getAssertMessage('Unexpected value of {0}', methodName, (Map<String, Object>) null)
     */
    public static String getUnexpectedValueMessage(String methodName) {
        return getAssertMessage(
            'Unexpected value of {0}', 
            methodName, 
            (Map<String, Object>) null
        );
    }

    /**
     * @description Provide a descriptive message in System.assertEquals(...) when testing expected equals actual
     * @param  methodName Passes methodName as getAssertMessage(...)'s title
     * @param values Map: Value Name -> Value to be passed in as getAssertMessage(...)'s values
     * @return getAssertMessage('Unexpected value of {0}', methodName, values)
     */
    public static String getUnexpectedValueMessage(String methodName, Map<String, Object> values) {
        return getAssertMessage(
            'Unexpected value of {0}.  {1}', 
            methodName, 
            values
        );
    }

    /**
     * @description testRollupField() tests all combinations of inputs to test each part of CRLP_Rollup_SEL.RollupField.  The validity of this test is proved in the quality of the test data.  This test should also "future proof" meaning if someone changes the behavior of CRLP_Rollup_SEL.RollupField, this test should fail.  A side note, CRLP_Operation_TEST asserts that the is a 1:1 correspondence between both CRLP_Operation.TimeBoundOperationType and Rollup__mdt.Time_Bound_Operation_Type__c Picklist Vlaues and CRLP_Operation.RollupType and Rollup__mdt.Operation__c Picklist Values.
     */
    @IsTest
    private static void testRollupField() {
        // Data
        final Map<SObjectField, SObjectField> fieldLookupBySObjectLookup = new Map<SObjectField, SObjectField> {
            null => null, 
            Schema.Rollup__mdt.Date_Object__c => Schema.Rollup__mdt.Date_Field__c, 
            Schema.Rollup__mdt.Amount_Object__c => Schema.Rollup__mdt.Amount_Field__c, 
            Schema.Rollup__mdt.Detail_Object__c => Schema.Rollup__mdt.Detail_Field__c
        };
    
        final List<Map<String, Set<String>>> supportedOperationsByTimeBoundOperationTypes = new List<Map<String, Set<String>>> {
            null, 
            new Map<String, Set<String>>(), 
            new Map<String, Set<String>> {
                CRLP_Operation.TimeBoundOperationType.All_Time.name() => (Set<String>) null, 
                CRLP_Operation.TimeBoundOperationType.Days_Back.name() => new Set<String> {
                    CRLP_Operation.RollupType.Average.name(), 
                    CRLP_Operation.RollupType.Best_Year.name()
                }
                // Missing Key: CRLP_Operation.TimeBoundOperationType.Years_Ago.name()
            }
        };

        final List<Rollup__mdt> rollups = new List<Rollup__mdt> {
            null
        };

        final List<String> timeBoundOperationTypes = new List<String> {
            null
        };

        final List<String> sObjectNames = new List<String> {
            null, 
            'A_Different_Custom_Object__c'
        };

        // Set rollups
        {
            final List<Boolean> options = new List<Boolean> {
                true, 
                false
            };

            final String ROLLUP_OBJECT_NAME = Schema.SObjectType.Rollup__mdt.getName();
            final String FIELD_NAME = 'Field__c';
            final String SOBJECT_NAME = 'Custom_Object__c';
            {
                sObjectNames.add(SOBJECT_NAME);
            }

            final String TIME_BOUND_OPERATION_TYPE_FIELD = Schema.SObjectType.Rollup__mdt.fields.Time_Bound_Operation_Type__c.getName();
            final String OPERATION_FIELD = Schema.SObjectType.Rollup__mdt.fields.Operation__c.getName();

            final List<String> SOBJECT_RELATIONSHIP_NAMES = new List<String>();
            for (SObjectField sObjectField : fieldLookupBySObjectLookup.keySet()) {
                if (sObjectField != null) {
                    SOBJECT_RELATIONSHIP_NAMES.add(sObjectField.getDescribe().getName().removeEnd('__c') + '__r');
                }
            }

            final List<String> FIELD_RELATIONSHIP_NAMES = new List<String>();
            for (SObjectField sObjectField : fieldLookupBySObjectLookup.values()) {
                if (sObjectField != null) {
                    FIELD_RELATIONSHIP_NAMES.add(sObjectField.getDescribe().getName().removeEnd('__c') + '__r');
                }
            }
            
            Map<String, Set<String>> allOperationsByTimeBoundOperationType = new Map<String, Set<String>>();
            {
                supportedOperationsByTimeBoundOperationTypes.add(allOperationsByTimeBoundOperationType);
            }
            for (CRLP_Operation.TimeBoundOperationType timeBoundOperationType : CRLP_Operation.TimeBoundOperationType.values()) {
                Set<String> allOperations = new Set<String>();
                {
                    allOperationsByTimeBoundOperationType.put(timeBoundOperationType.name(), allOperations);
                }
                {
                    timeBoundOperationTypes.add(timeBoundOperationType.name());
                }
                
                for( CRLP_Operation.RollupType rollupType : CRLP_Operation.RollupType.values()) {
                    {
                        allOperations.add(rollupType.name());
                    }

                    for (Boolean isSObjectNotNull : options) {
                        for (Boolean isFieldNotNull : options) {
                            final Map<String, Object> fields = new Map<String, Object> {
                                TIME_BOUND_OPERATION_TYPE_FIELD => timeBoundOperationType.name(), 
                                OPERATION_FIELD => rollupType.name()
                            };

                            if (isSObjectNotNull) {
                                final Object relationship = getEntityMetadataRelationship(SOBJECT_NAME);
                                for(String relationshipName : SOBJECT_RELATIONSHIP_NAMES) {
                                    fields.put(relationshipName, relationship);
                                }
                            }

                            if (isFieldNotNull) {
                                final Object relationship = getFieldMetadataRelationship(FIELD_NAME);
                                for(String relationshipName : FIELD_RELATIONSHIP_NAMES) {
                                    fields.put(relationshipName, relationship);
                                }
                            }

                            rollups.add((Rollup__mdt) getSObject(ROLLUP_OBJECT_NAME, fields));
                        }
                    }
                }
            }
        }

        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // RollupField
            for (SObjectField sObjectLookup : fieldLookupBySObjectLookup.keySet()) {
                final SObjectField fieldLookup = fieldLookupBySObjectLookup.get(sObjectLookup);


                for (Map<String, Set<String>> supportedOperationsByTimeBoundOperationType : supportedOperationsByTimeBoundOperationTypes) {
                    final CRLP_Rollup_SEL.RollupField rollupField = new CRLP_Rollup_SEL.RollupField(
                        sObjectLookup, 
                        fieldLookup, 
                        supportedOperationsByTimeBoundOperationType
                    );

                    // SObjectField getSObjectLookup()
                    {
                        System.assertEquals(
                            sObjectLookup, 
                            rollupField.getSObjectLookup(), 
                            getUnexpectedValueMessage('CRLP_Rollup_SEL.RollupField.getSObjectLookup()')
                        );
                    }

                    // String getFieldLookup()
                    {
                        System.assertEquals(
                            fieldLookup, 
                            rollupField.getFieldLookup(), 
                            getUnexpectedValueMessage('CRLP_Rollup_SEL.RollupField.getFieldLookup()')
                        );
                    }

                    // Map<String, Set<String>> getSupportedOperationsByTimeBoundOperationType()
                    {
                        System.assertEquals(
                            supportedOperationsByTimeBoundOperationType, 
                            rollupField.getSupportedOperationsByTimeBoundOperationType(), 
                            getUnexpectedValueMessage('CRLP_Rollup_SEL.RollupField.getSupportedOperationsByTimeBoundOperationType()')
                        );
                    }

                    // Set<String> getSupportedOperations(String timeBoundOperationType)
                    for (String timeBoundOperationType : timeBoundOperationTypes) {
                        final String METHOD_NAME = 'CRLP_Rollup_SEL.RollupField.getSupportedOperations(String timeBoundOperationType)';
                        
                        final Set<String> operations = supportedOperationsByTimeBoundOperationType == null || supportedOperationsByTimeBoundOperationType.get(timeBoundOperationType) == null ? new Set<String>() : supportedOperationsByTimeBoundOperationType.get(timeBoundOperationType);
                        final Set<String> expected = operations == null ? new Set<String>() : operations;

                        Exception e;
                        Set<String> actual;

                        try {
                            actual = rollupField.getSupportedOperations(timeBoundOperationType);
                        }
                        catch (Exception whoops) {
                            e = whoops;
                        }
                        
                        System.assertEquals(
                            null, 
                            e, 
                            getNeverExpectExceptionMessage(METHOD_NAME)
                        );
                        System.assertEquals(
                            expected, 
                            actual, 
                            getUnexpectedValueMessage(
                                METHOD_NAME, 
                                new Map<String, Object> {
                                    'timeBoundOperationType' => timeBoundOperationType
                                }
                            )
                        );
                    }

                    for(Rollup__mdt rollup : rollups) {
                        // String getSObjectName(Rollup__mdt rollup)
                        {
                            final String METHOD_NAME = 'CRLP_Rollup_SEL.RollupField.getSObjectName(Rollup__mdt rollup)';

                            final String expected = CRLP_Rollup_SEL.getQualifiedApiName(
                                rollup, 
                                rollupField.getSObjectLookup()
                            );
                            
                            Exception e;
                            String actual;

                            try {
                                actual = rollupField.getSObjectName((rollup));
                            }
                            catch (Exception whoops) {
                                e = whoops;
                            }
                            
                            System.assertEquals(
                                null, 
                                e, 
                                getNeverExpectExceptionMessage(METHOD_NAME)
                            );
                            System.assertEquals(
                                expected, 
                                actual, 
                                getUnexpectedValueMessage(
                                    METHOD_NAME, 
                                    new Map<String, Object> {
                                        'rollup' => rollup, 
                                        'rollupField.getSObjectLookup()' => rollupField.getSObjectLookup()
                                    }
                                )
                            );
                        }

                        // String getFieldName(Rollup__mdt rollup)
                        {
                            final String METHOD_NAME = 'CRLP_Rollup_SEL.RollupField.getFieldName(Rollup__mdt rollup)';

                            final String expected = CRLP_Rollup_SEL.getQualifiedApiName(
                                rollup, 
                                rollupField.getFieldLookup()
                            );
                            
                            Exception e;
                            String actual;

                            try {
                                actual = rollupField.getFieldName((rollup));
                            }
                            catch (Exception whoops) {
                                e = whoops;
                            }
                            
                            System.assertEquals(
                                null, 
                                e, 
                                getNeverExpectExceptionMessage(METHOD_NAME)
                            );
                            System.assertEquals(
                                expected, 
                                actual, 
                                getUnexpectedValueMessage(
                                    METHOD_NAME, 
                                    new Map<String, Object> {
                                        'rollup' => rollup, 
                                        'rollupField.getFieldLookup()' => rollupField.getFieldLookup()
                                    }
                                )
                            );
                        }

                        // Boolean isRollupSupported(Rollup__mdt rollup)
                        {
                            final String METHOD_NAME = 'CRLP_Rollup_SEL.RollupField.isRollupSupported(Rollup__mdt rollup)';

                            final Boolean expected = 
                                rollup != null 
                                && rollupField.getSupportedOperations(rollup.Time_Bound_Operation_Type__c).contains(rollup.Operation__c);
                            
                            Exception e;
                            Boolean actual;

                            try {
                                actual = rollupField.isRollupSupported(rollup);
                            }
                            catch (Exception whoops) {
                                e = whoops;
                            }
                            
                            System.assertEquals(
                                null, 
                                e, 
                                getNeverExpectExceptionMessage(METHOD_NAME)
                            );
                            System.assertEquals(
                                expected, 
                                actual, 
                                getUnexpectedValueMessage(
                                    METHOD_NAME, 
                                    new Map<String, Object> {
                                        'rollup' => rollup, 
                                        'rollupField.getSupportedOperations(rollup == null ? null : rollup.Time_Bound_Operation_Type__c)' => rollupField.getSupportedOperations(rollup == null ? null : rollup.Time_Bound_Operation_Type__c)
                                    }
                                )
                            );
                        }

                        // Boolean isFieldUsed(Rollup__mdt rollup, String sObjectName)
                        for (String sObjectName : sObjectNames) {
                            final String METHOD_NAME = 'CRLP_Rollup_SEL.RollupField.isFieldUsed(Rollup__mdt rollup, String sObjectName)';

                            final Boolean expected = 
                                rollupField.getFieldName(rollup) != null
                                && sObjectName != null
                                && rollupField.getSObjectName(rollup) == sObjectName
                                && rollupField.isRollupSupported(rollup);
                            
                            Exception e;
                            Boolean actual;

                            try {
                                actual = rollupField.isFieldUsed(rollup, sObjectName);
                            }
                            catch (Exception whoops) {
                                e = whoops;
                            }
                            
                            System.assertEquals(
                                null, 
                                e, 
                                getNeverExpectExceptionMessage(METHOD_NAME)
                            );
                            System.assertEquals(
                                expected, 
                                actual, 
                                getUnexpectedValueMessage(
                                    METHOD_NAME, 
                                    new Map<String, Object> {
                                        'rollup' => rollup, 
                                        'sObjectName' => sObjectName
                                    }
                                )
                            );
                        }
                    }
                }
            }
        }

        Test.stopTest();
    }

    /**
     * @param  DescribeFieldResult's getPicklsitValues()
     * @return Set of all picklists' Values
     */
    public static Set<String> getPicklistValues(Schema.PicklistEntry[] picklists) {
        final Set<String> picklistValues = new Set<String>();
        for (Schema.PicklistEntry picklist : picklists) {
            picklistValues.add(picklist.getValue());
        }
        return picklistValues;
    }

    /**
     * @description Asserts CRLP_Rollup_SEL.RollupFields are equal
     * @param  expected 
     * @param  actual 
     * @param  methodName Name of method being tested.  Prefixes all assertEquals(...) messages
     */
    public static void assertEquals(
        CRLP_Rollup_SEL.RollupField expected, 
        CRLP_Rollup_SEL.RollupField actual, 
        String methodName
    ) {
        if (expected == null) {
            System.assertEquals(
                null, 
                actual, 
                methodName + ' is expected to be null'
            );
        }
        else {
            System.assertNotEquals(
                null, 
                actual, 
                methodName + ' is expected to be non-null'
            );

            System.assertEquals(
                expected.getSObjectLookup(), 
                actual.getSObjectLookup(), 
                methodName + ' has an unexpected getSObjectLookup()'
            );

            System.assertEquals(
                expected.getFieldLookup(), 
                actual.getFieldLookup(), 
                methodName + ' has an unexpected getFieldLookup()'
            );

            System.assertEquals(
                expected.getSupportedOperationsByTimeBoundOperationType(), 
                actual.getSupportedOperationsByTimeBoundOperationType(), 
                methodName + ' has an unxpected getSupportedOperationsByTimeBoundOperationType()'
            );
        }
    }

    /**
     * @description Asserts List<CRLP_Rollup_SEL.RollupField> are equal
     * @param  expected 
     * @param  actual 
     * @param  methodName Name of method being tested.  Prefixes all assertEquals(...) messages
     */
    public static void assertEquals(
        List<CRLP_Rollup_SEL.RollupField> expected, 
        List<CRLP_Rollup_SEL.RollupField> actual, 
        String methodName
    ) {
        if (expected == null) {
            System.assertEquals(
                null, 
                actual, 
                methodName + ' is expected to be null'
            );
        }
        else {
            System.assertNotEquals(
                null, 
                actual, 
                methodName + ' is expected to be non-null'
            );

            final Integer expectedSize = expected.size();

            System.assertEquals(
                expectedSize, 
                actual.size(), 
                methodName + ' has an unexpected size()'
            );

            for(Integer i = 0; i < expectedSize; i ++) {
                assertEquals(
                    expected[i], 
                    actual[i], 
                    methodName + '[' + i + ']'
                );
            }
        }
    }

    /**
     * @description Tests CRLP_Rollup_SEL's RollupField getDateRollupField(), RollupField getAmountRollupField(), RollupField getDetailRollupField(), RollupField[] getRollupFields()
     */
    @IsTest
    private static void testGetRollupFields() {
        // Data
        final Set<String> timeBoundOperationTypes = getPicklistValues(Schema.SObjectType.Rollup__mdt.fields.Time_Bound_Operation_Type__c.getPicklistValues());
        

        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // RollupField getDateRollupField()
            {
                final String METHOD_NAME = 'CRLP_Rollup_SEL.getDateRollupField()';

                final Set<String> allOperations = getPicklistValues(Schema.SObjectType.Rollup__mdt.fields.Operation__c.getPicklistValues());

                final CRLP_Rollup_SEL.RollupField expected = new CRLP_Rollup_SEL.RollupField(
                    Schema.Rollup__mdt.Date_Object__c, 
                    Schema.Rollup__mdt.Date_Field__c, 
                    new Map<String, Set<String>> {
                        CRLP_Operation.TimeBoundOperationType.All_Time.name() => new Set<String> {
                            CRLP_Operation.RollupType.First.name(), 
                            CRLP_Operation.RollupType.Last.name(), 
                            CRLP_Operation.RollupType.Years_Donated.name(), 
                            CRLP_Operation.RollupType.Donor_Streak.name(), 
                            CRLP_Operation.RollupType.Best_Year.name(), 
                            CRLP_Operation.RollupType.Best_Year_Total.name()
                        }, 
                        CRLP_Operation.TimeBoundOperationType.Days_Back.name() => allOperations, 
                        CRLP_Operation.TimeBoundOperationType.Years_Ago.name() => allOperations
                    }
                );

                Exception e;
                CRLP_Rollup_SEL.RollupField actual;

                // Setup
                {
                    CRLP_Rollup_SEL.dateRollupField = null;
                }

                try {
                    actual = CRLP_Rollup_SEL.getDateRollupField();
                }
                catch (Exception whoops) {
                    e = whoops;
                }
                
                System.assertEquals(
                    null, 
                    e, 
                    getNeverExpectExceptionMessage(METHOD_NAME)
                );

                assertEquals(
                    expected, 
                    actual, 
                    METHOD_NAME
                );

                assertEquals(
                    expected, 
                    CRLP_Rollup_SEL.dateRollupField, 
                    'CRLP_Rollup_SEL.dateRollupField'
                );
            }

            // RollupField getAmountRollupField()
            {
                final String METHOD_NAME = 'CRLP_Rollup_SEL.getAmountRollupField()';

                final Set<String> operations = new Set<String> {
                    CRLP_Operation.RollupType.Sum.name(), 
                    CRLP_Operation.RollupType.Average.name(), 
                    CRLP_Operation.RollupType.Smallest.name(), 
                    CRLP_Operation.RollupType.Largest.name(), 
                    CRLP_Operation.RollupType.Years_Donated.name(), 
                    CRLP_Operation.RollupType.Donor_Streak.name(), 
                    CRLP_Operation.RollupType.Best_Year.name(), 
                    CRLP_Operation.RollupType.Best_Year_Total.name()
                };

                final CRLP_Rollup_SEL.RollupField expected = new CRLP_Rollup_SEL.RollupField(
                    Schema.Rollup__mdt.Amount_Object__c, 
                    Schema.Rollup__mdt.Amount_Field__c, 
                    new Map<String, Set<String>> {
                        CRLP_Operation.TimeBoundOperationType.All_Time.name() => operations, 
                        CRLP_Operation.TimeBoundOperationType.Days_Back.name() => operations, 
                        CRLP_Operation.TimeBoundOperationType.Years_Ago.name() => operations
                    }
                );

                Exception e;
                CRLP_Rollup_SEL.RollupField actual;

                // Setup
                {
                    CRLP_Rollup_SEL.amountRollupField = null;
                }

                try {
                    actual = CRLP_Rollup_SEL.getAmountRollupField();
                }
                catch (Exception whoops) {
                    e = whoops;
                }
                
                System.assertEquals(
                    null, 
                    e, 
                    getNeverExpectExceptionMessage(METHOD_NAME)
                );

                assertEquals(
                    expected, 
                    actual, 
                    METHOD_NAME
                );

                assertEquals(
                    expected, 
                    CRLP_Rollup_SEL.amountRollupField, 
                    'CRLP_Rollup_SEL.amountRollupField'
                );
            }

            // RollupField getDetailRollupField()
            {
                final String METHOD_NAME = 'CRLP_Rollup_SEL.getDetailRollupField()';

                final Set<String> operations = new Set<String> {
                    CRLP_Operation.RollupType.Smallest.name(), 
                    CRLP_Operation.RollupType.Largest.name(), 
                    CRLP_Operation.RollupType.First.name(), 
                    CRLP_Operation.RollupType.Last.name()
                };

                final CRLP_Rollup_SEL.RollupField expected = new CRLP_Rollup_SEL.RollupField(
                    Schema.Rollup__mdt.Detail_Object__c, 
                    Schema.Rollup__mdt.Detail_Field__c, 
                    new Map<String, Set<String>> {
                        CRLP_Operation.TimeBoundOperationType.All_Time.name() => operations, 
                        CRLP_Operation.TimeBoundOperationType.Days_Back.name() => operations, 
                        CRLP_Operation.TimeBoundOperationType.Years_Ago.name() => operations
                    }
                );

                Exception e;
                CRLP_Rollup_SEL.RollupField actual;

                // Setup
                {
                    CRLP_Rollup_SEL.detailRollupField = null;
                }

                try {
                    actual = CRLP_Rollup_SEL.getDetailRollupField();
                }
                catch (Exception whoops) {
                    e = whoops;
                }
                
                System.assertEquals(
                    null, 
                    e, 
                    getNeverExpectExceptionMessage(METHOD_NAME)
                );

                assertEquals(
                    expected, 
                    actual, 
                    METHOD_NAME
                );

                assertEquals(
                    expected, 
                    CRLP_Rollup_SEL.detailRollupField, 
                    'CRLP_Rollup_SEL.detailRollupField'
                );
            }

            // List<RollupField> getRollupFields()
            {
                final String METHOD_NAME = 'CRLP_Rollup_SEL.getRollupFields()';

                final List<CRLP_Rollup_SEL.RollupField> expected = new List<CRLP_Rollup_SEL.RollupField> {
                    CRLP_Rollup_SEL.getDateRollupField(), 
                    CRLP_Rollup_SEL.getAmountRollupField(), 
                    CRLP_Rollup_SEL.getDetailRollupField()
                };

                Exception e;
                List<CRLP_Rollup_SEL.RollupField> actual;

                // Setup
                {
                    CRLP_Rollup_SEL.detailRollupField = null;
                }

                try {
                    actual = CRLP_Rollup_SEL.getRollupFields();
                }
                catch (Exception whoops) {
                    e = whoops;
                }
                
                System.assertEquals(
                    null, 
                    e, 
                    getNeverExpectExceptionMessage(METHOD_NAME)
                );

                assertEquals(
                    expected, 
                    actual, 
                    METHOD_NAME
                );
            }
        }

        Test.stopTest();
    }

    public with sharing class GetReferencedFieldsByObjectData {
        final SObjectType sObjectType;
        final List<Rollup__mdt> cachedRollups;
        final List<Schema.DescribeFieldResult> expectedReferencedFieldsBySObject;
        final String description;

        public GetReferencedFieldsByObjectData(
            final SObjectType objType, 
            final List<Rollup__mdt> cachedRollups, 
            final List<Schema.DescribeFieldResult> expectedReferencedFieldsBySObject, 
            final String description
        ) {
            this.sObjectType = objType; // Uses objType as name to match CRLP_Rollup_SEL.getReferencedFieldsByObject(...)'s signature
            this.cachedRollups = cachedRollups;
            this.expectedReferencedFieldsBySObject = expectedReferencedFieldsBySObject;
            this.description = description;
        }

        public String getMethodName() {
            return 'CRLP_Rollup_SEL.getReferencedFieldsByObject(SObjectType objType)';
        }

        public SObjectType getSObjectType() {
            return this.sObjectType;
        }

        public List<Rollup__mdt> getCachedRollups() {
            return this.cachedRollups;
        }

        public List<Schema.DescribeFieldResult> getExpectedReferencedFieldsBySObject() {
            return this.expectedReferencedFieldsBySObject;
        }

        public String getDescription() {
            return this.description;
        }

        public String getDescription(List<Schema.DescribeFieldResult> describes) {
            final List<String> names = new List<String>();
            for (Schema.DescribeFieldResult describe : describes) {
                names.add(describe.getName());
            }
            return String.join(names, ', ');
        }

        public void assertGetsReferencedFieldsBySObject() {
            final List<Schema.DescribeFieldResult> expected = this.getExpectedReferencedFieldsBySObject();

            Exception e;
            List<Schema.DescribeFieldResult> actual;

            // Setup
            {
                //CRLP_Rollup_SEL.cachedRollups = null; // Reset so previous reference doesn't get overwritten
                CRLP_Rollup_SEL.cachedRollups = this.getCachedRollups();
            }

            try {
                actual = CRLP_Rollup_SEL.getReferencedFieldsByObject(this.getSObjectType());
            }
            catch (Exception whoops) {
                e = whoops;
            }

            System.assertEquals(
                null, 
                e, 
                getNeverExpectExceptionMessage(this.getMethodName())
            );
            System.assertEquals(
                expected, 
                actual, 
                getUnexpectedValueMessage(
                    this.getMethodName(), 
                    new Map<String, Object> {
                        'README' => 'Check that all Rollup__mdt Time_Bound_Operation_Type__c and Operation__c supported by all RollupFields', 
                        'description' => this.getDescription(), 
                        'objType' => this.getSObjectType(), 
                        'this.getCachedRollups()' => this.getCachedRollups(), 
                        'CRLP_Rollup_SEL.cachedRollups' => CRLP_Rollup_SEL.cachedRollups, 
                        'expected' => getDescription(expected), 
                        'actual' => getDescription(actual)
                    }
                )
            );
        }
    }

    public static void addCurrencyIsoCode(
        List<Schema.DescribeFieldResult> expectedReferencedFields, 
        DescribeSObjectResult describe
    ) {
        if (
            UserInfo.isMultiCurrencyOrganization()
            && describe.fields.getMap().get('CurrencyIsoCode') != null
        ) {
            expectedReferencedFields.add(describe.fields.getMap().get('CurrencyIsoCode').getDescribe());
        }
    }

    public static List<List<Rollup__mdt>> getAllRollupsWithNoSObjectReference() {
        return new List<List<Rollup__mdt>> {
            new List<Rollup__mdt>(), 
            
            // No Summary or Rollup Fields
            new List<Rollup__mdt> {
                new Rollup__mdt(
                    Active__c = false, 
                    // Rollup__mdt's Time_Bound_Operation_Type__c and Operation__c should be supported for all RollupFields
                    Time_Bound_Operation_Type__c = CRLP_Operation.TimeBoundOperationType.Years_Ago.name(), 
                    Operation__c = CRLP_Operation.RollupType.Smallest.name()
                ), 
                new Rollup__mdt(
                    Active__c = true, 
                    // Rollup__mdt's Time_Bound_Operation_Type__c and Operation__c should be supported for all RollupFields
                    Time_Bound_Operation_Type__c = CRLP_Operation.TimeBoundOperationType.Years_Ago.name(), 
                    Operation__c = CRLP_Operation.RollupType.Smallest.name()
                )
            }
        };
    }

    public static List<Rollup__mdt> getRollupsWithSummaryAndRollupFields() {
        final List<Rollup__mdt> rollups = new List<Rollup__mdt>();

        for (Boolean isActive : new List<Boolean> {
            true, 
            false
        }) {
            final Map<String, Object> fields = new Map<String, Object> {
                'Summary_Object__r' => getEntityMetadataRelationship(Schema.SObjectType.Account.getName()), 
                'Summary_Field__r' => getFieldMetadataRelationship(Schema.SObjectType.Account.fields.AccountNumber.getName()), 
                'Date_Object__r' => getEntityMetadataRelationship(Schema.SObjectType.Contact.getName()), 
                'Date_Field__r' => getFieldMetadataRelationship(Schema.SObjectType.Contact.fields.npo02__FirstCloseDate__c.getName()), 
                'Amount_Object__r' => getEntityMetadataRelationship(Schema.SObjectType.Opportunity.getName()), 
                'Amount_Field__r' => getFieldMetadataRelationship(Schema.SObjectType.Opportunity.fields.Amount.getName()), 
                'Detail_Object__r' => getEntityMetadataRelationship(Schema.SObjectType.Opportunity.getName()), 
                'Detail_Field__r' => getFieldMetadataRelationship(Schema.SObjectType.Opportunity.fields.Amount.getName())
            };
            {
                fields.put(Schema.SObjectType.Rollup__mdt.fields.Active__c.getName(), isActive);

                // Rollup__mdt's Time_Bound_Operation_Type__c and Operation__c should be supported for all RollupFields
                fields.put(
                    Schema.SObjectType.Rollup__mdt.fields.Time_Bound_Operation_Type__c.getName(), CRLP_Operation.TimeBoundOperationType.Years_Ago.name()
                );
                fields.put(
                    Schema.SObjectType.Rollup__mdt.fields.Operation__c.getName(), 
                    CRLP_Operation.RollupType.Smallest.name()
                );
                
            }
            rollups.add((Rollup__mdt) getSObject(
                Schema.SObjectType.Rollup__mdt.getName(), 
                fields
            ));
        }
        return rollups;
    }

    @IsTest
    private static void testGetReferencedFieldByObject() {
        // Data

        final List<GetReferencedFieldsByObjectData> allGetReferencedFieldsByObjectData = new List<GetReferencedFieldsByObjectData>();
        {
            // Null SObjectType + any cached Rollups => empty referencedFields
            {
                // allRollupsWithNoSObjectReference
                for(List<Rollup__mdt> rollups : getAllRollupsWithNoSObjectReference()) {
                    allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                        (SObjectType) null, 
                        rollups, 
                        new List<Schema.DescribeFieldResult>(), 
                        'Null SObjectType + any cached Rollups => empty referencedFields; allRollupsWithNoSObjectReference'
                    ));
                }

                // rollupsWithSummaryAndRollupFields
                {
                    allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                        (SObjectType) null, 
                        getRollupsWithSummaryAndRollupFields(), 
                        new List<Schema.DescribeFieldResult>(), 
                        'Null SObjectType + any cached Rollups => empty referencedFields; rollupsWithSummaryAndRollupFields'
                    ));
                }
            }

            // Non-Null SObjectType + any cached Rollups => expected referencedFields
            {
                // No cachedRollup matches objType
                {
                    final SObjectType objType = Schema.Lead.SObjectType;

                    final List<Schema.DescribeFieldResult> expectedReferencedFields = new List<Schema.DescribeFieldResult>();
                    addCurrencyIsoCode(expectedReferencedFields, Schema.SObjectType.Lead);

                    // rollupsWithNoSObjectReference
                    for (List<Rollup__mdt> rollups : getAllRollupsWithNoSObjectReference()) {
                        allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                            objType, 
                            rollups, 
                            expectedReferencedFields, 
                            'No cachedRollup matches objType; rollupsWithNoSObjectReference'
                        ));
                    }

                    // rollupsWithSummaryAndRollupFields
                    {
                        allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                            objType, 
                            getRollupsWithSummaryAndRollupFields(), 
                            expectedReferencedFields, 
                            'No cachedRollup matches objType; rollupsWithSummaryAndRollupFields'
                        ));
                    }
                }

                // objType: Account
                {
                    final SObjectType objType = Schema.Account.SObjectType;

                    // rollupsWithNoSObjectReference
                    {
                        final List<Schema.DescribeFieldResult> expectedReferencedFields = new List<Schema.DescribeFieldResult>();
                        addCurrencyIsoCode(expectedReferencedFields, Schema.SObjectType.Account);

                        for (List<Rollup__mdt> rollups : getAllRollupsWithNoSObjectReference()) {
                            allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                                objType, 
                                rollups, 
                                expectedReferencedFields, 
                                'objType: Account; rollupsWithNoSObjectReference'
                            ));
                        }
                    }

                    // rollupsWithSummaryAndRollupFields
                    {
                        final List<Schema.DescribeFieldResult> expectedReferencedFields = new List<Schema.DescribeFieldResult>();
                        addCurrencyIsoCode(expectedReferencedFields, Schema.SObjectType.Account);
                        {
                            expectedReferencedFields.add(Schema.SObjectType.Account.fields.AccountNumber);
                        }

                        allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                            objType, 
                            getRollupsWithSummaryAndRollupFields(), 
                            expectedReferencedFields, 
                            'objType: Account; rollupsWithSummaryAndRollupFields'
                        ));
                    }
                }
            
                // objType: Contact
                {
                    final SObjectType objType = Schema.Contact.SObjectType;

                    // rollupsWithNoSObjectReference
                    {
                        final List<Schema.DescribeFieldResult> expectedReferencedFields = new List<Schema.DescribeFieldResult>();
                        addCurrencyIsoCode(expectedReferencedFields, Schema.SObjectType.Contact);

                        for (List<Rollup__mdt> rollups : getAllRollupsWithNoSObjectReference()) {
                            allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                                objType, 
                                rollups, 
                                expectedReferencedFields, 
                                'objType: Contact; rollupsWithNoSObjectReference'
                            ));
                        }
                    }
                    // rollupsWithSummaryAndRollupFields
                    {
                        final List<Schema.DescribeFieldResult> expectedReferencedFields = new List<Schema.DescribeFieldResult>();
                        addCurrencyIsoCode(expectedReferencedFields, Schema.SObjectType.Contact);
                        {
                            expectedReferencedFields.add(Schema.SObjectType.Contact.fields.npo02__FirstCloseDate__c);
                        }

                        GetReferencedFieldsByObjectData data = new GetReferencedFieldsByObjectData(
                            objType, 
                            getRollupsWithSummaryAndRollupFields(), 
                            expectedReferencedFields, 
                            'objType: Contact; rollupsWithSummaryAndRollupFields'
                        );

                        allGetReferencedFieldsByObjectData.add(data);
                    }
                
                }
            
                // objType: Opportunity
                {
                    final SObjectType objType = Schema.Opportunity.SObjectType;

                    // rollupsWithNoSObjectReference
                    {
                        final List<Schema.DescribeFieldResult> expectedReferencedFields = new List<Schema.DescribeFieldResult> {
                            Schema.SObjectType.Opportunity.fields.AccountId, 
                            Schema.SObjectType.Opportunity.fields.Primary_Contact__c
                        };
                        addCurrencyIsoCode(expectedReferencedFields, Schema.SObjectType.Opportunity);

                        for (List<Rollup__mdt> rollups : getAllRollupsWithNoSObjectReference()) {
                            allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                                objType, 
                                rollups, 
                                expectedReferencedFields, 
                                'objType: Opportunity; rollupsWithNoSObjectReference'
                            ));
                        }
                    }

                    // rollupsWithSummaryAndRollupFields
                    {
                        final List<Schema.DescribeFieldResult> expectedReferencedFields = new List<Schema.DescribeFieldResult> {
                            Schema.SObjectType.Opportunity.fields.AccountId, 
                            Schema.SObjectType.Opportunity.fields.Primary_Contact__c
                        };
                        addCurrencyIsoCode(expectedReferencedFields, Schema.SObjectType.Opportunity);
                        {
                            // Opportunity.Amount is "duplicated" in Rollup__mdt.Amount_Field__c and Rollup__mdt.Detail_Field__c
                            expectedReferencedFields.add(Schema.SObjectType.Opportunity.fields.Amount);
                        }

                        allGetReferencedFieldsByObjectData.add(new GetReferencedFieldsByObjectData(
                            objType, 
                            getRollupsWithSummaryAndRollupFields(), 
                            expectedReferencedFields, 
                            'objType: Opportunity; rollupsWithSummaryAndRollupFields'
                        ));
                    }
                }
            }
        }

        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // List<Schema.DescribeFieldResult> getReferencedFieldsByObject(SObjectType objType)
            for(GetReferencedFieldsByObjectData getReferencedFieldsByObjectData : allGetReferencedFieldsByObjectData) {
                getReferencedFieldsByObjectData.assertGetsReferencedFieldsBySObject();
            }
        }

        Test.stopTest();
    }
}