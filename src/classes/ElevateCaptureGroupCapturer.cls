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
* @date 2021
* @group Gift Entry
* @group-content
* @description Makes the callout to the Elevate endpoint for capturing
* payments in Elevate Batches.
*/
public without sharing class ElevateCaptureGroupCapturer implements Finalizer, Queueable {

    private NPSP_Batch giftBatch;
    private Set<Id> captureGroupIds;
    private final Integer maxCaptureCountPerQueueable;
    private List<ElevateCaptureGroupResponse> captureGroupResponses;

    public ElevateCaptureGroupCapturer(Id giftBatchId) {
        // giftBatch = new NPSP_Batch(giftBatchId);

        // TODO: retrieve capture group ids from batch entity
    }

    public void execute(QueueableContext context) {
        // captureGroupResponses = new List<ElevateCaptureGroupResponse>();

        // for (String captureGroupId : captureGroupIds) {
        //     HttpRequest captureRequest = captureRequest(captureGroupId);
        //     UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest();
        //     ElevateCaptureGroupResponse captureGroupResponse =
        //         (ElevateCaptureGroupResponse) JSON.deserialize(response.body, ElevateCaptureGroupResponse.class);

        //     captureGroupResponses.add(captureGroupResponse);
        // }
    }

    public execute(FinalizerContext context) {
        // TODO: Update the relevant gift records with success/fail info from captureGroupResponse 
    }

    private HttpRequest captureRequest(String groupId) {
        return new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withCaptureGroupId(groupId)
            .withEndpoint(PS_Request.ElevateEndpoint.CHARGE_CAPTURE_GROUP)
            .build();
    }
}
