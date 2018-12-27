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
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Utilities to support Batch Gift Entry.
*/
public with sharing class BGE_BatchGiftEntry_UTIL {

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
    public static void checkFieldPermissions(List<DescribeFieldResult> fieldsToCheck) {
        Boolean hasPermission = true;
        List<String> fieldsWithoutPermission = new List<String>();

        for (DescribeFieldResult dfr : fieldsToCheck) {
            if (!UTIL_Permissions.canUpdate(dfr, false)) {
                hasPermission = false;
                fieldsWithoutPermission.add(dfr.getLabel());
            }
        }

        if (!hasPermission) {
            handleMissingPermissions(fieldsWithoutPermission);
        }

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
            throw new AuraHandledException(
                Label.bgeFLSError + ' [' + truncateList(missingPermissions, 3) + ']'
            );
        }
    }

    /*******************************************************************************************************
    * @description Takes a list of strings and converts it to a string of a subset of the original list
    * @param items list of Strings
    * @param maxItems the maximum number of Strings from the list to retain
    * @return String the truncated list of strings, separated by a comma
    * @example truncateList(new List<String>{ 'apple', 'orange', 'banana', 'pear' }, 2); // returns 'apple, orange ...'
    */
    private static String truncateList(List<String> items, Integer maxItems) {
        Integer totalItems = items.size();

        if (totalItems >= maxItems) {
            for (Integer i = maxItems; i < totalItems; i++) {
                items.remove(i);
            }
        }

        return String.join(items, ', ') + (totalItems > maxItems ? ' ...' : '');
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

        // Donation Amount is also required
        fieldsToCheck.add(UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c')));

        checkFieldPermissions(fieldsToCheck);
    }



}