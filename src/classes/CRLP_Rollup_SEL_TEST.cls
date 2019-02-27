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


/*
    @IsTest
    private static void testRollupField() {
        // Data
        final SObjectField[] sObjectLookups = new SObjectField[] {
            Schema.Rollup__mdt.Date_Object__c,
            Schema.Rollup__mdt.Amount_Object__c,
            Schema.Rollup__mdt.Detail_Object__c
        };
        final Integer sObjectLookupsSize = sObjectLookups.size();

        final SObjectField[] fieldLookups = new SObjectField[] {
            Schema.Rollup__mdt.Date_Field__c, 
            Schema.Rollup__mdt.Amount_Field__c, 
            Schema.Rollup__mdt.Detail_Field__c
        };
        {
            System.assertEquals(
                sObjectLookupsSize, 
                fieldLookups.size(), 
                'Test data should have same size.  sObjectLookups and fieldLookups should have 1:1 correspondence: Each fieldLookup belongs to sObjectLookup for the same index'    
            );
        }
        
        final String[] testOperations = new String[] {
            null
        };

        final String[] testTimeBoundOperationTypes = new String[] {
            null
        };

        final List<Map<String, Set<String>>> supportedOperationsByTimeBoundOperationTypes = new List<Map<String, Set<String>>> {
            new Map<String, Set<String>>()
        };
        {
            // Picklist Values
            String firstOperation;
            final Set<String> operations = new Set<String>();
            for (Schema.PicklistEntry picklist : Schema.SObjectType.Rollup__mdt.fields.Operation__c.getPicklistValues()) {
                operations.add(picklist.getValue());
                testOperations.add(picklist.getValue());
            }

            final Set<String> timeBoundOperationTypes = new Set<String>();
            for (Schema.PicklistEntry picklist : Schema.SObjectType.Rollup__mdt.fields.Time_Bound_Operation_Type__c.getPicklistValues()) {
                timeBoundOperationTypes.add(picklist.getValue());
                testTimeBoundOperationTypes.add(picklist.getValue());
            }

            // All
            {
                Map<String, Set<String>> supportedOperations = new Map<String, Set<String>>();
                {
                    supportedOperationsByTimeBoundOperationTypes.add(supportedOperations);
                }

                for (String timeBoundOperationType : timeBoundOperationTypes) {
                    supportedOperations.put(timeBoundOperationType, operations);
                }
            }

            // First Time Bound Operation Type with subset of Operations
            {
                Map<String, Set<String>> supportedOperations = new Map<String, Set<String>>();
                {
                    supportedOperationsByTimeBoundOperationTypes.add(supportedOperations);
                }

                final Set<String> operationsSubset = new Set<String>();
                final Integer operationsSize = operations.size();
                if (1 < operationsSize) {
                    final Integer size = Math.floor(Math.random() * Double.valueOf(operationsSize - 1)).intValue();
                    final String[] operationsList = new List<String>(operations);
                    for (Integer i = 0; i < size; i ++) {
                        operationsSubset.add(operationsList[i]);
                    }
                }
                
                Boolean isFirst = true;
                for (String timeBoundOperationType : timeBoundOperationTypes) {
                    if (isFirst) {
                        supportedOperations.put(timeBoundOperationType, operationsSubset);
                        isFirst = false;
                    }
                    else {
                        supportedOperations.put(timeBoundOperationType, new Set<String>());
                    }
                }
            }
        }

        final String[] sObjectNames = new String[] {
            null, 
            Schema.SObjectType.Opportunity.getName()
        };

        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // RollupField
            for (Integer rollupFieldIndex = 0; rollupFieldIndex < sObjectLookupsSize; rollupFieldIndex ++) {
                final SObjectField sObjectLookup = sObjectLookups[rollupFieldIndex];
                final SObjectField fieldLookup = fieldLookups[rollupFieldIndex];
                {
                    System.assertNotEquals(null, sObjectLookup);
                    System.assertNotEquals(null, fieldLookup);
                }

                final String sObjectLookupRelationshipName = sObjectLookup.getDescribe().getName().removeEnd('__c') + '__r';
                final String fieldLookupRelationshipName = fieldLookup.getDescribe().getName().removeEnd('__c') + '__r';

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
                            rollupField.getSObjectLookup()
                        );
                    }

                    // String getFieldLookup()
                    {
                        System.assertEquals(
                            fieldLookup, 
                            rollupField.getFieldLookup()
                        );
                    }

                    // Map<String, Set<String>> getSupportedOperationsByTimeBoundOperationType()
                    {
                        System.assertEquals(
                            supportedOperationsByTimeBoundOperationType, 
                            rollupField.getSupportedOperationsByTimeBoundOperationType()
                        );
                    }

                    // Methods requiring Rollup__mdt with null Rollup__mdt
                    {
                        final Rollup__mdt rollup = null;

                        // String getSObjectName(Rollup__mdt rollup)
                        {
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
                            
                            System.assertEquals(null, e);
                            System.assertEquals(expected, actual);
                        }

                        // String getFieldName(Rollup__mdt rollup)
                        {
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
                            
                            System.assertEquals(null, e);
                            System.assertEquals(expected, actual);
                        }

                        // Boolean isRollupSupported(Rollup__mdt rollup)
                        {
                            final Boolean expected = rollup != null 
                                && rollupField.getSupportedOperations(rollup.Time_Bound_Operation_Type__c).contains(rollup.Operation__c);
                            
                            Exception e;
                            Boolean actual;

                            try {
                                actual = rollupField.isRollupSupported(rollup);
                            }
                            catch (Exception whoops) {
                                e = whoops;
                            }
                            
                            System.assertEquals(null, e);
                            System.assertEquals(expected, actual);
                        }

                        // Boolean isFieldUsed(Rollup__mdt rollup, String sObjectName)
                        for (String sObjectName : sObjectNames) {
                            final Boolean expected = rollupField.getFieldName(rollup) != null
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
                            
                            System.assertEquals(null, e);
                            System.assertEquals(expected, actual);
                        }
                    }

                    for (String timeBoundOperationType : testTimeBoundOperationTypes) {
                        // Set<String> getSupportedOperations(String timeBoundOperationType)
                        {
                            final Set<String> expected = supportedOperationsByTimeBoundOperationType.get(timeBoundOperationType) == null ? new Set<String>() : supportedOperationsByTimeBoundOperationType.get(timeBoundOperationType);

                            Exception e;
                            Set<String> actual;

                            try {
                                actual = rollupField.getSupportedOperations(timeBoundOperationType);
                            }
                            catch (Exception whoops) {
                                e = whoops;
                            }
                            
                            System.assertEquals(null, e);
                            System.assertEquals(expected, actual);
                        }

                        for (String operation : testOperations) {
                            final Rollup__mdt rollup = (Rollup__mdt) getSObject(
                                Schema.SObjectType.Rollup__mdt.getName(), 
                                new Map<String, Object> {
                                    fieldLookupRelationshipName => getEntityMetadataRelationship(Schema.SObjectType.Opportunity.getName()), 
                                    fieldLookupRelationshipName => getFieldMetadataRelationship(Schema.SObjectType.Opportunity.fields.Amount.getName()), 
                                    Schema.SObjectType.Rollup__mdt.fields.Time_Bound_Operation_Type__c.getName() => timeBoundOperationType, 
                                    Schema.SObjectType.Rollup__mdt.fields.Operation__c.getName() => operation
                                }
                            );

                            // String getSObjectName(Rollup__mdt rollup)
                            {
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
                                
                                System.assertEquals(null, e);
                                System.assertEquals(expected, actual);
                            }

                            // String getFieldName(Rollup__mdt rollup)
                            {
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
                                
                                System.assertEquals(null, e);
                                System.assertEquals(expected, actual);
                            }

                            // Boolean isRollupSupported(Rollup__mdt rollup)
                            {
                                final Boolean expected = rollup != null 
                                    && rollupField.getSupportedOperations(rollup.Time_Bound_Operation_Type__c).contains(rollup.Operation__c);
                                
                                Exception e;
                                Boolean actual;

                                try {
                                    actual = rollupField.isRollupSupported(rollup);
                                }
                                catch (Exception whoops) {
                                    e = whoops;
                                }
                                
                                System.assertEquals(null, e);
                                System.assertEquals(expected, actual);
                            }

                            // Boolean isFieldUsed(Rollup__mdt rollup, String sObjectName)
                            for (String sObjectName : sObjectNames) {
                                final Boolean expected = rollupField.getFieldName(rollup) != null
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
                                
                                System.assertEquals(null, e);
                                System.assertEquals(expected, actual);
                            }
                        }
                    }
                }
            }
        }

        Test.stopTest();
    }

    public static Set<String> getPicklistValues(Schema.PicklistEntry[] picklists) {
        final Set<String> picklistValues = new Set<String>();
        for(Schema.PicklistEntry picklist : picklists) {
            picklistValues.add(picklist.getValue());
        }
        return picklistValues;
    }

    public static void assertEquals(CRLP_Rollup_SEL.RollupField expected, CRLP_Rollup_SEL.RollupField actual, String description) {
        if (expected == null) {
            System.assertEquals(null, actual, description);
        }
        else {
            System.assertNotEquals(null, actual, description);
            System.assertEquals(
                expected.getSObjectLookup(), 
                actual.getSObjectLookup(), 
                description
            );
            System.assertEquals(
                expected.getFieldLookup(), 
                actual.getFieldLookup(), 
                description
            );
            System.assertEquals(
                expected.getSupportedOperationsByTimeBoundOperationType(), 
                actual.getSupportedOperationsByTimeBoundOperationType(), 
                description
            );
        }
    }

    /**
     * @description Tests CRLP_Rollup_SEL's RollupField getDateRollupField(), RollupField getAmountRollupField(), RollupField getDetailRollupField(), RollupField[] getRollupFields()
     * /
    @IsTest
    private static void testGetRollupFields() {
        // Data
        final Set<String> timeBoundOperationTypes = getPicklistValues(Schema.SObjectType.Rollup__mdt.fields.Time_Bound_Operation_Type__c.getPicklistValues());
        final Set<String> operations = getPicklistValues(Schema.SObjectType.Rollup__mdt.fields.Operation__c.getPicklistValues());

        Test.startTest();

        // CRLP_Rollup_SEL
        {
            // RollupField getDateRollupField()
            {
                final CRLP_Rollup_SEL.RollupField expected = new CRLP_Rollup_SEL.RollupField(
                    Schema.Rollup__mdt.Detail_Object__c, 
                    Schema.Rollup__mdt.Detail_Field__c, 
                    new Map<String, Set<String>> {
                        CRLP_Operation.TimeBoundOperationType.All_Time.name() => new Set<String> {
                            CRLP_Operation.RollupType.First.name(), 
                            CRLP_Operation.RollupType.Last.name(), 
                            CRLP_Operation.RollupType.Years_Donated.name(), 
                            CRLP_Operation.RollupType.Donor_Streak.name(), 
                            CRLP_Operation.RollupType.Best_Year.name(), 
                            CRLP_Operation.RollupType.Best_Year_Total.name()
                        }, 
                        CRLP_Operation.TimeBoundOperationType.Days_Back.name() => new Set<String> {
                            CRLP_Operation.RollupType.Sum.name(), 
                            CRLP_Operation.RollupType.Count.name(), 
                            CRLP_Operation.RollupType.Average.name(), 
                            CRLP_Operation.RollupType.Smallest.name(), 
                            CRLP_Operation.RollupType.Largest.name(), 
                            CRLP_Operation.RollupType.First.name(), 
                            CRLP_Operation.RollupType.Last.name(), 
                            CRLP_Operation.RollupType.Years_Donated.name(), 
                            CRLP_Operation.RollupType.Donor_Streak.name(), 
                            CRLP_Operation.RollupType.Best_Year.name(), 
                            CRLP_Operation.RollupType.Best_Year_Total.name()
                        }, 
                        CRLP_Operation.TimeBoundOperationType.Years_Ago.name() => new Set<String> {
                            CRLP_Operation.RollupType.Sum.name(), 
                            CRLP_Operation.RollupType.Count.name(), 
                            CRLP_Operation.RollupType.Average.name(), 
                            CRLP_Operation.RollupType.Smallest.name(), 
                            CRLP_Operation.RollupType.Largest.name(), 
                            CRLP_Operation.RollupType.First.name(), 
                            CRLP_Operation.RollupType.Last.name(), 
                            CRLP_Operation.RollupType.Years_Donated.name(), 
                            CRLP_Operation.RollupType.Donor_Streak.name(), 
                            CRLP_Operation.RollupType.Best_Year.name(), 
                            CRLP_Operation.RollupType.Best_Year_Total.name()
                        }
                    }
                );

                // Setup
                {

                }
            }
        }

        Test.stopTest();
    }

/*
    /**
     * Cached data for Set<String> getRollupPicklistValues(SObjectField picklistField)
     * /
    private static final Map<SObjectField, Set<String>> ROLLUP_PICKLIST_VALUES_BY_FIELD = new Map<SObjectField, Set<String>>();
    
    /**
     * Returns cached Set of Picklist Values for picklistField
     * @param  picklistField 
     * @return               return cached Set of picklistField's Picklist Entries' values
     * /
    public static Set<String> getRollupPicklistValues(SObjectField picklistField) {
        if(
            picklistField != null 
            && ROLLUP_PICKLIST_VALUES_BY_FIELD.get(picklistField) == null
        ) {
            Set<String> picklistValues = new Set<String>{};
            {
                ROLLUP_PICKLIST_VALUES_BY_FIELD.put(picklistField, picklistValues);
            }
            for(Schema.PicklistEntry picklistEntry : picklistField.getDescribe().getPicklistValues()) {
                // Including all Picklist Entries, i.e. not checking if picklistEntry.isActive() is true
                picklistValues.add(picklistEntry.getValue());
            }
        }
       return ROLLUP_PICKLIST_VALUES_BY_FIELD.get(picklistField);
    }

    /**
     * getOperationsAndAssertValidity Validates rollupField and timeBoundOperationType are supported in  CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType and returns CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType's Set of supported Rollup__mdt.Operation__c Picklist Values.
     * @param  rollupField            rollupField Used in Boolean isFieldReferenced(Rollup__mdt rollup, SObjectField rollupField).  Asserts rollupField is supported.
     * @param  timeBoundOperationType timeBoundOperationType rollup's Time_Bound_Operation_Type__c used in Boolean isFieldReferenced(Rollup__mdt rollup, SObjectField rollupField).  Asserts timeBoundOperationType is a valid Rollup__mdt.Time_Bound_Operation_Type__c Picklist Value
     * @return                        return Set of Rollup__mdt.Operation__c Picklist Values from CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType after validating rollupField and timeBoundOperationType are valid values and return Set of Rollup__mdt.Operation
     * /
    public static Set<String> getOperationsAndAssertValidity(
        SObjectField rollupField, 
        String timeBoundOperationType
    ) {
        if(CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType == null) {
            CRLP_Rollup_SEL.isFieldReferenced(
                (Rollup__mdt) null, 
                (SObjectField) null
            );
            System.assertNotEquals(null, CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType);
        }

        // Assert supported rollupField
        System.assertNotEquals(
            null, 
            CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType.get(rollupField), 
            String.format(
                '"{0}" is not a supported Rollup__mdt rollup field', 
                new String[] {
                    String.valueOf(rollupField)
                }
            )
        );
        
        // Assert timeBoundOperationType is a valid Rollup__mdt.Time_Bound_Operation_Type__c Picklist Value
        System.assertEquals(
            true, 
            getRollupPicklistValues(Schema.Rollup__mdt.Time_Bound_Operation_Type__c).contains(timeBoundOperationType), 
            String.format(
                '"{0}" is not a Rollup__mdt.Time_Bound_Operation_Type__c Picklist Value', 
                new String[] {
                    timeBoundOperationType
                }
            )
        );

        final Set<String> operations = CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType
            .get(rollupField)
            .get(timeBoundOperationType);
        
        // Assert timeBoundOperationType is supported operations
        System.assertNotEquals(
            null, 
            operations, 
            String.format(
                'CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType cannot be null for SObjectField "{0}" and Rollup__mdt.Time_Bound_Operation_Type__c Picklist Value "{1}"', 
                new String[] {
                    String.valueOf(rollupField), 
                    timeBoundOperationType
                }
            )    
        );

        // operations contains only Rollup__mdt.Operation__c Picklist Values
        System.assertEquals(
            true, 
            getRollupPicklistValues(Schema.Rollup__mdt.Operation__c).containsAll(operations), 
            String.format(
                'CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType for SObjectField "{0}" and Rollup__mdt.Time_Bound_Operation_Type__c Picklist Value "{1}" can only contain Rollup__mdt.Operation__c Picklsit Values', 
                new String[] {
                    String.valueOf(rollupField), 
                    timeBoundOperationType
                }
            )
        );

        return operations;
    }

    /**
     * @description Tests the following CRLP_Rollup_SEL methods:
     *      Boolean isFieldReferenced(Rollup__mdt rollup, SObjectField rollupField)
     * / 
    @IsTest
    private static void testIsFieldReferenced() {
        // Supported rollupField values
        final Set<SObjectField> rollupFields = new Set<SObjectField>{
            Schema.Rollup__mdt.Date_Field__c, 
            Schema.Rollup__mdt.Amount_Field__c, 
            Schema.Rollup__mdt.Detail_Field__c
        };

        // Used to test all possible rollupFields
        final SObjectField[] testRollupFields = new SObjectField[] {
            null, 
            Schema.Rollup__mdt.Id
        };
        {
            testRollupFields.addAll(rollupFields);
        }

        // Used to test all possible Time_Bound_Operation_Type__c values
        final String[] testTimeBoundOperationTypes = new String[] {
            null, 
            'Not a supported Time Bound Operation Type'
        };
        {
            testTimeBoundOperationTypes.addAll(getRollupPicklistValues(Schema.Rollup__mdt.Time_Bound_Operation_Type__c));
        }
        
        // Used to test all possible Time_Bound_Operation_Type__c values
        final String[] testOperations = new String[] {
            null, 
            'Not a supported Operation'
        };
        {
            testOperations.addAll(getRollupPicklistValues(Schema.Rollup__mdt.Operation__c));
        }

        // Note: CRLP_Operation_TEST asserts CRLP_Operation.RollupType getRollupTypeFromString(String operation) returns a non-null CRLP_Operation.RollupType for all Schema.Rollup__mdt.Operation__c Picklist Values

        Test.startTest();
        
        // CRLP_Rollup_SEL
        {
            // Boolean isFieldReferenced(Rollup__mdt rollup, SObjectField rollupField)
            {
                // operationsByFieldByTimeBoundOperationType
                {
                    CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType = null;

                    CRLP_Rollup_SEL.isFieldReferenced(
                        (Rollup__mdt) null, 
                        Schema.Rollup__mdt.Date_Field__c
                    );

                    System.assertNotEquals(null, CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType);
                    System.assertEquals(
                        rollupFields, 
                        CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType.keySet(), 
                        'CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType only supports SObjectFields listed in rollupFields defined at the start of this test'
                    );
                    
                    // Date_Field__c
                    {
                        // All_Time
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Date_Field__c, 
                                'All_Time'
                            );
                            
                            // Contains
                            System.assertEquals(6, operations.size());

                            System.assertEquals(true, operations.contains('First'));
                            System.assertEquals(true, operations.contains('Last'));
                            System.assertEquals(true, operations.contains('Years_Donated'));
                            System.assertEquals(true, operations.contains('Donor_Streak'));
                            System.assertEquals(true, operations.contains('Best_Year'));
                            System.assertEquals(true, operations.contains('Best_Year_Total'));

                            // Not contains
                            System.assertEquals(false, operations.contains('Sum'));
                            System.assertEquals(false, operations.contains('Count'));
                            System.assertEquals(false, operations.contains('Average'));
                            System.assertEquals(false, operations.contains('Smallest'));
                            System.assertEquals(false, operations.contains('Largest'));
                        }

                        // Days_Back
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Date_Field__c, 
                                'Days_Back'
                            );
                            
                            // Contains all
                            System.assertEquals(11, operations.size());

                            System.assertEquals(true, operations.containsAll(getRollupPicklistValues(Schema.Rollup__mdt.Operation__c)));
                        }

                        // Years_Ago
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Date_Field__c, 
                                'Years_Ago'
                            );
                            
                            // Contains all
                            System.assertEquals(11, operations.size());

                            System.assertEquals(true, operations.containsAll(getRollupPicklistValues(Schema.Rollup__mdt.Operation__c)));
                        }
                    }

                    // Amount_Field__c
                    {
                        // All_Time
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Amount_Field__c, 
                                'All_Time'
                            );
                            
                            // Contains
                            System.assertEquals(8, operations.size());

                            System.assertEquals(true, operations.contains('Sum'));
                            System.assertEquals(true, operations.contains('Average'));
                            System.assertEquals(true, operations.contains('Smallest'));
                            System.assertEquals(true, operations.contains('Largest'));
                            System.assertEquals(true, operations.contains('Years_Donated'));
                            System.assertEquals(true, operations.contains('Donor_Streak'));
                            System.assertEquals(true, operations.contains('Best_Year'));
                            System.assertEquals(true, operations.contains('Best_Year_Total'));

                            // Not contains
                            System.assertEquals(false, operations.contains('Count'));
                            System.assertEquals(false, operations.contains('First'));
                            System.assertEquals(false, operations.contains('Last'));
                        }

                        // Days_Back
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Amount_Field__c, 
                                'Days_Back'
                            );
                            
                            // Contains
                            System.assertEquals(8, operations.size());

                            System.assertEquals(true, operations.contains('Sum'));
                            System.assertEquals(true, operations.contains('Average'));
                            System.assertEquals(true, operations.contains('Smallest'));
                            System.assertEquals(true, operations.contains('Largest'));
                            System.assertEquals(true, operations.contains('Years_Donated'));
                            System.assertEquals(true, operations.contains('Donor_Streak'));
                            System.assertEquals(true, operations.contains('Best_Year'));
                            System.assertEquals(true, operations.contains('Best_Year_Total'));

                            // Not contains
                            System.assertEquals(false, operations.contains('Count'));
                            System.assertEquals(false, operations.contains('First'));
                            System.assertEquals(false, operations.contains('Last'));
                        }

                        // Years_Ago
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Amount_Field__c, 
                                'Years_Ago'
                            );
                            
                            // Contains
                            System.assertEquals(8, operations.size());

                            System.assertEquals(true, operations.contains('Sum'));
                            System.assertEquals(true, operations.contains('Average'));
                            System.assertEquals(true, operations.contains('Smallest'));
                            System.assertEquals(true, operations.contains('Largest'));
                            System.assertEquals(true, operations.contains('Years_Donated'));
                            System.assertEquals(true, operations.contains('Donor_Streak'));
                            System.assertEquals(true, operations.contains('Best_Year'));
                            System.assertEquals(true, operations.contains('Best_Year_Total'));

                            // Not contains
                            System.assertEquals(false, operations.contains('Count'));
                            System.assertEquals(false, operations.contains('First'));
                            System.assertEquals(false, operations.contains('Last'));
                        }
                    }

                    // Detail_Field__c
                    {
                        // All_Time
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Detail_Field__c, 
                                'All_Time'
                            );
                            
                            // Contains
                            System.assertEquals(4, operations.size());

                            System.assertEquals(true, operations.contains('Smallest'));
                            System.assertEquals(true, operations.contains('Largest'));
                            System.assertEquals(true, operations.contains('First'));
                            System.assertEquals(true, operations.contains('Last'));


                            // Not contains
                            System.assertEquals(false, operations.contains('Sum'));
                            System.assertEquals(false, operations.contains('Count'));
                            System.assertEquals(false, operations.contains('Average'));
                            System.assertEquals(false, operations.contains('Years_Donated'));
                            System.assertEquals(false, operations.contains('Donor_Streak'));
                            System.assertEquals(false, operations.contains('Best_Year'));
                            System.assertEquals(false, operations.contains('Best_Year_Total'));
                        }

                        // Days_Back
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Detail_Field__c, 
                                'Days_Back'
                            );
                            
                            // Contains
                            System.assertEquals(4, operations.size());

                            System.assertEquals(true, operations.contains('Smallest'));
                            System.assertEquals(true, operations.contains('Largest'));
                            System.assertEquals(true, operations.contains('First'));
                            System.assertEquals(true, operations.contains('Last'));


                            // Not contains
                            System.assertEquals(false, operations.contains('Sum'));
                            System.assertEquals(false, operations.contains('Count'));
                            System.assertEquals(false, operations.contains('Average'));
                            System.assertEquals(false, operations.contains('Years_Donated'));
                            System.assertEquals(false, operations.contains('Donor_Streak'));
                            System.assertEquals(false, operations.contains('Best_Year'));
                            System.assertEquals(false, operations.contains('Best_Year_Total'));
                        }

                        // Years_Ago
                        {
                            final Set<String> operations = getOperationsAndAssertValidity(
                                Schema.Rollup__mdt.Detail_Field__c, 
                                'Years_Ago'
                            );
                            
                            // Contains
                            System.assertEquals(4, operations.size());

                            System.assertEquals(true, operations.contains('Smallest'));
                            System.assertEquals(true, operations.contains('Largest'));
                            System.assertEquals(true, operations.contains('First'));
                            System.assertEquals(true, operations.contains('Last'));


                            // Not contains
                            System.assertEquals(false, operations.contains('Sum'));
                            System.assertEquals(false, operations.contains('Count'));
                            System.assertEquals(false, operations.contains('Average'));
                            System.assertEquals(false, operations.contains('Years_Donated'));
                            System.assertEquals(false, operations.contains('Donor_Streak'));
                            System.assertEquals(false, operations.contains('Best_Year'));
                            System.assertEquals(false, operations.contains('Best_Year_Total'));
                        }
                    }
                }
            
                // null Rollup__mdt  
                for(SObjectField rollupField : testRollupFields) {
                    // Test
                    final Boolean expected = false;
                    
                    Exception e;
                    Boolean actual;

                    try {
                        actual = CRLP_Rollup_SEL.isFieldReferenced(
                            (Rollup__mdt) null, 
                            rollupField
                        );
                    }
                    catch(Exception whoops) {
                        e = whoops;
                    }

                    System.assertEquals(null, e);
                    System.assertEquals(
                        expected, 
                        actual, 
                        'CRLP_Rollup_SEL.isFieldReferenced(...) should always return false for a null Rollup__mdt'
                    );
                }

                // With rollup + isDateFieldReferenced + isAmountFieldReferenced + isDetailFieldReferenced
                for(String timeBoundOperationType : testTimeBoundOperationTypes) {
                    for(String operation : testOperations) {
                        final Rollup__mdt rollup = new Rollup__mdt(
                            Time_Bound_Operation_Type__c = timeBoundOperationType, 
                            Operation__c = operation
                        );

                        // With rollup
                        for(SObjectField rollupField : testRollupFields) {
                            if(CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType == null) {
                                CRLP_Rollup_SEL.isFieldReferenced(
                                    (Rollup__mdt) null, 
                                    (SObjectField) null
                                );
                                System.assertNotEquals(
                                    null, 
                                    CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType
                                );
                            }
                            
                            final Boolean expected = rollup != null
                                && CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType.get(rollupField) != null
                                && getRollupPicklistValues(Schema.Rollup__mdt.Time_Bound_Operation_Type__c).contains(timeBoundOperationType)
                                && getRollupPicklistValues(Schema.Rollup__mdt.Operation__c).contains(operation)
                                && CRLP_Rollup_SEL.operationsByFieldByTimeBoundOperationType
                                    .get(rollupField)
                                    .get(timeBoundOperationType)
                                    .contains(operation);

                            Exception e;
                            Boolean actual;

                            try {
                                actual = CRLP_Rollup_SEL.isFieldReferenced(
                                    rollup, 
                                    rollupField
                                );
                            }
                            catch(Exception whoops) {
                                e = whoops;
                            }

                            System.assertEquals(null, e);
                            System.assertEquals(expected, actual);
                        }
                    }
                }
            }
        }

        Test.stopTest();
    }
*/
}