/*
    Copyright (c) 2021, Salesforce.org
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
* @date 2021
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests for AllocationParent class.
*/
@IsTest
public with sharing class AllocationParent_TEST {

    private static Campaign insertCampaign() {
        Campaign testCampaign = new Campaign(
            Name='fooCampaign'
        );
        insert testCampaign;
        return testCampaign;
    }

    private static Opportunity insertOpportunity(Integer amount) {
        Opportunity testOpp = new Opportunity(
            Name='fooOpp',
            Amount = amount,
            CloseDate=system.today(),
            StageName=UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert testOpp;
        return testOpp;
    }

    private static npe01__OppPayment__c insertPayment(Integer amount) {
        Opportunity testOpp = insertOpportunity(10);
        npe01__OppPayment__c payment = new npe01__OppPayment__c(
            npe01__Opportunity__c = testOpp.Id,
            npe01__Payment_Amount__c = amount
        );
        insert payment;
        return payment;
    }

    @IsTest
    static void shouldReturnCorrectDescribeInfoForCampaign() {
        Campaign testCampaign = insertCampaign();
        AllocationParent parent = new AllocationParent(testCampaign.id);

        DescribeSObjectResult describe = Campaign.SObjectType.getDescribe();
        System.assertEquals(describe.getKeyPrefix(), parent.getKeyPrefix());
        System.assertEquals(describe.getName(), parent.getObjectApiName());
        System.assertEquals(describe.getLabelPlural(), parent.getObjectLabelPlural());
    }

    @IsTest
    static void shouldReturnCorrectRecordName() {
        Campaign testCampaign = insertCampaign();
        AllocationParent parent = new AllocationParent(testCampaign.id);

        System.assertEquals('fooCampaign', parent.getRecordName());
    }

    @IsTest
    static void shouldReturnCorrectLookupApiName() {
        Campaign testCampaign = insertCampaign();
        AllocationParent parentCampaign = new AllocationParent(testCampaign.id);

        System.assertEquals(
            String.valueOf(Allocation__c.SObjectType.fields.Campaign__c),
            parentCampaign.getAllocationLookupApiName());

        Opportunity testOpportunity = insertOpportunity(10);
        AllocationParent parentOpportunity = new AllocationParent(testOpportunity.id);

        System.assertEquals(
            String.valueOf(Allocation__c.SObjectType.fields.Opportunity__c),
            parentOpportunity.getAllocationLookupApiName());
    }

    @IsTest
    static void shouldReturnTrueForParentOpportunity() {
        Opportunity testOpportunity = insertOpportunity(10);
        AllocationParent parentOpportunity = new AllocationParent(testOpportunity.id);

        System.assert(parentOpportunity.isOpportunity());
    }

    @IsTest
    static void shouldReturnTrueForParentPayment() {
        npe01__OppPayment__c testPayment = insertPayment(10);
        AllocationParent parentPayment = new AllocationParent(testPayment.id);

        System.assert(parentPayment.isPayment());
    }

    @IsTest
    static void shouldReturnTrueIfParentIsOpportunityOrPayment() {
        npe01__OppPayment__c testPayment = insertPayment(100);
        AllocationParent parentPayment = new AllocationParent(testPayment.id);

        System.assert(parentPayment.hasAmountField());

        Opportunity testOpportunity = insertOpportunity(10);
        AllocationParent parentOpportunity = new AllocationParent(testOpportunity.id);

        System.assert(parentOpportunity.hasAmountField());
    }

    @IsTest
    static void shouldReturnTrueForOpportunityWithZeroAmount() {
        Opportunity testOpportunity = insertOpportunity(0);
        AllocationParent parentOpportunity = new AllocationParent(testOpportunity.id);

        System.assert(parentOpportunity.isOpportunityWithZeroAmount());
    }

    @IsTest
    static void shouldReturnCorrectAmount() {
        npe01__OppPayment__c testPayment = insertPayment(100);
        AllocationParent parentPayment = new AllocationParent(testPayment.id);

        System.assertEquals(100, parentPayment.getAmount());

        Opportunity testOpportunity = insertOpportunity(5);
        AllocationParent parentOpportunity = new AllocationParent(testOpportunity.id);

        System.assertEquals(5, parentOpportunity.getAmount());
    }
}
