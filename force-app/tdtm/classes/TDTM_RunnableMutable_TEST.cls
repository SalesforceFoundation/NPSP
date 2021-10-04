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
 * @author Roger Mitchell
 * @date 4/12/2019
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Test class for TDTM_RunnableMutable
 */
@isTest(isParallel=true)
private with sharing class TDTM_RunnableMutable_TEST {
    
    /*************************************************************************** 
    * @description Creates data to be used in unit tests
    **/
    @TestSetup
    static void makeData() {
        insert UTIL_UnitTestData_TEST.createMultipleTestContacts(3);
    }

    /*************************************************************************** 
    * @description Verifies that when calling the same Trigger Handler multiple
    * times where that class implements TDTM_RunnableMutable
    **/
    @isTest
    private static void shouldPermitDmlWrapperMutation() {
        // we will run the same class this many times, and based on the sample
        // implementation of TDTM_RunnableMutable, this will be the value
        // of the NumberOfEmployees field on each Account 
        Integer numberOfIterations = 5;

        String mockClass = TDTM_RunnableMutableMock_TEST.class.getName();
        mockClass = (mockClass.contains('.') ? mockClass.substringAfter('.') : mockClass);

        // creating multiple trigger handlers of the same type
        List<Trigger_Handler__c> triggerHandlers = new List<Trigger_Handler__c>();

        for (Integer i = 0; i < numberOfIterations; i += 1) {
            Trigger_Handler__c triggerHandler = new Trigger_Handler__c();
            triggerHandler.Active__c = true;
            triggerHandler.Asynchronous__c = false;
            triggerHandler.Class__c = mockClass;
            triggerHandler.Load_Order__c = i;
            triggerHandler.Object__c = 'Contact';
            triggerHandler.Trigger_Action__c = 'AfterUpdate';
            triggerHandlers.add(triggerHandler);
        }
        insert triggerHandlers;

        Test.startTest();

        // pull some contacts, perform update
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
        update contacts;

        // get collection of AccountId from contacts, retrieve accounts for assertions
        Set<Id> accountIds = new Set<Id>();

        for (Contact contact : contacts) {
            accountIds.add(contact.AccountId);
        }

        List<Account> accounts = [
            SELECT Id, NumberOfEmployees
            FROM Account
            WHERE Id IN :accountIds
        ];

        Test.stopTest();

        for (Account account : accounts) {
            System.assertEquals(numberOfIterations, account.NumberOfEmployees);
        }
    }
}
