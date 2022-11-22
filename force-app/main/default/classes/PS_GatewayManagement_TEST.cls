/*
 * Copyright (c) 2020 Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */

@isTest
private with sharing class PS_GatewayManagement_TEST {
    public static final String TEST_MERCHANT_ID = 'abc123-xyz456';
    public static final String TEST_GATEWAY_ID = 'def123-ghi456';
    public static final Boolean TEST_GATEWAY_ASSIGNMENT_ENABLED = true;

    @isTest
    static void shouldUpdateGatewayId() {
        Test.startTest();

        PS_GatewayManagement.setGatewayId(TEST_GATEWAY_ID);

        Test.stopTest();

        System.assertEquals(TEST_GATEWAY_ID, new PS_IntegrationServiceConfig.Service().getGatewayIds(), 'The gateway ' +
                'id stored in CRM should be successfully updated to the new value provided.');
    }

    @isTest
    static void shouldRetrieveCorrectGatewayId() {
        Test.startTest();

        PS_GatewayManagement.setGatewayId(TEST_GATEWAY_ID);

        Test.stopTest();

        System.assertEquals(TEST_GATEWAY_ID, PS_GatewayManagement.getGatewayIdFromConfig(), 'When this method is ' +
                'invoked, the gateway Id stored in CRM should be the gateway returned.');
    }
    
    @isTest
    static void shouldRetrieveGatewayAssignmentEnabled() {
        Test.startTest();

        PS_GatewayManagement.setGatewayAssignmentEnabled(TEST_GATEWAY_ASSIGNMENT_ENABLED);

        Test.stopTest();

        System.assertEquals(TEST_GATEWAY_ASSIGNMENT_ENABLED, PS_GatewayManagement.isGatewayAssignmentEnabled(), 'When this method is ' +
                'invoked, the gateway assignment enabled status stored in CRM should be the gateway assignment enabled status returned.');
    }

    @isTest
    private static void shouldReturnAsAdmin() {
        User adminUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);

        System.runAs(adminUser) {
            System.assertEquals(true, PS_GatewayManagement.isSystemAdmin(), 'If the user has a system admin profile ' +
                'with the correct admin permissions assigned the method should correctly identify that the user ' +
                'has admin permissions.');
        }
    }

}