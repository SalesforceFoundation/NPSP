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
     * @description Return a map of Rollup Definitions with a key of the Summary object and a list of
     * all rollups for each Summary object
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

    /**
     * getRollupById description
     * @param  id id description
     * @return    return description
     */
    public static Rollup__mdt getRollupById(Id id) {

        return getRollupsById().get(id);

    }

    /**
     * @description             Returns rollup's SObject for relationshipName's QualifiedApiName with null checking.
     * @param  rollup           Metadata
     * @param  relationshipName Metadata Relationship Field's Relationship Name used to call rollup.getSObject(...)
     * @return                  rollup's SObject for relationshipName's QualifiedApiName.  Returns null if rollup or rollup's SObject for relationshipName is null.
     */

    /**
     * getQualifiedApiName description
     * @return   return description
     */
    public static String getQualifiedApiName(
        Rollup__mdt rollup, 
        SObjectField lookup
    ) {
        try {
            return (String) rollup.getSObject(lookup).get('QualifiedApiName');
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

        @TestVisible
        private RollupField(
            SObjectField sObjectLookup, 
            SObjectField fieldLookup, 
            Map<CRLP_Operation.TimeBoundOperationType, Set<CRLP_Operation.RollupType>> excludedOperationsByTimeBoundOperationType
        ) {
            this.sObjectField = sObjectLookup;
            this.fieldLookup = fieldLookup;
            
            // Generate supportedOperationsByTimeBoundOperationType by adding all CRLP_Operation.TimeBoundOperationType and CRLP_Operation.RollupType to supportedOperationsByTimeBoundOperationType unless the values are included in excludedOperationsByTimeBoundOperationType
            {
                this.supportedOperationsByTimeBoundOperationType = new Map<String, Set<String>>();

                final List<CRLP_Operation.RollupType> rollupTypes = CRLP_Operation.RollupType.values();

                for (CRLP_Operation.TimeBoundOperationType timeBoundOperationType : CRLP_Operation.TimeBoundOperationType.values()) {      
                    final Set<String> supportedOperations = new Set<String>();
                    {
                        this.supportedOperationsByTimeBoundOperationType.put(timeBoundOperationType.name(), supportedOperations);
                    }

                    for (CRLP_Operation.RollupType operation : rollupTypes) {
                        if (
                            excludedOperationsByTimeBoundOperationType.get(timeBoundOperationType) == null
                            || !excludedOperationsByTimeBoundOperationType.get(timeBoundOperationType).contains(operation)
                        ) {
                            supportedOperations.add(operation.name());
                        }
                    }
                }
            }
        }
    
        /**
         * @description 
         * @return      Rollup__mdt's Object Lookup
         */
        public SObjectField getSObjectLookup() {
            return this.sObjectField;
        }

        /**
         * @description  Returns rollup's SObject Name for this RollupField
         * *param rollup Metadata
         * @return       getQualifiedApiName for rollup and SObject Relationship Name
         */
        public String getSObjectName(Rollup__mdt rollup) {
            return getQualifiedApiName(rollup, this.getSObjectLookup());
        }

        /**
         * @description 
         * @return      Rollup__mdt's Field Lookup
         */
        public SObjectField getFieldLookup() {
            return this.fieldLookup;
        }

        /**
         * @description  Returns rollup's Field Name for this RollupField
         * *param rollup Metadata
         * @return       getQualifiedApiName for rollup and Field Relationship Name
         */
        public String getFieldName(Rollup__mdt rollup) {
            return getQualifiedApiName(rollup, this.getFieldLookup());
        }

        /**
         * @description Set of Rollup__mdt.Operation__c Picklist Values by Rollup__mdt.Time_Bound_Operation_Type__c which this RollupField supports. Private so the return value is publically immutable.
         * @return      opps
         */
        @TestVisible
        private Map<String, Set<String>> getSupportedOperationsByTimeBoundOperationType() {
            return this.supportedOperationsByTimeBoundOperationType;
        }

        /**
         * @description                  Returns set of Rollup__mdt.Operation__c Picklist Values this RollupField supports for timeboundOperationType.  Private so the return value is publically immutable.
         * @param timeBoundOperationType Rollup__mdt.Time_Bound_Operation_Type__c Picklist Value
         * @return                       Supported Operations By Time Bound Operation Type for timeBoundOperationType with null checking.  Never returns null.
         */
        @TestVisible
        private Set<String> getSupportedOperations(String timeBoundOperationType) {
            Set<String> operations = this.getSupportedOperationsByTimeBoundOperationType().get(timeBoundOperationType);
            return operations == null ? new Set<String>() : operations;
        }

        /**
         * @description  Returns if this RollupField is supported for rollup's Operation__c and Time_Bound_Operation_Type__c
         * *param rollup Metadata
         * @return       If this RollupField is supported for rollup's Operation__c and Time_Bound_Operation_Type__c
         */

        /**
         * @description 
         * @param  rollup rollup description
         * @return        return description
         */
        public Boolean isRollupSupported(Rollup__mdt rollup) {
            return rollup != null 
                && this.getSupportedOperations(rollup.Time_Bound_Operation_Type__c).contains(rollup.Operation__c);
        }

        /**
         * @description        Returns if this RollupField for rollup may be used in query builder
         * @param  rollup      Metadata
         * @param  sObjectName Name of SObject to equal SObject Name for rollup
         * @return             If Field Name for rollup is not null, SObject Name for rollup equals sObjectName, and isRollupSupported for rollup is true.
         */
        public Boolean isFieldUsed(Rollup__mdt rollup, String sObjectName) {
            return 
                this.getFieldName(rollup) != null
                && this.getSObjectName(rollup) == sObjectName
                && this.isRollupSupported(rollup);
        }
    }

    @TestVisible
    private static RollupField dateRollupField, amountRollupField, detailRollupField;

    public static RollupField getDateRollupField() {
        if(dateRollupField == null) {
            dateRollupField = new RollupField(
                Schema.Rollup__mdt.Date_Object__c, 
                Schema.Rollup__mdt.Date_Field__c, 
                new Map<CRLP_Operation.TimeBoundOperationType, Set<CRLP_Operation.RollupType>> {
                    CRLP_Operation.TimeBoundOperationType.All_Time => new Set<CRLP_Operation.RollupType> {
                        CRLP_Operation.RollupType.Sum, 
                        CRLP_Operation.RollupType.Count, 
                        CRLP_Operation.RollupType.Average, 
                        CRLP_Operation.RollupType.Smallest, 
                        CRLP_Operation.RollupType.Largest
                    }, 
                    CRLP_Operation.TimeBoundOperationType.Days_Back => new Set<CRLP_Operation.RollupType> {
                    }, 
                    CRLP_Operation.TimeBoundOperationType.Years_Ago => new Set<CRLP_Operation.RollupType> {
                    }
                }
            );
        }
        return dateRollupField;
    }

    public static RollupField getAmountRollupField() {
        if(amountRollupField == null) {
            final Map<CRLP_Operation.TimeBoundOperationType, Set<CRLP_Operation.RollupType>> excludedOperationsByTimeBoundOperationType = new Map<CRLP_Operation.TimeBoundOperationType,  Set<CRLP_Operation.RollupType>>();
            {
                // The same Operation__c values are excluded for all Time_Bound_Operation_Type__c values
                final Set<CRLP_Operation.RollupType> excludedOperations = new Set<CRLP_Operation.RollupType> {
                    CRLP_Operation.RollupType.Count, 
                    CRLP_Operation.RollupType.First, 
                    CRLP_Operation.RollupType.Last
                };
        
                for(CRLP_Operation.TimeBoundOperationType timeBoundOperationType : CRLP_Operation.TimeBoundOperationType.values()) {
                    excludedOperationsByTimeBoundOperationType.put(timeBoundOperationType, excludedOperations);
                }
            }

            amountRollupField = new RollupField(
                Schema.Rollup__mdt.Amount_Object__c, 
                Schema.Rollup__mdt.Amount_Field__c, 
                excludedOperationsByTimeBoundOperationType
            );
        }
        return amountRollupField;
    }

    public static RollupField getDetailRollupField() {
        if(detailRollupField == null) {
            final Map<CRLP_Operation.TimeBoundOperationType, Set<CRLP_Operation.RollupType>> excludedOperationsByTimeBoundOperationType = new Map<CRLP_Operation.TimeBoundOperationType, Set<CRLP_Operation.RollupType>>();
            {
                // The same Operation__c values are excluded for all Time_Bound_Operation_Type__c values
                final Set<CRLP_Operation.RollupType> excludedOperations = new Set<CRLP_Operation.RollupType> {
                    CRLP_Operation.RollupType.Sum, 
                    CRLP_Operation.RollupType.Count, 
                    CRLP_Operation.RollupType.Average, 
                    CRLP_Operation.RollupType.Years_Donated, 
                    CRLP_Operation.RollupType.Donor_Streak, 
                    CRLP_Operation.RollupType.Best_Year, 
                    CRLP_Operation.RollupType.Best_Year_Total
                };
            
                for(CRLP_Operation.TimeBoundOperationType timeBoundOperationType : CRLP_Operation.TimeBoundOperationType.values()) {
                    excludedOperationsByTimeBoundOperationType.put(timeBoundOperationType, excludedOperations);
                }
            }

            detailRollupField = new RollupField(
                Schema.Rollup__mdt.Detail_Object__c, 
                Schema.Rollup__mdt.Detail_Field__c, 
                excludedOperationsByTimeBoundOperationType
            );
        }
        return detailRollupField;
    }

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
        String sObjectName = UTIL_Describe.getObjectDescribe(objType).getName();

        Map<String, Schema.DescribeFieldResult> allFields = UTIL_Describe.getAllFieldsDescribe(sObjectName);
        Map<String, Schema.DescribeFieldResult> referencedFields = new Map<String, Schema.DescribeFieldResult>();

        {
            final RollupField[] rollupFields = getRollupFields();

            for (Rollup__mdt rollup : cachedRollups) {
                if (rollup.Active__c == true) {
                    // Summary Field
                    if (rollup.Summary_Object__r.QualifiedApiName == sObjectName) {
                        String fieldName = rollup.Summary_Field__r.QualifiedApiName;
                        referencedFields.put(
                            fieldName, 
                            allFields.get(fieldName.toLowerCase())
                        );
                    }

                    // Rollup Fields
                    for (RollupField rollupField : rollupFields) {
                        if (rollupField.isFieldUsed(rollup, sObjectName)) {
                            final String fieldName = rollupField.getFieldName(rollup);
                            referencedFields.put(
                                fieldName, 
                                allFields.get(fieldName.toLowerCase())
                            );
                        }
                    }

                }
            }
        }

        // Always include the CurrencyIsoCode field if it's available for the object
        if (UserInfo.isMultiCurrencyOrganization() && allFields.get('currencyisocode') != null) {
            referencedFields.put('CurrencyIsoCode', allFields.get('currencyisocode'));
        }

        // Always add the AccountId and Primary_Contact__c for the Opportunity object
        if (objType == Schema.Opportunity.SObjectType) {
            for (String fieldName : new String[] {
                Schema.SObjectType.Opportunity.fields.AccountId.getName(), 
                Schema.SObjectType.Opportunity.fields.Primary_Contact__c.getName()
            }) {
                referencedFields.put(
                    fieldName, 
                    allFields.get(fieldName.toLowerCase())
                );
            }
        }

        validateReferencedFields(referencedFields, sObjectName);
        return referencedFields.values();
    }

    /**
     * @description If the field describe for a given field is null, assert a false to allow for debugging
     * @param referencedFields Map<String, DescribeFieldResult>
     * @param objName Object Name
     */
    public static void validateReferencedFields(Map<String, Schema.DescribeFieldResult> referencedFields, String objName) {
        for (String fld : referencedFields.keySet()) {
            if (referencedFields.get(fld) == null) {
                throw new CRLP_Rollup_SVC.CRLP_Exception('Field ' + fld + ' not found in allFields collection for ' + objName);
            }
        }
    }

    /**
     * @description Returns a simple comma separated string list of field names to add to a SOQL Query
     * @param objType The type of object to retrieve referenced fields for
     * @return String list of fields to append to a SOQL query
     */
    public static String getReferencedFieldsByObjectAsString(SObjectType objType) {
        String soql = '';
        for (DescribeFieldResult dfr : getReferencedFieldsByObject(objType)) {
            soql += dfr.getName() + ',';
        }
        return soql.removeEnd(',');
    }

    /** @description Static cache of filtered rollups by RollupType and Applied Filter */
    private static Map<String, List<Rollup__mdt>> cachedRollupsByTypeAndFilter = new Map<String, List<Rollup__mdt>>();

    /**
     * @description Used to populate the cache with the saved value from the Batch stateful property.
     * @param rollupType Enum of the job type (AccountHardCredit, ContactHardCredit, etc.)
     * @param typeFilter Enum of the rollup filter to apply (All, DaysAgoOnly, NonDaysAgoOnly, etc.)
     * @param rollups List of Rollup__mdt records to store
     */
    public static void stuffRollupsByTypeCache(CRLP_RollupProcessingOptions.RollupType rollupType,
            CRLP_RollupProcessingOptions.RollupTypeFilter typeFilter, List<Rollup__mdt> rollups) {
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
    public static List<Rollup__mdt> getRollupDefinitionsToUse(CRLP_RollupProcessingOptions.RollupType rollupType,
            CRLP_RollupProcessingOptions.RollupTypeFilter typeFilter) {

        // If the list exists in the cache, just return it
        if (cachedRollupsByTypeAndFilter != null && cachedRollupsByTypeAndFilter.containsKey(rollupType.name() + typeFilter.name())) {
            return cachedRollupsByTypeAndFilter.get(rollupType.name() + typeFilter.name());
        }

        List<Rollup__mdt> filteredRollups = new List<Rollup__mdt>();

        String oppObjectName = UTIL_Describe.getObjectDescribe('Opportunity').getName();
        String pmtObjectName = UTIL_Describe.getObjectDescribe('npe01__OppPayment__c').getName();
        String pscObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c')).getName();
        String accSCObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('Account_Soft_Credit__c')).getName();

        // Determine the correct base summary object based on the Rollup Type
        SObjectType summaryObjectType;
        if (rollupType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                rollupType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit ||
                rollupType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
            summaryObjectType = Account.SObjectType;
        } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit ||
                rollupType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
            summaryObjectType = Contact.SObjectType;
        } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.GAU) {
            summaryObjectType = General_Accounting_Unit__c.SObjectType;
        } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
            summaryObjectType = npe03__Recurring_Donation__c.SObjectType;
        }

        // Retrieve all the Rollup Definitions for the summary object
        List<Rollup__mdt> rlps = CRLP_Rollup_SEL.getRollupsBySummaryType().get(summaryObjectType);
        if (rlps != null) {
            // Loop through each Rollup__mdt and determine whether the record should be included based on the
            // Rollup Type Job AND the Type Filter if there is one.
            for (Rollup__mdt r : rlps) {
                Boolean includeRollupDefinition=false;
                if (r.Is_Deleted__c == true || r.Active__c == false) {
                    // ignore deleted or inactive rollups
                } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                        rollupType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
                    includeRollupDefinition = ((r.Detail_Object__r.QualifiedApiName == oppObjectName || r.Detail_Object__r.QualifiedApiName == pmtObjectName)
                            && r.Amount_Object__r.QualifiedApiName != pscObjectName && r.Amount_Object__r.QualifiedApiName != accSCObjectName);
                } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                    includeRollupDefinition = ((r.Detail_Object__r.QualifiedApiName == oppObjectName || r.Detail_Object__r.QualifiedApiName == accSCObjectName)
                            && r.Amount_Object__r.QualifiedApiName == accSCObjectName);
                } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit ||
                        rollupType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit) {
                    includeRollupDefinition = (r.Amount_Object__r.QualifiedApiName == pscObjectName);
                } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.GAU) {
                    includeRollupDefinition = true;
                } else if (rollupType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
                    includeRollupDefinition = true;
                }
                if (includeRollupDefinition) {
                    if (typeFilter == CRLP_RollupProcessingOptions.RollupTypeFilter.NonDaysAgo &&
                            r.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.DAYS_BACK.name()) {
                        includeRollupDefinition = false;
                    } else if (typeFilter == CRLP_RollupProcessingOptions.RollupTypeFilter.DaysAgoOnly &&
                            r.Time_Bound_Operation_Type__c != CRLP_Operation.TimeBoundOperationType.DAYS_BACK.name()) {
                        includeRollupDefinition = false;
                    } else if (typeFilter == CRLP_RollupProcessingOptions.RollupTypeFilter.MembershipsOnly &&
                            !r.Summary_Field__r.QualifiedApiName.containsIgnoreCase('Membership')) {
                        includeRollupDefinition = false;
                    }
                }
                if (includeRollupDefinition) {
                    filteredRollups.add(r);
                }
            }
        }

        // Save the list in the cache
        cachedRollupsByTypeAndFilter.put(rollupType.name() + typeFilter.name(), filteredRollups);
        return filteredRollups;
    }
}