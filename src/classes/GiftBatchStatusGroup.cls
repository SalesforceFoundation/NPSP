/*
    Copyright (c) 2021 Salesforce.org
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
* @description Value object for Gift Batch Status Groups
*/
public inherited sharing class GiftBatchStatusGroup {
    final private String status;
    final private String paymentStatus;    
    private Integer recordCount;

    public GiftBatchStatusGroup(AggregateResultProxy result) {
        Map<String,Object> resultProxy = result.getValuesByAlias();
        paymentStatus = (String) resultProxy.get(String.valueOf(DataImport__c.fields.Payment_Status__c));
        status = (String) resultProxy.get(String.valueOf(DataImport__c.fields.Status__c));
        recordCount = (Integer) resultProxy.get('recordCount');
    }

    public Integer recordCount() {
        return this.recordCount;
    }

    public Boolean isImported() {
        return status == BDI_DataImport_API.bdiImported;
    }

    public Boolean isProcessingFailed() {
        return status == BDI_DataImport_API.bdiFailed;
    }

    public Boolean isProcessing() {
        return status == BDI_DataImport_API.bdiProcessing;
    }

    public Boolean isPaymentFailed() {
      return paymentStatus == ElevateTransactionStatus.DECLINED.name()
          || paymentStatus == ElevateTransactionStatus.EXPIRED.name()
          || paymentStatus == ElevateTransactionStatus.NONRETRYABLEERROR.name()
          || paymentStatus == ElevateTransactionStatus.RETRYABLEERROR.name();
    }
    
    public Boolean isPaymentAuthorizationExpired() {
      return paymentStatus == ElevateTransactionStatus.EXPIRED.name();
    }

    public Boolean isPaymentAuthorized() {
      return paymentStatus == ElevateTransactionStatus.AUTHORIZED.name();
    }
}
