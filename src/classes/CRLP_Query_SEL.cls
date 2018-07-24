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
* @description Selector class for relevant summary/target fields for use by the Rollup Engine
*/public class CRLP_Query_SEL {

    /**
     * @description For a given SObject, identify all referenced fields from the currently defined Rollups and
     * and Filter Rules and build a SOQL statement that queries all these fields (excluding fields that the current
     * User does not have permissions to access).
     * @param resultObject ObjectType being queried
     * @return SOQL query WITHOUT a where clause
     */
    public static String buildObjectQueryForRollup(SObjectType resultObject) {

        // Start by getting all the fields referenced by any Filter Group or active Rollup
        Set<Schema.DescribeFieldResult> allFieldsToQuery = new Set<DescribeFieldResult>();
        allFieldsToQuery.addAll(CMT_FilterRule_SEL.getReferencedFieldsByObject(resultObject));
        allFieldsToQuery.addAll(CRLP_Rollup_SEL.getReferencedFieldsByObject(resultObject));

        // Force Add the following fields for each of the specific objects below. These may not be directly referenced
        // in a filter or rollup, but they are needed to support related rollup processes.
        if (resultObject == Partial_Soft_Credit__c.SObjectType) {
            allFieldsToQuery.add(SObjectType.Partial_Soft_Credit__c.fields.Opportunity__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Partial_Soft_Credit__c.fields.Contact__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Partial_Soft_Credit__c.fields.Amount__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Partial_Soft_Credit__c.fields.Role_Name__c.getSobjectField().getDescribe());
        } else if (resultObject == Account_Soft_Credit__c.SObjectType) {
            allFieldsToQuery.add(SObjectType.Account_Soft_Credit__c.fields.Opportunity__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Account_Soft_Credit__c.fields.Account__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Account_Soft_Credit__c.fields.Amount__c.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Account_Soft_Credit__c.fields.Role__c.getSobjectField().getDescribe());
        } else if (resultObject == OpportunityContactRole.SObjectType) {
            allFieldsToQuery.add(SObjectType.OpportunityContactRole.fields.ContactId.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.OpportunityContactRole.fields.OpportunityId.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.OpportunityContactRole.fields.Role.getSobjectField().getDescribe());
        } else if (resultObject == Opportunity.SObjectType) {
            allFieldsToQuery.add(SObjectType.Opportunity.fields.Amount.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Opportunity.fields.CloseDate.getSobjectField().getDescribe());
            allFieldsToQuery.add(SObjectType.Opportunity.fields.npe03__Recurring_Donation__c.getSobjectField().getDescribe());
        } else if (resultObject == npe01__OppPayment__c.SObjectType) {
            allFieldsToQuery.add(SObjectType.npe01__OppPayment__c.fields.npe01__Opportunity__c.getSobjectField().getDescribe());
        }

        // Loop through the FieldDescribeResults list and add each field that is accessible to the current user
        // to the Set of strings (enforcing uniqueness)
        String contactRelField = UTIL_Namespace.StrAllNSPrefix('Contact__c');
        Set<String> queryFields = new Set<String>{'Id'};
        for (DescribeFieldResult dfr : allFieldsToQuery) {
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
            } else if (dfr.getName() == 'ContactId') {
                queryFields.add('Contact.AccountId');
            } else if (dfr.getName() == contactRelField) {
                queryFields.add(contactRelField.replace('__c', '__r') + '.AccountId');
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
    public static String buildDetailObjectQueryForRollup(SObjectType detailObject, List<SObjectType> childObjects) {
        // Get the main SOQL statement for the detail object and parse out the FROM portion
        String mainSoql = buildObjectQueryForRollup(detailObject).split(' FROM ')[0];

        if (detailObject == OpportunityContactRole.SObjectType
                || detailObject == Partial_Soft_Credit__c.SObjectType
                || detailObject == Allocation__c.SObjectType
                || detailObject == Account_Soft_Credit__c.SObjectType) {

            // ====================================================================================================
            // If the detailObject is OCR, PSC, ASC or Allocation, then rather than include a sub-query for the child objects
            // we'll include foreignkey references to the Opportunity object
            // ====================================================================================================

            String oppParentField = (detailObject == OpportunityContactRole.SObjectType
                    ? 'Opportunity' : UTIL_Namespace.StrAllNSPrefix('Opportunity__r'));

            mainSoql += appendParentQuery(Opportunity.SObjectType, oppParentField);

            if (detailObject == Allocation__c.SObjectType) {
                mainSoql += ',' + SObjectType.Allocation__c.fields.General_Accounting_Unit__c.getName();
            }

        } else if (detailObject == Opportunity.SObjectType) {
            // ====================================================================================================
            // Is the primary detail object NOT the OCR or Allocation object (must be Opportunity)
            // ====================================================================================================

            Map<SObjectType, String> opportunityChildRelationships = getOpportunityChildRelationships();

            // Get the query for each child object, change the FROM object to the relationship name, and append to the main query
            for (SObjectType obj : childObjects) {
                if (opportunityChildRelationships.containsKey(obj)) {
                    mainSoql += buildChildQuery(obj, opportunityChildRelationships.get(obj));
                }
            }

            // always include these two extra fields for Opportunity queries
            mainSoql += ', Account.npe01__SYSTEMIsIndividual__c';

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
     * @param includeChildPayments True if npe01__OppPayment__c child records should be included in the query
     * @return SOQL
     */
    public static String buildFullDetailsQueryForSummaryRecords(Set<Id> summaryRecordIds, Boolean includeChildPayments,
            CRLP_RollupProcessingOptions.ProcessingOptions options) {
        SObjectType objType = (new List<Id>(summaryRecordIds))[0].getSobjectType();
        SObjectType mainObject;
        String detailKeyField;
        List<SObjectType> childObjects = new List<SObjectType>();

        // The specific set of 'detail' records is fixed based on the target summary object.
        if (objType == Account.SObjectType) {

            if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                    options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit) {

                // Opportunity and Payment to Account
                mainObject = Opportunity.SObjectType;
                if (includeChildPayments == true) {
                    childObjects.add(npe01__OppPayment__c.SObjectType);
                }
                detailKeyField = SObjectType.Opportunity.fields.AccountId.getName();
            } else if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                // Account Soft Credit to Account
                mainObject = Account_Soft_Credit__c.SObjectType;
                detailKeyField = SObjectType.Account_Soft_Credit__c.fields.Account__c.getName();
            }

        } else if (objType == Contact.SObjectType) {
            // Opportunity and Payment to Contact
            mainObject = Opportunity.SObjectType;
            if (includeChildPayments == true) {
                childObjects.add(npe01__OppPayment__c.SObjectType);
            }
            detailKeyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
        } else if (objType == npe03__Recurring_Donation__c.SObjectType) {
            mainObject = Opportunity.SObjectType;
            detailKeyField = SObjectType.Opportunity.fields.npe03__Recurring_Donation__c.getName();
        }

        // Get the base query
        String detailsQuery = CRLP_Query_SEL.buildDetailObjectQueryForRollup(mainObject, childObjects);

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
        String childQuery = ', (' + buildObjectQueryForRollup(childObject).split(' FROM ')[0] + + ' FROM ' + relationshipName + ')';
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

        return addlQuery;
    }

    /**
     * @description For a given query against a specific detail SObject, and a set of active Rollup__mdt records that
     * will be processed for those detail records, identify a common Where clause fragment that can be used to
     * limit the records queried by the main batch job engine. For example, if all the Rollups use a Filter Group that
     * filters for IsWon=True, the main query where clause can be improved by adding "WHERE IsWon=TRUE" to the query.
     * This can be used to drastically improve performance of the batch jobs by severely limiting the number of
     * records queried and processed by the rollups engine.
     *
     * This is pretty complex, so the matching logic is limited to the following common fields only:
     * - IsWon
     * - IsClosed
     * - RecordTypeId
     *
     * And the following operations: EQUALS, NOT EQUALS, IN LIST, NOT IN LIST
     *
     * @param summaryObjectType If the main object is something other than Opportunity, this is the field
     * in the detail object needed to get the Opportunity (ex: "Opportunity__r")
     * @param detailObjectType The detail object being queried
     * @param rollups Collection of filtered Rollup__mdt records (or null)
     * @return A string to append to the main query's WHERE clause (without the "WHERE")
     */
    public static String buildCommonQueryFilterOnOpportunity(SObjectType summaryObjectType, SObjectType detailObjectType) {
        return buildCommonQueryFilterOnOpportunity(summaryObjectType, detailObjectType, null);
    }
    public static String buildCommonQueryFilterOnOpportunity(SObjectType summaryObjectType, SObjectType detailObjectType,
                List<Rollup__mdt> rollups) {

        String pscObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c')).getName();

        // Attempt to further limit the number of records queried by building a common filter that
        // is shared across all the Filter Groups used by the Rollups that will be processed.
        if (rollups == null || rollups.isEmpty()) {
            rollups = CRLP_Rollup_SEL.getRollupsBySummaryType().get(summaryObjectType);
        }
        if (rollups == null) {
            return '';
        }

        for (Integer n=0; n<rollups.size(); n++) {
            if ((detailObjectType == Partial_Soft_Credit__c.SObjectType && rollups[n].Amount_Object__r.QualifiedApiName != pscObjectName) ||
                    (detailObjectType != Partial_Soft_Credit__c.SObjectType && rollups[n].Amount_Object__r.QualifiedApiName == pscObjectName)) {
                rollups.remove(n);
                n--;
            }
        }

        // Get a list of the applied FilterGroupId's
        Boolean hasRollupWithNoFilter = false;
        Set<Id> filterGroupIds = new Set<Id>();
        for (Rollup__mdt r : rollups) {
            if (r.Filter_Group__c == null) {
                hasRollupWithNoFilter = true;
                break;
            }
            filterGroupIds.add(r.Filter_Group__c);
        }

        // If there are no rollups, no filter groups, or at least one rollup that is not using a filter group
        // just exit out because there is no common filter that can be built for this set.
        if (hasRollupWithNoFilter || filterGroupIds.size() == 0) {
            return '';
        }

        // Determine the parent Opportunity foreign key relationship field.
        String parentRelationshipPrefix;
        if (detailObjectType == Allocation__c.SObjectType) {
            parentRelationshipPrefix = SObjectType.Allocation__c.fields.Opportunity__c.getName().replace('__c', '__r');
        } else if (detailObjectType == Partial_Soft_Credit__c.SObjectType) {
            parentRelationshipPrefix = 'Opportunity';
        } else if (detailObjectType == Account_Soft_Credit__c.SObjectType) {
            parentRelationshipPrefix = SObjectType.Account_Soft_Credit__c.fields.Opportunity__c.getName().replace('__c', '__r');
        }

        // The following loop will confirm that all Filter Groups use the same Rule for the same field
        // If the Rule is used across all Filter Groups, the Integer value in the Map will match the
        // total number of rules
        Map<String, Integer> countOfRuleUsage = new Map<String, Integer>{
                'IsWon' => 0, 'IsClosed' => 0, 'RecordTypeId' => 0 };
        Map<String,String> targetFieldAndOperator = new Map<String, String>();
        Map<String,String> targetFieldAndConstant = new Map<String, String>();
        for (Id fg : filterGroupIds) {

            for (Filter_Rule__mdt rule : CMT_FilterRule_SEL.getFilterRulesByGroup().get(fg)) {
                String fieldName = rule.Field__r.QualifiedApiName;
                if (countOfRuleUsage.containsKey(fieldName)) {
                    countOfRuleUsage.put(fieldName, countOfRuleUsage.get(fieldName)+1);
                    // Next compare the Constant value for each of the rules. If the value is the same across
                    // each of the Rules for this field, the value will is stored in the targetFieldAndConstant map.
                    // If the value doesn't match though, the countOfRuleUsage map value is decremented to indicate
                    // that the Rule for the field isn't used consistently across all Filter Groups
                    if (!targetFieldAndConstant.containsKey(fieldName)) {
                        targetFieldAndConstant.put(fieldName, rule.Constant__c);
                        targetFieldAndOperator.put(fieldName, rule.Operator__c);
                    } else if (targetFieldAndConstant.get(fieldName) != rule.Constant__c ||
                            targetFieldAndOperator.get(fieldName) != rule.Operator__c) {
                        countOfRuleUsage.put(fieldName, countOfRuleUsage.get(fieldName)-1);
                    }
                }
            }
        }

        List<String> whereClauses = new List<String>();
        for (String fieldName : countOfRuleUsage.keySet()) {
            if (countOfRuleUsage.get(fieldName) == filterGroupIds.size()) {
                String whereClause = fieldName;
                // If the field is RecordTypeId, switch it to RecordType.DeveloperName to match the
                // constant values used which are DeveloperName values.
                if (fieldName == 'RecordTypeId') {
                    whereClause = 'RecordType.DeveloperName';
                }
                whereClause = (!String.isEmpty(parentRelationshipPrefix) ? parentRelationshipPrefix + '.' : '') + whereClause;

                if (targetFieldAndOperator.get(fieldName) == CMT_FilterRule.FilterOperation.EQUALS.name()) {
                    if (fieldName.startsWith('Is')) {
                        whereClause += ' = ' + targetFieldAndConstant.get(fieldName);
                    } else {
                        whereClause += ' = \'' + targetFieldAndConstant.get(fieldName) + '\'';
                    }

                } else if (targetFieldAndOperator.get(fieldName) == CMT_FilterRule.FilterOperation.NOT_EQUALS.name()) {
                    if (fieldName.startsWith('Is')) {
                        whereClause += ' != ' + targetFieldAndConstant.get(fieldName);
                    } else {
                        whereClause += ' != \'' + targetFieldAndConstant.get(fieldName) + '\'';
                    }

                } else if (targetFieldAndOperator.get(fieldName) == CMT_FilterRule.FilterOperation.IN_LIST.name()) {
                    whereClause += ' IN (';
                    for (String v : targetFieldAndConstant.get(fieldName).split(';')) {
                        whereClause += '\'' + v + '\',';
                    }
                    whereClause =  whereClause.removeEnd(',') + ')';

                } else if (targetFieldAndOperator.get(fieldName) == CMT_FilterRule.FilterOperation.NOT_IN_LIST.name()) {
                    whereClause += ' NOT IN (';
                    for (String v : targetFieldAndConstant.get(fieldName).split(';')) {
                        whereClause += '\'' + v + '\',';
                    }
                    whereClause =  whereClause.removeEnd(',') + ')';

                } else {
                    whereClause = null;
                }

                if (whereClause != null) {
                    whereClauses.add(whereClause);
                }
            }
        }

        return String.join(whereClauses, ' AND ');
    }

    /*******************************************************************************************************
    * @description Gets the Child Relationships on Opportunity, used by Rollups logic.
    * @return Map<SObjectType, String>.
    ********************************************************************************************************/
    private static Map<SObjectType, String> getOpportunityChildRelationships() {

        return new Map<SObjectType, String>{
            Partial_Soft_Credit__c.SObjectType => UTIL_Namespace.StrTokenNSPrefix('Partial_Soft_Credits__r'),
            Allocation__c.SObjectType => UTIL_Namespace.StrTokenNSPrefix('Allocations__r'),
            OpportunityContactRole.SObjectType => 'OpportunityContactRoles',
            npe01__OppPayment__c.SObjectType => 'npe01__OppPayment__r'
        };
    }
}