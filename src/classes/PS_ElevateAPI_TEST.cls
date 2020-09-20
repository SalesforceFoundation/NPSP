/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Elevate Payment Services
* @description Contains common Elevate payment services API tests
*/
@isTest
public with sharing class PS_ElevateAPI_TEST {
    public static final String COMMITMENT_ID = 'abcd-efgh-ijkl-mnop-qrst';

    /**
    * @description Verifees that the Endpoint is set correctly for Cancel Commitment callout
    */
    @isTest
    private static void shouldCreateHttpRequestWhenEndpointIsCommitmentCancel() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        Test.startTest();
        HttpRequest request = new PS_ElevateAPI.RequestBuilder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_ElevateAPI.ElevateEndpoint.COMMITMENT_CANCEL)
            .withCommitmentId(COMMITMENT_ID)
            .build();
        Test.stopTest();

        String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl
            + '/v1/payments/verified/commitments/'
            + COMMITMENT_ID
            + '/cancel';

        System.assertEquals(expectedEndpoint, request.getEndpoint(),
            'Endpoint value should match');
        System.assertEquals(UTIL_Http.Method.POST.name(), request.getMethod(),
            'The request method should be POST');
        System.assertEquals(UserInfo.getUserName(), request.getHeader(PS_IntegrationServiceConfig.SFDO_USERNAME),
            'User name should be specified in the request header');
    }

}
