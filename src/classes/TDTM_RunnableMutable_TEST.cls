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
        insert UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(3, CAO_Constants.HH_ACCOUNT_TYPE);      
        insert UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
    }

    /*************************************************************************** 
    * @description Verifies that when calling the same Trigger Handler multiple
    * times where that class implements TDTM_RunnableMutable
    **/
    @isTest
    private static void testAllowMutation()
    {
        // we will run the same class this many times, and based on the sample
        // implementation of TDTM_RunnableMutable, this will be the value
        // of the NumberOfEmployees field on each Account 
        Integer numberOfIterations = 5;

        // creating multiple trigger handlers of the same type
        List<Trigger_Handler__c> triggerHandlers = new List<Trigger_Handler__c>();

        for (Integer i = 0; i < numberOfIterations; i += 1) {
            Trigger_Handler__c triggerHandler = new Trigger_Handler__c();
            triggerHandler.Active__c = true;
            triggerHandler.Asynchronous__c = false;
            triggerHandler.Class__c = 'TDTM_RunnableMutableExample_TEST';
            triggerHandler.Load_Order__c = i;
            triggerHandler.Object__c = 'Contact';
            triggerHandler.Trigger_Action__c = 'AfterUpdate';
            triggerHandlers.add(triggerHandler);
        }

        insert triggerHandlers;

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

        for (Account account : accounts) {
            System.assertEquals(numberOfIterations, account.NumberOfEmployees);
        }
    }
}