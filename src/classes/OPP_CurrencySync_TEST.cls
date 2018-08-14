/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Customizable Rollups Operations Services
* @description Unit Test for the Opportunity/Payment to Account Rollups
*/
@isTest
private class OPP_CurrencySync_TEST {

    /**
     * @description Test Setup: Insert an Account. The Opportunity data has to
     * be created in the actual unit test to allow for the trigger test to run
     */
    @isTest
    private static void testCurrencyCodeSync() {
        if (UserInfo.isMultiCurrencyOrganization()) {
            SObjectField oppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
            if (OppCurrencyField != null) {

                // WARNING: lots of funkiness ahead so this will COMPILE in non-multi-currency orgs

                List<Schema.PicklistEntry> currencies = oppCurrencyField.getDescribe().getPicklistValues();
                if (currencies.size() > 1) {

                    String curr1 = currencies[0].value;
                    String curr2 = currencies[1].value;

                    // Insert Account, Contact, Opp
                    Account acc1 = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, CAO_Constants.HH_ACCOUNT_TYPE)[0];
                    insert acc1;
                    Contact con1 = UTIL_UnitTestData_TEST.getContact();
                    insert con1;
                    Opportunity opp1 = new Opportunity(
                            Amount = 5,
                            StageName = 'Closed Won',
                            AccountId = acc1.Id,
                            CloseDate = System.today(),
                            Name = 'abc'
                    );
                    opp1.put('CurrencyIsoCode', curr1);
                    insert opp1;

                    // Insert PSC
                    Partial_Soft_Credit__c psc = new Partial_Soft_Credit__c(
                            Contact__c = con1.Id,
                            Amount__c = 1,
                            Opportunity__c = opp1.Id
                    );
                    insert psc;

                    // Insert ASC
                    Account_Soft_Credit__c accSC = new Account_Soft_Credit__c(
                            Account__c = acc1.Id,
                            Amount__c = 1,
                            Opportunity__c = opp1.Id
                    );
                    insert accSC;

                    // Currency should be inherited from Opportunity
                    String pscCurrencyQuery = 'SELECT Id, CurrencyIsoCode FROM Partial_Soft_Credit__c LIMIT 1';
                    String accSCCurrencyQuery = 'SELECT Id, CurrencyIsoCode FROM Account_Soft_Credit__c LIMIT 1';
                    psc = Database.query(pscCurrencyQuery);
                    accSC = Database.query(accSCCurrencyQuery);
                    System.assertEquals(curr1, psc.get('CurrencyIsoCode'), 'PSC Currency Code should be ' + curr1 + ', inherited from its Opportunity.');
                    System.assertEquals(curr1, accSC.get('CurrencyIsoCode'), 'Account Soft Credit Currency Code should be ' + curr1 + ', inherited from its Opportunity.');

                    // Reset blockers
                    PSC_PartialSoftCredit_TDTM.blockCurrencyChange = true;
                    OPP_AccountSoftCredit_TDTM.blockCurrencyChange = true;

                    // Currency Update from Opportunity should be inherited
                    opp1.put('CurrencyIsoCode', curr2);
                    update opp1;
                    psc = Database.query(pscCurrencyQuery);
                    accSC = Database.query(accSCCurrencyQuery);
                    System.assertEquals(curr2, psc.get('CurrencyIsoCode'), 'PSC Currency Code should be ' + curr2 + ', inherited change from its Opportunity.');
                    System.assertEquals(curr2, accSC.get('CurrencyIsoCode'), 'Account Soft Credit Currency Code should be ' + curr2 + ', inherited change from its Opportunity.');

                    // Reset blockers
                    PSC_PartialSoftCredit_TDTM.blockCurrencyChange = true;
                    OPP_AccountSoftCredit_TDTM.blockCurrencyChange = true;

                    // Currency update directly to PSC/ASC should be blocked
                    String err = Label.pscManageSoftCreditsCantChangeCurrency;
                    try {
                        psc.put('CurrencyIsoCode', curr1);
                        update psc;
                    } catch (Exception ex) {
                        System.assert(ex.getMessage().contains(err));
                    }

                    try {
                        accSC.put('CurrencyIsoCode', curr1);
                        update accSC;
                    } catch (Exception ex) {
                        System.assert(ex.getMessage().contains(err));
                    }
                }
            }
        } else {
            return;
        }
    }
}