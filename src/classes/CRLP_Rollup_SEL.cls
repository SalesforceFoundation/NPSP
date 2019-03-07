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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Selector class for Rollup definition custom metadata.
*/
public class CRLP_Rollup_SEL {

    /**
     * @description Private static var to cache the Custom Metadata Type records.
     * In terms of limits, these DO use up Query Rows, but NOT Queries.
     * This are testVisible to allow unit tests to mock the contents of the static var
     */
    @TestVisible
    public static List<Rollup__mdt> cachedRollups {
        get {
            if (cachedRollups == null) {
                cachedRollups = [
                    SELECT 
                        Id, 
                        DeveloperName, 
                        MasterLabel, 
                        Active__c, 
                        Use_Fiscal_Year__c, 
                        Description__c, 
                        Operation__c, 
                        Time_Bound_Operation_Type__c, 
                        Integer__c,
                        Is_Deleted__c, 
                        Filter_Group__c, 
                        Filter_Group__r.MasterLabel, 
                        Filter_Group__r.DeveloperName, 
                        Summary_Object__r.QualifiedApiName, 
                        Summary_Object__r.Label, 
                        Summary_Field__r.QualifiedApiName, 
                        Summary_Field__r.Label, 
                        Detail_Object__r.QualifiedApiName, 
                        Detail_Object__r.Label, 
                        Detail_Field__r.QualifiedApiName, 
                        Detail_Field__r.Label, 
                        Amount_Object__r.QualifiedApiName, 
                        Amount_Object__r.Label, 
                        Amount_Field__r.QualifiedApiName, 
                        Amount_Field__r.Label, 
                        Date_Object__r.QualifiedApiName, 
                        Date_Object__r.Label, 
                        Date_Field__r.QualifiedApiName, 
                        Date_Field__r.Label
                    FROM Rollup__mdt
                    WHERE Is_Deleted__c = false
                    ORDER BY Summary_Object__c, MasterLabel
                ];

            }
            return cachedRollups;
        }
        private set;
    }

    /**
     * @description Return a simple list of all Rollup definition CMT records
     */
    public static List<Rollup__mdt> getRollupDefinitions() {
        return cachedRollups;
    }

    /**
     * @description Return a map of Rollup Definitions with a key of the Summary object 
     * and a list of all rollups for each Summary object
     */
    private static Map<Schema.SObjectType, List<Rollup__mdt>> rollupsBySummaryType;
    public static Map<Schema.SObjectType, List<Rollup__mdt>> getRollupsBySummaryType() {
        if (rollupsBySummaryType == null) {
            rollupsBySummaryType = new Map<Schema.SObjectType, List<Rollup__mdt>>();
            for (Rollup__mdt rollup : cachedRollups) {
                Schema.SObjectType objType = UTIL_Describe.getObjectDescribe(rollup.Summary_Object__r.QualifiedApiName).getSObjectType();
                if (!rollupsBySummaryType.containsKey(objType)) {
                    rollupsBySummaryType.put(objType, new List<Rollup__mdt>());
                }
                rollupsBySummaryType.get(objType).add(rollup);
            }
        }
        return rollupsBySummaryType;
    }

    /**
     * @description Return a map of Rollup Definitions with a key of the Detail object and a list of
     * all rollups for each Detail object
     */
    private static Map<Schema.SObjectType, List<Rollup__mdt>> rollupsByDetailType;
    public static Map<Schema.SObjectType, List<Rollup__mdt>> getRollupsByDetailType() {
        if (rollupsByDetailType == null) {
            rollupsByDetailType = new Map<Schema.SObjectType, List<Rollup__mdt>>();
            for (Rollup__mdt rollup : cachedRollups) {
                Schema.SObjectType objType = UTIL_Describe.getObjectDescribe(rollup.Detail_Object__r.QualifiedApiName).getSObjectType();
                if (!rollupsByDetailType.containsKey(objType)) {
                    rollupsByDetailType.put(objType, new List<Rollup__mdt>());
                }
                rollupsByDetailType.get(objType).add(rollup);
            }
        }
        return rollupsByDetailType;
    }

