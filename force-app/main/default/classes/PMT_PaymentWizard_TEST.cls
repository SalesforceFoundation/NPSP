/*
    Copyright (c) 2011, Salesforce.org
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
* @author Evan Callahan & Steve Andersen
* @date 2008/7 (2.1)
* @group Payments
* @description tests for payment creation wizard
*/
@isTest
private class PMT_PaymentWizard_TEST {
    private static final String PARAM_ID = 'id';
    private static final String PARAM_WTYPE = 'wtype';
    private static final String PARAM_PAYMENT = 'payment';
    private static final String PARAM_WRITEOFF = 'writeoff';

    /*********************************************************************************************************
    * @description Verifies payments write off
    */
    @isTest
    private static void testPaymentsEnabledWhenWriteOff() {
        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c = true)
        );

        Opportunity opp = createClosedWonOpportunity(150);

        npe01__OppPayment__c[] opmtUpdate = getPayments(opp.Id);
        opmtUpdate[0].npe01__payment_amount__c = 50;
        System.assertEquals(true, opmtUpdate[0].npe01__paid__c);
        update opmtUpdate;

        npe01__OppPayment__c newOpmt = new npe01__OppPayment__c(
            npe01__Opportunity__c = opp.id,
            npe01__Payment_Amount__c = 100,
            npe01__Paid__c = false,
            npe01__Payment_Date__c = Date.newInstance(2001,12,12)
        );
        insert newOpmt;

        Test.startTest();

        npe01__OppPayment__c[] opmtAllStart = getPayments(opp.Id);
        System.assertEquals(2, opmtAllStart.size());

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_WRITEOFF);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        // set values
        controller.writeoffPayment.npe01__payment_date__c = Date.newInstance(2001,12,12);

        PageReference ref = controller.writeoff();

        Test.stopTest();

        // look for the data
        //should be two, one paid, one written off for the balance
        npe01__OppPayment__c[] opmtAll = getPayments(opp.Id);
        System.assertEquals(2, opmtAll.size());

        //the single payment should be written off
        npe01__OppPayment__c[] opmtOpen = [
            SELECT Id, npe01__Payment_Method__c, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Written_Off__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c = :opp.Id AND npe01__Paid__c = false AND npe01__Written_Off__c = false];
        System.assertEquals(0, opmtOpen.size());

        npe01__OppPayment__c[] opmtPaid = [
            SELECT Id, npe01__Payment_Method__c, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Written_Off__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c = :opp.Id AND npe01__Paid__c = true AND npe01__Written_Off__c = false];
        System.assertEquals(1, opmtPaid.size());
        System.assertEquals(50, opmtPaid[0].npe01__payment_amount__c);

        npe01__OppPayment__c[] opmtWrittenOff = [
            SELECT Id, npe01__Payment_Method__c, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Written_Off__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c = :opp.Id AND npe01__Paid__c = false AND npe01__Written_Off__c = true];
        System.assertEquals(1, opmtWrittenOff.size());
        System.assertEquals(100, opmtWrittenOff[0].npe01__payment_amount__c);
    }

    /*********************************************************************************************************
    * @description Verifies multi-payment writeoff combines the records
    */
    @isTest
    private static void verifyPaymentsAreCombinedAfterWiteOff() {
        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c = true)
        );

        Opportunity opp = createClosedWonOpportunity(1200);

        // Create 11 additional payments (for a total of 12)
        // And mark 2 of them as paid and 3 of them as written off
        // The resulting payments should be (3 paid / 3 written off / 6 open)
        List<npe01__OppPayment__c> newPayments = new List<npe01__OppPayment__c>();

        Boolean isPaid = true;
        Boolean isWrittenOff = false;

        for (Integer paymentNum=1; paymentNum<12; paymentNum++) {

            if (paymentNum>2) {
                isPaid = false;
                isWrittenOff = true;
            }

            if (paymentNum>5) {
                isWrittenOff = false;
            }

            npe01__OppPayment__c newOppPayment = new npe01__OppPayment__c(
                npe01__Opportunity__c = opp.id,
                npe01__Payment_Amount__c = 100,
                npe01__Paid__c = isPaid,
                npe01__Written_Off__c = isWrittenOff,
                npe01__Payment_Date__c = Date.newInstance(2001,paymentNum,12)
            );
            newPayments.add(newOppPayment);

        }

        // Add auto generated payment
        List<npe01__OppPayment__c> opmtUpdate = getPayments(opp.Id);
        opmtUpdate[0].npe01__payment_amount__c = 100;
        newPayments.add(opmtUpdate[0]);

        upsert newPayments;

        Test.startTest();

        List<npe01__OppPayment__c> allPayments = getPayments(opp.Id);
        System.assertEquals(12, allPayments.size(), 'There should be 12 payments associated with the Oppportunity');

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_WRITEOFF);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        // set values
        controller.writeoffPayment.npe01__payment_date__c = Date.newInstance(2001,12,12);
        System.assertEquals(6, controller.writeoffPaymentCount, 'There should be 6 payments to writeoff');
        PageReference ref = controller.writeoff();

        Test.stopTest();

        // should be seven payments - 3 paid, 3 written off (previously), 1 new combined written off
        allPayments = getPayments(opp.Id);
        System.assertEquals(7, allPayments.size(), 'There should be 7 total payments after write off');

        // loop through and get counts as well as totals
        Integer openCount = allPayments.size();
        Integer paidCount = 0;
        Integer writtenOffCount = 0;
        Decimal paidAmount = 0;
        Decimal writtenOffAmount = 0;

        for (npe01__OppPayment__c payment : allPayments) {

            if (payment.npe01__Paid__c) {
                paidCount++;
                paidAmount += payment.npe01__Payment_Amount__c;
                openCount--;
            }

            if (payment.npe01__Written_Off__c) {
                writtenOffCount++;
                writtenOffAmount += payment.npe01__Payment_Amount__c;
                openCount--;
            }
        }

        // there should be no open payments left
        System.assertEquals(0, openCount, 'There should be no open payments');
        System.assertEquals(3, paidCount, 'There should be 3 paid payments');
        System.assertEquals(300, paidAmount, 'There should be 300 in paid payments');
        System.assertEquals(4, writtenOffCount, 'There should be 4 written off payments');
        System.assertEquals(900, writtenOffAmount, 'There should be 900 in written off payments');

    }

    /*********************************************************************************************************
    * @description Verifies creation of payments does not remove existing written off payments unless the remove
    *   paid payments is checked off
    */
    @isTest
    private static void generatedPaymentScheduleShouldNotDeleteWrittenOffPayments() {
        Opportunity opp = createPledgedOpportunity(1000);

        npe01__OppPayment__c[] pmts = new npe01__OppPayment__c[0];
        pmts.add(new npe01__OppPayment__c(
            npe01__Opportunity__c = opp.id,
            npe01__payment_amount__c = 100,
            npe01__Paid__c = true)
        );
        pmts.add(new npe01__OppPayment__c(
            npe01__Opportunity__c = opp.id,
            npe01__payment_amount__c = 100,
            npe01__Paid__c = false,
            npe01__Written_Off__c = true)
        );
        insert pmts;

        Test.startTest();

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        List<SelectOption> l = controller.getItems();
        l = controller.getIntervals();
        l = controller.getIntervalUnits();

        // set values
        controller.samplePayment.npe01__payment_method__c = 'Stock';
        controller.intervalUnit = 'Month';
        controller.numberOfPayments = 8;
        controller.samplePayment.npe01__Scheduled_Date__c = Date.newInstance(2001,12,12);

        PageReference ref = controller.calculate();
        PageReference savePage = controller.createPayments();

        // look for the data
        Decimal totalPaid = 0;
        Decimal totalWrittenOff = 0;
        Decimal totalUnPaid = 0;
        Integer writtenOffCount = 0;
        Integer paidCount = 0;
        Integer unpaidCount = 0;

        npe01__OppPayment__c[] payments = getPayments(opp.Id);
        for (npe01__OppPayment__c payment : payments) {
            if (payment.npe01__Paid__c == true) {
                paidCount++;
                totalPaid += payment.npe01__Payment_Amount__c;
            } else if (payment.npe01__Written_Off__c == true) {
                writtenOffCount++;
                totalWrittenOff += payment.npe01__Payment_Amount__c;
            } else {
                unpaidCount++;
                totalUnPaid += payment.npe01__Payment_Amount__c;
            }
        }

        System.assertEquals(1, paidCount);
        System.assertEquals(100, totalPaid);
        System.assertEquals(1, writtenOffCount);
        System.assertEquals(100, totalWrittenOff);
        System.assertEquals(8, unpaidCount);
        System.assertEquals(800, totalUnPaid);

        Opportunity oppAfterPayments = [
            SELECT Amount, npe01__Payments_Made__c, npe01__Amount_Written_Off__c, npe01__Amount_Outstanding__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(totalPaid, oppAfterPayments.npe01__Payments_Made__c);
        System.assertEquals(totalWrittenOff, oppAfterPayments.npe01__Amount_Written_Off__c);
        System.assertEquals(totalUnPaid, oppAfterPayments.npe01__Amount_Outstanding__c);


    }

    /*********************************************************************************************************
    * @description Verifies creation of payments for monthly intervals
    */
    @isTest
    private static void testPageElementsMonthly() {
        Opportunity opp = createPledgedOpportunity(1300);

        npe01__OppPayment__c[] pmts = new npe01__OppPayment__c[0];
        pmts.add(new npe01__OppPayment__c (
            npe01__Opportunity__c = opp.id,
            npe01__payment_amount__c = 100,
            npe01__Paid__c = true )
        );
        pmts.add(new npe01__OppPayment__c (
            npe01__Opportunity__c = opp.id,
            npe01__payment_amount__c = 999,
            npe01__Paid__c = false )
        );
        insert pmts;

        Test.startTest();

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        List<SelectOption> l = controller.getItems();
        l = controller.getIntervals();
        l = controller.getIntervalUnits();

        // set values
        controller.samplePayment.npe01__payment_method__c = 'Stock';

        PageReference ref = controller.calculate();
        PageReference savePage = controller.createPayments();
        Boolean redirect = controller.redirect;

        // look for the data
        npe01__OppPayment__c[] opmt = getUnpaidPayments(opp.Id);
        System.assertEquals(12, opmt.size());
        System.assertEquals('Stock', opmt[0].npe01__payment_method__c);
        System.assertEquals(100, opmt[0].npe01__payment_amount__c);

        // verify that the page reference is null - redirect will happen on page
        System.assertEquals(null, savePage);
        System.assert(redirect);
    }

    /*********************************************************************************************************
    * @description Verifies creation of payments for weekly intervals
    */
    @isTest
    private static void testPageElementsWeekly() {
        Opportunity opp = createPledgedOpportunity(400.01);

        Test.startTest();

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        List<SelectOption> l = controller.getItems();
        l = controller.getIntervals();
        l = controller.getIntervalUnits();

        // set values
        controller.samplePayment.npe01__payment_method__c = 'Stock';
        controller.intervalUnit = 'Week';
        controller.numberOfPayments = 4;
        controller.samplePayment.npe01__Scheduled_Date__c = Date.newInstance(2001,12,12);

        PageReference ref = controller.calculate();
        PageReference savePage = controller.createPayments();

        // look for the data
        npe01__OppPayment__c[] opmt = getUnpaidPayments(opp.Id);
        System.assertEquals(4, opmt.size());
        System.assertEquals('Stock', opmt[0].npe01__payment_method__c);
        //System.assertEquals(100, opmt[0].npe01__payment_amount__c);
        System.assertEquals(opmt[1].npe01__scheduled_date__c, opmt[0].npe01__scheduled_date__c.addDays(7));
    }

    /*********************************************************************************************************
    * @description Verifies creation of payments for yearly intervals
    */
    @isTest
    private static void testPageElementsYearly() {
        Opportunity opp = createPledgedOpportunity(400);

        Test.startTest();

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        List<SelectOption> l = controller.getItems();
        l = controller.getIntervals();
        l = controller.getIntervalUnits();

        // set values
        controller.samplePayment.npe01__payment_method__c = 'Stock';
        controller.intervalUnit = 'Year';
        controller.numberOfPayments = 4;
        controller.samplePayment.npe01__Scheduled_Date__c = Date.newInstance(2001,12,12);

        PageReference ref = controller.calculate();
        PageReference savePage = controller.createPayments();

        // look for the data
        npe01__OppPayment__c[] opmt = getUnpaidPayments(opp.Id);
        System.assertEquals(4, opmt.size());
        System.assertEquals('Stock', opmt[0].npe01__payment_method__c);
        System.assertEquals(100, opmt[0].npe01__payment_amount__c);
        System.assertEquals(opmt[1].npe01__scheduled_date__c, opmt[0].npe01__scheduled_date__c.addDays(365));
    }

    /*********************************************************************************************************
    * @description Verifies opportunity not found message is displayed when "id" page param is invalid
    */
    @isTest
    private static void testOppNotFoundMessageWhenOppIdDoesNotExist() {
        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, null);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        System.assertEquals(null, controller.currentOpp);
        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.pmtWizardMsgNoOppFound);
    }

    /*********************************************************************************************************
    * @description Verifies opportunity not found message is displayed when "wtype" page param is invalid
    */
    @isTest
    private static void testOppNotFoundMessageWhenTypePageParamIsInvalid() {
        Opportunity opp = createPledgedOpportunity(400);

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.Id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, 'invalidType');

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        System.assertEquals(null, controller.currentOpp);
        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.pmtWizardMsgNoOppFound);
    }

    /*********************************************************************************************************
    * @description Verifies opportunity not found message is displayed when "wtype" page param is invalid and
    * the user has no create/delete permissions on the payments SObject.
    */
    @isTest
    private static void testOppNotFoundMessageWhenTypePageParamIsInvalidAndUserHasNoAccessOnPayments() {
        Opportunity opp = createPledgedOpportunity(400);

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.Id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, 'invalidType');

        System.runAs(UTIL_UnitTestData_TEST.createStandardProfileUser()) {
            PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

            System.assertEquals(null, controller.currentOpp);
            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.pmtWizardMsgNoOppFound);
        }
    }

    /*********************************************************************************************************
    * @description Verifies no access message is displayed when user tries the write off while
    * having no create/delete permissions on the payments SObject.
    */
    @isTest
    private static void testNoAccessMessageIsDisplayedWhenWriteoffByUserWithoutAccessOnPayments() {
        Opportunity opp = createPledgedOpportunity(400);

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.Id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_WRITEOFF);

        System.runAs(UTIL_UnitTestData_TEST.createStandardProfileUser()) {
            PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

            System.assertNotEquals(null, controller.currentOpp);
            System.assertEquals(false, controller.hasFeatureAccess);
        }
    }

    /*********************************************************************************************************
    * @description Verifies no access message is displayed when user tries the create payments while
    * having no create/delete permissions on the payments SObject.
    */
    @isTest
    private static void testNoAccessMessageIsDisplayedWhenCreatePaymentByUserWithoutAccessOnPayments() {
        Opportunity opp = createPledgedOpportunity(400);

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.Id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        System.runAs(UTIL_UnitTestData_TEST.createStandardProfileUser()) {
            PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

            System.assertNotEquals(null, controller.currentOpp);
            System.assertEquals(false, controller.hasFeatureAccess);
        }
    }

    /*********************************************************************************************************
    * @description Ensures no error is raised when public methods are called
    */
    @isTest
    private static void testPublicGetters() {
        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        //test public method code
        Test.startTest();
        controller.getPaymentsSettings();
        List<PMT_PaymentWizard_CTRL.payment> oplist = controller.getPayments();
        ApexPages.PageReference pr = controller.removePaidPayments();
        Test.stopTest();
    }


    /*********************************************************************************************************
    * @description Verifies payments are removed correctly
    */
    @isTest
    private static void testRemovePaidPayments() {
        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c= true)
        );

        Opportunity opp = createClosedWonOpportunity(150);

        npe01__OppPayment__c[] opmtUpdate = getPayments(opp.Id);
        opmtUpdate[0].npe01__payment_amount__c = 50;
        System.assertEquals(true, opmtUpdate[0].npe01__paid__c);
        update opmtUpdate;

        npe01__OppPayment__c newOpmt = new npe01__OppPayment__c(
            npe01__Opportunity__c = opp.id,
            npe01__Payment_Amount__c = 100,
            npe01__Paid__c = true,
            npe01__Payment_Date__c = Date.newInstance(2001,12,12)
        );
        insert newOpmt;

        Test.startTest();

        npe01__OppPayment__c[] opmtAllStart = getPayments(opp.Id);
        System.assertEquals(2, opmtAllStart.size());

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        // set values
        System.assertEquals(false, controller.haveAmount);
        controller.removePaidPayments();
        System.assertEquals(true, controller.removePaidPayments);
        controller.intervalUnit = 'Monthly';
        controller.numberOfPayments = 4;
        controller.samplePayment.npe01__Scheduled_Date__c = Date.newInstance(2001,12,12);

        PageReference ref = controller.calculate();
        System.assertEquals(4, controller.getPayments().size());

        PageReference savePage = controller.createPayments();

        npe01__OppPayment__c[] opmt = getPayments(opp.Id);
        System.assertEquals(4, opmt.size());
    }

    /*********************************************************************************************************
    * @description
    operation:
        create a new payment schedule for an open opportunity, which has Payment Mappings.
    verify:
        payments created
        payment mappings correctly applied from Opportunity to each Payment
    **********************************************************************************************************/
    @isTest
    private static void testPaymentMappingsApplied() {
        // create our Payment Field Mapping
        npe01__Payment_Field_Mapping_Settings__c pfmNew = new npe01__Payment_Field_Mapping_Settings__c();
        pfmNew.npe01__Opportunity_Field__c = 'Name';
        pfmNew.npe01__Payment_Field__c = 'npe01__Custom_Payment_Field__c';
        pfmNew.Name = 'test field mapping';
        insert pfmNew;

        Opportunity opp = createPledgedOpportunity(1300);

        npe01__OppPayment__c[] pmts = new npe01__OppPayment__c[0];
        pmts.add( new npe01__OppPayment__c (
            npe01__Opportunity__c = opp.id,
            npe01__payment_amount__c = 100,
            npe01__Paid__c = true )
        );
        pmts.add( new npe01__OppPayment__c (
            npe01__Opportunity__c = opp.id,
            npe01__payment_amount__c = 999,
            npe01__Paid__c = false )
        );
        insert pmts;

        Test.startTest();

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        List<SelectOption> l = controller.getItems();
        l = controller.getIntervals();
        l = controller.getIntervalUnits();

        // set values
        controller.samplePayment.npe01__payment_method__c = 'Stock';

        PageReference ref = controller.calculate();
        PageReference savePage = controller.createPayments();

        Boolean redirect = controller.redirect;

        Test.stopTest();

        npe01__OppPayment__c[] opmt = getUnpaidPayments(opp.Id);
        System.assertEquals(12, opmt.size());
        for (npe01__OppPayment__c pmt : opmt) {
            System.assertEquals('Stock', pmt.npe01__payment_method__c);
            System.assertEquals(100, pmt.npe01__payment_amount__c);
            System.assertEquals(opp.Name, pmt.npe01__Custom_Payment_Field__c);
        }

        System.assertEquals(null, savePage, 'The page reference is null, the redirect will occur on the page');
        System.assert(redirect);
    }

    /*********************************************************************************************************
    * @description Verify if Warning message is displayed in Schedule Payment when Automatic Payment is disabled
    * in Payment custom settings
    */
    @isTest
    private static void shouldDisplayWarningInSchedulePaymentWhenAutoPaymentDisabled() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c = false));

        Opportunity opp = createPledgedOpportunity(100);

        Test.startTest();

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_PAYMENT);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        Test.stopTest();

        System.assertEquals(opp.id, controller.currentOpp.id);
        UTIL_UnitTestData_TEST.assertPageHasMessage(System.Label.pmtWizardPaymentsDisabledTitle, ApexPages.Severity.WARNING);

    }

    /*********************************************************************************************************
    * @description Verify if Warning message is displayed in WriteOff Payment when Automatic Payment is disabled
    * in Payment custom settings
    */
    @isTest
    private static void shouldDisplayWarningInWriteOffPaymentWhenAutoPaymentDisabled() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c = false));

        Opportunity opp = createPledgedOpportunity(100);

        Test.startTest();

        PageReference pageRef = Page.PMT_PaymentWizard;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put(PARAM_ID, opp.id);
        ApexPages.currentPage().getParameters().put(PARAM_WTYPE, PARAM_WRITEOFF);

        PMT_PaymentWizard_CTRL controller = new PMT_PaymentWizard_CTRL();

        Test.stopTest();

        System.assertEquals(opp.id, controller.currentOpp.id);
        UTIL_UnitTestData_TEST.assertPageHasMessage(System.Label.pmtWizardPaymentsDisabledTitle, ApexPages.Severity.WARNING);

    }

    // Helpers
    ///////////////


    /*********************************************************************************************************
    * @description Creates an Opportunity with Pledged stage name
    * @param amount Opportunity Amount
    * @return Opportunity
    */
    private static Opportunity createPledgedOpportunity(Decimal amount) {
        return createOpportunity(amount, 'Pledged');
    }

    /*********************************************************************************************************
    * @description Creates an Opportunity with a stage name that represents closed won state
    * @param amount Opportunity Amount
    * @return Opportunity
    */
    private static Opportunity createClosedWonOpportunity(Decimal amount) {
        return createOpportunity(amount, UTIL_UnitTestData_TEST.getClosedWonStage());
    }

    /*********************************************************************************************************
    * @description Creates an Opportunity
    * @param amount Opportunity Amount
    * @param stageName Opportunity StageName
    * @return Opportunity
    */
    private static Opportunity createOpportunity(Decimal amount, String stageName) {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Opportunity opp = new Opportunity (
            Name = 'Test Opp',
            AccountId = acct.id,
            Amount = amount,
            closedate = Date.newInstance(2001,12,12),
            stagename = stageName
        );

        insert opp;
        return opp;
    }

    /*********************************************************************************************************
    * @description Returns payments for an Opportunity
    * @param oppId Opportunity Id
    * @return List<npe01__OppPayment__c>
    */
    private static List<npe01__OppPayment__c> getPayments(Id oppId) {
        return [
            SELECT Id,
                npe01__Payment_Method__c,
                npe01__Payment_Amount__c,
                npe01__Scheduled_Date__c,
                npe01__Custom_Payment_Field__c,
                npe01__Paid__c,
                npe01__Written_Off__c,
                npe01__Payment_Date__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c = :oppId
        ];
    }

    /*********************************************************************************************************
    * @description Returns unpaid payments for an Opportunity
    * @param oppId Opportunity Id
    * @return List<npe01__OppPayment__c>
    */
    private static List<npe01__OppPayment__c> getUnpaidPayments(Id oppId) {
        return [
            SELECT Id,
                npe01__Payment_Method__c,
                npe01__Payment_Amount__c,
                npe01__Scheduled_Date__c,
                npe01__Custom_Payment_Field__c,
                npe01__Paid__c,
                npe01__Written_Off__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c = :oppId
            AND npe01__Paid__c = false
            ORDER BY npe01__scheduled_date__c ASC
        ];
    }

}