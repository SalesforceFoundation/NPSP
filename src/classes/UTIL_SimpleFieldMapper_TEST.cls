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
* @group Utilities
* @description Unit tests for UTIL_SimpleFieldMapper class
*
*/
@isTest(IsParallel=true)
private class UTIL_SimpleFieldMapper_TEST {

    /*******************************************************************************************************************
    * @description Confirm Source and Target are properly set when getting an instance of the SimpleFieldMapper class
    */
    @isTest private static void getInstanceOfProperlySetsSourceAndTargetVariables() {
        UTIL_SimpleFieldMapper sFldMapper = UTIL_SimpleFieldMapper.getInstanceOf(Engagement_Plan_Task__c.getSObjectType(), Task.getSObjectType());

        System.assertEquals(Engagement_Plan_Task__c.getSObjectType(), sFldMapper.sourceSObjectType, 'Source SObject Type');
        System.assertEquals(Task.getSObjectType(), sFldMapper.targetSObjectType, 'Target SObject Type');
        System.assertEquals(false, sFldMapper.includeAnySoapTypeToString, 'Include Any SoapType To String');
    }

    /*******************************************************************************************************************
    * @description Confirms can update includeAnySoapTypeToString to true.  Little beyond this is currently possible
    *              unless we decide to create test objects and fields to use for/with this.
    */
    @isTest private static void withIncludeAnySoapTypesToStringChangesIncludeAnySoapTypeToStringHandling() {
        UTIL_SimpleFieldMapper sFldMapper = UTIL_SimpleFieldMapper.getInstanceOf(Engagement_Plan_Task__c.getSObjectType(), Task.getSObjectType()).withIncludeAnySoapTypeToString(true);

        System.assertEquals(true, sFldMapper.includeAnySoapTypeToString, 'Include Any SoapType To String');
    }

    /*******************************************************************************************************************
    * @description adds additional fields to exclude from mapping
    */
    @isTest private static void addAdditionalFieldsToExcludeFromMapping() {
        Set<String> addtlFieldsToExclude = new Set<String> {
            'Subject',
            'Priority',
            'Type'
         };

        Set<String> invalidAddtlFieldsToExclude = new Set<String> {
            'NonExistent_Field_1'
        };

        UTIL_SimpleFieldMapper sFldMapper = UTIL_SimpleFieldMapper.getInstanceOf(Engagement_Plan_Task__c.getSObjectType(), Task.getSObjectType());

        Integer excludedFieldCnt = sFldMapper.fieldsToExclude.size();
        sFldMapper = sFldMapper.withAdditionalFieldsToExclude(addtlFieldsToExclude);
        sFldMapper = sFldMapper.withAdditionalFieldsToExclude(invalidAddtlFieldsToExclude);

        System.assertEquals (excludedFieldCnt + 3, sFldMapper.fieldsToExclude.size(), 'Fields to Exclude Size increased by 3');
        for (String addtlFieldToExclude : addtlFieldsToExclude) {
            System.assertEquals (true, sFldMapper.fieldsToExclude.contains(addtlFieldToExclude.toLowerCase()), 'Fields To Exclude should contain: ' + addtlFieldToExclude.toLowerCase());
        }
    }

    /*******************************************************************************************************************
    * @description Determine Mappable Fields Between Contact and Account
    */
    @isTest private static void determineMappableFieldsBetweenContactAndAccount() {
        UTIL_SimpleFieldMapper sFldMapper = UTIL_SimpleFieldMapper.getInstanceOf(Account.getSObjectType(), Contact.getSObjectType());

        Set<String> mappableFields = sFldMapper.determineMappableFields();

        System.assertNotEquals(0, mappableFields.size(), 'There should be mappable custom fields between the Contact and Account');

        Map<String, Schema.SObjectField> accountFields = Account.getSObjectType().getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> contactFields = Contact.getSObjectType().getDescribe().fields.getMap();
        for (String mappableField : mappableFields) {
            System.assertEquals (true, accountFields.containsKey(mappableField), 'Field \'' +  mappableField + 'should be present on Account');
            System.assertEquals (true, contactFields.containsKey(mappableField), 'Field \'' +  mappableField + 'should be present on Contact');
        }

        // TODO: Setup Regression Tests Outside of this process that deploy specific extra custom fields and assert their presence.
    }

}
