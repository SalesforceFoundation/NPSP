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
@IsTest
private class GiftSelector_TEST {

    @isTest
    private static void shouldIncludeElevateFields() {
        mockElevateCustomerStatus(true);
        GiftSelector selector = new GiftSelector();
        List<String> selectFields = selector.fields();

        System.assert(selectFields.contains(String.valueOf(DataImport__c.Elevate_Payment_Status__c)), 'List is missing Elevate_Payment_Status__c');
        System.assert(selectFields.contains(String.valueOf(DataImport__c.Payment_Declined_Reason__c)), 'List is missing Payment_Declined_Reason__c');
        System.assert(selectFields.contains(String.valueOf(DataImport__c.Payment_Elevate_Batch_ID__c)), 'List is missing Payment_Elevate_Batch_ID__c');
        System.assert(selectFields.contains(String.valueOf(DataImport__c.Payment_Elevate_ID__c)), 'List is missing Payment_Elevate_ID__c');
    }

    @isTest
    private static void shouldNotIncludeElevateFields() {
        mockElevateCustomerStatus(false);
        GiftSelector selector = new GiftSelector();
        List<String> selectFields = selector.fields();

        System.assert(!selectFields.contains(String.valueOf(DataImport__c.Elevate_Payment_Status__c)), 'List should not include Elevate_Payment_Status__c');
        System.assert(!selectFields.contains(String.valueOf(DataImport__c.Payment_Declined_Reason__c)), 'List should not include Payment_Declined_Reason__c');
        System.assert(!selectFields.contains(String.valueOf(DataImport__c.Payment_Elevate_Batch_ID__c)), 'List should not include Payment_Elevate_Batch_ID__c');
        System.assert(!selectFields.contains(String.valueOf(DataImport__c.Payment_Elevate_ID__c)), 'List should not include Payment_Elevate_ID__c');
    }

    private static void mockElevateCustomerStatus(Boolean isCustomer) {
        GE_PaymentServicesMock mockInstance = new GE_PaymentServicesMock();
        mockInstance.withIsElevateCustomer(isCustomer);
        GE_PaymentServices paymentServicesMock = (GE_PaymentServices) Test.createStub(
            GE_PaymentServices.class,
            mockInstance
        );
        GE_PaymentServices.setInstance(paymentServicesMock);
    }
}
