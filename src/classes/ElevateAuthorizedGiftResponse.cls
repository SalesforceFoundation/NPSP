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
public with sharing class ElevateAuthorizedGiftResponse {
    @TestVisible private Body body;
    private Integer statusCode;
    private List<Errors> errors;

    @TestVisible private class Body {
        @TestVisible private String id;
        @TestVisible private DateTime authExpiresAt;
        @TestVisible private ElevateTransactionStatus status;
        @TestVisible private String gatewayTransactionId;
        @TestVisible private String paymentType;
        @TestVisible private String originalTransactionId;
        @TestVisible private String batchId;
        @TestVisible private String declineReason;
    }

    public class Errors {
        public String message;
        public String failure_reason;
    }

    public String paymentId() {
        return body?.id;
    }

    public DateTime authExpiration() {
        return this.body?.authExpiresAt;
    }

    public ElevateTransactionStatus status() {
        return body?.status;
    }

    public String declineReason() {
        return body?.declineReason;
    }

    public List<Errors> errors() {
        return errors;
    }

    public String gatewayTransactionId() {
        return this.body?.gatewayTransactionId;
    }

    public String paymentMethod() {
        return this.body?.paymentType;
    }

    public String originalTransactionId() {
        return this.body?.originalTransactionId;
    }

    public String groupId() {
        return this.body?.batchId;
    }

}