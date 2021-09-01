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
* @group TDTM
* @description Tests for TDTM_ObjectDataGateway
*/
@isTest
private with sharing class TDTM_ObjectDataGateway_TEST {

    /***
     * @description Verifies no exception is raised when TDTM trigger handler does not have defined action
     */
    @isTest
    private static void shouldNotThrowExceptionWhenTriggerHandlerActionIsUndefined() {
        String className = 'Test_TDTM';

        insert new Trigger_Handler__c(
            Object__c = 'Account', 
            Class__c = className, 
            Load_Order__c = 0, 
            Active__c = true, 
            Asynchronous__c = false, 
            Trigger_Action__c = null
        );

        Exception actualException;
        List<SObject> triggerHandlers = new List<SObject>();
        try {
            triggerHandlers = TDTM_ObjectDataGateway.getClassesToCallForObject(
                String.valueOf(Account.SObjectType), TDTM_Runnable.Action.BeforeInsert
            );

        } catch (Exception e) {
            actualException = e;
        }

        System.assertEquals(null, actualException, 'No exception should be thrown');

        for (Trigger_Handler__c handler : (List<Trigger_Handler__c>) triggerHandlers) {
            System.assertNotEquals(className, handler.Class__c, 'Trigger handler with undefined action should not be returned');
        }
    }

    /***
     * @description Verifies TDTM trigger handler having defined action is returned
     */
    @isTest
    private static void shouldReturnTriggerHandlerWhenActionIsDefined() {
        String className = 'Test_TDTM';

        insert new Trigger_Handler__c(
            Object__c = 'Account', 
            Class__c = className, 
            Load_Order__c = 0, 
            Active__c = true, 
            Asynchronous__c = false, 
            Trigger_Action__c = TDTM_Runnable.Action.BeforeInsert.name()
        );

        List<SObject> triggerHandlers = TDTM_ObjectDataGateway.getClassesToCallForObject(
            String.valueOf(Account.SObjectType), TDTM_Runnable.Action.BeforeInsert
        );

        Boolean isTriggerHandlerReturned = false;
        for (Trigger_Handler__c handler : (List<Trigger_Handler__c>) triggerHandlers) {
            if (handler.Class__c == className) {
                isTriggerHandlerReturned = true;
            }
        }
        System.assertEquals(true, isTriggerHandlerReturned, 'Trigger handler with defined action should be returned');
    }

}