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

    @TestVisible private Data_Import_Settings__c dataImportSettings;
    @TestVisible private DataImport__c dataImport;
    private Donation donation;
    private List<String> availableFields;
    private SoftCredits softCredits {
        get {
            if (softCredits == null) {
                softCredits = new SoftCredits(new List<OpportunityContactRole>());
            }
            return softCredits;
        }
        set;
    }

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
        this(dataImport, null);
    }

    public Gift(DataImport__c dataImport, Donation donation) {
        this.donation = donation;
        this.dataImport = dataImport;
        this.populateAvailableFields();
        this.populateSoftCredits();
    }

    public Id id() {
        return this.dataImport.Id;
    }

    public String status() {
        return this.dataImport.Status__c;
    }

    public Id giftBatchId() {
        return this.dataImport.NPSP_Data_Import_Batch__c;
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

    public Donation donation() {
        return this.donation;
    }

    public Map<String, Object> fields() {
        return this.dataImport.getPopulatedFieldsAsMap();
    }

    public void deleteRecord() {
        delete this.dataImport;
    }

    public void saveRecord() {
        convertAdditionalObjectMembers();
        if (this.dataImport.Id != null) {
            unitOfWork.registerDirty(new List<sObject> { this.dataImport });
        } else {
            unitOfWork.registerNew(new List<sObject> { this.dataImport });
        }
        unitOfWork.save();
    }

    public void dryRunThroughBDI() {
        loadDataImportSettings();
        runBdiDryRun();
    }

    public void processThroughBDI() {
        loadDataImportSettings();
        BDI_DataImport_API.processDataImportRecords(
            dataImportSettings,
            new List<DataImport__c> { this.dataImport },
            false);

        if (this.dataImport.FailureInformation__c == null) {
            BDI_DataImportService.instrumentGiftEntry(1);
        }
    }

    public void assignSoftCredits(SoftCredits incomingSoftCredits) {
        this.softCredits = incomingSoftCredits;
    }

    public DataImport__c asDataImport() {
        return this.dataImport;
    }

    public String additionalObjectString() {
        return this.dataImport.Additional_Object_JSON__c;
    }

    private void convertAdditionalObjectMembers() {
        AdditionalObjectJSON additionalObjectJSONHelper =
            new AdditionalObjectJSON(additionalObjectString());

        additionalObjectJSONHelper.add(this.softCredits);

        this.dataImport.Additional_Object_JSON__c = additionalObjectJSONHelper.asJSON();
    }

    public Boolean isImported() {
        return this.status() == BDI_DataImport_API.bdiImported;
    }

    public Boolean isProcessing() {
        return this.status() == BDI_DataImport_API.bdiProcessing;
    }

    public Boolean hasAuthorizedPayment() {
        return this.dataImport.Payment_Status__c == ElevateTransactionStatus.AUTHORIZED.name();
    }

    public Boolean isPaymentProcessing() {
        return this.dataImport.Payment_Status__c == ElevateTransactionStatus.PAYMENTPROCESSING.name();
    }

    public Boolean isDryRunValidated() {
        return this.dataImport.Status__c == BDI_DataImport_API.bdiDryRunValidated;
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
        populateSoftCreditsFromDonation();
        populateSoftCreditsFromAdditionalObjectJSON();
    }

    private void populateSoftCreditsFromDonation() {
        if (hasDonation()) {
            this.softCredits.addAll(this.donation.softCredits().all());
        }
    }

    private void populateSoftCreditsFromAdditionalObjectJSON() {
        String additionalObjectString = this.dataImport.Additional_Object_JSON__c;
        if (additionalObjectString != null) {
            SoftCredits softCreditsFromAdditionalObjectJSON =
                new AdditionalObjectJSON(additionalObjectString)?.asSoftCredits();
            this.softCredits.addAll(softCreditsFromAdditionalObjectJSON.unprocessed());
        }
    }

    private Boolean hasDonation() {
        return this.dataImport.DonationImported__c != null && this.donation != null;
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

    private void loadDataImportSettings() {
        if (giftBatchId() != null) {
            dataImportSettings = BDI_DataImportService.loadSettings(giftBatchId());
        } else {
            dataImportSettings = BDI_DataImportService.loadSettings(null);
        }

        if (isMatchingToOpenDonation()) {
            dataImportSettings.Donation_Matching_Behavior__c =
                BDI_DataImport_API.ExactMatchOrCreate;
        } else {
            dataImportSettings.Donation_Matching_Behavior__c =
                BDI_DataImport_API.DoNotMatch;
        }
    }

    private Boolean isMatchingToOpenDonation() {
        return this.dataImport.PaymentImported__c != null ||
            this.dataImport.DonationImported__c != null;
    }

    private void runBdiDryRun() {
        BDI_DataImport_API.processDataImportRecords(
            dataImportSettings,
            new List<DataImport__c> { this.dataImport },
            true);
    }

    @TestVisible
    private UnitOfWork unitOfWork {
        get {
            if (unitOfWork == null) {
                unitOfWork = new UnitOfWork();
            }
            return unitOfWork;
        }
        set;
    }

}
