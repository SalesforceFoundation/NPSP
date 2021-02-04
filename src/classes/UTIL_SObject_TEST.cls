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
* @group Utility
* @description Test for SObject utility methods
*
*/
@isTest
private with sharing class UTIL_SObject_TEST {

    /***
    * @description Verifies the correct Ids are returned from the List of SObjects
    */
    @isTest
    private static void shouldReturnSObjectIdsWhenListIsPassedIn() {
        List<Opportunity> opps = buildOpportunities(3);
        Set<Id> ids = UTIL_SObject.extractIds(opps);

        System.assertEquals(opps.size(), ids.size(), 'All SObject Ids should be returned');
        for (Opportunity opp : opps) {
            System.assert(ids.contains(opp.Id), 'SObject Ids should be extracted');
        }
    }

    /***
    * @description Verifies the correct Ids are returned from the Set of SObjects
    */
    @isTest
    private static void shouldReturnSObjectIdsWhenSetIsPassedIn() {
        List<Opportunity> opps = buildOpportunities(3);
        Set<Id> ids = UTIL_SObject.extractIds(new Set<SObject>((List<SObject>) opps));

        System.assertEquals(opps.size(), ids.size(), 'All SObject Ids should be returned');
        for (Opportunity opp : opps) {
            System.assert(ids.contains(opp.Id), 'SObject Ids should be extracted');
        }
    }

    /***
    * @description Verifies an empty set is returned if no records are provided
    */
    @isTest    
    private static void shouldReturnEmptySetWhenNoSObjectIsPassedIn() {
        System.assertEquals(0, UTIL_SObject.extractIds(new Set<SObject>()).size(), 
            'An empty set should be returned when an empty set is passed.');
        System.assertEquals(0, UTIL_SObject.extractIds(new List<SObject>()).size(), 
            'An empty set should be returned when an empty list is passed.');
    }

    /***
    * @description Verifies specified Id type field values are extracted and returned.
    */
    @isTest
    private static void shouldReturnIdSetOfTheTargetField() {
        List<Opportunity> opps = buildOpportunities(3);

        Test.startTest();
            Set<Id> ids = UTIL_SObject.extractId(opps, Opportunity.AccountId);
        Test.stopTest();

        System.assertEquals(opps.size(), ids.size(), 'All target field Id should be returned');
        for (Opportunity opp : opps) {
            System.assert(ids.contains(opp.AccountId), 'Field Ids should be extracted');
        }
    }

    /***
    * @description Verifies specified Id type field values are extracted and returned
    * and null values are not returned.
    */
    @isTest
    private static void shouldNotReturnNullInIdSetOfTheTargetField() {
        final Id mockRDId = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.SObjectType);

        List<Opportunity> opps = buildOpportunities(3);
        opps[0].npe03__Recurring_Donation__c = mockRDId;

        Test.startTest();
        Set<Id> ids = UTIL_SObject.extractId(opps, Opportunity.npe03__Recurring_Donation__c);
        Test.stopTest();

        System.assertEquals(new Set<Id>{ mockRDId }, ids, 'Recurring Donation target field Id should be returned');
    }

    /***
    * @description Verifies specified String type field values are extracted and returned. 
    */
    @isTest
    private static void shouldReturnStringSetOfTheTargetField() {
        List<Opportunity> opps = buildOpportunities(3);

        Test.startTest();
            Set<String> strings = UTIL_SObject.extractString(opps, Opportunity.Name);
        Test.stopTest();

        System.assertEquals(opps.size(), strings.size(), 'All target field String should be returned');
        for (Opportunity opp : opps) {
            System.assert(strings.contains(opp.Name), 'Field String should be extracted');
        }
    }

    /***
    * @description Verifies specified Datetime type field values are extracted and returned.
    */
    @isTest
    private static void shouldReturnDatetimeSetOfTheTargetField() {
        List<Opportunity> opps = buildOpportunities(3);

        Test.startTest();
            Set<Datetime> datetimes = UTIL_SObject.extractDatetime(opps, Opportunity.CloseDate);
        Test.stopTest();

        System.assertEquals(opps.size(), datetimes.size(), 'All target field Datetime should be returned');
        for (Opportunity opp : opps) {
            System.assert(datetimes.contains(opp.CloseDate), 'Field Datetime should be extracted');
        }
    }

    /***
    * @description Verifies specified Decimal type field values are extracted and returned. 
    */
    @isTest
    private static void shouldReturnDecimalSetOfTheTargetField() {
        List<Opportunity> opps = buildOpportunities(3);

        Test.startTest();
            Set<Decimal> decimals = UTIL_SObject.extractDecimal(opps, Opportunity.Amount);
        Test.stopTest();

        System.assertEquals(opps.size(), decimals.size(), 'All target field Deciaml should be returned');
        for (Opportunity opp : opps) {
            System.assert(decimals.contains(opp.Amount), 'Field Deciaml should be extracted');
        }
    }

    // Helpers
    ////////////////

    /***
    * @description Builds specified number of Opportunities
    * @param size Numer of records to build
    * @return List<Opportunity>
    */
    private static List<Opportunity> buildOpportunities(Integer size) {
        List<Opportunity> opps = new List<Opportunity>();
        List<Id> oppMockIds = UTIL_UnitTestData_TEST.mockIds(Opportunity.sObjectType, size);
        List<Id> accountMockIds = UTIL_UnitTestData_TEST.mockIds(Account.sObjectType, size);

        for (Integer i = 0; i < size; i++) {
            opps.add(new TEST_OpportunityBuilder()
                .withId(oppMockIds[i])
                .withAccount(accountMockIds[i])
                .withCloseDate(Date.today().addDays(i))
                .withAmount(i)
                .withName()
                .build()
            );
        }

        return opps;
    }


}
