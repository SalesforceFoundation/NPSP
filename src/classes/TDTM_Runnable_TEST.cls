/*
    Copyright (c) 2013, Salesforce.org
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
 * @date 2014
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Test class for TDTM_Runnable
 *
***/
@isTest
private with sharing class TDTM_Runnable_TEST {

    /*************************************************************************** 
    * @description Creates data to be used in unit tests
    **/
    @TestSetup
    static void makeData() {
        insert UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(3, CAO_Constants.HH_ACCOUNT_TYPE);      
        insert UTIL_UnitTestData_TEST.CreateMultipleTestContacts(3);
    }
    
    /*************************************************************************** 
    * @description This test verifies that the runFuture method of the TDTM_Runnable class works properly 
    **/
    @isTest
    private static void testAsync() { 
        String runFutureAccountName = 'New Acc Name';
        String runFutureContactName = 'New First Name';

        insert new Trigger_Handler__c(
            Active__c = true, 
            Asynchronous__c = true, 
            Class__c = 'ERR_ParentAccountUpdater2_TEST', 
            Load_Order__c = 1, 
            Object__c = 'Contact', 
            Trigger_Action__c = 'AfterInsert;'
        );
         
        Account acc = [SELECT Name FROM Account LIMIT 1][0];
        System.assertNotEquals(runFutureAccountName, acc.Name);
        
        Contact contact = new Contact(FirstName = 'Old First Name', LastName = 'Testerson', AccountId = acc.Id);        
        Test.startTest(); 
        insert contact;
        Test.stopTest();
        
        Contact actualContact = [SELECT FirstName FROM Contact WHERE Id = :contact.Id];
        Account actualAccount = [SELECT Name FROM Account WHERE Id = :acc.Id];
        
        // Ensure 'ERR_ParentAccountUpdater2_TEST' trigger handler future method processing has been applied
        System.assertEquals(runFutureContactName, actualContact.FirstName); 
        System.assertEquals(runFutureAccountName, actualAccount.Name);
    }

    /*************************************************************************** 
    * @description Verifies duplicate records are removed before DML operations
    * in order to prevent "Duplicate id in list" error.
    **/
    @isTest
    private static void groupByTypeShouldRemoveDuplicateSObjects() {
        List<Id> accountIds = new List<Id>(UTIL_SObject.extractIds([SELECT Id FROM Account]));
        List<Id> contactIds = new List<Id>(UTIL_SObject.extractIds([SELECT Id FROM Contact]));

        List<SObject> objectsToInsert = new List<SObject>{
            new Contact(LastName = 'GroupBySmith', AccountId = accountIds[0]),
            new Contact(LastName = 'GroupByClark', AccountId = accountIds[0]),
            new Contact(LastName = 'GroupByClark', AccountId = accountIds[1]),
            new Contact(LastName = 'GroupByClark', AccountId = accountIds[1])
        };

        List<SObject> objectsToUpdate = new List<SObject>{
            new Contact(Id = contactIds[0], LastName = 'GroupBySmith', AccountId = accountIds[0]),
            new Contact(Id = contactIds[1], LastName = 'GroupByClark', AccountId = accountIds[1]),
            new Contact(Id = contactIds[0], LastName = 'GroupBySmith', AccountId = accountIds[0]),
            new Contact(Id = contactIds[2], LastName = 'GroupByClark', AccountId = accountIds[1])
        };

        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
        dmlWrapper.objectsToInsert.addAll(objectsToInsert);
        dmlWrapper.objectsToUpdate.addAll(objectsToUpdate);

        dmlWrapper.groupByType();

        System.assertEquals(3, dmlWrapper.objectsToInsert.size(),
            'Duplicate records should be removed from insert list: ' + dmlWrapper.objectsToInsert);
        System.assertEquals(3, dmlWrapper.objectsToUpdate.size(),
            'Duplicate records should be removed from update list: ' + dmlWrapper.objectsToUpdate);        

        update dmlWrapper.objectsToUpdate;
    }
    
    /*************************************************************************** 
    * @description Verifies records are grouped by their sObjectType in order to
    * prevent "Cannot have more than 10 chunks in a single operation" error.
    **/
    @isTest
    private static void groupByTypeShouldGroupSObjectsByType() {
        List<Id> accountIds = new List<Id>(UTIL_SObject.extractIds([SELECT Id FROM Account]));

        // Assign more than 10 groups of sObjectTypes in sequence
        List<SObject> objectsToInsert = new List<SObject>{
            new Account(Name = 'GroupByAccountA'),
            new Address__c(Household_Account__c = accountIds[0]),
            new Contact(LastName = 'GroupBySmith', AccountId = accountIds[0]),
            new Account(Name = 'GroupByAccountB'),
            new Address__c(Household_Account__c = accountIds[1]),
            new Contact(LastName = 'GroupByClark', AccountId = accountIds[1]),
            new Account(Name = 'GroupByAccountC'),
            new Address__c(Household_Account__c = accountIds[2]),
            new Contact(LastName = 'GroupByJacobsen', AccountId = accountIds[2]),
            new Account(Name = 'GroupByAccountD'),
            new Contact(LastName = 'GroupByJackson', AccountId = accountIds[2])
        };

        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
        dmlWrapper.objectsToInsert.addAll(objectsToInsert);

        dmlWrapper.groupByType();

        System.assertEquals(objectsToInsert.size(), dmlWrapper.objectsToInsert.size(),
            'Insert list size should be unchanged: ' + dmlWrapper.objectsToInsert);

        insert dmlWrapper.objectsToInsert;
    }

    @IsTest
    static void groupByTypeHandlesNull() {
        //Given
        Boolean dmlWrapperThrewException = false;
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
        dmlWrapper.objectsToInsert = null;
        dmlWrapper.objectsToUpdate = null;
        dmlWrapper.objectsToDelete = null;
        dmlWrapper.objectsToUndelete = null;

        //When
        try {
            dmlWrapper.groupByType();
        } catch (Exception e) {
            dmlWrapperThrewException = true;
        }

        //Then
        System.assertEquals(false, dmlWrapperThrewException,
                'The DmlWrapper should handle its variables being set to null.');
    }

}
