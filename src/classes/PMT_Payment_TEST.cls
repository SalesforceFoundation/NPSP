/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Payments
* @description tests for the PMT_Payment_TDTM class
*/
@isTest
private class PMT_Payment_TEST {

    /** @description Non default currency type sObject for this org.*/
    private static sObject nonDefaultCurrencyType;
    /** @description Default currency type sObject for this org.*/
    private static sObject defaultCurrencyType;

    /** @description Queries currency types and fills class variables.*/
    private static void setupISOCodes() {
        if (nonDefaultCurrencyType!=null || defaultCurrencyType!=null)
            return;
        else {
            for (sObject ct : database.query('SELECT IsoCode, ConversionRate, IsCorporate FROM CurrencyType WHERE IsActive = True')) {
                if ((boolean)ct.get('IsCorporate')) {
                    defaultCurrencyType = ct;
                } else {
                    nonDefaultCurrencyType = ct;
                }
            }
        }
    }

    @TestSetup
    static void test_createTestData() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        Account acc = new Account(Name='foo');
        insert acc;
    }

    /**
     * @description Validate that new payment records created with an opportunity get the CurrencyIsoCode set
     * properly to the Opportunities currency code
     */
    static testMethod void test_newPaymentCurrencyMatchesOpportunity() {

        //only run test in multicurrency orgs
        if (!userInfo.isMultiCurrencyOrganization()) {
            return;
        }

        Account acc = [SELECT Id FROM Account LIMIT 1];

        setupISOCodes();
        // If there is no active non-default currency just exit out at this point.
        if (nonDefaultCurrencyType == null) {
            return;
        }

        Test.startTest();

        Opportunity opp = new Opportunity(
                Name = 'success',
                Amount = 10,
                AccountID = acc.id,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        opp.put('CurrencyIsoCode', (String) nonDefaultCurrencyType.get('IsoCode'));
        insert opp;

        Test.StopTest();

        String soql = 'SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id = \'' + opp.Id + '\' LIMIT 1';
        opp = database.query(soql);

        npe01__OppPayment__c pmt = getPaymentRecord(opp.Id);
        System.AssertEquals((String) opp.get('CurrencyIsoCode'), (String) pmt.get('CurrencyIsoCode'));
    }

    /**
     * @description Validate that a change to the CurrencyIsoCode on the Opportunity record is copied
     * down the Payment records.
     */
    static testMethod void test_UpdatePaymentCurrencyFromOpportunity() {

        //only run test in multicurrency orgs
        if (!userInfo.isMultiCurrencyOrganization()) {
            return;
        }

        setupISOCodes();
        // If there is no active non-default currency just exit out at this point.
        if (nonDefaultCurrencyType == null) {
            return;
        }

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        Opportunity opp = new Opportunity(
                Name = 'success',
                Amount = 10,
                AccountID = acc.id,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;


        // Verify that the Payment CurrencyIsoCode is updated when the Opportunity CurrencyIsoCode is changed
        opp.put('CurrencyIsoCode', (String) nonDefaultCurrencyType.get('IsoCode'));
        update opp;

        Test.stopTest();

        npe01__OppPayment__c pmt = getPaymentRecord(opp.Id);
        System.AssertEquals((String) opp.get('CurrencyIsoCode'), (String) pmt.get('CurrencyIsoCode'));
        System.AssertEquals(opp.Amount, (Double)pmt.npe01__Payment_Amount__c);
    }

    /**
     * @description Validate that an error is thrown when the CurrencyIsoCode is modified on Payment record directly
     * or when a new payment is added with a different currency code than the parent opportunity.
     */
    static testMethod void test_BlockPaymentCurrencyChange() {

        //only run test in multicurrency orgs
        if (!userInfo.isMultiCurrencyOrganization()) {
            return;
        }

        setupISOCodes();
        // If there is no active non-default currency just exit out at this point.
        if (nonDefaultCurrencyType == null) {
            return;
        }

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        Opportunity opp = new Opportunity(
                Name='success',
                Amount = 10,
                AccountID=acc.id,
                CloseDate=system.today(),
                StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        npe01__OppPayment__c pmt = getPaymentRecord(opp.Id);

        // Verify that individual changes to the Payment CurrencyIsoCode are blocked
        pmt.put('CurrencyIsoCode', (String)nonDefaultCurrencyType.get('IsoCode'));
        try {
            update pmt;
            System.Assert(False, 'Updating the Payment.CurrencyIsoCode directly should have failed');
        } catch (Exception ex) {
            // GOOD!
            System.Assert(ex.getMessage().contains(System.Label.pmtModifyCurrency), 'Error message should contain "' +
                    System.Label.pmtModifyCurrency + '"');
        }

        // Verify that a new Payment cannot be inserted with a different currencyIsoCode
        pmt = new npe01__OppPayment__c(
            npe01__Opportunity__c = opp.Id,
            npe01__Payment_Amount__c = 100
        );
        pmt.put('CurrencyIsoCode', (String)nonDefaultCurrencyType.get('IsoCode'));
        try {
            insert pmt;
            System.Assert(False, 'Inserting the Payment.CurrencyIsoCode directly should have failed');
        } catch (Exception ex) {
            // GOOD!
            System.Assert(ex.getMessage().contains(System.Label.pmtModifyCurrency), 'Error message should contain "' +
                    System.Label.pmtModifyCurrency + '"');
        }
    }

    private static npe01__OppPayment__c getPaymentRecord(Id oppId) {
        String soql = 'SELECT Id, CurrencyIsoCode, npe01__Payment_Amount__c ' +
                ' FROM npe01__OppPayment__c WHERE npe01__Opportunity__c = \'' + oppId + '\' LIMIT 1';
        return (npe01__OppPayment__c)database.query(soql);
    }
}