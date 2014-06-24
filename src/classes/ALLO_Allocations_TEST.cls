/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Tests specific to Opportunity Allocations. 
*/

@isTest
private with sharing class ALLO_Allocations_TEST {
    
    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = 'oppAmountIncrease';
    private static Allocations_Settings__c settings;

    @isTest
    static void codeCoverage() {
        if (strTestOnly != '*' && strTestOnly != 'codeCoverage') return;
        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        Allocation__c allo = new Allocation__c(Opportunity__c=opp.id);
        insert allo;

        list<Trigger_Handler__c> th = [select Asynchronous__c, Class__c, Load_Order__c, Object__c, Active__c, 
                Trigger_Action__c from Trigger_Handler__c order by Load_Order__c];
        system.debug('lookhere!' + th);
    }
    /*
    only percentage defined, amount is calculated
    percentage changed, amount is recalculated
    enabled default allocation:
        allocations must equal 100% or total
    disabled default allocation
        allocations must equal less than 100% or total 

    Opportunity cases: 
        increase amount, default GAU is adjusted
        decrease amount by an amount that doesn't bork: everything is readjusted
        decrease amount by too much: exception thrown
    */

    @isTest
    static void oppAmountIncrease() {
        if (strTestOnly != '*' && strTestOnly != 'oppAmountIncrease') return;
        settings = UTIL_CustomSettingsFacade.getAllocationsSettings();
        settings.Allocations_Enabled__c = true;
        settings.Default_Allocations_Enabled__c = false;
        update settings;

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert gau;
        Allocation__c percentAllo = new Allocation__c(Opportunity__c=opp.id, Percent__c = 50, General_Accounting_Unit__c = gau.id);
        insert percentAllo;
        Allocation__c amountAllo = new Allocation__c(Opportunity__c=opp.id, Amount__c = 4, General_Accounting_Unit__c = gau.id);
        insert amountAllo;

        list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c ORDER BY Percent__c];
        system.assertEquals(50, queryAllo[1].Percent__c, 'The amount of the percentage allocation should be calculated based on the Opportunity amount.');
        system.assertEquals(4, queryAllo[1].Amount__c, 'The amount of the percentage allocation should be calculated based on the Opportunity amount.');


        opp.Amount = 10;
        update opp;

        queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c ORDER BY Percent__c];
        system.assertEquals(5, queryAllo[0].Amount__c, 'The amount of the percentage allocation should increase proportionately with the Opportunity.');

    }
}