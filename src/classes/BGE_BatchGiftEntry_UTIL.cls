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

    private enum BGEObjectType { BATCH, TEMPLATE }

    private BGEObjectType getObjectType(String sObjectName) {
        if (sObjectName == 'Batch_Template__c' || sObjectName == UTIL_Namespace.StrTokenNSPrefix('Batch_Template__c')) {
            return BGEObjectType.BATCH;
        } else if (sObjectName == 'DataImportBatch__c' || sObjectName == UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c')) {
            return BGEObjectType.TEMPLATE;
        }
        return null;
        // else throw an exception
    }

    /*******************************************************************************************************
    * @description Checks for field permissions to create a new Batch/Template
    * @param sObjectName string of the sObjectName
    * @return void; throws an AuraHandledException if any fields fail FLS check
    */
    public static void checkFieldPermissions(String sObjectName) {

        List<DescribeFieldResult> fieldsToCheck = new List<DescribeFieldResult>();

        List<String> fieldNames = getRecordFieldNames(sObjectName);

        for (String field : fieldNames) {
            if (field != 'Id') {
                fieldsToCheck.add(UTIL_Describe.getFieldDescribe(sObjectName, UTIL_Namespace.StrTokenNSPrefix(field)));
            }
        }

        // Donation Amount is also required
        fieldsToCheck.add(UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c')));

        for (DescribeFieldResult dfr : fieldsToCheck) {
            if (!canUpdateField(dfr)) {
                throw new AuraHandledException(Label.bgeFLSError);
            }
        }
    }

    /*******************************************************************************************************
    * @description checks for read, create, and edit FLS for a given field
    * @param dfr DescribeFieldResult of the field to check
    * @return Boolean
    */
    public static Boolean canUpdateField(DescribeFieldResult dfr) {
        if (!dfr.isCreateable() || !dfr.isUpdateable()) {
            return false;
        } else {
            return true;
        }
    }


    public static List<String> getRecordFieldNames(String sObjectName) {
        BGEObjectType objectType = getObjectType(sObjectName);

        if (objectType == BGEObjectType.BATCH) {
            return getBatchFieldNames();
        } else if (objectType == BGEObjectType.TEMPLATE) {
            return getTemplateFieldNames();
        }
        // TODO: throw exception
        return null;
    }

    /*******************************************************************************************************
    * @description Returns the relevant Batch or Template fields for soql
    * @return list of field API names
    */
    public static List<String> getTemplateFieldNames() {
        return  new List<String>{
                'Id',
                'Name',
                'Active_Fields__c',
                'Batch_Process_Size__c',
                'Contact_Matching_Rule__c',
                'Description__c',
                'Donation_Matching_Behavior__c',
                'Donation_Matching_Implementing_Class__c',
                'Donation_Matching_Rule__c',
                'Donation_Date_Range__c',
                'Post_Process_Implementing_Class__c',
                'Process_Using_Scheduled_Job__c',
                'RequireTotalMatch__c',
                'Run_Opportunity_Rollups_while_Processing__c'
        };
    }

    /*******************************************************************************************************
    * @description Returns the relevant Batch or Template fields for soql
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
    * @description Returns the relevant Batch or Template fields for soql
    * @return list of field API names
    */
    private static List<String> getRecordFieldNames(String sObjectName) {

        String descriptionField = (sObjectName == 'DataImportBatch__c') ? 'Batch_Description__c' : 'Description__c';

        List<String> recordFieldNames = new List<String>{
                descriptionField,
                'Name',
                'Id',
                'RequireTotalMatch__c',
                'Active_Fields__c',
                'Batch_Process_Size__c',
                'Run_Opportunity_Rollups_while_Processing__c',
                'Contact_Matching_Rule__c',
                'Donation_Matching_Behavior__c',
                'Donation_Matching_Implementing_Class__c',
                'Donation_Matching_Rule__c',
                'Donation_Date_Range__c',
                'Post_Process_Implementing_Class__c',
                'Process_Using_Scheduled_Job__c'
        };

        if (sObjectName == 'DataImportBatch__c') {
            recordFieldNames.add('Expected_Count_of_Gifts__c');
            recordFieldNames.add('Expected_Total_Batch_Amount__c');
        }

        return recordFieldNames;
    }

}