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
* @group ErrorHandling
* @description Unit tests for the Error Log controller
*
*/
@IsTest(IsParallel=false)
private with sharing class ERR_Log_TEST {
    private static final SObjectType SOBJECT_TYPE = Contact.getSObjectType();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
    }

    /****
    * @description Verifies returned data when record has related error logs
    */
    @isTest
    private static void shouldReturnData() { 
        Contact contact = getContact();

        Error__c error = new Error__c(
            Datetime__c = System.now(),
            Related_Record_ID__c = contact.Id,
            Full_Message__c = 'test error message'
        );
        insert error;

        Map<String, Object> data = ERR_Log_CTRL.getData(contact.Id);
        
        assertCommonData(data, contact);       

        List<Error__c> errors = (List<Error__c>) data.get('data');
        System.assertEquals(1, errors.size(), 'An error record should be returned');
    }

    /****
    * @description Verifies returned data when record has no related error log
    */
    @isTest
    private static void shouldReturnNotReturnErrorLogsWhenRecordHasNoError() { 
        Contact contact = getContact();

        Map<String, Object> data = ERR_Log_CTRL.getData(contact.Id); 
        
        assertCommonData(data, contact);

        List<Error__c> errors = (List<Error__c>) data.get('data');
        System.assertEquals(0, errors.size(), 'No error record should be returned');
    }

    /****
    * @description Verifies data is not returned when user does not have access
    */
    @isTest
    private static void shouldNotReturnDataWhenUserDoesNotHaveAccess() { 
        Contact contact = getContact();

        Error__c error = new Error__c(
            Datetime__c = System.now(),
            Related_Record_ID__c = contact.Id,
            Full_Message__c = 'test error message'
        );
        insert error;

        UTIL_Permissions_TEST.Stub permissionStub = new UTIL_Permissions_TEST.Stub();
        permissionStub.hasRead = false;
        ERR_Log_CTRL.permissions = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class, permissionStub);

        Map<String, Object> data = ERR_Log_CTRL.getData(contact.Id);        
           
        System.assertEquals(null, ((String) data.get(ERR_Log_CTRL.KEY_RECORD_NAME)),
            'Record name should not be returned'
        );      

        List<Error__c> errors = (List<Error__c>) data.get('data');
        System.assertEquals(null, errors, 'No error record should be returned');
    }



    // Helpers
    /////////////


    /****
    * @description Verifies common properties on returned record data when user has access
    * @param data Data to verify
    * @param contact Record
    * @return void
    */
    private static void assertCommonData(Map<String, Object> data, Contact contact) {
        System.assertEquals(
            String.valueOf(SOBJECT_TYPE), 
            ((String) data.get(ERR_Log_CTRL.KEY_SOBJECT_TYPE)),
            'SObjectType should match'
        );
        System.assertEquals(
            SOBJECT_TYPE.getDescribe().getLabelPlural(), 
            ((String) data.get(ERR_Log_CTRL.KEY_SOBJECT_LABEL)),
            'SObject label should match'
        );
        System.assertEquals(true, ((Boolean) data.get(ERR_Log_CTRL.KEY_ACCESS)),
            'User should have the access to Error Log page'
        );     
        System.assertEquals(contact.Name, ((String) data.get(ERR_Log_CTRL.KEY_RECORD_NAME)),
            'Record name should match'
        );  
    }

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT Name, FirstName, LastName
            FROM Contact
            LIMIT 1
        ];
    }
    
}
