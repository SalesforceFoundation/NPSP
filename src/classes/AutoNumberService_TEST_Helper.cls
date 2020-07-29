/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @description Contains static helper methods used by the AutoNumberService test class,
* and the test classes of Apex controllers that wrap the AutoNumberService methods in
* AuraHandledExceptions for use in LWC.
*/
@IsTest
public class AutoNumberService_TEST_Helper {

    public static String autoNumberJSON =
            '{"fields":{"' + String.valueOf(AutoNumber__c.fields.Object_API_Name__c) +
                    '":"'
                    + String.valueOf(DataImportBatch__c.SObjectType)
                    + '","' + String.valueOf(AutoNumber__c.fields.Field_API_Name__c) +
                    '":"'
                    + String.valueOf(DataImportBatch__c.fields.Batch_Number__c)
                    + '","' + String.valueOf(AutoNumber__c.fields.Display_Format__c) +
                    '":"abc-{000}","' +
                    String.valueOf(AutoNumber__c.fields.Starting_Number__c) +
                    '":100,"' +
                    String.valueOf(AutoNumber__c.fields.Max_Used_Number__c) +
                    '":105,"' +
                    String.valueOf(AutoNumber__c.fields.IsActive__c) +
                    '":false}}';

    public static Id setupAutoNumber(Boolean isActive, String displayFormat,
            Integer startingNumber, Boolean insertTriggerHandler) {
        AutoNumber__c a = new AutoNumber__c(
                Object_API_Name__c = String.valueOf(DataImportBatch__c.SObjectType),
                Field_API_Name__c = String.valueOf(DataImportBatch__c.fields.Batch_Number__c),
                Display_Format__c = displayFormat,
                Starting_Number__c = startingNumber,
                IsActive__c = isActive,
                Description__c = 'test description',
                Max_Used_Number__c = 0
        );
        insert a;

        if (insertTriggerHandler) {
            insert new AutoNumberService(DataImportBatch__c.SObjectType).triggerHandler;
        }

        return a.Id;
    }

    public static AutoNumber__c getAutoNumberById(Id id) {
        return [
                SELECT IsActive__c, Max_Used_Number__c
                FROM AutoNumber__c
                WHERE Id = :id
        ];
    }

}