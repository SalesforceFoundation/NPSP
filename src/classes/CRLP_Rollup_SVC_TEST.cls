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
* @group Customizable Rollups Operations Services
* @description Unit Test for the Rollup Operation Services Classes
*/
@isTest
private class CRLP_Rollup_SVC_TEST {

    static testMethod void test_get_batch_sizes() {
        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                        npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_LDV__c = 200,
                        Rollups_LDV_Batch_Size__c = 200,
                        Rollups_Account_Batch_Size__c = 20,
                        Rollups_Contact_Batch_Size__c = 20
                ));

        system.assertEquals(20, CRLP_Rollup_SVC.getBatchSize(Account.SObjectType));
        system.assertEquals(20, CRLP_Rollup_SVC.getBatchSize(Contact.SObjectType));
        system.assertEquals(200, CRLP_Rollup_SVC.getLDVBatchSize(General_Accounting_Unit__c.SObjectType));
        system.assertEquals(200, CRLP_Rollup_SVC.getMaxRelatedOppsForNonLDVMode());
        system.assertEquals(true, CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled);
        system.assertNotEquals(null, CRLP_Rollup_SVC.getSObjectFieldDescribe('Account', 'Name'));
    }
}