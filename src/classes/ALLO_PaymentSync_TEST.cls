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
* @date 2014
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests specific to Allocations trigger based functionality. 
*/
@isTest
private with sharing  class ALLO_PaymentSync_TEST {
//TODO null and zero amounts for both opps and payments
//TODO negative amounts
//TODO over and underscheduled

    /*******************************************************************************************************
    * @description When changing the amount of a Payment with Allocations: 
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust 
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an 
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    static testMethod void syncPaymentsToOpportunities() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='default GAU');
        insert defaultGau;

        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(
            new Allocations_Settings__c(
                Payment_Allocations_Enabled__c = true,
                Default_Allocations_Enabled__c = true,
                Default__c = defaultGau.Id
            )
        );

        Account acc = new Account(Name='Account-syncPaymentsToOpportunities');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Opp-syncPaymentsToOpportunities', 
            Amount = 10, 
            AccountID = acc.id, 
            CloseDate = system.today(), 
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp;
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = 8, 
            npe01__Opportunity__c = opp.Id
        );
        insert pmt;

        list<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>();
        gaus.add(new General_Accounting_Unit__c(Name='GAU-syncPaymentsToOpportunities-1'));
        gaus.add(new General_Accounting_Unit__c(Name='GAU-syncPaymentsToOpportunities-2'));
        insert gaus;

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        Allocation__c percentAllo = new Allocation__c(Payment__c=pmt.id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Payment__c=pmt.id, Amount__c = 3, General_Accounting_Unit__c = gaus[1].id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount(opp.id);
        System.assertEquals(3, queryAllocations.size(), 'Three opportunity allocations should exist.');
    }

    /*******************************************************************************************************
    * @description When changing the Allocation amount of an Opportunity with Payments:
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust 
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an 
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    static testMethod void syncOpportunitiesToPayments() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='default GAU');
        insert defaultGau;

        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(
            new Allocations_Settings__c(
                Payment_Allocations_Enabled__c = true,
                Default_Allocations_Enabled__c = true,
                Default__c = defaultGau.Id
            )
        );

        Account acc = new Account(Name='Account-syncPaymentsToOpportunities');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Opp-syncPaymentsToOpportunities', 
            Amount = 10, 
            AccountID = acc.id, 
            CloseDate = system.today(), 
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp;
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = 8, 
            npe01__Opportunity__c = opp.Id
        );
        insert pmt;

        list<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>();
        gaus.add(new General_Accounting_Unit__c(Name='GAU-syncPaymentsToOpportunities-1'));
        gaus.add(new General_Accounting_Unit__c(Name='GAU-syncPaymentsToOpportunities-2'));
        insert gaus;

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        Allocation__c percentAllo = new Allocation__c(Payment__c=pmt.id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Payment__c=pmt.id, Amount__c = 3, General_Accounting_Unit__c = gaus[1].id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount(opp.id);
        System.assertEquals(3, queryAllocations.size(), 'Three payment allocations should exist.');
    }


    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Get all Allocations ordered by Amount
    * @return List<Allocation__c> A list of all Allocations 
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByAmount() {
        return Database.query(getAllocationsQuery().build() + ' ORDER BY Amount__c');
    }

    /*********************************************************************************************************
    * @description Get all Allocations ordered by Percent
    * @return List<Allocation__c> A list of all Allocations 
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByPercent() {
        return Database.query(getAllocationsQuery().build() + ' ORDER BY Percent__c');
    }

    /*********************************************************************************************************
    * @description Get Allocations for the Opportunity ordered by Amount
    * @param oppId An Opportunity Id
    * @return List<Allocation__c> A list of Allocations assigned to the Opportunity
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByAmount(Id oppId) {
        return Database.query(getAllocationsQuery(oppId).build() + ' ORDER BY Amount__c');
    }

    /*********************************************************************************************************
    * @description Get Allocations for the Opportunity ordered by Percent
    * @param oppId An Opportunity Id
    * @return List<Allocation__c> A list of Allocations assigned to the Opportunity
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByPercent(Id oppId) {
        return Database.query(getAllocationsQuery(oppId).build() + ' ORDER BY Percent__c');
    }

    /*********************************************************************************************************
    * @description Build query to retrieve Allocations for the Opportunity
    * @return UTIL_Query Allocation SOQL
    **********************************************************************************************************/
    private static UTIL_Query getAllocationsQuery(Id oppId) {
        return getAllocationsQuery()
            .withWhere(String.format('Opportunity__c = \'\'{0}\'\'', new String[] { oppId }));
    }

    /*********************************************************************************************************
    * @description Build query to retrieve all Allocations
    * @return UTIL_Query Allocation SOQL
    **********************************************************************************************************/
    private static UTIL_Query getAllocationsQuery() {
        return new UTIL_Query()
            .withSelectFields(new String[]{
                'General_Accounting_Unit__c', 
                'General_Accounting_Unit__r.Name', 
                'Amount__c', 
                'Percent__c' 
            })
            .withFrom('Allocation__c');
    }
}