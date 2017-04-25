/*
    Copyright (c) 2009, Salesforce.org
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
* @author Sten Ebenau
* @date 27 February 2017
* @description Tests for CON_ContactMerge_BATCH
* @group ContactMerge
*/
@isTest
private class CON_ContactMerge_BATCH_TEST {
    
    static testMethod void mergeContactViaBatch() {
    	
    	npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
        
        // ACCOUNT MERGE TRIGGER NEEDS TO BE Asynchronous. 
        insert new Trigger_Handler__c(Active__c = true, Asynchronous__c = true,
              Class__c = 'ACCT_AccountMerge_TDTM', Load_Order__c = 1, Object__c = 'Account',
              Trigger_Action__c = 'AfterDelete');
        
        //set up 3 contacts for the merge interface to work with
        Contact master = UTIL_UnitTestData_TEST.getContact();
        
        Contact loser1 = UTIL_UnitTestData_TEST.getContact();
        loser1.LastName = '2Contact_forTests_Merge';
        
        insert new Contact[]{master, loser1};
        
        test.startTest();
        	database.executeBatch(new CON_ContactMerge_BATCH(master, new List<Id>{loser1.Id}), 1);
        test.stopTest();
        
        system.assertEquals(1, [SELECT Id FROM CONTACT LIMIT 100].size());
        system.assertEquals(master.Id, [Select Id from Contact LIMIT 1].Id);
        
    }
    
}