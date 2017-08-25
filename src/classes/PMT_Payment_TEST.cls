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
    public static sObject nonDefaultCurrencyType;
    /** @description Default currency type sObject for this org.*/
    public static sObject defaultCurrencyType;

    /** @description Queries currency types and fills class variables.*/
    public static void setupISOCodes() {
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

    static testMethod void test_MultiCurrency() {
        //only run test in multicurrency orgs
        if (!userInfo.isMultiCurrencyOrganization()) {
            return;
        }

        setupISOCodes();

        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));

        Account acc = new Account(Name='foo');
        insert acc;

        Test.startTest();

        Opportunity opp = new Opportunity(
                Name='success',
                Amount = 10,
                AccountID=acc.id,
                CloseDate=system.today(),
                StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        String soql = 'SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id = \'' + opp.Id + '\' LIMIT 1';
        opp = database.query(soql);

        soql = 'SELECT Id, CurrencyIsoCode FROM npe01__OppPayment__c WHERE npe01__Opportunity__c = \'' + opp.Id + '\' LIMIT 1';
        npe01__OppPayment__c pmt = database.query(soql);
        System.AssertEquals((String)opp.get('CurrencyIsoCode'), (String)pmt.get('CurrencyIsoCode'));

        // If there is no active non-default currency just exit out at this point.
        if (nonDefaultCurrencyType == null) {
            return;
        }

        // Verify that individual changes to the Payment CurrencyIsoCode are blocked
        pmt.put('CurrencyIsoCode', (String)nonDefaultCurrencyType.get('IsoCode'));
        try {
            update pmt;
            System.Assert(False, 'Updating the Payment.CurrencyIsoCode directly should have failed');
        } catch (Exception ex) {
            // GOOD!
        }

        // Verify that the Payment CurrencyIsoCode is updated when the Opportunity CurrencyIsoCode is changed
        pmt.put('CurrencyIsoCode', (String)nonDefaultCurrencyType.get('IsoCode'));
        update opp;
        soql = 'SELECT Id, CurrencyIsoCode FROM npe01__OppPayment__c WHERE npe01__Opportunity__c = \'' + opp.Id + '\' LIMIT 1';
        pmt = database.query(soql);
        System.AssertEquals((String)opp.get('CurrencyIsoCode'), (String)pmt.get('CurrencyIsoCode'));
    }
}