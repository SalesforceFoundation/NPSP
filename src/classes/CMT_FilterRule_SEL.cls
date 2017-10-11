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
* @group Selectors
* @description Selector class for FilterGroups and FilterRule Custom Metadata Type objects
*/
public without sharing class CMT_FilterRule_SEL {

    /**
     * Private static vars to cache the Custom Metadata Type records
     */
    @TestVisible
    private static final List<Filter_Group__mdt> cachedFilterGroups = [SELECT Id, MasterLabel, DeveloperName,
            Is_Deleted__c, Description__c
            FROM Filter_Group__mdt
            WHERE Is_Deleted__c = false
            ORDER BY MasterLabel];
    @TestVisible
    private static final List<Filter_Rule__mdt> cachedFilterRules = [SELECT Id, MasterLabel, DeveloperName,
            Filter_Group__c, Field__c, Object__c, Operator__c, Constant__c, Is_Deleted__c
            FROM Filter_Rule__mdt
            WHERE Is_Deleted__c = false
            ORDER BY Filter_Group__c];

    /**
     * @description Returns a map of List<FilterRule> by FilterGroupId
     * @return Map<Id, List<Filter_Rule__mdt>>
     */
    public static Map<Id, List<Filter_Rule__mdt>> filterRulesByGroup() {
        Map<Id, List<Filter_Rule__mdt>> response = new Map<Id, List<Filter_Rule__mdt>>();
        for (Filter_Group__mdt fg : cachedFilterGroups) {
            List<Filter_Rule__mdt> rules = new List<Filter_Rule__mdt>();
            for (Filter_Rule__mdt fr : cachedFilterRules) {
                if (fr.Filter_Group__c == fg.Id) {
                    rules.add(fr);
                }
            }
            response.put(fg.Id, rules);
        }
        return response;
    }

    /**
     * @description Returns a Map of Filter Group records by FilterGroupId
     * @return Map<Id, Filter_Group__mdt>
     */
    public static Map<Id, Filter_Group__mdt> filterGroupsById() {
        Map<Id, Filter_Group__mdt> response = new Map<Id, Filter_Group__mdt>();
        for (Filter_Group__mdt fg : cachedFilterGroups) {
            response.put(fg.Id, fg);
        }
        return response;
    }

    /**
     * @description Creates a list of all fields for a given object that are referenced in any way on an
     *  existing FilterRule. This list can be used when building a query of the needed fields to retrieve
     *  for an object.
     * @param objType The type of object to retrieve referenced fields for
     * @return List<DescribeFieldResult>
     */
    public static List<Schema.DescribeFieldResult> getReferencedFieldsByObject(SObjectType objType) {
        String objName = objType.getDescribe().getName();
        Map<String, Schema.DescribeFieldResult> allFields = UTIL_Describe.getAllFieldsDescribe(objName);
        System.Debug(allFields);
        Map<String, Schema.DescribeFieldResult> fields = new Map<String, Schema.DescribeFieldResult>();
        for (Filter_Rule__mdt fr : cachedFilterRules) {
            if (fr.Object__c == objName) {
                String fldName = fr.Field__c.split('\\.')[1];
                fields.put(fr.Field__c, allFields.get(fldName.toLowerCase()));
            }
        }
        return fields.values();
    }
}