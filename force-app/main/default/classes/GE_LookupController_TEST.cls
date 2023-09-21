/*
    Copyright (c) 2019 Salesforce.org
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
* @group HGE
* @description Unit Test for the Gift Entry Lookup Component Controller
*
*/
@IsTest
private class GE_LookupController_TEST {

    /**
     * Test SOSL implementation of searching.
     */
    @IsTest
    static void testSearch() {
        List<Account> accounts = new List<Account>{
                new Account(Name = 'Test Account'),
                new Account(Name = 'Non-Matching Account')
        };
        insert accounts;

        // doSearch utilizes SOSL, which means results must be hardcoded in tests
        Test.setFixedSearchResults(new List<Id>{accounts[0].Id});

        Test.startTest();
        List<GE_LookupController.LookupResult> results = GE_LookupController.doSearchSOSL('test', 'Account');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected results to not be null.');
        System.assertEquals(1, results.size(), 'Expected one result.');
        System.assertEquals('Test Account', results[0].displayValue, 'Expected display value to be Test Account');
    }

    /**
     * Ensure that when no results are found, we still get an empty List<LookupResult> and not null.
     */
    @IsTest
    static void testSearchNoResults() {
        Test.startTest();
        List<GE_LookupController.LookupResult> results = GE_LookupController.doSearchSOSL('test', 'Account');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected results to not be null.');
        System.assertEquals(0, results.size(), 'Expected results to be empty.');
    }

    /**
     * Test searching record types, which have an additional WHERE clause to restrict results to the parent SObject Type
     */
    @IsTest
    static void testSearchRecordType() {

        Test.startTest();
        List<GE_LookupController.LookupResult> results = GE_LookupController.doSearchRecordType('Donation', 'Opportunity');
        Test.stopTest();

        // auto-builds do not deploy record types, but dev/qa builds do, run equivalent query and check results
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName LIKE '%Donation%' LIMIT 50];

        System.assertNotEquals(null, results);
        System.assertEquals(recordTypes.size(), results.size());
    }

    @IsTest
    static void testSearchSOQL() {
        TEST_OpportunityBuilder builder = new TEST_OpportunityBuilder()
            .withClosedWonStage()
            .withCloseDate(Date.today());

        List<Opportunity> opps = new List<Opportunity> {
            builder.withName('Test Opportunity').build(),
            builder.withName('Non-Matching Opportunity').build()
        };
        
        insert opps;

        // doSearch utilizes SOSL, which means results must be hardcoded in tests
        Test.setFixedSearchResults(new List<Id>{opps[0].Id});

        Test.startTest();
        List<GE_LookupController.LookupResult> results = GE_LookupController.doSearchSOQL('test', 'Opportunity');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected results to not be null.');
        System.assertEquals(1, results.size(), 'Expected one result.');
        System.assertEquals('Test Opportunity', results[0].displayValue, 'Expected display value to be Test Opportunity');
    }
}