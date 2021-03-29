/*
 * Copyright (c) 2020, Salesforce.org
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
public class CreditCardCaptureGroupMock implements StubProvider {

    public static final String INVALID_PARAMETER = 'invalid-parameter';
    public static final String INVALID_GROUP_ID = 'invalid-group-id';
    private static final String DUMMY_GROUP_ID = 'gp-12345';

    private String requestBodyParameter;
    private String groupId;
    private ElevateTokenizedGift tokenizedGift;

    public CreditCardCaptureGroupMock withInvalidRequestBody() {
        requestBodyParameter = INVALID_PARAMETER;
        return this;
    }

    public CreditCardCaptureGroupMock withInvalidGroupId() {
        groupId = INVALID_GROUP_ID;
        return this;
    }

    public CreditCardCaptureGroupMock withElevateTokenizedGift(ElevateTokenizedGift tokenizedGift) {
        this.tokenizedGift = tokenizedGift;
        return this;
    }

    public String groupId() {
        if (String.isBlank(groupId)) {
            return DUMMY_GROUP_ID;
        } else {
            return groupId;
        }
    }

    private HttpRequest mockCreateGroupRequest() {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withEndpoint(PS_Request.ElevateEndpoint.CREATE_CAPTURE_GROUP)
                .withBody('{merchantId:' + requestBodyParameter + '}')
                .build();
    }

    private HttpRequest mockAddToGroupRequest() {
        String requestBody = getMockRequestBody();

        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withCaptureGroupId(groupId)
                .withEndpoint(PS_Request.ElevateEndpoint.ADD_TO_CAPTURE_GROUP)
                .withBody(requestBody)
                .build();
    }

    private String getMockRequestBody() {
        return '{paymentMethodToken:' + requestBodyParameter + '}';
    }

    public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

        switch on (stubbedMethodName) {
            when 'create' {
                return new UTIL_Http.RequestService().sendRequest(mockCreateGroupRequest());
            }
        }
        return null;
    }

}