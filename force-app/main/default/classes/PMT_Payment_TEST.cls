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
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();

    @TestSetup
    static void createTestData() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        Account acc = new Account(Name = 'foo');
        insert acc;
    }

    /*******************************************************************************************************
     * @description Validate that new payment records created with an opportunity get the CurrencyIsoCode set
     * properly to the Opportunities currency code
     *******************************************************************************************************/
    static testMethod void shouldVerifyThatNewPaymentCurrencyMatchesOpportunity() {

        //only run test in multicurrency orgs
        if (!userInfo.isMultiCurrencyOrganization()) {
            return;
        }

        Account acc = [SELECT Id FROM Account LIMIT 1];

        // If there is no active non-default currency just exit out at this point.
        if (UTIL_UnitTestData_TEST.nonDefaultCurrencyType == null) {
            return;
        }

        Test.startTest();

        Opportunity opp = new Opportunity(
                Name = 'success',
                Amount = 10,
                AccountID = acc.id,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        opp.put('CurrencyIsoCode', UTIL_UnitTestData_TEST.nonDefaultCurrencyType.IsoCode);
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
    static testMethod void shouldVerifyThatPaymentCurrencyUpdatesFromOpportunity() {

        //only run test in multicurrency orgs
        if (!userInfo.isMultiCurrencyOrganization()) {
            return;
        }

        // If there is no active non-default currency just exit out at this point.
        if (UTIL_UnitTestData_TEST.nonDefaultCurrencyType == null) {
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
        opp.put('CurrencyIsoCode', UTIL_UnitTestData_TEST.nonDefaultCurrencyType.IsoCode);
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
    static testMethod void shouldVerifyThatPaymentCurrencyChangesAreBlocked() {

        //only run test in multicurrency orgs
        if (!userInfo.isMultiCurrencyOrganization()) {
            return;
        }

        // If there is no active non-default currency just exit out at this point.
        if (UTIL_UnitTestData_TEST.nonDefaultCurrencyType == null) {
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
        pmt.put('CurrencyIsoCode', UTIL_UnitTestData_TEST.nonDefaultCurrencyType.IsoCode);
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
        pmt.put('CurrencyIsoCode', UTIL_UnitTestData_TEST.nonDefaultCurrencyType.IsoCode);
        try {
            insert pmt;
            System.Assert(False, 'Inserting the Payment.CurrencyIsoCode directly should have failed');
        } catch (Exception ex) {
            // GOOD!
            System.Assert(ex.getMessage().contains(System.Label.pmtModifyCurrency), 'Error message should contain "' +
                    System.Label.pmtModifyCurrency + '"');
        }
    }

    /**
     * @description Test that when Advanced Currency Management (ACM) is enabled, the logic that determines
     * when an Opportunity should be auto-closed still executes properly. In this scenario, the roll-ups from
     * Payment to the Opportunity object do not work, so a trigger on the Payment object is used instead.
     * This test validates that logic by setting mock to pretend that ACM is enabled.
     */
    private static testMethod void shouldVerifyThatOpportunityWillAutoCloseWithACMEnabled() {

        // Pretend the advanced multi-currency is enabled
        // Note: Trigger methods need to use UserInfo.isMultiCurrencyOrganization() to determine if the
        // CurrencyIsoCode should be queried to avoid an error when multi-currency is actually enabled
        // in an organization.
        UTIL_Currency_TEST.UtilCurrencyMock mock = new UTIL_Currency_TEST.UtilCurrencyMock();
        mock.getCurrencySymbolReturn = 'USD';
        mock.isMultiCurrencyOrganizationReturn = true;
        mock.isAdvancedCurrencyManagementEnabledReturn = true;
        UTIL_Currency.instance = mock;

        String closedWonStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        String openStage = UTIL_UnitTestData_TEST.getOpenStage();

        if (String.isEmpty(closedWonStage) || String.isEmpty(openStage)) {
            System.debug(
                    System.LoggingLevel.ERROR,
                    'Organization settings do not contain the necessary opportunity stages to run this test. Not running test.'
            );
            return;
        }

        // Disable auto payment creation fro this test
        UTIL_CustomSettingsFacade.getContactsSettings().npe01__Payments_Enabled__c = false;
        UTIL_CustomSettingsFacade.getContactsSettings().Payments_Auto_Close_Stage_Name__c = closedWonStage;

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
                Name='success',
                Amount = 500,
                AccountID=acc.id,
                CloseDate=system.today(),
                StageName=openStage);
        insert opp;

        List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c>{
                new npe01__OppPayment__c(
                        npe01__Paid__c = true,
                        npe01__Payment_Amount__c = 250,
                        npe01__Opportunity__c = opp.Id
                ),
                new npe01__OppPayment__c(
                        npe01__Paid__c = false,
                        npe01__Payment_Amount__c = 250,
                        npe01__Opportunity__c = opp.Id
                )
        };

        Test.startTest();

        insert pmts;

        opp = [SELECT Name, Amount, StageName, IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(openStage, opp.StageName, 'The Opportunity should still be in an open state');

        // Mark the payment as Paid
        pmts[1].npe01__Paid__c = true;
        update pmts;

        Test.stopTest();

        // Verify that the Opportunity is now closed
        /*opp = [SELECT Name, Amount, StageName, IsClosed, IsWon, npe01__Number_Of_Payments__c,
                npe01__Amount_Outstanding__c, npe01__Payments_Made__c,
                (SELECT npe01__Paid__c, npe01__Payment_Amount__c, npe01__Written_Off__c FROM npe01__OppPayment__r)
                FROM Opportunity
                WHERE Id = :opp.Id LIMIT 1];*/
        opp = [SELECT Name, Amount, StageName, IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(closedWonStage, opp.StageName);
    }


    /*******************************************************************************************************
     * @description     Validate that payment records are not both paid and written off on Update
     *******************************************************************************************************/
    @isTest
    private static void shouldVerifyPaymentsAreNotBothPaidAndWrittenOffOnUpdate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'success',
            Amount = 400,
            AccountID = acc.id,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getOpenStage()
        );

        insert opp;

        npe01__OppPayment__c payment = getPaymentRecord(opp.Id);

        Test.startTest();
        try {
            // Attempt to update an existing system
            payment.npe01__Paid__c = true;
            payment.npe01__Written_Off__c = true;

            update payment;
            System.assert(false, 'Updating an existing payment with both written off and paid checked should fail');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(System.Label.pmtWriteOffPaidPayment), 'Error message should contain "' +
                System.Label.pmtWriteOffPaidPayment + '"');
        }

        try {
            payment.npe01__Paid__c = false;
            payment.npe01__Written_Off__c = false;
            update payment;

            payment.npe01__Paid__c = true;
            payment.npe01__Written_Off__c = false;
            update payment;

            payment.npe01__Paid__c = false;
            payment.npe01__Written_Off__c = true;
            update payment;

        } catch (Exception ex) {
            System.assert(false, 'Updating an existing payment with valid values should succeed');
        }
        Test.stopTest();
    }

    /*******************************************************************************************************
     * @description     Validate that payment records are not both paid and written off on Insert
     *******************************************************************************************************/
    @isTest
    private static void shouldVerifyPaymentsAreNotBothPaidAndWrittenOffOnInsert() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'success',
            Amount = 400,
            AccountID = acc.id,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getOpenStage()
        );

        insert opp;

        // Attempt to create a new payment with both fields set to true
        npe01__OppPayment__c newPayment = new npe01__OppPayment__c();
        newPayment.npe01__Opportunity__c = opp.Id;
        newPayment.npe01__Payment_Amount__c = 400;
        newPayment.npe01__Payment_Date__c = System.today();
        newPayment.npe01__Scheduled_Date__c = System.today();
        newPayment.npe01__Paid__c = true;
        newPayment.npe01__Written_Off__c = true;

        Test.startTest();
        try {
            insert newPayment;
            System.assert(False, 'Inserting an existing payment with both written off and paid checked should fail');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(System.Label.pmtWriteOffPaidPayment), 'Error message should contain "' +
                System.Label.pmtWriteOffPaidPayment + '"');
        }

        // You should still be able to insert new payments without paid or written off
        List<npe01__OppPayment__c> newPayments = new List<npe01__OppPayment__c>();
        newPayment.npe01__Written_Off__c = false;
        newPayment.npe01__Paid__c = false;
        newPayment.npe01__Payment_Amount__c = 100;
        newPayments.add(newPayment);

        npe01__OppPayment__c p2 = newPayment.clone();
        p2.npe01__Paid__c = false;
        p2.npe01__Written_Off__c = true;
        p2.npe01__Payment_Amount__c = 200;
        newPayments.add(p2);

        npe01__OppPayment__c p3 = newPayment.clone();
        p3.npe01__Paid__c = true;
        p3.npe01__Written_Off__c = false;
        p3.npe01__Payment_Amount__c = 300;
        newPayments.add(p3);

        insert newPayments;

        List<npe01__OppPayment__c> insertedPayments = [
            SELECT Id, Name, npe01__Paid__c, npe01__Written_Off__c, npe01__Payment_Amount__c
            FROM npe01__OppPayment__c];

        System.assertEquals(insertedPayments.size(), 4, 'Valid payment records should be created');

        Test.stopTest();
    }

    /**
     * @description Validate that the accounting rules are enforced properly.
     * If there is a paid or written off payment, it must have a payment date.
     */
     @isTest
    static void shouldPreventMissingPaymentDateWhenEnforceAccting() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true, Enforce_Accounting_Data_Consistency__c = true));
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
                Name = 'PreventMissingPaymentDateTest',
                Amount = 10,
                AccountID = acc.id,
                CloseDate = System.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        Test.startTest();

        // Test the invalid paid insertion case
        npe01__OppPayment__c invalidPaidPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Paid__c = true);
        try {
            insert invalidPaidPayment;
            System.assert(false, 'Inserting a paid payment without a paid date will fail');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.pmtPaidPaymentDateRequired), 'The error message is not expected, actual: ' + e.getMessage());
        }

        // Test the valid paid payment insertion case
        npe01__OppPayment__c validPaidPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Paid__c = true, npe01__Payment_Date__c = Date.today());
        insert validPaidPayment;
        assertDataForPayment('Accounting enforced, Insert Paid Payment with payment date', validPaidPayment.Id, true, false, System.today(), null);

        // Test the invalid paid payment update case
        invalidPaidPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Paid__c = true, npe01__Payment_Date__c = Date.Today());
        insert invalidPaidPayment;

        invalidPaidPayment = updatePaymentForTesting(invalidPaidPayment, true, false, false, false);
        try {
            update invalidPaidPayment;
            System.assert(false, 'Updating a payment to paid without a paid date will fail');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.pmtPaidPaymentDateRequired), 'The error message is not expected, actual: ' + e.getMessage());
        }

        // Test the valid paid payment update case
        validPaidPayment = updatePaymentForTesting(validPaidPayment, true, false, true, false);
        update validPaidPayment;
        assertDataForPayment('Accounting enforced, Update Paid Payment with payment date', validPaidPayment.Id, true, false, System.today(), null);

        // Test the invalid written off insertion case
        npe01__OppPayment__c invalidWrittenOffPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Written_Off__c = true);
        try {
            insert invalidWrittenOffPayment;
            System.assert(false, 'Inserting a written off payment without a paid date will fail');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.pmtWrittenOffPaymentDateRequired), 'The error message is not expected, actual: ' + e.getMessage());
        }

         // Test the valid written off payment insertion case
        npe01__OppPayment__c validWrittenOffPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Written_Off__c = true, npe01__Payment_Date__c = Date.today());
        insert validWrittenOffPayment;
        assertDataForPayment('Accounting enforced, Insert Written Off Payment with payment date', validWrittenOffPayment.Id, false, true, System.today(), null);

        invalidWrittenOffPayment = new npe01__OppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Written_Off__c = true, npe01__Payment_Date__c = Date.today());
        insert invalidWrittenOffPayment;

        // Test the invalid written off payment update case
        invalidWrittenOffPayment = updatePaymentForTesting(invalidWrittenOffPayment, false, true, false, false);

        try {
            update invalidWrittenOffPayment;
            System.assert(false, 'Updating a payment to written off without a paid date will fail');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.pmtWrittenOffPaymentDateRequired), 'The error message is not expected, actual: ' + e.getMessage());
        }

        // Test the valid written off payment update case
        validWrittenOffPayment = updatePaymentForTesting(validWrittenOffPayment, false, true, true, false);
        update validWrittenOffPayment;
        assertDataForPayment('Accounting enforced, Update Written Off Payment with payment date', validWrittenOffPayment.Id, false, true, System.today(), null);

        Test.stopTest();
    }

    /**
     * @description Validate that the accounting rules are enforced properly.
     * If it is an unpaid payment, it must have a scheduled date.
     */
     @isTest
    static void shouldPreventMissingScheduledDateWhenEnforceAccting() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true, Enforce_Accounting_Data_Consistency__c = true));
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
                Name = 'PreventMissingScheduledDateTest',
                Amount = 10,
                AccountID = acc.id,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        Test.startTest();

        // Test the invalid unpaid insertion case
        npe01__OppPayment__c invalidUnpaidPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Paid__c = false);
        try {
            insert invalidUnpaidPayment;
            System.assert(false, 'Inserting a scheduled payment without a scheduled date will fail');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.pmtUnpaidPaymentScheduledDateRequired), 'The error message is not expected, actual: ' + e.getMessage());
        }

       // Test the valid unpaid payment insertion case
        npe01__OppPayment__c validUnpaidPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Paid__c = false, npe01__Scheduled_Date__c = Date.today());
        insert validUnpaidPayment;
        assertDataForPayment('Accounting enforced, Insert Unpaid Payment with scheduled date', validUnpaidPayment.Id, false, false, null, System.today());

        // Test the invalid unpaid payment update case
        validUnpaidPayment = updatePaymentForTesting(validUnpaidPayment, false, false, false, false);
        try {
            update validUnpaidPayment;
            System.assert(false, 'Updating a scheduled payment without a scheduled date will fail');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.pmtUnpaidPaymentScheduledDateRequired), 'The error message is not expected, actual: ' + e.getMessage());
        }

        // Test the valid unpaid payment update case
        validUnpaidPayment = updatePaymentForTesting(validUnpaidPayment, false, false, false, true);
        update validUnpaidPayment;
        assertDataForPayment('Accounting enforced, Update Unpaid Payment with scheduled date', validUnpaidPayment.Id, false, false, null, System.today());

        Test.stopTest();
    }

    /**
     * @description Validate that the accounting rules are not enforced
     * when Enforce Accounting Data Consistency is not checked.
     * If there is a paid or written off payment, nothing additional is enforced.
     */
     @isTest
    static void shouldAllowMissingPaymentDateWhenNotEnforceAccting() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
                Name = 'AllowMissingPaymentDateTest',
                Amount = 10,
                AccountID = acc.id,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        Test.startTest();

        // Test the invalid paid insertion case
        npe01__OppPayment__c invalidPaidPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Paid__c = true);
        insert invalidPaidPayment;
        assertDataForPayment('Accounting not enforced, Insert Paid Payment without payment date', invalidPaidPayment.Id, true, false, null, null);

        // Test the invalid written off insertion case
        npe01__OppPayment__c invalidWrittenOffPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Written_Off__c = true);
        insert invalidWrittenOffPayment;
        assertDataForPayment('Accounting not enforced, Insert Written Off Payment without payment date', invalidWrittenOffPayment.Id, false, true, null, null);

       // Test the invalid paid payment update case
        invalidPaidPayment = updatePaymentForTesting(invalidPaidPayment, true, false, false, false);
        update invalidPaidPayment;
        assertDataForPayment('Accounting not enforced, Update Paid Payment without payment date', invalidPaidPayment.Id, true, false, null, null);

       // Test the invalid written off payment update case
        invalidWrittenOffPayment = updatePaymentForTesting(invalidWrittenOffPayment, false, true, false, false);
        update invalidWrittenOffPayment;
        assertDataForPayment('Accounting not enforced, Update Written Off Payment without payment date', invalidWrittenOffPayment.Id, false, true, null, null);

        Test.stopTest();
    }

    /**
     * @description Validate that the accounting rules are not enforced
     * when Enforce Accounting Data Consistency is not checked.
     * If there is a scheduled payment, nothing additional is enforced
     */
     @isTest
    static void shouldAllowMissingScheduledDateWhenNotEnforceAccting() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
                Name = 'AllowMissingScheduledDateTest',
                Amount = 10,
                AccountID = acc.id,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        Test.startTest();

        // Test the invalid unpaid insertion case
        npe01__OppPayment__c invalidUnpaidPayment = new npe01__oppPayment__c(npe01__Opportunity__c = opp.Id, npe01__Paid__c = false);
        insert invalidUnpaidPayment;
        invalidUnpaidPayment = getPaymentRecordByPaymentId(invalidUnpaidPayment.Id);
        assertDataForPayment('Accounting not enforced, Insert Unpaid without schedule date', invalidUnpaidPayment.Id, false, false, null, null);

        // Test the invalid unpaid update case
        invalidUnpaidPayment = updatePaymentForTesting(invalidUnpaidPayment, false, false, false, false);
        update invalidUnpaidPayment;
        assertDataForPayment('Accounting not enforced, Update Unpaid without schedule date', invalidUnpaidPayment.Id, false, false, null, null);
        Test.stopTest();
    }


    /*******************************************************************************************************
     * HELPER FUNCTIONS
     *******************************************************************************************************/

    /*******************************************************************************************************
    * @description Retrieves payment and asserts key date for Payment concerning accounting and payment dates
    * @param String testName Used as part of the assertion text that will display if the assertion fails
    * @param Id paymentId Payment Id to check
    * @param Boolean isPaid value to assert against npe01__Paid__c
    * @param Boolean isWrittenOff value to assert against npe01__Written_Off__c
    * @param Date paidDate value to assert against npe01__Payment_Date__c
    * @param Date scheduledDate value to assert against npe01__Scheduled_Date__c
    * @return void Does not return anything
    ********************************************************************************************************/
    private static void assertDataForPayment(String testName, Id paymentId, Boolean isPaid, Boolean isWrittenOff, Date paidDate, Date scheduledDate) {
        npe01__OppPayment__c pmt = getPaymentRecordByPaymentId(paymentId);
        System.assertEquals (isPaid, pmt.npe01__Paid__c, testName + ': Paid');
        System.assertEquals (isWrittenOff, pmt.npe01__Written_Off__c, testName + ': Written Off');
        System.assertEquals (paidDate, pmt.npe01__Payment_Date__c, testName + ': Payment Date');
        System.assertEquals (scheduledDate, pmt.npe01__Scheduled_Date__c, testName + ': Scheduled Date');
    }

    /**
     * @description Helper function to help set the payment attributes as necessary for testing that accounting data consistency is enforced.
     */
    private static npe01__OppPayment__c updatePaymentForTesting(npe01__OppPayment__c payment, Boolean isPaid, Boolean isWrittenOff, Boolean hasPaymentDate, Boolean hasScheduledDate) {
        payment.npe01__Paid__c = isPaid;
        payment.npe01__Written_Off__c = isWrittenOff;

        if (hasPaymentDate == true) {
            payment.npe01__Payment_Date__c = Date.today();
        } else {
            payment.npe01__Payment_Date__c = null;
        }

        if (hasScheduledDate == true) {
            payment.npe01__Scheduled_Date__c = Date.today();
        } else {
            payment.npe01__Scheduled_Date__c = null;
        }

        return payment;
    }

    /**
     * @description Reusable utility method to retrieve a specific payment record using the payments Id.
     */
    private static npe01__OppPayment__c getPaymentRecordByPaymentId(Id paymentId) {

        String soql = 'SELECT Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Written_Off__c, npe01__Payment_Date__c, npe01__Scheduled_Date__c ';
        if (UserInfo.isMultiCurrencyOrganization()) {
            soql += ', CurrencyIsoCode ';
        }
        soql += ' FROM npe01__OppPayment__c WHERE Id = \'' + paymentId + '\' LIMIT 1';
        return (npe01__OppPayment__c)Database.query(soql);
    }

    /**
     * @description Test that when Advanced Currency Management (ACM) is enabled, the logic that determines
     * when an Opportunity should be auto-closed still executes properly for overpaid opportunities. In this scenario, the roll-ups from
     * Payment to the Opportunity object do not work, so a trigger on the Payment object is used instead.
     * This test validates that logic by setting mock to pretend that ACM is enabled.
     */
    @isTest
    private static void testOverpaidOpportunityWillAutoCloseWithACMEnabled() {

        // Pretend the advanced multi-currency is enabled
        // Note: Trigger methods need to use UserInfo.isMultiCurrencyOrganization() to determine if the
        // CurrencyIsoCode should be queried to avoid an error when multi-currency is actually enabled
        // in an organization.
        UTIL_Currency_TEST.UtilCurrencyMock mock = new UTIL_Currency_TEST.UtilCurrencyMock();
        mock.getCurrencySymbolReturn = 'USD';
        mock.isMultiCurrencyOrganizationReturn = true;
        mock.isAdvancedCurrencyManagementEnabledReturn = true;
        UTIL_Currency.instance = mock;

        String closedWonStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        String openStage = UTIL_UnitTestData_TEST.getOpenStage();

        if (String.isEmpty(closedWonStage) || String.isEmpty(openStage)) {
            System.debug(
                    System.LoggingLevel.ERROR,
                    'Organization settings do not contain the necessary opportunity stages to run this test. Not running test.'
            );
            return;
        }

        // Disable auto payment creation fro this test
        UTIL_CustomSettingsFacade.getContactsSettings().npe01__Payments_Enabled__c = false;
        UTIL_CustomSettingsFacade.getContactsSettings().Payments_Auto_Close_Stage_Name__c = closedWonStage;

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
                Name='success',
                Amount = 500,
                AccountID=acc.id,
                CloseDate=system.today(),
                StageName=openStage);
        insert opp;

        List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c>{
                new npe01__OppPayment__c(
                        npe01__Paid__c = true,
                        npe01__Payment_Amount__c = 250,
                        npe01__Opportunity__c = opp.Id
                ),
                new npe01__OppPayment__c(
                        npe01__Paid__c = false,
                        npe01__Payment_Amount__c = 250,
                        npe01__Opportunity__c = opp.Id
                )
        };

        Test.startTest();

        insert pmts;

        opp = [SELECT Name, Amount, StageName, IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(openStage, opp.StageName, 'The Opportunity should still be in an open state');

        // Mark the payment as Paid
        pmts[1].npe01__Payment_Amount__c = 500;
        pmts[1].npe01__Paid__c = true;
        update pmts;

        Test.stopTest();

        // Verify that the Opportunity is now closed
        /*opp = [SELECT Name, Amount, StageName, IsClosed, IsWon, npe01__Number_Of_Payments__c,
                npe01__Amount_Outstanding__c, npe01__Payments_Made__c,
                (SELECT npe01__Paid__c, npe01__Payment_Amount__c, npe01__Written_Off__c FROM npe01__OppPayment__r)
                FROM Opportunity
                WHERE Id = :opp.Id LIMIT 1];*/
        opp = [SELECT Name, Amount, StageName, IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(closedWonStage, opp.StageName);
    }

    /**
     * @description Test that the logic that determines when an Opportunity should be auto-closed still executes 
     * properly for overpaid opportunities. In this scenario, the roll-ups from
     * Payment to the Opportunity object do not work, so a trigger on the Payment object is used instead.
     */
    @isTest
    private static void testOverpaidOpportunityWillAutoClose() {

        String closedWonStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        String openStage = UTIL_UnitTestData_TEST.getOpenStage();

        if (String.isEmpty(closedWonStage) || String.isEmpty(openStage)) {
            System.debug(
                    System.LoggingLevel.ERROR,
                    'Organization settings do not contain the necessary opportunity stages to run this test. Not running test.'
            );
            return;
        }

        // Disable auto payment creation for this test
        UTIL_CustomSettingsFacade.getContactsSettings().Payments_Auto_Close_Stage_Name__c = closedWonStage;

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
                Name='success',
                Amount = 500,
                AccountID=acc.id,
                CloseDate=system.today(),
                StageName=openStage);
        insert opp;

        List<npe01__OppPayment__c> pmts = [Select Id from npe01__oppPayment__c Where npe01__Opportunity__c =: opp.Id];

        Test.startTest();

        opp = [SELECT Name, Amount, StageName, IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(openStage, opp.StageName, 'The Opportunity should still be in an open state');

        // Mark the payment as Paid
        pmts[0].npe01__Payment_Amount__c = 1000;
        pmts[0].npe01__Paid__c = true;
        update pmts;

        Test.stopTest();

        // Verify that the Opportunity is now closed
        /*opp = [SELECT Name, Amount, StageName, IsClosed, IsWon, npe01__Number_Of_Payments__c,
                npe01__Amount_Outstanding__c, npe01__Payments_Made__c,
                (SELECT npe01__Paid__c, npe01__Payment_Amount__c, npe01__Written_Off__c FROM npe01__OppPayment__r)
                FROM Opportunity
                WHERE Id = :opp.Id LIMIT 1];*/
        opp = [SELECT Name, Amount, StageName, IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(closedWonStage, opp.StageName);
    }

    /**
     * @description Test that the logic that determines when an Opportunity should be auto-closed still executes 
     * properly. In this scenario, the roll-ups from
     * Payment to the Opportunity object do not work, so a trigger on the Payment object is used instead.
     */
    @isTest
    private static void testOpportunityWillAutoClose() {

        String closedWonStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        String openStage = UTIL_UnitTestData_TEST.getOpenStage();

        if (String.isEmpty(closedWonStage) || String.isEmpty(openStage)) {
            System.debug(
                    System.LoggingLevel.ERROR,
                    'Organization settings do not contain the necessary opportunity stages to run this test. Not running test.'
            );
            return;
        }

        // Disable auto payment creation for this test
        UTIL_CustomSettingsFacade.getContactsSettings().Payments_Auto_Close_Stage_Name__c = closedWonStage;

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
                Name='success',
                Amount = 500,
                AccountID=acc.id,
                CloseDate=system.today(),
                StageName=openStage);
        insert opp;

        List<npe01__OppPayment__c> pmts = [Select Id from npe01__oppPayment__c Where npe01__Opportunity__c =: opp.Id];

        Test.startTest();

        opp = [SELECT Name, Amount, StageName, IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(openStage, opp.StageName, 'The Opportunity should still be in an open state');

        // Mark the payment as Paid
        pmts[0].npe01__Payment_Amount__c = 500;
        pmts[0].npe01__Paid__c = true;
        update pmts;

        Test.stopTest();

        // Verify that the Opportunity is now closed
        /*opp = [SELECT Name, Amount, StageName, IsClosed, IsWon, npe01__Number_Of_Payments__c,
                npe01__Amount_Outstanding__c, npe01__Payments_Made__c,
                (SELECT npe01__Paid__c, npe01__Payment_Amount__c, npe01__Written_Off__c FROM npe01__OppPayment__r)
                FROM Opportunity
                WHERE Id = :opp.Id LIMIT 1];*/
        opp = [SELECT Name, Amount, StageName, IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(closedWonStage, opp.StageName);
    }

    /**
    * @description Verifies that when auto payment is not enabled and payments are fully received
    *    the Opp will be updated to the Closed per Payment Auto Close State settings
    */
    @isTest
    private static void oppStageShouldClosedWhenPaymentsAreFullyReceivedAndAutoPaymentNotEnabled() {
        UTIL_CustomSettingsFacade.getContactsSettings().npe01__Payments_Enabled__c = false;
        UTIL_CustomSettingsFacade.getContactsSettings().Payments_Auto_Close_Stage_Name__c = UTIL_UnitTestData_TEST.getClosedWonStage();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new TEST_OpportunityBuilder()
            .withAccount(acc.Id)
            .withOpenStage()
            .withCloseDate(System.today())
            .withAMount(500)
            .build();

        insert opp;

        List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c>{
            new npe01__OppPayment__c(
                    npe01__Paid__c = true,
                    npe01__Payment_Amount__c = 250,
                    npe01__Opportunity__c = opp.Id
            ),
            new npe01__OppPayment__c(
                    npe01__Paid__c = true,
                    npe01__Payment_Amount__c = 250,
                    npe01__Opportunity__c = opp.Id
            )
        };

        Test.startTest();
        insert pmts;
        Test.stopTest();

        opp = oppGateway.getRecord(opp.Id);

        System.assertEquals(UTIL_UnitTestData_TEST.getClosedWonStage(), opp.StageName,
            'Opportunity should be automatically closed when payments are fully received and payment enabled is off');
    }

    /**
    * @description Verifies that when auto payment is enabled and payments are fully received,
    *    the Opp will be updated to the Closed per Payment Auto Close State settings
    */
    @isTest
    private static void oppStageShouldClosedWhenPaymentsAreFullyReceivedAndAutoPaymentEnabled() {
        UTIL_CustomSettingsFacade.getContactsSettings().npe01__Payments_Enabled__c = true;
        UTIL_CustomSettingsFacade.getContactsSettings().Payments_Auto_Close_Stage_Name__c = UTIL_UnitTestData_TEST.getClosedWonStage();

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new TEST_OpportunityBuilder()
            .withAccount(acc.Id)
            .withOpenStage()
            .withCloseDate(System.today())
            .withAMount(500)
            .build();

        insert opp;

        List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c>{
            new npe01__OppPayment__c(
                    npe01__Paid__c = true,
                    npe01__Payment_Amount__c = 250,
                    npe01__Opportunity__c = opp.Id
            ),
            new npe01__OppPayment__c(
                    npe01__Paid__c = true,
                    npe01__Payment_Amount__c = 250,
                    npe01__Opportunity__c = opp.Id
            )
        };

        Test.startTest();
        insert pmts;
        Test.stopTest();

        opp = oppGateway.getRecord(opp.Id);

        System.assertEquals(UTIL_UnitTestData_TEST.getClosedWonStage(), opp.StageName,
            'Opportunity should be automatically closed when payments are fully received and payment enabled is off');
    }

    /**
     * @description Reusable utility method to retrieve a specific payment record for an Opportunity
     */
    private static npe01__OppPayment__c getPaymentRecord(Id oppId) {

        String soql = 'SELECT Id, npe01__Payment_Amount__c ';
        if (UserInfo.isMultiCurrencyOrganization()) {
            soql += ', CurrencyIsoCode ';
        }
        soql += ' FROM npe01__OppPayment__c WHERE npe01__Opportunity__c = \'' + oppId + '\' LIMIT 1';
        return (npe01__OppPayment__c)Database.query(soql);
    }
}