    /**
     * @description Return a map of Rollup Definitions with a key of the FilterGroup Id and a list of
     * all rollups for each FilterGroup
     */
    private static Map<Id, List<Rollup__mdt>> rollupsByFilterGroup;
    public static Map<Id, List<Rollup__mdt>> getRollupsByFilterGroup() {
        if (rollupsByFilterGroup == null) {
            rollupsByFilterGroup = new Map<Id, List<Rollup__mdt>>();
            for (Rollup__mdt rollup : cachedRollups) {
                if (!rollupsByFilterGroup.containsKey(rollup.Filter_Group__c)) {
                    rollupsByFilterGroup.put(rollup.Filter_Group__c, new List<Rollup__mdt>());
                }
                rollupsByFilterGroup.get(rollup.Filter_Group__c).add(rollup);
            }
        }
        return rollupsByFilterGroup;
    }

    /**
     * @description Queries a single Rollup Definition using the specified DeveloperName
     * @return Record Id or null
     */
    public static Id getRollupIdByDeveloperName(String developerName) {

        for (Rollup__mdt rlp : cachedRollups) {
            if (developerName == rlp.DeveloperName) {
                return rlp.Id;
            }
        }
        return null;
    }

    /**
     * @description Returns a Map of Rollup records by Rollup Id
     * @return requested rollup__mdt
     */
    public static Map<Id, Rollup__mdt> getRollupsById() {

        Map<Id, Rollup__mdt> rollupsById = new Map<Id, Rollup__mdt>();
        for (Rollup__mdt rollup : cachedRollups) {
            rollupsById.put(rollup.Id, rollup);
        }
        return rollupsById;

    }

    /**
     * @description Queries a single Rollup Definition based on the requested Id
     * @return requested rollup__mdt
     */
    public static Rollup__mdt getRollupById(Id id) {
        return getRollupsById().get(id);
    }

    /**
     * @description Returns metadata's SObject for relationshipName's QualifiedApiName with null checking.
     * @param  metadata Metadata SObject with Metadata Relationship
     * @param  metadataRelationship Metadata Relationship of metadata's SObject
     * @return Tries to return metadata's SObject for metadataRelationship's QualifiedApiName.  Else, returns null
     */
    public static String getQualifiedApiName(SObject metadata, SObjectField metadataRelationship) {
        try {
            return (String) metadata.getSObject(metadataRelationship).get('QualifiedApiName');
        }
        catch (Exception e) {
            return null;
        }
    }

