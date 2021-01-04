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
* @group Gift Entry
* @description This class wraps Auto Number Services as @AuraEnabled methods, which
* manage the creation and retrieval of Auto Number records, for use with the
* DataImportBatch object in Lightning web components.
*/
public class BDI_BatchNumberSettingsController {

    static SObjectType sObjType = DataImportBatch__c.SObjectType;
    static AN_AutoNumberService autoNumberService =
            new AN_AutoNumberService(sObjType);

    @AuraEnabled
    public static Boolean isSysAdmin() {
        return STG_Panel.runningUserIsAdmin();
    }

    @AuraEnabled
    public static void activate(String autoNumberId) {
        autoNumberService.activate(autoNumberId);
    }

    @AuraEnabled
    public static void deactivate(String autoNumberId) {
        autoNumberService.deactivate(autoNumberId);
    }

    @AuraEnabled
    public static AutoNumber__c save(String autoNumber) {
        try {
            return autoNumberService.save(autoNumber);
        } catch (AN_AutoNumberService.AutoNumberException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<AutoNumber__c> getAutoNumbers() {
        return autoNumberService.getAutoNumbers(sObjType);
    }

    /**
     * @description The AutoNumber__c object is protected, and cannot be imported
     * into LWC modules.  This method provides the FieldDescribe info for the
     * AutoNumber__c fields to the UI.
     * @return A map of field API Name to SObjectFieldDescribe object.
     */
    @AuraEnabled(cacheable=true)
    public static String getFieldDescribes() {
        return JSON.serialize(new Map<String, Object>{
                Schema.SObjectType.AutoNumber__c.fields.IsActive__c.Name =>
                        Schema.SObjectType.AutoNumber__c.fields.IsActive__c,
                Schema.SObjectType.AutoNumber__c.fields.Display_Format__c.Name =>
                        Schema.SObjectType.AutoNumber__c.fields.Display_Format__c,
                Schema.SObjectType.AutoNumber__c.fields.Starting_Number__c.Name =>
                        Schema.SObjectType.AutoNumber__c.fields.Starting_Number__c,
                Schema.SObjectType.AutoNumber__c.fields.Description__c.Name =>
                        Schema.SObjectType.AutoNumber__c.fields.Description__c,
                Schema.SObjectType.AutoNumber__c.fields.Max_Used_Number__c.Name =>
                        Schema.SObjectType.AutoNumber__c.fields.Max_Used_Number__c,
                Schema.SObjectType.AutoNumber__c.fields.Object_API_Name__c.Name =>
                        Schema.SObjectType.AutoNumber__c.fields.Object_API_Name__c,
                Schema.SObjectType.AutoNumber__c.fields.Field_API_Name__c.Name =>
                        Schema.SObjectType.AutoNumber__c.fields.Field_API_Name__c
        });
    }

}