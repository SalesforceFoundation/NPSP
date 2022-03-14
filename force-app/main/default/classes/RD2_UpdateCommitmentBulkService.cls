/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Recurring Donations
* @description Update Elevate Commitment In Bulk
*/
public with sharing class RD2_UpdateCommitmentBulkService {
    public static Integer apiCallOutCounter = 5;
    public static final Integer REQUEST_SIZE = 50;
   
    private ERR_LogService.Logger logger = new ERR_LogService.Logger(
        ERR_Handler_API.Context.Elevate,
        npe03__Recurring_Donation__c.SObjectType
    );

    private UTIL_Http.RequestService requestService {
        get {
            if (requestService == null) {
                requestService = new UTIL_Http.RequestService();
            }
            return requestService;
        }
        set;
    }

    private List<Commitment> commitments;

    public RD2_UpdateCommitmentBulkService withCommitments(List<npe03__Recurring_Donation__c> rds) {
        if (rds == null || rds.isEmpty()) {
            return this;
        }

        this.commitments = new List<Commitment>();
        for (npe03__Recurring_Donation__c rd : rds) {
            this.commitments.add(new Commitment(rd));
        }

        return this;
    }

    public void processCommitments() {
        if (this.commitments == null
            || !RD2_ElevateIntegrationService.isIntegrationEnabled()
            || this.commitments.isEmpty()
            || apiCallOutCounter == 0
        ) {
            this.logger.processErrors();
            return;
        }

        apiCallOutCounter--;

        RequestBody reqBody = new RequestBody();
        reqBody.commitments =  getCommitmentsToProcess();

        HttpRequest request = buildBulkStatusUpdateRequest(reqBody);
        UTIL_Http.Response response;
        try {
            response = requestService.sendRequest(request);
        } catch (Exception ex) {
            response = requestService.buildErrorResponse(ex);
        }

        processResponse(response);
        processCommitments();
    }

    private List<Commitment> getCommitmentsToProcess() {
        List<Commitment> toProcess = new List<Commitment>();

        for (Integer i = 0; i < REQUEST_SIZE; i++) {
            if (this.commitments.size() == 0) {
                break;
            }

            toProcess.add(this.commitments.remove(0));
        }
        return toProcess;
    }

    private HttpRequest buildBulkStatusUpdateRequest(RequestBody reqBody) {
        return new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_Request.ElevateEndpoint.COMMITMENT_UPDATE_BULK)
            .withRecommendedTimeout()
            .withBody(JSON.serialize(reqBody))
            .build();
    }

    private void processResponse(UTIL_Http.Response response) {
        if (isCommitmentSuccess(response)) {
            return;
        }

        this.logger.addError(
            null,
            response.getErrorMessages(),
            RD2_ElevateIntegrationService.LOG_TYPE_COMMITMENT_UPDATE_BULK
        );
    }

    private Boolean isCommitmentSuccess(UTIL_Http.Response response) {
        return response.statusCode == UTIL_Http.STATUS_CODE_CREATED
            || response.statusCode == UTIL_Http.STATUS_CODE_OK;
    }

    public class RequestBody {
        List<Commitment> commitments;
    }

    public class Commitment {
        String id;
        String status;
        String statusUpdateReason;

        public Commitment(npe03__Recurring_Donation__c rd) {
            id = rd.CommitmentId__c;
            status = rd.Status__c;
            statusUpdateReason = rd.ClosedReason__c;
        }
    }
}
