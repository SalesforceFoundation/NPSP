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
* @group General Accounting Units
* @description Test class for the GAU_TDTM class
*/
@isTest
private with sharing class GAU_TDTM_TEST {

    /*******************************************************************************************************
     * @description Confirms GAUs are dispatched to integration gateway on before delete
     */
    @isTest
    private static void shouldDispatchGAUsToIntegrationGatewayOnBeforeDelete() {
        List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c> {
            new General_Accounting_Unit__c(Name = 'TEST_GAU'),
            new General_Accounting_Unit__c(Name = 'TEST_GAU1'),
            new General_Accounting_Unit__c(Name = 'TEST_GAU2')
        };

        UTIL_UnitTestData_TEST.setMockIds(gaus);

        GAU_TDTM tdtm = new GAU_TDTM();
        UTIL_IntegrationGateway_TEST.Stub gatewayStub = new UTIL_IntegrationGateway_TEST.Stub();
        tdtm.integrationGateway = (UTIL_IntegrationGateway) Test.createStub(UTIL_IntegrationGateway.class, gatewayStub);

        Test.startTest();
        tdtm.run(
            null,
            gaus,
            TDTM_Runnable.Action.BeforeDelete,
            General_Accounting_Unit__c.SObjectType.getDescribe()
        );
        Test.stopTest();

        System.assert(gatewayStub.paramsByMethodName.containsKey('handleBeforeDelete'),
            'handleBeforeDelete should have been called on the integration gateway');

        Map<String, Object> paramsForMethod = gatewayStub.paramsByMethodName.get('handleBeforeDelete');

        System.assertEquals(gaus, paramsForMethod.get('triggerOld'),
            'The triggerOld parameter should contain the data from the oldList parameter');
    }

    /*******************************************************************************************************
     * @description Confirms GAUs can be deleted (mainly to get coverage for the trigger)
     */
    @isTest
    private static void shouldDeleteGAUs() {
        List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c> {
            new General_Accounting_Unit__c(Name = 'TEST_GAU'),
            new General_Accounting_Unit__c(Name = 'TEST_GAU1'),
            new General_Accounting_Unit__c(Name = 'TEST_GAU2')
        };

        insert gaus;

        Test.startTest();
        delete gaus;
        Test.stopTest();

        System.assert([SELECT Id FROM General_Accounting_Unit__c].isEmpty(), 'The GAUs should have been deleted');
    }
}
