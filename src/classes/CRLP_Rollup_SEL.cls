/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
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
                        SELECT Id, DeveloperName, MasterLabel, Active__c, Use_Fiscal_Year__c,
                                Description__c, Filter_Group__c, Filter_Group__r.MasterLabel, Operation__c, Integer__c,
                                Amount_Field__r.QualifiedApiName, Amount_Object__r.QualifiedApiName,
                                Use_OCR_for_Attribution_Object__c, Yearly_Operation_Type__c,
                                Date_Field__r.QualifiedApiName, Date_Object__r.QualifiedApiName,
                                Detail_Field__r.QualifiedApiName, Detail_Object__r.QualifiedApiName,
                                Summary_Field__r.QualifiedApiName, Summary_Object__r.QualifiedApiName
                        FROM Rollup__mdt
                        ORDER BY Summary_Object__c];
            }
            return cachedRollups;
        } private set;
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
    public static Map<Schema.SObjectType, List<Rollup__mdt>> getRollupsBySummaryType() {
        Map<Schema.SObjectType, List<Rollup__mdt>> rollupsBySummaryType = new Map<Schema.SObjectType, List<Rollup__mdt>>();
        for (Rollup__mdt rollup : cachedRollups) {
            Schema.SObjectType objType = UTIL_Describe.getObjectDescribe(rollup.Summary_Object__r.QualifiedApiName).getSObjectType();
            if (!rollupsBySummaryType.containsKey(objType)) {
                rollupsBySummaryType.put(objType, new List<Rollup__mdt>());
            }
            rollupsBySummaryType.get(objType).add(rollup);
        }
        return rollupsBySummaryType;
    }

    /**
     * @description Return a map of Rollup Definitions with a key of the Detail object and a list of
     * all rollups for each Detail object
     */
    public static Map<Schema.SObjectType, List<Rollup__mdt>> getRollupsByDetailType() {
        Map<Schema.SObjectType, List<Rollup__mdt>> rollupsByDetailType = new Map<Schema.SObjectType, List<Rollup__mdt>>();
        for (Rollup__mdt rollup : cachedRollups) {
            Schema.SObjectType objType = UTIL_Describe.getObjectDescribe(rollup.Detail_Object__r.QualifiedApiName).getSObjectType();
            if (!rollupsByDetailType.containsKey(objType)) {
                rollupsByDetailType.put(objType, new List<Rollup__mdt>());
            }
            rollupsByDetailType.get(objType).add(rollup);
        }
        return rollupsByDetailType;
    }

    /**
     * @description Return a map of Rollup Definitions with a key of the FilterGroup Id and a list of
     * all rollups for each FilterGroup
     */
    public static Map<Id, List<Rollup__mdt>> getRollupsByFilterGroup() {
        Map<Id, List<Rollup__mdt>> rollupsByFilterGroup = new Map<Id, List<Rollup__mdt>>();
        for (Rollup__mdt rollup : cachedRollups) {
            if (!rollupsByFilterGroup.containsKey(rollup.Filter_Group__c)) {
                rollupsByFilterGroup.put(rollup.Filter_Group__c, new List<Rollup__mdt>());
            }
            rollupsByFilterGroup.get(rollup.Filter_Group__c).add(rollup);
        }
        return rollupsByFilterGroup;
    }

    /**
     * @description Creates a list of all fields for a given object that are referenced in any way on an
     *  existing Rollup. This list can be used when building a query of the needed fields to retrieve
     *  for an object.
     * @param objType The type of object to retrieve referenced fields for
     * @return List<DescribeFieldResult>
     */
    public static List<Schema.DescribeFieldResult> getReferencedFieldsByObject(SObjectType objType) {
        String objName = objType.getDescribe().getName();
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
                if (rollup.Use_OCR_for_Attribution_Object__c == true && objName == 'OpportunityContactRole') {
                    String fldName = 'Role';
                    referencedFields.put(fldName, allFields.get(fldName.toLowerCase()));
                    fldName = 'ContactId';
                    referencedFields.put(fldName, allFields.get(fldName.toLowerCase()));
                }
            }
        }
        // Always include the CurrencyIsoCode field if it's available for the object
        if (UserInfo.isMultiCurrencyOrganization() && allFields.containsKey('currencyisocode')) {
            referencedFields.put('CurrencyIsoCode', allFields.get('currencyisocode'));
        }
        validateReferencedFields(referencedFields, objName);
        return referencedFields.values();
    }

    /**
     * @description If the field describe for a given field is null, assert a false to allow for debugging
     * TODO Should this just do an Assert(false) for unit testing or should this throw an exception/log an error?
     * @param referencedFields Map<String, DescribeFieldResult>
     * @param objName Object Name
     */
    public static void validateReferencedFields(Map<String, Schema.DescribeFieldResult> referencedFields, String objName) {
        for (String fld : referencedFields.keySet()) {
            if (referencedFields.get(fld) == null) {
                system.assert(false, '>> Field ' + fld + ' not found in allFields collection for ' + objName);
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
}