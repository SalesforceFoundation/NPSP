/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Utilities
* @description Unit test for the Custom Metadata Type api class
*/
@isTest(IsParallel=true)
private class CMT_MetadataAPI_TEST {

    private static final String SUCCESS_HANDLER_EXECUTED = 'SuccessHandlerExecuted';
    private static final String ERROR_HANDLER_EXECUTED = 'ErrorHandlerExecuted';

    /***********************************************************************************************************
     * @description verify that the metadata deploy calls the callback handler when provided
     **/
    @isTest
    private static void metadataDeployExecutesSuccessCallbackHandler() {
        CMT_MetadataAPI.upsertCustomMetadata(CRLP_RollupCMT.MetadataObject.Filter_Rule, 'Rule_1', 'Rule 1: OCR.Role',
                new Map<String,Object>{
                        'Filter_Group__c' => 'm016A000000YXdG',
                        'Operation__c' => 'Equals',
                        'Constant__c' => 'Solicitor',
                        'Object__c' => SObjectType.OpportunityContactRole.getName(),
                        'Field__c' => SObjectType.OpportunityContactRole.Fields.Role.getName()
                });

        CMT_MetadataAPI.deployMetadata(UserInfo.getUserId(), CMT_MetadataAPI.cmtUpsertQueue);
        CMT_MetadataAPI.deleteCustomMetadataTypeRecord(CRLP_RollupCMT.MetadataObject.Filter_Group, 'SomeName');

        // Construct our callback class
        CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack('Test');
        MockCallbackHandler callbackHandler = new MockCallbackHandler();

        // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();
        callback.callbackHandler = callbackHandler;

        // Call the handleResult() method of our main Callback with our dummy context var
        callback.handleResult(null, context);

        List<Account> accounts = getAccounts(SUCCESS_HANDLER_EXECUTED);
        System.assertEquals(0, accounts.size(), 'No accounts should be created.');

        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;

        callback.handleResult(result, context);

        accounts = getAccounts(SUCCESS_HANDLER_EXECUTED);
        System.assertEquals(1, accounts.size(), 'A single account should be created.');
        System.assertNotEquals(null, accounts[0].Description, 'Account Description Should have description');
 
    }

    /***********************************************************************************************************
     * @description DeployCallbackContext subclass for testing that returns myJobId
     **/
    public class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }

    /******************************************************************************************************
     * @description verify that the metadata deploy calls the error callback handler when an error occurs
     **/
    @isTest
    private static void metadataDeployExecutesErrorCallbackHandler() {
        CMT_MetadataAPI.upsertCustomMetadata(CRLP_RollupCMT.MetadataObject.Filter_Rule, 'Rule_1', 'Rule 1: OCR.Role',
                new Map<String,Object>{
                        'Filter_Group__c' => 'm016A000000YXdG',
                        'Operation__c' => 'Equals',
                        'Constant__c' => 'Solicitor',
                        'Object__c' => SObjectType.OpportunityContactRole.getName(),
                        'Field__c' => SObjectType.OpportunityContactRole.Fields.Role.getName()
                });

        CMT_MetadataAPI.deployMetadata(UserInfo.getUserId(), CMT_MetadataAPI.cmtUpsertQueue);
        CMT_MetadataAPI.deleteCustomMetadataTypeRecord(CRLP_RollupCMT.MetadataObject.Filter_Group, 'SomeName');

        // Construct our callback class
        CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack('Test');
        MockCallbackHandler callbackHandler = new MockCallbackHandler();

         // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();
        callback.callbackHandler = callbackHandler;
        callback.callbackParams = new Map<String, Object>();

        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.FAILED;
        result.details = new Metadata.DeployDetails();
        result.details.componentFailures = new List<Metadata.DeployMessage>();

        callback.handleResult(result, context);

        List<Contact> contacts = getContacts(ERROR_HANDLER_EXECUTED);
        System.assertEquals(1, contacts.size(), 'A single contact should be created.'); 
    }

    /*************************************************************************************************************
     * @description Returns accounts matching the provided name
     **/
    private static List<Account> getAccounts(String searchName) {
        List<Account> accounts = new List<Account>();

        for (Account acc : [SELECT Name, Description FROM Account]) {
            if (acc.Name == searchName) {
                accounts.add(acc);
            }
        }

        return accounts;
    }

    /*************************************************************************************************************
     * @description Returns contacts matching the provided last name
     **/
    private static List<Contact> getContacts(String searchName) {
        List<Contact> contacts = new List<Contact>();

        for (Contact c : [SELECT LastName FROM Contact]) {
            if (c.LastName == searchName) {
                contacts.add(c);
            }
        }

        return contacts;
    }

    /*************************************************************************************************************
     * @description Callback Handler to test the result callback
     **/
    public class MockCallbackHandler implements CMT_MetadataAPI.MetadataCallbackHandler {
        public void performSuccessHandler(Map<String, Object> params, String status) {
            Account newAccount = new Account(Name = SUCCESS_HANDLER_EXECUTED, Description = status);
            insert newAccount;
        }

        public void performErrorHandler(Map<String, Object> params, String status) {
            Contact c = new Contact(LastName = ERROR_HANDLER_EXECUTED);
            insert c;
        }
    }



}