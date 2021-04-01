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
/**
* @description Used to mock invalid elevate capture group requests for unit tests
 */
@isTest
public class ElevateCaptureGroupServiceInvalidRequest extends ElevateCaptureGroupService {

    public override ElevateAuthorizedGift addToCaptureGroup(ElevateTokenizedGift tokenizedGift, String groupId) {
        ElevateAuthorizedGiftResponse giftResponse = addCaptureGroupErrorMessage();

        return new ElevateAuthorizedGift(tokenizedGift, giftResponse);
    }

    public override ElevateCaptureGroup createCaptureGroup() {
        ElevateCaptureGroupResponse captureGroupResponse = createCaptureGroupErrorMessage();

        ElevateCaptureGroup captureGroup = new ElevateCaptureGroup();
        captureGroup.captureGroupResponse = captureGroupResponse;

        return captureGroup;
    }

    public ElevateAuthorizedGiftResponse addCaptureGroupErrorMessage() {
        return (ElevateAuthorizedGiftResponse)JSON.deserialize('{\n' +
                '  "errors": [\n' +
                '    {\n' +
                '      "message": "authorize failed",\n' +
                '      "localizedPaymentsMessage": "Bad Request",\n' +
                '      "detailedMessage": "create failed"\n' +
                '    }\n' +
                '  ]\n' +
                '}', ElevateAuthorizedGiftResponse.class);
    }

    public ElevateCaptureGroupResponse createCaptureGroupErrorMessage() {
        return (ElevateCaptureGroupResponse)JSON.deserialize('{\n' +
                '  "errors": [\n' +
                '    {\n' +
                '      "message": "create failed",\n' +
                '      "localizedPaymentsMessage": "Bad Request",\n' +
                '      "detailedMessage": "create failed"\n' +
                '    }\n' +
                '  ]\n' +
                '}', ElevateCaptureGroupResponse.class);
    }

}