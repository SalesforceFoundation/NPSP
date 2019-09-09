/*
    Copyright (c) 2019 Salesforce.org
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
* @group Recurring Donations
* @description Enhanced Recurring Donations trigger handler tests
*
*/
@isTest
private with sharing class RD2_RecurringDonations_TEST {


    /****
    * @description Verifies integration dispatcher is called
    * when enhanced Recurring Donations are enabled
    */
    @isTest
    private static void shouldDispatchRDsToIntegrationGatewayOnBeforeDelete() {
        RD2_EnablementService.isEnhancementEnabled = true;

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c> {
            new RD2_TestRecurringDonationBuilder()
                .withAccount(UTIL_UnitTestData_TEST.mockId(Account.SObjectType))
                .withAmount(100)
                .withId(UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.SObjectType))
                .build()
        };

        RD2_RecurringDonations_TDTM triggerHandler = new RD2_RecurringDonations_TDTM();
        UTIL_IntegrationGateway_TEST.Stub gatewayStub = new UTIL_IntegrationGateway_TEST.Stub();
        triggerHandler.integrationGateway = (UTIL_IntegrationGateway) Test.createStub(UTIL_IntegrationGateway.class, gatewayStub);

        Test.startTest();
        triggerHandler.run(
            null,
            rds,
            TDTM_Runnable.Action.BeforeDelete,
            npe03__Recurring_Donation__c.SObjectType.getDescribe()
        );
        Test.stopTest();

        System.assert(gatewayStub.paramsByMethodName.containsKey('handleBeforeDelete'),
            'handleBeforeDelete should have been called on the integration gateway');

        Map<String, Object> paramsForMethod = gatewayStub.paramsByMethodName.get('handleBeforeDelete');

        System.assertEquals(rds, paramsForMethod.get('triggerOld'),
            'The triggerOld parameter should contain the data from the oldList parameter');
    }

}