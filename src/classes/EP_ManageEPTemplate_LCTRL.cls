/*
    Copyright (c) 2015, Salesforce.org
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
* @description Lightning controller for Manage Engagement Plans Template page.
*/
public with sharing class EP_ManageEPTemplate_LCTRL {
    /** @description our exception object for Field Level & Object Security errors. */
    private class permsException extends Exception {}

    @AuraEnabled
    public static Engagement_Plan_Template__c getTemplate(Id templateId) {
        List<String> templateFields = new List<String>{'Name', 'Blank_Assignment_Rule__c', 'Automatically_Update_Child_Task_Due_Date__c', 'Skip_Day__c', 'Skip_Weekends__c'};

        //Field Level Security check
        for (String fieldName : templateFields) {
            DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('Engagement_Plan_Template__c'), fieldName);
            if (dfr == null || !dfr.isAccessible() || !dfr.isUpdateable()) {
                throw (new permsException(string.format(label.flsError, new string[]{UTIL_Namespace.StrTokenNSPrefix('Engagement_Plan_Template__c.' + fieldName)})));
            }
        }

        System.debug('njjc templateId ' + templateId);

        return [SELECT Id, Name, Blank_Assignment_Rule__c, Automatically_Update_Child_Task_Due_Date__c, Skip_Day__c, Skip_Weekends__c, Description__c
                FROM Engagement_Plan_Template__c WHERE Id = :templateId LIMIT 1];
    }
    
    @AuraEnabled
    public static Engagement_Plan_Template__c saveTemplate(Engagement_Plan_Template__c template) {
        upsert template;
        return template;
    }
}