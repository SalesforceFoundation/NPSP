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
* @description Gift entity class in NPSP.
*/

public with sharing class Gift {
    
    @TestVisible private DataImport__c dataImport;
    private List<String> availableFields;
    private SoftCredits softCredits;

    @TestVisible
    private GiftSelector giftSelector {
        get {
            if (giftSelector == null) {
                GiftTemplate defaultGiftTemplate = new GiftTemplate();
                giftSelector = new GiftSelector(defaultGiftTemplate);
            }
            return giftSelector;
        }
        set;
    }

    public Gift(GiftId giftId) {
        this.dataImport = giftSelector.getGiftById(giftId.value(), new GiftTemplate());
        this.populateSoftCredits();
    }

    public Gift(DataImport__c dataImport) {
        this.dataImport = dataImport;
        this.populateAvailableFields();
        this.populateSoftCredits();
    }

    public Boolean requiresReauthorizationBeforeChange() {
        if (dataImport.Payment_Status__c != ElevateTransactionStatus.AUTHORIZED.name()) { 
            return false; 
        }

        return this.hasPaymentFieldsChanged();
    }

    public SoftCredits softCredits() {
        return this.softCredits;
    }

    public Map<String, Object> fields() {
        return this.dataImport.getPopulatedFieldsAsMap();
    }

    private void populateAvailableFields() {
        Map<String, Object> dataImportFields = this.dataImport.getPopulatedFieldsAsMap();
        List<String> fields = new List<String>();

        for (String field : dataImportFields.keySet()) {
            if (GiftBatchService.PAYMENT_INTEGRATION_FIELDS.contains(field)) {
                fields.add(field);
            }
        }

        this.availableFields = fields;
    }

    private void populateSoftCredits() {
        // TODO: update existingSoftCredits to be populated with existing soft credits related to the dataImport
        // this actually likely going come from a Donation (domain) when the Donor and an Opportunity is
        // related to the Gift in question
        String additionalObjectString = this.dataImport.Additional_Object_JSON__c;
        this.softCredits = new AdditionalObjectJSON(additionalObjectString)?.asSoftCredits();
    }

    private Boolean hasPaymentFieldsChanged() {
        DataImport__c databaseDataImport = giftSelector.getGiftById(this.dataImport.Id, this.availableFields);

        for (String field : this.availableFields) {
            if (this.dataImport.get(field) != databaseDataImport.get(field)) {
                return true;
            }
        }

        return false;
    }

}