    /**
     * @description 
     */
    public with sharing class RollupField {
        final SObjectField sObjectField, fieldLookup;
        final Map<String, Set<String>> supportedOperationsByTimeBoundOperationType;

        /**
         * @param  sObjectLookup Metadata Relationship to an Entity Definition
         * @param  fieldLookup Metadata Relationship to an Field Definition dependent on sObjectLookup
         * @param  excludedOperationsByTimeBoundOperationType Matrix of 
         * (CRLP_Operation.TimeBoundOperationType, CRLP_Operation.RollupType) to exclude from being supported.  
         * This means that isFieldSupported(Rollup__mdt rollup) will return false for 
         * (Rollup__mdt.Time_Bound_Operation_Type__c, Rollup__mdt.Operation__c) mapping to this matrix.
         */
        @TestVisible
        private RollupField(
            SObjectField sObjectLookup, 
            SObjectField fieldLookup, 
            Map<String, Set<String>> supportedOperationsByTimeBoundOperationType
        ) {
            this.sObjectField = sObjectLookup;
            this.fieldLookup = fieldLookup;
            this.supportedOperationsByTimeBoundOperationType = supportedOperationsByTimeBoundOperationType;
        }
    
        /**
         * @return Rollup__mdt's SObject Metadata Relationship
         */
        public SObjectField getSObjectLookup() {
            return this.sObjectField;
        }

        /**
         * @return Rollup__mdt's Field Metadata Relationship
         */
        public SObjectField getFieldLookup() {
            return this.fieldLookup;
        }

        /**
         * @description Set of Rollup__mdt.Operation__c Picklist Values by Rollup__mdt.Time_Bound_Operation_Type__c 
         * which this RollupField supports. Private so the return value is publically immutable.
         * @return supportedOperationsByTimeBoundOperationType
         */
        @TestVisible
        private Map<String, Set<String>> getSupportedOperationsByTimeBoundOperationType() {
            return this.supportedOperationsByTimeBoundOperationType;
        }

        /**
         * @description Returns rollup's SObject Name for this RollupField
         * @param rollup 
         * @return getQualifiedApiName for rollup and SObject Relationship Name
         */
        public String getSObjectName(Rollup__mdt rollup) {
            return getQualifiedApiName(rollup, this.getSObjectLookup());
        }

        /**
         * @description  Returns rollup's Field Name for this RollupField
         * *param rollup 
         * @return       getQualifiedApiName for rollup and Field Relationship Name
         */
        public String getFieldName(Rollup__mdt rollup) {
            return getQualifiedApiName(rollup, this.getFieldLookup());
        }

        /**
         * @description Returns set of Rollup__mdt.Operation__c Picklist Values
         * this RollupField supports for timeboundOperationType.  
         * Private so the return value is publically immutable.
         * @param timeBoundOperationType Rollup__mdt.Time_Bound_Operation_Type__c Picklist Value
         * @return Supported Operations By Time Bound Operation Type for timeBoundOperationType with null checking.  
         * Never returns null.
         */
        @TestVisible
        private Set<String> getSupportedOperations(String timeBoundOperationType) {
            Set<String> operations;
            if (this.getSupportedOperationsByTimeBoundOperationType() == null) {
                operations = null;
            } else if (timeBoundOperationType == null) {
                // Treat a null timeBoundOperationType as All_Time
                operations = this.getSupportedOperationsByTimeBoundOperationType().get(CRLP_Operation.TimeBoundOperationType.All_Time.name());
            } else {
                operations = this.getSupportedOperationsByTimeBoundOperationType().get(timeBoundOperationType);
            }

            return operations == null ? new Set<String>() : operations;
        }

        /**
         * @description Returns if this RollupField is supported for rollup's Operation__c 
         * and Time_Bound_Operation_Type__c
         * *param rollup 
         * @return If this RollupField is supported for rollup's Operation__c and Time_Bound_Operation_Type__c
         */
        public Boolean isRollupSupported(Rollup__mdt rollup) {
            return 
                rollup != null 
                && this.getSupportedOperations(rollup.Time_Bound_Operation_Type__c).contains(rollup.Operation__c);
        }

        /**
         * @description Returns if this RollupField for rollup may be used in query builder
         * @param  rollup 
         * @param  sObjectName Name of SObject to equal SObject Name for rollup
         * @return If Field Name for rollup is not null, SObject Name for rollup equals sObjectName, and isRollupSupported for rollup all are true.
         */
        public Boolean isFieldUsed(Rollup__mdt rollup, String sObjectName) {
            return 
                sObjectName != null
                && this.getSObjectName(rollup) == sObjectName
                && this.getFieldName(rollup) != null
                && this.isRollupSupported(rollup);
        }
    }

    @TestVisible
    private static RollupField dateRollupField, amountRollupField, detailRollupField;

