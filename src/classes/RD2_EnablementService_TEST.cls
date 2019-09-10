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
* @group Recurring Donations
* @description Enhanced Recurring Donations Enablement Service class
*
*/
@isTest
public with sharing class RD2_EnablementService_TEST {

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }


    /****
    * @description Verifies a new Opportunity is created on Recurring Donations insert
    * when enhanced Recurring Donations are not enabled
    */
    @isTest
    private static void shouldCreateNewOppOnInsertWhenEnhancedRDsAreNotEnabled() {
        RD2_EnablementService.isEnhancementEnabled = false;

        npe03__Recurring_Donation__c rd = new RD2_TestRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withAmount(100)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = getOpportunities(rd.Id);
        System.assertEquals(1, opps.size(), 'An Opp should be created on Recurring Donations insert: ' + opps);
    }

    /****
    * @description Verifies a new Opportunity is not created on Recurring Donations insert
    * when enhanced Recurring Donations are enabled
    */
    @isTest
    private static void shouldNotCreateNewOppOnInsertWhenEnhancedRDsAreEnabled() {
        RD2_EnablementService.isEnhancementEnabled = true;

        npe03__Recurring_Donation__c rd = new RD2_TestRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withAmount(100)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = getOpportunities(rd.Id);
        System.assertEquals(true, opps.isEmpty(), 'No Opp should be created on Recurring Donations insert: ' + opps);
    }

    /****
    * @description Verifies a new Opportunity is created or existing updated on Recurring Donation update
    * when enhanced Recurring Donations are not enabled
    */
    @isTest
    private static void shouldCreateOrUpdateOppOnUpdateWhenEnhancedRDsAreNotEnabled() {
        RD2_EnablementService.isEnhancementEnabled = false;

        npe03__Recurring_Donation__c rd = new RD2_TestRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withAmount(100)
            .build();
        insert rd;

        Test.startTest();
        rd.npe03__Amount__c += 100;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = getOpportunities(rd.Id);
        System.assertEquals(1, opps.size(), 'An Opp should be created on Recurring Donations update: ' + opps);
        System.assertEquals(200, opps[0].Amount, 'Opportunity Amount should be updated');
    }

    /****
    * @description Verifies no new Opportunity is created or existing updated on Recurring Donation update
    * when enhanced Recurring Donations are enabled
    */
    @isTest
    private static void shouldNotCreateOrUpdateOppOnUpdateWhenEnhancedRDsAreEnabled() {
        RD2_EnablementService.isEnhancementEnabled = true;

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd = new RD2_TestRecurringDonationBuilder()
            .withContact(contact.Id)
            .withAmount(100)
            .build();
        insert rd;

        insert buildOpportunity(rd.Id, contact.AccountId);

        Test.startTest();
        rd.npe03__Amount__c += 100;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = getOpportunities(rd.Id);
        System.assertEquals(1, opps.size(), 'No Opp should be created on Recurring Donations update: ' + opps);
        System.assertEquals(100, opps[0].Amount, 'Existing Opp Amount should be unchanged');
    }

    /****
    * @description Verifies name is auto-generated when enhanced Recurring Donations are not enabled
    */
    @isTest
    private static void shouldAutogenerateNameWhenEnhancedRDsAreNotEnabled() {
        RD2_EnablementService.isEnhancementEnabled = false;
        
        verfyNameIsAutogenerated();
    }

    /****
    * @description Verifies name is auto-generated when enhanced Recurring Donations are enabled
    */
    @isTest
    private static void shouldAutogenerateNameWhenEnhancedRDsAreEnabled() {
        RD2_EnablementService.isEnhancementEnabled = true;

        verfyNameIsAutogenerated();
    }

    /****
    * @description Verifies name is auto-generated 
    */
    private static void verfyNameIsAutogenerated() {
        RD2_NamingService_TEST.enableAutomaticNaming();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd = new RD2_TestRecurringDonationBuilder()
            .withName('foo')
            .withContact(contact.Id)
            .withAmount(100)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = getRecurringDonations(new Set<Id>{ rd.Id })[0];
        System.assertEquals(RD2_NamingService_TEST.getExpectedName(contact, '100'), rd.Name, 'Name should match');
    }


    // Helpers
    ///////////////


    /****
    * @description Returns contact record
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId
            FROM Contact
            LIMIT 1
        ];
    }

    /****
    * @description Builds an Opportunity for the Recurring Donation record
    */
    private static Opportunity buildOpportunity(Id rdId, Id accountId) {
        return new Opportunity(
            Name = 'foo', 
            Amount = 100, 
            AccountId = accountId,
            CloseDate = System.today(), 
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            npe03__Recurring_Donation__c = rdId
        );
    }

    /****
    * @description Returns Opportunities associated with the specified Recurring Donation
    */
    private static List<Opportunity> getOpportunities(Id rdId) {
        return getOpportunities(new Set<Id>{ rdId });
    }

    /****
    * @description Returns Opportunities associated with specified Recurring Donations
    */
    private static List<Opportunity> getOpportunities(Set<Id> rdIds) {
        return [
            SELECT Amount, npe03__Recurring_Donation__c
            FROM Opportunity
            WHERE npe03__Recurring_Donation__c IN :rdIds
        ];
    }

    /***
    * @description Retrieves recurring donation records for the specified Id
    * @param rdIds The recurring donations Ids
    * @return List<npe03__Recurring_Donation__c>
    */
    private static List<npe03__Recurring_Donation__c> getRecurringDonations(Set<Id> rdIds) {
        return [
            SELECT Name, npe03__Next_Payment_Date__c, npe03__Last_Payment_Date__c, npe03__Paid_Amount__c
            FROM npe03__Recurring_Donation__c 
            WHERE Id IN :rdIds
        ];
    }

}