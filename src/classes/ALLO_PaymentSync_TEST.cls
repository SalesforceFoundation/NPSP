/*
    Copyright (c) 2019, Salesforce.org
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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests specific to Allocations trigger based functionality. 
*/
@isTest
private with sharing  class ALLO_PaymentSync_TEST {
//TODO null and zero amounts for both opps and payments
//TODO negative payment amounts
//TODO over and underscheduled

    static General_Accounting_Unit__c defaultGau;
    static List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>();

    static Opportunity opportunity;
    static List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();

    @testSetup 
    static void setup() {
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='Default GAU');
        insert gau;

        Account account = new Account(Name='Account');
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = 'Opp', 
            Amount = 1000, 
            AccountID = account.Id, 
            CloseDate = System.today(), 
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            npe01__Do_Not_Automatically_Create_Payment__c = true
        );
        insert opportunity;

    }

    /*******************************************************************************************************
    * @description When changing the amount of a Payment with Allocations: 
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust 
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an 
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    @isTest
    static void syncPaymentToOpportunity() {
        makePayments(1000, 1);
        makeGAUs(2);

        System.assert(UTIL_CustomSettingsFacade.getAllocationsSettings().Payment_Allocations_Enabled__c, UTIL_CustomSettingsFacade.getAllocationsSettings());

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        Allocation__c percentAllo = new Allocation__c(Payment__c=payments[0].id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Payment__c=payments[0].id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(6, queryAllocations.size(), 'Six opportunity allocations should exist.');
        //synced opportunity allocations
        assertAllocation(queryAllocations[0], 200, defaultGau.Id, true);
        assertAllocation(queryAllocations[1], 300, gaus[1].id, true);
        assertAllocation(queryAllocations[2], 500, gaus[0].id, true);
        //original payment allocations
        assertAllocation(queryAllocations[3], 200, defaultGau.Id, false);
        assertAllocation(queryAllocations[4], 300, gaus[1].id, false);
        assertAllocation(queryAllocations[5], 500, gaus[0].id, false);
    }

    /*******************************************************************************************************
    * @description When changing the Allocation amount of an Opportunity with Payments:
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust 
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an 
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    @isTest
    static void syncOpportunityToPayment() {
        makePayments(1000, 1);
        makeGAUs(2);

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        Allocation__c percentAllo = new Allocation__c(Opportunity__c=opportunity.id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Opportunity__c=opportunity.id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(6, queryAllocations.size(), 'Six allocations should exist.');
        //original opportunity allocations
        assertAllocation(queryAllocations[0], 200, defaultGau.Id, true);
        assertAllocation(queryAllocations[1], 300, gaus[1].id, true);
        assertAllocation(queryAllocations[2], 500, gaus[0].id, true);
        //synced payment allocations
        assertAllocation(queryAllocations[3], 200, defaultGau.Id, false);
        assertAllocation(queryAllocations[4], 300, gaus[1].id, false);
        assertAllocation(queryAllocations[5], 500, gaus[0].id, false);
    }

//TODO can't update opportunity and payment allocations for the same opportunity (only substantial updates)
    @isTest
    private static void validateOverlappingChanges() {

    }

    // Helpers
    ////////////
    private static void makePayments(Decimal totalAmount, Integer numberOfPayments) {
        defaultGau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = 'Default GAU' LIMIT 1];
        opportunity = [SELECT Id, Name, Amount FROM Opportunity LIMIT 1];

        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(
            new Allocations_Settings__c(
                Payment_Allocations_Enabled__c = true,
                Default_Allocations_Enabled__c = true,
                Default__c = defaultGau.Id
            )
        );

        for (Integer i=0; i<numberOfPayments; i++) {
            payments.add(new npe01__OppPayment__c(
                npe01__Payment_Amount__c = totalAmount / numberOfPayments, 
                npe01__Opportunity__c = opportunity.Id,
                npe01__Payment_Date__c = System.today()
            ));
        }
        insert payments;
    } 

    private static void makeGAUs(Integer numberOfGAUs) {
        for (Integer i=0; i<numberOfGAUs; i++) {
            gaus.add(new General_Accounting_Unit__c(Name='GAU' + i));
        }
        insert gaus;
    }

    private static void assertAllocation(Allocation__c allocation, Decimal amount, Id gau, Boolean isOpportunityAllocation) {
        System.assertEquals(amount, allocation.Amount__c, 'Allocation amount mismatch: ' + allocation);
        System.assertEquals(gau, allocation.General_Accounting_Unit__c, 'Allocation GAU mismatch: ' + allocation);
        System.assertEquals(isOpportunityAllocation, allocation.Opportunity__c != null, 'Allocation type mismatch: ' + allocation);
    }
    /*********************************************************************************************************
    * @description Get all Allocations ordered by Amount
    * @return List<Allocation__c> A list of all Allocations 
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByAmount() {
        return Database.query(getAllocationsQuery().build() + ' ORDER BY Payment__c, Amount__c');
    }

    /*********************************************************************************************************
    * @description Get all Allocations ordered by Percent
    * @return List<Allocation__c> A list of all Allocations 
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByPercent() {
        return Database.query(getAllocationsQuery().build() + ' ORDER BY Payment__c, Percent__c');
    }

    /*********************************************************************************************************
    * @description Build query to retrieve all Allocations
    * @return UTIL_Query Allocation SOQL
    **********************************************************************************************************/
    private static UTIL_Query getAllocationsQuery() {
        return new UTIL_Query()
            .withSelectFields(new String[]{
                'Opportunity__c',
                'Payment__c',
                'General_Accounting_Unit__c', 
                'General_Accounting_Unit__r.Name', 
                'Amount__c', 
                'Percent__c' 
            })
            .withFrom('Allocation__c');
    }
}