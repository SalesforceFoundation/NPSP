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
public with sharing class ElevateAuthorizedGift {
    @AuraEnabled public ElevateTokenizedGift tokenizedGift;
    @AuraEnabled public String paymentId;
    @AuraEnabled public DateTime authExpiration;
    @AuraEnabled public ElevateTransactionStatus status;
    @AuraEnabled public String gatewayTransactionId;
    @AuraEnabled public String paymentMethod;
    @AuraEnabled public String originalTransactionId;
    @AuraEnabled public String groupId;

    public ElevateAuthorizedGift(ElevateTokenizedGift tokenizedGift,
                                 ElevateAuthorizedGiftResponse authorizedGiftResponse) {
        this.tokenizedGift = tokenizedGift;
        this.paymentId = authorizedGiftResponse.paymentId();
        this.authExpiration = authorizedGiftResponse.authExpiration();
        this.status = authorizedGiftResponse.status();
        this.gatewayTransactionId = authorizedGiftResponse.gatewayTransactionId();
        this.paymentMethod = authorizedGiftResponse.paymentMethod();
        this.groupId = authorizedGiftResponse.groupId();
        this.originalTransactionId = authorizedGiftResponse.originalTransactionId();
    }

    public String groupId() {
        return this.groupId;
    }

    public String paymentId() {
        return this.paymentId;
    }

    public DateTime authExpiration() {
        return this.authExpiration;
    }

    public ElevateTransactionStatus status() {
        return this.status;
    }

    public String gatewayTransactionId() {
        return this.gatewayTransactionId;
    }

    public String paymentMethod() {
        return this.paymentMethod;
    }

    public String originalTransactionId() {
        return this.originalTransactionId;
    }
}