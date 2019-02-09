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
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Utilities to support Batch Gift Entry.
*/
public with sharing class BGE_BatchGiftEntry_UTIL {

    /*******************************************************************************************************
    * @description Permissions class used to determine if the running user has permissions
    */
    @TestVisible
    private UTIL_Permissions perms {
        get {
            if (perms == null) {
                perms = new UTIL_Permissions();
            }

            return perms;   
        }
        set;
    }

    private static final BGE_BatchGiftEntry_UTIL instance = new BGE_BatchGiftEntry_UTIL();

    public static BGE_BatchGiftEntry_UTIL getInstance() {
        return instance;
    }


    /*******************************************************************************************************
    * @description Returns the relevant Batch fields for soql
    * @return list of field API names
    */
    public static List<String> getBatchFieldNames() {
        return new List<String>{
            'Id',
            'Name',
            'Active_Fields__c',
            'Batch_Description__c',
            'Batch_Process_Size__c',
            'Contact_Matching_Rule__c',
            'Donation_Matching_Behavior__c',
            'Donation_Matching_Implementing_Class__c',
            'Donation_Matching_Rule__c',
            'Donation_Date_Range__c',
            'Expected_Count_of_Gifts__c',
            'Expected_Total_Batch_Amount__c',
            'Post_Process_Implementing_Class__c',
            'Process_Using_Scheduled_Job__c',
            'RequireTotalMatch__c',
            'Run_Opportunity_Rollups_while_Processing__c'

        };
    }

    /*******************************************************************************************************
    * @description Checks to see whether the running user has permission to edit a given list of fields
    * @param fieldsToCheck list of DescribeFieldResult records to check
    * @return void Throws an exception if user lacks edit permissions on any field
    */
    public void checkFieldPermissionsInstance(List<DescribeFieldResult> fieldsToCheck) {
        Boolean hasPermission = true;
        List<String> fieldsWithoutPermission = new List<String>();

        for (DescribeFieldResult dfr : fieldsToCheck) {
            if (!perms.canUpdateInstance(dfr, false)) {
                hasPermission = false;
                fieldsWithoutPermission.add(dfr.getLabel());
            }
        }

        if (!hasPermission) {
            BGE_BatchGiftEntry_UTIL.handleMissingPermissions(fieldsWithoutPermission);
        }

    }

    /*******************************************************************************************************
    * @description Checks to see whether the running user has permission to edit a given list of fields
    * @param fieldsToCheck list of DescribeFieldResult records to check
    * @return void Throws an exception if user lacks edit permissions on any field
    */
    public static void checkFieldPermissions(List<DescribeFieldResult> fieldsToCheck) {
        BGE_BatchGiftEntry_UTIL.getInstance().checkFieldPermissionsInstance(fieldsToCheck);
    }

    public static void checkFieldPermissions(String objectName, List<String> fieldNamesToCheck) {
        List<DescribeFieldResult> fieldResults = new List<DescribeFieldResult>();
        for (String fieldName : fieldNamesToCheck) {
            if (fieldName.contains('__r')) {
                fieldName = fieldName.substringBefore('__r') + '__c';
            }

            DescribeFieldResult fieldResult =
                UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrAllNSPrefix(objectName), UTIL_Namespace.StrAllNSPrefix(fieldName));

            if (fieldName != 'Id' && !fieldResults.contains(fieldResult)) {
                fieldResults.add(fieldResult);
            }
        }
        checkFieldPermissions(fieldResults);
    }

    /*******************************************************************************************************
    * @description Handles missing field permissions
    * @param missingPermissions list of DescribeFieldResult records for which permissions are lacking
    * @return void Throws an exception if user lacks permissions on any field
    */
    public static void handleMissingPermissions(List<DescribeFieldResult> missingPermissions) {
        List<String> fieldNames = new List<String>();
        for (DescribeFieldResult fieldResult : missingPermissions) {
            fieldNames.add(fieldResult.getLabel());
        }
        handleMissingPermissions(fieldNames);
    }

    /*******************************************************************************************************
    * @description Handles missing field permissions
    * @param missingPermissions list of Strings identifying the fields with missing permissions
    * @return void Throws an exception if user lacks permissions on any field
    */
    private static void handleMissingPermissions(List<String> missingPermissions) {

        if (!missingPermissions.isEmpty()) {
            String errorMsg = Label.bgeFLSError + ' [' + truncateList(missingPermissions, 3) + ']';
            AuraHandledException ex = new AuraHandledException(errorMsg);
            ex.setMessage(errorMsg);
            throw ex;
        }
    }

    /*******************************************************************************************************
    * @description Takes a list of strings and converts it to a string of a subset of the original list
    * @param items list of Strings
    * @param maxItems the maximum number of Strings from the list to retain
    * @return String the truncated list of strings, separated by a comma
    * @example truncateList(new List<String>{ 'apple', 'orange', 'banana', 'pear' }, 2); // returns 'apple, orange ...'
    */
    @TestVisible
    private static String truncateList(List<String> items, Integer maxItems) {
        Integer totalItems = items.size();
        List<String> limitedItems = new List<String>();

        for (Integer i = 0; i < maxItems && i < items.size(); i++) {
            limitedItems.add(items[i]);
        }

        return String.join(limitedItems, ', ') + (totalItems > maxItems ? ' ...' : '');
    }

    /*******************************************************************************************************
    * @description Checks for field permissions needed to create a new Batch
    * User must have fields on DataImportBatch__c that appear in the config wizard
    * as well as Donation_Amount__c on DataImport__c because it is locked as a required field in config wizard
    * @return void; throws an AuraHandledException if any fields fail FLS check
    */
    public static void checkFieldPermissionsNeededForBatch() {

        List<DescribeFieldResult> fieldsToCheck = new List<DescribeFieldResult>();

        List<String> batchFieldNames = getBatchFieldNames();

        for (String field : batchFieldNames) {
            if (field != 'Id') {
                field = UTIL_Namespace.StrAllNSPrefix(field);
                fieldsToCheck.add(UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'), field));
            }
        }

        // Donation Amount and Donation Date are also required
        fieldsToCheck.add(UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c')));
        fieldsToCheck.add(UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c')));

        // Lookup from Data Import row to Data Import Batch is also required
        fieldsToCheck.add(UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), UTIL_Namespace.StrTokenNSPrefix('NPSP_Data_Import_Batch__c')));

        checkFieldPermissions(fieldsToCheck);
    }



    /*******************************************************************************************************
    * @description Returns the source field's options formatted for lightning:select if the source field is a picklist
    * or the target field's options if the source field is a string and the target field is a picklist.
    * Returns an empty map if neither case applies.
    */
    public static List<Map<String, String>> getPicklistOptions(String dataImportField){
        List<Map<String, String>> options = new List<Map<String, String>>();

        String dataImportObject = UTIL_Namespace.StrTokenNSPrefix('DataImport__c');

        Schema.DisplayType rawSourceFieldType = UTIL_Describe.getFieldDisplaytype(dataImportObject, dataImportField.toLowerCase());

        if (rawSourceFieldType == Schema.DisplayType.Picklist) {
            options = UTIL_Describe.getLightningSelectOptions(dataImportObject, dataImportField);

        } else if (rawSourceFieldType == Schema.DisplayType.String) {

            String targetObject = BDI_DataImportService.getTargetObject(dataImportField);
            if (targetObject == 'Payment') {
                targetObject = 'npe01__OppPayment__c';
            }

            String targetField = BDI_DataImportService.getTargetField(dataImportField);
            Schema.DisplayType targetFieldType = UTIL_Describe.getFieldDisplaytype(targetObject, targetField);

            if (targetFieldType == Schema.DisplayType.PICKLIST) {
                options = UTIL_Describe.getLightningSelectOptions(targetObject, targetField);
            } else if (targetField == 'RecordTypeId') {
                options = UTIL_RecordTypes.getStringRecordTypesForLightningSelect(UTIL_Describe.getSObjectType(targetObject));
            }
        }

        return options;
    }

}