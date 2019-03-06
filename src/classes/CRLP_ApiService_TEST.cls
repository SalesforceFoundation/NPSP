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
* @group API
* @description Unit Tests for the Customizable Rollups Api Service class
*/
@IsTest(IsParallel=true)
private class CRLP_ApiService_TEST {

    @IsTest
    static void validateRollupTypeConversion() {
        mockRollupTypes();
        CRLP_ApiService crlpApiSvc = new CRLP_ApiService();
        for (CRLP_RollupProcessingOptions.RollupType crlpType : CRLP_RollupProcessingOptions.RollupType.values()) {
            String crlpTypeString = crlpType.name();
            List<CRLP_Rollup> rollups = crlpApiSvc.getRollupDefsForRollupType(crlpTypeString);
            System.assert(!rollups.isEmpty(), 'The collection of returned rollups should not be empty for ' + crlpTypeString);
        }
    }

    static void mockRollupTypes() {
        List<Rollup__mdt> mockedRollupDefs = new List<Rollup__mdt>{
                new Rollup__mdt(
                        MasterLabel = 'Account Hard Credit',
                        Summary_Field__c = 'npo02__TotalOppAmount__c',
                        Operation__c = CRLP_Operation.RollupType.Sum.name(),
                        Detail_Object__c = 'Opportunity',
                        Detail_Field__c = 'Amount',
                        Amount_Object__c = 'Opportunity',
                        Amount_Field__c = 'Amount',
                        Date_Object__c = 'Opportunity',
                        Date_Field__c = 'CloseDate',
                        Active__c = True
                ),
                new Rollup__mdt(
                        MasterLabel = 'Contact Hard Credit',
                        Summary_Object__c = 'Contact',
                        Summary_Field__c = 'npo02__TotalOppAmount__c',
                        Operation__c = CRLP_Operation.RollupType.Sum.name(),
                        Detail_Object__c = 'Opportunity',
                        Detail_Field__c = 'Amount',
                        Amount_Object__c = 'Opportunity',
                        Amount_Field__c = 'Amount',
                        Date_Object__c = 'Opportunity',
                        Date_Field__c = 'CloseDate',
                        Active__c = True
                ),
                new Rollup__mdt(
                        MasterLabel = 'Contact Soft Credit',
                        Summary_Object__c = 'Contact',
                        Summary_Field__c = 'npo02__TotalOppAmount__c',
                        Operation__c = CRLP_Operation.RollupType.Sum.name(),
                        Detail_Object__c = Partial_Soft_Credit__c.SObjectType.getDescribe().getName(),
                        Detail_Field__c = Partial_Soft_Credit__c.Amount__c.getDescribe().getName(),
                        Amount_Object__c = Partial_Soft_Credit__c.SObjectType.getDescribe().getName(),
                        Amount_Field__c = Partial_Soft_Credit__c.Amount__c.getDescribe().getName(),
                        Date_Object__c = 'Opportunity',
                        Date_Field__c = 'CloseDate',
                        Active__c = True
                ),
                new Rollup__mdt(
                        MasterLabel = 'Account Soft Credit',
                        Summary_Object__c = 'Account',
                        Summary_Field__c = 'npo02__TotalOppAmount__c',
                        Operation__c = CRLP_Operation.RollupType.Sum.name(),
                        Detail_Object__c = Partial_Soft_Credit__c.SObjectType.getDescribe().getName(),
                        Detail_Field__c = Partial_Soft_Credit__c.Amount__c.getDescribe().getName(),
                        Amount_Object__c = Partial_Soft_Credit__c.SObjectType.getDescribe().getName(),
                        Amount_Field__c = Partial_Soft_Credit__c.Amount__c.getDescribe().getName(),
                        Date_Object__c = 'Opportunity',
                        Date_Field__c = 'CloseDate',
                        Active__c = True
                ),
                new Rollup__mdt(
                        MasterLabel = 'Account Contact Soft Credit',
                        Summary_Object__c = 'Account',
                        Summary_Field__c = 'npo02__TotalOppAmount__c',
                        Operation__c = CRLP_Operation.RollupType.Sum.name(),
                        Detail_Object__c = Partial_Soft_Credit__c.SObjectType.getDescribe().getName(),
                        Detail_Field__c = Partial_Soft_Credit__c.Amount__c.getDescribe().getName(),
                        Amount_Object__c = Partial_Soft_Credit__c.SObjectType.getDescribe().getName(),
                        Amount_Field__c = Partial_Soft_Credit__c.Amount__c.getDescribe().getName(),
                        Date_Object__c = 'Opportunity',
                        Date_Field__c = 'CloseDate',
                        Active__c = True
                ),
                new Rollup__mdt(
                        MasterLabel = 'GAU',
                        Summary_Object__c = General_Accounting_Unit__c.SObjectType.getDescribe().getName(),
                        Summary_Field__c = General_Accounting_Unit__c.Total_Allocations__c.getDescribe().getName(),
                        Operation__c = CRLP_Operation.RollupType.Sum.name(),
                        Detail_Object__c = Allocation__c.SObjectType.getDescribe().getName(),
                        Detail_Field__c = Allocation__c.Amount__c.getDescribe().getName(),
                        Amount_Object__c = Allocation__c.SObjectType.getDescribe().getName(),
                        Amount_Field__c = Allocation__c.Amount__c.getDescribe().getName(),
                        Date_Object__c = 'Opportunity',
                        Date_Field__c = 'CloseDate',
                        Active__c = True
                ),
                new Rollup__mdt(
                        MasterLabel = 'Recurring Donation',
                        Summary_Object__c = npe03__Recurring_Donation__c.SObjectType.getDescribe().getName(),
                        Summary_Field__c = npe03__Recurring_Donation__c.npe03__Total_Paid_Installments__c.getDescribe().getName(),
                        Operation__c = CRLP_Operation.RollupType.Sum.name(),
                        Detail_Object__c = 'Opportunity',
                        Detail_Field__c = 'Amount',
                        Amount_Object__c = 'Opportunity',
                        Amount_Field__c = 'Amount',
                        Date_Object__c = 'Opportunity',
                        Date_Field__c = 'CloseDate',
                        Active__c = True
                )
        };
        CRLP_Rollup_SEL.cachedRollups = mockedRollupDefs;
    }
}