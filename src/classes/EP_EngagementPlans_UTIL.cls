/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Engagement Plans
* @group-content ../../ApexDocContent/EngagementPlans.htm
* @description Utility class for the Engagement_Plan__c object, for helping to manage the multiple lookups
* to parent objects; validates that one and only one parent object lookup is populated per Engagement Plan.
*/
public with sharing class EP_EngagementPlans_UTIL {

	public static final String TASK_STATUS_WAITING = 'Waiting on Dependent Task';
	public static final String BLANK_ASSIGNMENT_USER_CREATING = 'User Creating Action Plan';
	public static final String BLANK_ASSIGNMENT_OWNER_RECEIVING = 'Owner of Receiving Object';
	public static final String SKIP_DAY_FRIDAY = 'Friday';
	public static final String SKIP_DAY_MONDAY = 'Monday';
	public static final Integer MAX_ITERATIONS = 500;

    /** @description Engagement Plan field describe map.*/
    private static Map<String, Schema.DescribeFieldResult> fieldDescribeMap = UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrTokenNSPrefix('Engagement_Plan__c'));
    /** @description A map of Engagement Plan lookup field names to the relationship name and OwnerId for all custom relationship fields,
    * used for generating a query of all related object owners. Excludes the template master-detail field. */
    private static Map<String, String> lookupFieldsToRelationship {
        get {
            if (lookupFieldsToRelationship == null) {
                lookupFieldsToRelationship = new Map<String, String>();
                for (String fieldName : fieldDescribeMap.keySet()) {
                    Schema.DescribeFieldResult fieldDescribe = fieldDescribeMap.get(fieldName);
                    if (fieldDescribe.getRelationshipName() != null && fieldDescribe.isCustom()) { 
                        if (fieldName != UTIL_Namespace.StrTokenNSPrefix('Engagement_Plan_Template__c')) {
                            lookupFieldsToRelationship.put(fieldName, fieldDescribe.getRelationshipName() + '.OwnerId');
                        }
                    }
                }
            }
            return lookupFieldsToRelationship;
        }
        private set;
    }


    /** @description For each Engagement Plan, which lookup field is populated.*/
    public Map<Id, String> targetFieldMap = new Map<Id, String>();
    /** @description For each Engagement Plan, the Id of the target record.*/
    public Map<Id, Id> targetObjectIdMap = new Map<Id, Id>();
    /** @description For each Engagement Plan, the Id of the owner of the target record.*/
    public Map<Id, Id> targetOwnerMap = new Map<Id, Id>();

    /** @description Constructor initializes maps.*/
    public EP_EngagementPlans_UTIL(List<Engagement_Plan__c> engagementPlans) {
        for (Engagement_Plan__c engagementPlan : engagementPlans) {
            targetFieldMap.put(engagementPlan.id, getTargetObjectField(engagementPlan));
        }

        for (Engagement_Plan__c engagementPlan : database.query(getOwnerIdQuery() + ' WHERE Id IN :engagementPlans')) {
            String targetField = targetFieldMap.get(engagementPlan.id);
            if (!String.isBlank(targetField)) {
                targetObjectIdMap.put(engagementPlan.id, (Id)engagementPlan.get(targetField));
                //split the lookup_field__r.OwnerId reference for dynamic referencing
                List<String> splitRef = lookupFieldsToRelationship.get(targetField).split('\\.');
                targetOwnerMap.put(engagementPlan.id, (Id)engagementPlan.getSObject(splitRef[0]).get(splitRef[1]));
            }
        }
    }

    /*******************************************************************************************************
    * @description Generates an Action Plan query that queries for each lookup field, and for the lookup
    * record's OwnerId field.
    * @return String The query.
    ********************************************************************************************************/
    private String getOwnerIdQuery() {
        //compile list of all lookup fields and their relationship to the object's OwnerId
        List<String> queryFields = new List<String>(lookupFieldsToRelationship.keySet());
        queryFields.addAll(lookupFieldsToRelationship.values());

        String result = 'SELECT Id, ';
        result += String.join(queryFields, ', ');
        result += ' FROM Engagement_Plan__c';
        return result;
    }

    /*******************************************************************************************************
    * @description Iterates over each lookup field for an Engagement Plan, verifies that one and only
    * one of these fields is populated, and returns that field name.
    * @param engagementPlan The Engagement Plan 
    * @return String The name of the lookup field that is populated.
    ********************************************************************************************************/
    public String getTargetObjectField(Engagement_Plan__c engagementPlan) {
        String targetObjectField;
        for (String fieldName : lookupFieldsToRelationship.keySet()) {
            if (engagementPlan.get(fieldName) != null) {
                if (targetObjectField != null) {
                    engagementPlan.addError(Label.engagementPlanTwoLookups);
                } else {
                    targetObjectField = fieldName;
                }
            }
        }
        if (targetObjectField == null) {
            engagementPlan.addError(Label.engagementPlanNoLookups);
        }
        return targetObjectField;
    }
}