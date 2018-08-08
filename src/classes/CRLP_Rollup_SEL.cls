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
                        SELECT Id, DeveloperName, MasterLabel, Active__c, Use_Fiscal_Year__c, Filter_Group__r.DeveloperName,
                                Description__c, Filter_Group__c, Filter_Group__r.MasterLabel, Operation__c, Integer__c,
                                Time_Bound_Operation_Type__c
                                , Summary_Field__r.QualifiedApiName, Summary_Field__r.Label
                                , Summary_Object__r.QualifiedApiName, Summary_Object__r.Label
                                , Detail_Field__r.QualifiedApiName, Detail_Field__r.Label
                                , Detail_Object__r.QualifiedApiName, Detail_Object__r.Label
                                , Amount_Field__r.QualifiedApiName, Amount_Field__r.Label
                                , Amount_Object__r.QualifiedApiName, Amount_Object__r.Label
                                , Date_Field__r.QualifiedApiName, Date_Field__r.Label
                                , Date_Object__r.QualifiedApiName, Date_Object__r.Label
                                , Is_Deleted__c
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
    public static Rollup__mdt getRollupById(Id id) {

        return getRollupsById().get(id);

    }

    /**
     * @description Creates a list of all fields for a given object that are referenced in any way on an
     *  existing Rollup. This list can be used when building a query of the needed fields to retrieve
     *  for an object.
     * @param objType The type of object to retrieve referenced fields for
     * @return List<DescribeFieldResult>
     */
    public static List<Schema.DescribeFieldResult> getReferencedFieldsByObject(SObjectType objType) {
        String objName = UTIL_Describe.getObjectDescribe(objType).getName();
        Map<String, Schema.DescribeFieldResult> allFields = UTIL_Describe.getAllFieldsDescribe(objName);
        Map<String, Schema.DescribeFieldResult> referencedFields = new Map<String, Schema.DescribeFieldResult>();
        for (Rollup__mdt rollup : cachedRollups) {
            if (rollup.Active__c == true) {
                if (rollup.Summary_Object__r.QualifiedApiName == objName) {
                    String fldName = rollup.Summary_Field__r.QualifiedApiName;
                    referencedFields.put(fldName, allFields.get(fldName.toLowerCase()));
                }
                if (rollup.Detail_Object__r.QualifiedApiName == objName && rollup.Detail_Field__c != null) {
                    String fldName = rollup.Detail_Field__r.QualifiedApiName;
                    referencedFields.put(fldName, allFields.get(fldName.toLowerCase()));
                }
                if (rollup.Amount_Object__r.QualifiedApiName == objName && rollup.Amount_Field__r != null) {
                    String fldName = rollup.Amount_Field__r.QualifiedApiName;
                    referencedFields.put(fldName, allFields.get(fldName.toLowerCase()));
                }
                if (rollup.Date_Object__r.QualifiedApiName == objName && rollup.Date_Field__r != null) {
                    String fldName = rollup.Date_Field__r.QualifiedApiName;
                    referencedFields.put(fldName, allFields.get(fldName.toLowerCase()));
                }
            }
        }
        // Always include the CurrencyIsoCode field if it's available for the object
        if (UserInfo.isMultiCurrencyOrganization() && allFields.containsKey('currencyisocode')) {
            referencedFields.put('CurrencyIsoCode', allFields.get('currencyisocode'));
        }
        // Always add the AccountId and PrimaryContactId for the Opportunity object
        if (objType == Opportunity.SObjectType) {
            String fldName = SObjectType.Opportunity.fields.AccountId.getName();
            referencedFields.put(fldName, allFields.get(fldName.toLowerCase()));
            fldName = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
            referencedFields.put(fldName, allFields.get(fldName.toLowerCase()));
        }

        validateReferencedFields(referencedFields, objName);
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