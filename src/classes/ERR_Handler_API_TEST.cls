/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2021
* @description test class for Error Handling API
* @group ErrorHandling
*/
@isTest
private class ERR_Handler_API_TEST {

    private static final String TEST_ACCOUNT_NAME = 'ERR_Handler_API Acct';
    private static final String ERR_CONTEXT = 'ERR_Handler_API_TEST';

    @TestSetup
    static void setupInitalAccount() {
        Account account = new Account(Name = TEST_ACCOUNT_NAME);
        insert account;
    }

    /**
     * @description Verifies DML error is created and the error is displayed on a page
     */
    @IsTest
    private static void shouldCreateErrorFromDMLAndDisplayOnPage() {

        Test.setCurrentPage(Page.STG_SettingsManager);

        // set test account name to null to trigger update error (Required fields are missing: [Name])
        Account acct = [SELECT Id, Name FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        acct.Name = null;
        List<Account> accounts = new List<Account>{acct};

        Test.startTest();
        List<Database.SaveResult> saveResults = Database.update(accounts, false);
        ERR_Handler_API.processDMLErrors(saveResults, accounts, ERR_CONTEXT, true);
        Test.stopTest();

        // query Error__c record result for asserts
        List<Error__c> errors = new List<Error__c>([SELECT Id, Related_Record_ID__c, Context_Type__c FROM Error__c]);

        // assert error is created
        System.assertEquals(1, errors.size());
        // assert error fields match
        System.assertEquals(acct.Id, errors[0].Related_Record_ID__c);
        System.assertEquals(ERR_CONTEXT, errors[0].Context_Type__c);
        // assert page error is displayed
        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size(), 'Error message should be displayed on the page: ' + pageMessages);

    }

    /**
      * @description Verifies DML error is created and the error is displayed on a page
      */
    @IsTest
    private static void shouldCreateErrorFromDMLButDoNotDisplayOnPage() {

        Test.setCurrentPage(Page.STG_SettingsManager);

        // set test account name to null to trigger update error (Required fields are missing: [Name])
        Account acct = [SELECT Id, Name FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        acct.Name = null;
        List<Account> accounts = new List<Account>{acct};

        Test.startTest();
        List<Database.SaveResult> saveResults = Database.update(accounts, false);
        ERR_Handler_API.processDMLErrors(saveResults, accounts, ERR_CONTEXT, false);
        Test.stopTest();

        // assert error is created
        System.assertEquals(1, [SELECT COUNT() FROM Error__c]);
        // assert page error is NOT displayed
        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size(), 'Error message should not be displayed on the page: ' +
                pageMessages);

    }
}
