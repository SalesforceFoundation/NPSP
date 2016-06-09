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
* @description 
*/
public with sharing class EP_Utils {
    
    public static Map<String, Schema.DescribeFieldResult> fieldDescribeMap = UTIL_Describe.getAllFieldsDescribe('Engagement_Plan__c');
    public static Set<String> lookupFields {
        get {
            if (lookupFields == null) {
                lookupFields = new Set<String>();
                for (String fieldName : fieldDescribeMap.keySet()) {
                    if (fieldDescribeMap.get(fieldName).getRelationshipName() != null) { 
                        if (fieldName != UTIL_Namespace.StrTokenNSPrefix('Engagement_Plan_Template__c')) {
                            lookupFields.add(fieldName);
                        }
                    }
                }
            }
            return lookupFields;
        }
        private set;
    }

    public static Id getTargetObject(Engagement_Plan__c engagementPlan) {
        Id targetObjectId;
        for (String fieldName : lookupFields) {
            if (engagementPlan.get(fieldName) != null) {
                if (targetObjectId != null) {
                    engagementPlan.addError('Only one object lookup can be populated per engagement plan.');
                } else {
                    targetObjectId = (Id)engagementPlan.get(fieldName);
                }
            }
        }
        return targetObjectId;
    }
}