    /**
     * @description See "CRLP Operations Matrix" for matrix of included and excluded 
     * (Rollup__mdt.Time_Bound_Operation_Type__c, Rollup__mdt.Operation__c) values 
     * for each Rollup Field at https://salesforce.quip.com/YnKAApuvLgNj
     * @return Cached RollupField for (Date_Object__c, Date_Field__c)
     */
    public static RollupField getDateRollupField() {
        if (dateRollupField == null) {
            Set<String> allOperations = new Set<String>();
            for (CRLP_Operation.RollupType rollupType : CRLP_Operation.RollupType.values()) {
                allOperations.add(rollupType.name());
            }

            dateRollupField = new RollupField(
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
        }
        return dateRollupField;
    }

    /**
     * @description See "CRLP Operations Matrix" for matrix of included 
     * and excluded (Rollup__mdt.Time_Bound_Operation_Type__c, Rollup__mdt.Operation__c) values 
     * for each Rollup Field at https://salesforce.quip.com/YnKAApuvLgNj
     * @return Cached RollupField for (Amount_Object__c, Amount_Field__c)
     */
    public static RollupField getAmountRollupField() {
        if (amountRollupField == null) {
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

            Map<String, Set<String>> supportedOperationsByTimeBoundOperationType = new Map<String, Set<String>>();
            // Same operations for all Time Bound Operation Types
            for (CRLP_Operation.TimeBoundOperationType timeBoundOperationType : CRLP_Operation.TimeBoundOperationType.values()) {
                supportedOperationsByTimeBoundOperationType.put(timeBoundOperationType.name(), operations);
            }

            amountRollupField = new RollupField(
                Schema.Rollup__mdt.Amount_Object__c, 
                Schema.Rollup__mdt.Amount_Field__c, 
                supportedOperationsByTimeBoundOperationType
            );
        }
        return amountRollupField;
    }

    /**
     * @description See "CRLP Operations Matrix" for matrix of included 
     * and excluded (Rollup__mdt.Time_Bound_Operation_Type__c, Rollup__mdt.Operation__c) values 
     * for each Rollup Field at https://salesforce.quip.com/YnKAApuvLgNj
     * @return Cached RollupField for (Detail_Object__c, Detail_Field__c)
     */
    public static RollupField getDetailRollupField() {
        if (detailRollupField == null) {
            final Set<String> operations = new Set<String> {
                CRLP_Operation.RollupType.Smallest.name(), 
                CRLP_Operation.RollupType.Largest.name(), 
                CRLP_Operation.RollupType.First.name(), 
                CRLP_Operation.RollupType.Last.name()
            };

            Map<String, Set<String>> supportedOperationsByTimeBoundOperationType = new Map<String, Set<String>>();

            // Same operations for all Time Bound Operation Types
            for (CRLP_Operation.TimeBoundOperationType timeBoundOperationType : CRLP_Operation.TimeBoundOperationType.values()) {
                supportedOperationsByTimeBoundOperationType.put(timeBoundOperationType.name(), operations);
            }

            detailRollupField = new RollupField(
                Schema.Rollup__mdt.Detail_Object__c, 
                Schema.Rollup__mdt.Detail_Field__c, 
                supportedOperationsByTimeBoundOperationType
            );
        }
        return detailRollupField;
    }

    /**
     * @description See "CRLP Operations Matrix" for matrix of included 
     * and excluded (Rollup__mdt.Time_Bound_Operation_Type__c, Rollup__mdt.Operation__c) values 
     * for each Rollup Field at https://salesforce.quip.com/YnKAApuvLgNj
     * @return new List<RollupField> containing getDateRollupField(), getAmountRollupField(), and getDetailRollupField()
     */
    public static List<RollupField> getRollupFields() {
        return new List<RollupField> {
            getDateRollupField(), 
            getAmountRollupField(), 
            getDetailRollupField()
        };
    }

    /**
     * @description Creates a list of all fields for a given object that are referenced in any way on an
     *  existing Rollup. This list can be used when building a query of the needed fields to retrieve
     *  for an object.
     * @param objType The type of object to retrieve referenced fields for
     * @return List<DescribeFieldResult>
     */
    public static List<Schema.DescribeFieldResult> getReferencedFieldsByObject(SObjectType objType) {
        // Collect SObjectFields in set in case there are duplicates
        final Set<SObjectField> fields = new Set<SObjectField>();

        // Always add the AccountId and Primary_Contact__c for the Opportunity object
        if (objType == Schema.Opportunity.SObjectType) {
            fields.add(Schema.Opportunity.AccountId);
            fields.add(Schema.Opportunity.Primary_Contact__c);
        }

        if (objType != null) {
            final DescribeSObjectResult sObjectDescribe = UTIL_Describe.getObjectDescribe(objType);
            final String sObjectName = sObjectDescribe.getName();
            
            // Note: DescribeSObjectResult.fields.getMap() is a case-insensitive map
            final Map<String, SObjectField> fieldsByName = sObjectDescribe.fields.getMap();

            // Always include the CurrencyIsoCode field if available for the object
            if (
                UserInfo.isMultiCurrencyOrganization() 
                && fieldsByName.get('CurrencyIsoCode') != null
            ) {
                fields.add(fieldsByName.get('CurrencyIsoCode'));
            }
    
            // Summary Field and Rollup Field from cachedRollups
            {   
                final RollupField[] rollupFields = getRollupFields();

                for (Rollup__mdt rollup : cachedRollups) {
                    if (rollup.Active__c == true) {
                        // Summary Field
                        if (rollup.Summary_Object__r.QualifiedApiName == sObjectName) {
                            final SObjectField field = fieldsByName.get(rollup.Summary_Field__r.QualifiedApiName);
                            if (field != null) {
                                fields.add(field);
                            }
                        }

                        // Rollup Fields
                        for (RollupField rollupField : rollupFields) {
                            if (rollupField.isFieldUsed(rollup, sObjectName)) {
                                final SObjectField field = fieldsByName.get(rollupField.getFieldName(rollup));
                                if (field != null) {
                                    fields.add(field);
                                }
                            }
                        }
                    }
                }
            }   
        }

        final List<Schema.DescribeFieldResult> referencedFields = new List<Schema.DescribeFieldResult>();
        // Add fields' Describes to referencedFields
        for (SObjectField field : fields) {
            referencedFields.add(field.getDescribe());
        }

        return referencedFields;
    }

    /**
     * @description If the field describe for a given field is null, assert a false to allow for debugging
     * @param referencedFields Map<String, DescribeFieldResult>
     * @param objName Object Name
     */
    public static void validateReferencedFields(Map<String, Schema.DescribeFieldResult> referencedFields, String objName) {
        for (String field : referencedFields.keySet()) {
            if (referencedFields.get(field) == null) {
                throw new CRLP_Rollup_SVC.CRLP_Exception('Field ' + field + ' not found in allFields collection for ' + objName);
            }
        }
    }

    /**
     * @description Returns a simple comma separated string list of field names to add to a SOQL Query
     * @param objType The type of object to retrieve referenced fields for
     * @return String list of fields to append to a SOQL query
     */
    public static String getReferencedFieldsByObjectAsString(SObjectType objType) {
        List<String> names = new List<String>();
        for (DescribeFieldResult describe : getReferencedFieldsByObject(objType)) {
            names.add(describe.getName());
        }
        return String.join(names, ',');
    }

    /** @description Static cache of filtered rollups by RollupType and Applied Filter */
    private static Map<String, List<Rollup__mdt>> cachedRollupsByTypeAndFilter = new Map<String, List<Rollup__mdt>>();

    /**
     * @description Used to populate the cache with the saved value from the Batch stateful property.
     * @param rollupType Enum of the job type (AccountHardCredit, ContactHardCredit, etc.)
     * @param typeFilter Enum of the rollup filter to apply (All, DaysAgoOnly, NonDaysAgoOnly, etc.)
     * @param rollups List of Rollup__mdt records to store
     */
    public static void stuffRollupsByTypeCache(
        CRLP_RollupProcessingOptions.RollupType rollupType,
        CRLP_RollupProcessingOptions.RollupTypeFilter typeFilter, 
        List<Rollup__mdt> rollups
    ) {
        cachedRollupsByTypeAndFilter.put(rollupType.name() + typeFilter.name(), rollups);
    }

    /**
     * @description Return a list of Rollup__mdt records based on the Rollup Job Type (Account Hard Credit, etc.)
     * and the Rollup Type Filter (if there is one defined). This is called by each of the Rollup Job Handler
     * classes as well as the initial batch class.
     * @param rollupType Enum of the job type (AccountHardCredit, ContactHardCredit, etc.)
     * @param typeFilter Enum of the rollup filter to apply (All, DaysAgoOnly, NonDaysAgoOnly, etc.)
     * @return List<Rollup__mdt>
     */
    public static List<Rollup__mdt> getRollupDefinitionsToUse(
        CRLP_RollupProcessingOptions.RollupType rollupType,
        CRLP_RollupProcessingOptions.RollupTypeFilter typeFilter
    ) {
        // If the list exists in the cache, just return it
        if (
            cachedRollupsByTypeAndFilter != null 
            && cachedRollupsByTypeAndFilter.containsKey(rollupType.name() + typeFilter.name())
        ) {
            return cachedRollupsByTypeAndFilter.get(rollupType.name() + typeFilter.name());
        }

        List<Rollup__mdt> filteredRollups = new List<Rollup__mdt>();

        String oppObjectName = UTIL_Describe.getObjectDescribe('Opportunity').getName();
        String pmtObjectName = UTIL_Describe.getObjectDescribe('npe01__OppPayment__c').getName();
        String pscObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c')).getName();
        String accSCObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('Account_Soft_Credit__c')).getName();

        // Determine the correct base summary object based on the Rollup Type
        SObjectType summaryObjectType;
        if (
            rollupType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit 
            || rollupType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit 
            || rollupType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit
        ) {
            summaryObjectType = Account.SObjectType;
        }  else if (
            rollupType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit 
            || rollupType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit
        ) {
            summaryObjectType = Contact.SObjectType;
        }  else if (rollupType == CRLP_RollupProcessingOptions.RollupType.GAU) {
            summaryObjectType = General_Accounting_Unit__c.SObjectType;
        }  else if (rollupType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
            summaryObjectType = npe03__Recurring_Donation__c.SObjectType;
        }

        // Retrieve all the Rollup Definitions for the summary object
        List<Rollup__mdt> rollups = CRLP_Rollup_SEL.getRollupsBySummaryType().get(summaryObjectType);
        if (rollups != null) {
            // Loop through each Rollup__mdt and determine whether the record should be included based on the
            // Rollup Type Job AND the Type Filter if there is one.
            for (Rollup__mdt rollup : rollups) {
                Boolean includeRollupDefinition=false;
                if (
                    rollup.Is_Deleted__c == true 
                    || rollup.Active__c == false
                ) {
                    // ignore deleted or inactive rollups
                } else if (
                    rollupType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit 
                    || rollupType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit
                ) {
                    includeRollupDefinition = (
                        (
                            rollup.Detail_Object__r.QualifiedApiName == oppObjectName 
                            || rollup.Detail_Object__r.QualifiedApiName == pmtObjectName
                        )
                        && rollup.Amount_Object__r.QualifiedApiName != pscObjectName 
                        && rollup.Amount_Object__r.QualifiedApiName != accSCObjectName
                    );
                } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                    includeRollupDefinition = (
                        (
                            rollup.Detail_Object__r.QualifiedApiName == oppObjectName 
                            || rollup.Detail_Object__r.QualifiedApiName == accSCObjectName
                        )
                        && rollup.Amount_Object__r.QualifiedApiName == accSCObjectName
                    );
                }  else if (
                    rollupType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit 
                    || rollupType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit
                ) {
                    includeRollupDefinition = (rollup.Amount_Object__r.QualifiedApiName == pscObjectName);
                } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.GAU) {
                    includeRollupDefinition = true;
                } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
                    includeRollupDefinition = true;
                }
                
                if (includeRollupDefinition) {
                    if (
                        typeFilter == CRLP_RollupProcessingOptions.RollupTypeFilter.NonDaysAgo 
                        && rollup.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.DAYS_BACK.name()
                    ) {
                        includeRollupDefinition = false;
                    } else if (
                        typeFilter == CRLP_RollupProcessingOptions.RollupTypeFilter.DaysAgoOnly 
                        && rollup.Time_Bound_Operation_Type__c != CRLP_Operation.TimeBoundOperationType.DAYS_BACK.name()
                    ) {
                        includeRollupDefinition = false;
                    } else if (
                        typeFilter == CRLP_RollupProcessingOptions.RollupTypeFilter.MembershipsOnly 
                        && !rollup.Summary_Field__r.QualifiedApiName.containsIgnoreCase('Membership')
                    ) {
                        includeRollupDefinition = false;
                    }
                }

                if (includeRollupDefinition) {
                    filteredRollups.add(rollup);
                }
            }
        }

        // Save the list in the cache
        cachedRollupsByTypeAndFilter.put(rollupType.name() + typeFilter.name(), filteredRollups);
        return filteredRollups;
    }
}