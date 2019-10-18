/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Engagement Plans
* @group-content ../../ApexDocContent/EngagementPlans.htm
* @description EP Task Interim Field Helper - Assists in mapping
*              additional/custom fields from EP Tasks to Tasks
*
*/
public without sharing class EP_Task_InterimFieldHelper_UTIL {

    private static Set<String> ADDITIONAL_FIELDS_TO_MAP;

    public static Set<String> determineAdditionalEPTaskFieldsToMap() {
        if (ADDITIONAL_FIELDS_TO_MAP == null) {
            initializeAdditionalFieldsToMap();
        }

        return ADDITIONAL_FIELDS_TO_MAP;
    }

    @testVisible private static void initializeAdditionalFieldsToMap() {
        ADDITIONAL_FIELDS_TO_MAP = new Set<String>();

        // TODO: Determine fields that meet the following criteria:
        //       - Present on EP_Task and Task
        //       - Not Read Only On Task
        //       - Not long/rich text area type field

        // TODO: Consider extending to to source and destination SObjects when initializing
        Map<String, Schema.SObjectField> taskFields = Schema.SObjectType.Task.fields.getMap();
        Map<String, Schema.SObjectField> epTaskFields = Schema.SObjectType.Engagement_Plan_Task__c.fields.getMap();

        Set<String> candidateFields = new Set<String>();

        // Look for Candidate Task Fields
        for (String taskFieldName : taskFields.keySet()) {
            String taskFieldNameVal = taskFieldName.toLowerCase();
            Schema.SObjectField taskField = taskFields.get(taskFieldName);

            if (isFieldCandidateForMapping(taskFieldName, taskField, false)) {
                candidateFields.add(taskFieldName);
            }
        }

        // Check for matching Engagement Plan Task Fields
        for (String candidateField : candidateFields) {
            if (!epTaskFields.containsKey(candidateField)) { // No Matching Source Field
                continue;
            }

            Schema.SObjectField taskField = taskFields.get(candidateField);
            Schema.SObjectField epTaskField = epTaskFields.get(candidateField);

            if (isCompatibleFieldMapping(epTaskField, taskField)) {
                ADDITIONAL_FIELDS_TO_MAP.add(candidateField);
            }

        }


    }

    @testVisible private static Boolean isFieldCandidateForMapping(String fieldName, Schema.SObjectField soField, Boolean includeFormulaFields) {
            String fieldNameVal = fieldName.toLowerCase();

            Schema.DescribeFieldResult dfr = soField.getDescribe();

            if (!dfr.isCustom()) { // Only Custom Fields
                return false;
            }

            if (dfr.getByteLength() > 255) { // Not Mapping larger fields
                return false;
            }

            if (dfr.isCalculated() && !includeFormulaFields) { // Not Mapping formula fields
                return false;
            }

            return true;
    }


    @testVisible private static Boolean isCompatibleFieldMapping(Schema.SObjectField sourceField, Schema.SObjectField destinationField) {

        Map<Schema.DisplayType, Set<Schema.DisplayType>> validFieldMappingCombinations = new Map<Schema.DisplayType, Set<Schema.DisplayType>> {
            Schema.DisplayType.STRING => new Set<Schema.DisplayType> {Schema.DisplayType.PICKLIST, Schema.DisplayType.MULTIPICKLIST, Schema.Displaytype.URL}
            // TODO: Add additional checks for additional compatible types TBD
        };

        Schema.DescribeFieldResult  destDFR = destinationField.getDescribe();
        Schema.DescribeFieldResult srcDFR = sourceField.getDescribe();

        if (srcDFR.getType() == Schema.DisplayType.EncryptedString) { // Not allowing mapping of Encrypted fields
            return false;
        }

        if (destDFR.getSoapType() == Schema.SoapType.STRING) { // If target type is String, can map
            return true;
        }

        if (destDFR.getSoapType() == srcDFR.getSoapType()) { // If target type is same as source type, can map
            return true;
        }

        if (validFieldMappingCombinations.containsKey(srcDFR.getType())) {
            Set<Schema.DisplayType> validDestinationFieldTypes = validFieldMappingCombinations.get(srcDFR.getType());
            if (validDestinationFieldTypes.contains(destDFR.getType())) {
                return true;
            }
        }

        return false;
    }

}