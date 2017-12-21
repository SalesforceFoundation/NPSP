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
* @description Selector class for relevant summary/target fields for use by the Rollup Engine
*/public class CRLP_Query_SEL {

    /**
     * @description For a given SObject, identify all referenced fields from the currently defined Rollups and
     * and Filter Rules and build a SOQL statement that queries all these fields (excluding fields that the current
     * User does not have permissions to access).
     * @param resultObject ObjectType being queried
     * @return SOQL query WITHOUT a where clause
     */
    public static String getResultsQuery(SObjectType resultObject) {

        // Start by getting all the fields referenced by any Filter Group or active Rollup
        Set<Schema.DescribeFieldResult> allFieldsToQuery = new Set<DescribeFieldResult>();
        allFieldsToQuery.addAll(CMT_FilterRule_SEL.getReferencedFieldsByObject(resultObject));
        allFieldsToQuery.addAll(CRLP_Rollup_SEL.getReferencedFieldsByObject(resultObject));

        // Force Add these 3 fields if the object is partial soft credit. These may not be directly referenced
        // in a filter or rollup, but they are needed to support the full OCR/PSC rollup to Account and Contact.
        if (resultObject == Partial_Soft_Credit__c.SObjectType) {
            allFieldsToQuery.add(SObjectType.Partial_Soft_Credit__c.fields.Opportunity__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Partial_Soft_Credit__c.fields.Contact__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Partial_Soft_Credit__c.fields.Amount__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Partial_Soft_Credit__c.fields.Role_Name__c.getSobjectField().getDescribe());
        } else if (resultObject == OpportunityContactRole.SObjectType) {
            allFieldsToQuery.add(SObjectType.OpportunityContactRole.fields.ContactId.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.OpportunityContactRole.fields.OpportunityId.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.OpportunityContactRole.fields.Role.getSobjectField().getDescribe());
        } else if (resultObject == Opportunity.SObjectType) {
            allFieldsToQuery.add(SObjectType.Opportunity.fields.Amount.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Opportunity.fields.CloseDate.getSobjectField().getDescribe());
        }

        // Loop through the FieldDescribeResults list and add each field that is accessible to the current user
        // to the Set of strings (enforcing uniqueness)
        Set<String> queryFields = new Set<String>{'Id'};
        for (DescribeFieldResult dfr : allFieldsToQuery) {
            if (dfr.isAccessible()) {
                queryFields.add(dfr.getName());
                // Special conditions - these are foreign key fields that are supported in filters for record type and user
                if (dfr.getName() == 'RecordTypeId') {
                    queryFields.add('RecordType.DeveloperName');
                } else if (dfr.getName() == 'OwnerId') {
                    queryFields.add('Owner.Alias');
                } else if (dfr.getName() == 'CreatedById') {
                    queryFields.add('CreatedBy.Alias');
                } else if (dfr.getName() == 'LastModifiedById') {
                    queryFields.add('LastModifiedBy.Alias');
                }
            }
        }
        // Convert the Set to the List to support String.Join()
        List<String> fieldsList = new List<String>(queryFields);

        // Build the final SOQL string with the full list of fields
        String soql = 'SELECT ' + String.join(fieldsList, ',') + ' FROM ' + resultObject.getDescribe().getName();

        return soql;
    }

    /**
     * @description For a given SObject and it's child objects, identify all referenced fields from the currently
     * defined Rollups and and Filter Rules and build a SOQL statement that queries all these fields, as well as
     * building child sub-queries with their referenced fields (excluding fields that the current User does not
     * have permissions to access).
     * @param detailObject ObjectType being queried
     * @param childObjects ObjectType[] child objects to be included in the sub-query
     * @return SOQL query WITHOUT a where clause
     */
    public static String getDetailsQuery(SObjectType detailObject, List<SObjectType> childObjects) {
        // Get the main SOQL statement for the detail object and parse out the FROM portion
        String mainSoql = getResultsQuery(detailObject).split(' FROM ')[0];

        if (detailObject == OpportunityContactRole.SObjectType || detailObject == Partial_Soft_Credit__c.SObjectType
                    || detailObject == Allocation__c.SObjectType) {

            // ====================================================================================================
            // If the detailObject is OCR, PSC or Allocation, then rather than include a sub-query for the child objects
            // we'll include foreignkey references to the Opportunity object
            // ====================================================================================================

            String oppParentField = (detailObject == OpportunityContactRole.SObjectType
                    ? 'Opportunity' : UTIL_Namespace.StrAllNSPrefix('Opportunity__r'));

            mainSoql += appendParentQuery(Opportunity.SObjectType, oppParentField);

            if (detailObject == Allocation__c.SObjectType) {
                mainSoql += ',' + SObjectType.Allocation__c.fields.General_Accounting_Unit__c.getName();
            }


        } else {
            // ====================================================================================================
            // Is the primary detail object NOT the OCR or Allocation object (must be Opportunity)
            // ====================================================================================================

            // Get the query for each child object, change the FROM object to the relationship name, and append to the main query
            for (SObjectType obj : childObjects) {
                // Loop through all the relationships on the detail object to find the one that matches the child object
                for (ChildRelationship cr : detailObject.getDescribe().getChildRelationships()) {
                    if (cr.childSObject == obj) {
                        mainSoql += buildChildQuery(obj, cr.getRelationshipName());
                        break;
                    }
                }
            }
        }

        // Append the main object back to the query and return it
        mainSoql += ' FROM ' + detailObject.getDescribe().getName();
        UTIL_Debug.debug('SOQL=' + mainSoql);
        return mainSoql;
    }

    /**
     * @description Build a complete SOQL query string from a set of Summary Record Ids, including the requried
     * child objects and filtered by the parent record id's
     * @param summaryRecordIds Set<Id>
     * @return SOQL
     */
    public static String getFullDetailsQueryForSummaryRecords(Set<Id> summaryRecordIds) {
        SObjectType objType = (new List<Id>(summaryRecordIds))[0].getSobjectType();
        SObjectType mainObject;
        String detailKeyField;
        List<SObjectType> childObjects = new List<SObjectType>();

        // The specific set of 'detail' records is fixed based on the target summary object.
        if (objType == Account.SObjectType) {
            // Opportunity and Payment to Account
            mainObject = Opportunity.SObjectType;
            childObjects.add(npe01__OppPayment__c.SObjectType);
            detailKeyField = SObjectType.Opportunity.fields.AccountId.getName();

        } else if (objType == Contact.SObjectType) {
            // Opportunity and Payment to Contact
            mainObject = Opportunity.SObjectType;
            childObjects.add(npe01__OppPayment__c.SObjectType);
            detailKeyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
        }

        // Get the base query
        String detailsQuery = CRLP_Query_SEL.getDetailsQuery(mainObject, childObjects);

        // Add the appropriate filtering
        detailsQuery += ' WHERE ' + detailKeyField + ' IN :summaryRecordIds';

        return detailsQuery;
    }

    /**
     * @description Returns part of a query for a child object using fields referenced by rollup/filter operations.
     * @param childObject
     * @param relationshipName
     * @return part of a SOQL string
     */
    private static String buildChildQuery(SObjectType childObject, String relationshipName) {
        String childQuery = ', (' + getResultsQuery(childObject).split(' FROM ')[0] + + ' FROM ' + relationshipName + ')';
        return childQuery;
    }

    /**
     * @description Returns part of a query referencing parent fields through dot-notation.
     * @param parentObject
     * @param parentKeyField
     * @return part of a SOQL string
     */
    private static String appendParentQuery(SObjectType parentObject, String parentKeyField) {
        String addlQuery = '';

        Set<Schema.DescribeFieldResult> allFieldsToQuery = new Set<DescribeFieldResult>();
        allFieldsToQuery.addAll(CMT_FilterRule_SEL.getReferencedFieldsByObject(parentObject));
        allFieldsToQuery.addAll(CRLP_Rollup_SEL.getReferencedFieldsByObject(parentObject));

        // Include the Opportunity.PrimaryContact field in the query
        if (parentObject == Opportunity.SObjectType) {
            allFieldsToQuery.add(SObjectType.Opportunity.fields.Id.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Opportunity.fields.Primary_Contact__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Opportunity.fields.Amount.getSobjectField().getDescribe());
        }

        for (Schema.DescribeFieldResult fld : allFieldsToQuery) {
            if (fld.isAccessible()) {
                addlQuery += ',' + parentKeyField + '.' + fld.getName();
                // Special conditions - these are foreign key fields that are supported in filters for record type and user
                if (fld.getName() == 'RecordTypeId') {
                    addlQuery += ',' + parentKeyField + '.' + 'RecordType.DeveloperName';
                } else if (fld.getName() == 'OwnerId') {
                    addlQuery += ',' + parentKeyField + '.' + 'Owner.Alias';
                } else if (fld.getName() == 'CreatedById') {
                    addlQuery += ',' + parentKeyField + '.' + 'CreatedBy.Alias';
                } else if (fld.getName() == 'LastModifiedById') {
                    addlQuery += ',' + parentKeyField + '.' + 'LastModifiedBy.Alias';
                }
            }
        }

        return addlQuery;
    }

}