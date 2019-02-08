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
* @group Callable API 
* @group-content ../../ApexDocContent/CallableAPI.htm
* @description Tests specific to Callable API. 
*/
@IsTest

public with sharing class CallableApi_TEST {

    private static final String TDTM_TRIGGER_ACTION = 'TDTM.disableAllTriggers';
    
    /*******************************************************************************************************
    * @description verify the TDTM Callable action returns an Object
    */
    @IsTest
    public static void verifyCallableReturnsAnObject() {
       
        Test.startTest();

        // Call the API to disable All TDTM Triggers
        Callable npspApi = (Callable) Type.forName('CallableApi').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();
        Object result = npspApi.call(TDTM_TRIGGER_ACTION, triggerArgs);

        Test.stopTest();

        Map<String, Object> triggerResult = (Map<String, Object>)result;
        System.assertNotEquals(null, triggerResult, 'No result was returned from call');
        System.assertEquals(TDTM_TRIGGER_ACTION, String.valueOf(triggerResult.get('action')), 'Action was not returned');
    }    

    /*******************************************************************************************************
    * @description verify the TDTM Callable Action does not modify the TDTM Triggers globally
    */
    @IsTest
    public static void callableApiDoesNotChangeTdtmTriggers() {
       
        Test.startTest();
        // Get list of TDTM modified dates
        List<AggregateResult> handlerResults = [SELECT MAX(LastModifiedDate) maxDate FROM Trigger_Handler__c];
        Datetime maxDate = (Datetime)handlerResults[0].get('maxDate');

        // Get count of Accounts in the system
        Integer accountCountBefore = Database.countQuery('SELECT COUNT() FROM Account');

        // Call the API to disable All TDTM Triggers
        Callable npspApi = (Callable) Type.forName('CallableApi').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();
        Object result = npspApi.call(TDTM_TRIGGER_ACTION, triggerArgs);

        Contact contact1 = createContact();
        Test.stopTest();

        Integer accountCountAfter = Database.countQuery('SELECT COUNT() FROM Account');

        System.assertEquals(accountCountBefore, accountCountAfter, 'Account record was created');
        System.assertEquals(null, contact1.AccountId, 'Contact Triggers were not turned off');

        handlerResults = [SELECT MAX(LastModifiedDate) maxDate FROM Trigger_Handler__c];
        Datetime maxDate2 = (Datetime)handlerResults[0].get('maxDate');
        System.assertEquals(maxDate2, maxDate, 'TDTM records were modified');

        List<Trigger_Handler__c> handlers = TDTM_Config_API.getCachedRecords();
        for (Trigger_Handler__c handler: handlers) {
            System.assertEquals(false, handler.Active__c, handler.Class__c + ' is not turned off');
        }

    }

    /*******************************************************************************************************
    * @description Call the API with an invalid method format and make sure an exception is thrown
    */
    @IsTest
    public static void callableApiThrowsExceptionWhenMethodFormatIsInvalid() {
       
        Test.startTest();

        Callable npspApi = (Callable) Type.forName('CallableApi').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();
        Boolean methodExceptionThrown = false;

        try {
            Object result = npspApi.call('InvalidFormat', triggerArgs);

        } catch (CallableApi.MalformedMethodInvocationException apiException) {
            methodExceptionThrown = true;
            System.assert(apiException.getMessage().contains(' is invalid'));
        }

        System.assert(methodExceptionThrown, 'Method Exception Was Not Thrown');

        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Call the API with an invalid method name and make sure an exception is thrown
    */
    @IsTest
    public static void callableApiThrowsExceptionWhenMethodIsMissing() {
       
        Test.startTest();

        Callable npspApi = (Callable) Type.forName('CallableApi').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();
        Boolean methodExceptionThrown = false;

        try {
            Object result = npspApi.call('Some.invalidCall', triggerArgs);

        } catch (CallableApi.MalformedMethodInvocationException apiException) {
            methodExceptionThrown = true;
            System.assert(apiException.getMessage().contains(' not implemented'));
        }

        System.assert(methodExceptionThrown, 'Method Exception Was Not Thrown');

        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Populate the TDTM table so that we can test that the triggers are not modified
    */
    @TestSetup
    private static void populateTriggerTable(){
        // Create a contact and let the tdtm code populate the TDTM table

        Contact contact2 = createContact();
        System.assertNotEquals(null, contact2.AccountId, 'Contact Triggers Are not Populated');
    }

    /*******************************************************************************************************
    * HELPER FUNCTIONS
    */


    /*******************************************************************************************************
    * @description Create a contact and return the information
    * @return A newly created Contact
    */
    private static Contact createContact() {
        Contact contact1 = new Contact(LastName='CallableApiTest');
        insert contact1;

        Contact contact2 = [SELECT AccountId FROM Contact WHERE Id = :contact1.Id LIMIT 1];
        return contact2; 
    }

}
