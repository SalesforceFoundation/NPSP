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
* @description Batch entity class in NPSP.
*/

public inherited sharing class GiftBatch implements IGiftBatch {

    private Id batchId;
    private DataImportBatch__c batch;
    private Gifts gifts;

    @TestVisible
    private GE_Template.Template formTemplate {
        get {
            if (formTemplate == null) {
                formTemplate =
                    (GE_Template.Template) JSON.deserialize(
                        batch.Form_Template__r.Template_JSON__c,
                        GE_Template.Template.class);
            }
            return formTemplate;
        }
        set;
    }

    private GiftBatchSelector giftBatchSelector {
        get {
            if (giftBatchSelector == null) {
                giftBatchSelector = new GiftBatchSelector();
            }
            return giftBatchSelector;
        }
        set;
    }

    @TestVisible
    private ElevateBatchService elevateBatchService {
        get {
            if (elevateBatchService == null) {
                elevateBatchService = new ElevateBatchService();
            }
            return elevateBatchService;
        }
        set;
    }

    @TestVisible
    private GiftBatch(Gifts gifts) {
        this.gifts = gifts;
    }

    @TestVisible
    private GiftBatch() {}

    public GiftBatch(Id batchId) {
        this.batchId = batchId;
        this.batch = giftBatchSelector.selectGiftBatchById(this.batchId);
        this.gifts = new Gifts(this.batchId, giftFieldsToQuery());
    }

    public Boolean hasElevateWidget() {
        Boolean hasWidget = false;
        for (GE_Template.Section section : formTemplate.layout.sections) {
            for (GE_Template.Element element : section.elements) {
                if (isElevateWidget(element)) {
                    hasWidget = true;
                }
            }
        }
        return hasWidget;
    }

    private Boolean isElevateWidget(GE_Template.Element element) {
        return element.componentName != null
            && element.componentName == 'geFormWidgetTokenizeCard';
    }

    public void captureAuthorizedGifts() {
        elevateBatchService.enqueuePaymentCaptureJobFor(
            batchId, gifts?.elevateBatchIds());
        gifts.authorizedToPaymentProcessingStatus();
    }

    public void failGiftsWithReason(Map<String, String> failReasonByElevateBatchId) {
        gifts.failGiftsByElevateBatchIdWithReason(failReasonByElevateBatchId);
    }

    public void processGifts() {
        gifts.giftsToProcessingStatus();
        captureAuthorizedGifts();
        BDI_DataImport_API.processDataImportBatches(new List<Id>{batchId});
    }

    public void updateRecords() {
        gifts.updateRecords();
    }

    public Id id() {
        return this.batchId;
    }

    public Money total() {
        //todo: use giftBatch Totals (and place in Selector layer)
        return new Money(dataImportModel().totalRowAmount, 'US');
    }

    public Integer totalCount() {
        //todo: use giftBatch Totals (and place in Selector layer)
        return dataImportModel().totalCountOfRows;
    }

    @TestVisible
    private BGE_DataImportBatchEntry_CTRL.DataImportModel typedModel;
    private BGE_DataImportBatchEntry_CTRL.DataImportModel dataImportModel() {
        if (typedModel == null) {
            String model = BGE_DataImportBatchEntry_CTRL.getDataImportModel(batchId);
            typedModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel)
                    JSON.deserialize(model,
                            BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
        }
        return typedModel;
    }

    private List<String> getElevateRelatedFieldApiNames() {
        List<String> elevateFieldApiNames = new List<String>();
        if (GE_PaymentServices.getInstance().isElevateCustomer()
            && hasElevateWidget()) {

            elevateFieldApiNames = new List<String>{
                String.valueOf(DataImport__c.Payment_Declined_Reason__c),
                String.valueOf(DataImport__c.Elevate_Payment_Status__c),
                String.valueOf(DataImport__c.Payment_Elevate_Batch_ID__c)
            };
        }

        return elevateFieldApiNames;
    }

    private List<String> getGiftEntryFieldApiNames() {
        List<String> giftEntryFieldApiNames = new List<String>();
        giftEntryFieldApiNames.add(String.valueOf(DataImport__c.Payment_Status__c));
        giftEntryFieldApiNames.add(String.valueOf(DataImport__c.Status__c));
        giftEntryFieldApiNames.add(String.valueOf(DataImport__c.Additional_Object_JSON__c));

        return giftEntryFieldApiNames;
    }

    @TestVisible
    private List<String> giftFieldsToQuery() {
        Set<String> fieldSet = new Set<String>();
        fieldSet.addAll(formTemplate.giftFieldApiNames());
        fieldSet.addAll(getGiftEntryFieldApiNames());
        fieldSet.addAll(getElevateRelatedFieldApiNames());

        List<String> fieldsToQuery = new List<String>();
        fieldsToQuery.addAll(fieldSet);

        return fieldsToQuery;
    }
}
