/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group API
* @group-content ../../ApexDocContent/Rollups2.htm
* @description TODO
*/
public without sharing class CRLP_ApiExecuteRollups {

    private CRLP_RollupProcessingOptions.RollupType rollupType;
    private Id parentId;
    private List<CRLP_Rollup> rollupDefs;
    private SObject summaryRecord;
    private List<SObject> detailRecords;
    private Map<Id, List<SObject>> relatedRecords;

    private SObjectType summaryObjectType;

    public CRLP_ApiExecuteRollups() {}

    public CRLP_ApiExecuteRollups withRollupType(CRLP_RollupProcessingOptions.RollupType rollupType) {
        this.rollupType = rollupType;
        this.summaryObjectType = CRLP_Rollup_SVC.getSummaryObjectType(rollupType);
        return this;
    }
    public CRLP_ApiExecuteRollups withParentId(Id parentId) {
        String parentQuery = CRLP_Query_SEL.buildObjectQueryForRollup(summaryObjectType) + ' WHERE Id = :parentId LIMIT 1';
        this.summaryRecord = Database.query(parentQuery);
        this.parentId = parentId;
        return this;
    }
    public CRLP_ApiExecuteRollups withRollupDefs(List<CRLP_Rollup> rollupDefs) {
        this.rollupDefs = rollupDefs;
        return this;
    }
    public CRLP_ApiExecuteRollups withRollupData(Map<Id, Map<String, List<SObject>>> rollupData) {
        convertData(rollupData);
        return this;
    }

    public List<CRLP_Rollup> executeRollups() {

        CRLP_RollupProcessingOptions.ProcessingOptions options = new CRLP_RollupProcessingOptions.ProcessingOptions();
        options.doSummaryObjectComparison = false;

        CRLP_RollupProcessor processor = new CRLP_RollupProcessor()
                .withRollupDefinitions(rollupDefs)
                .withRollupType(rollupType)
                .withSummaryRecord(summaryRecord)
                .withDetailRecords(detailRecords)
                .withRelatedRecords(relatedRecords)
                .withJobOptions(options);

        processor.startRollupProcessing();
        return processor.getRollupDefsForParent(parentId);
    }

    private void convertData(Map<Id, Map<String, List<SObject>>> rollupData) {
        String detailObject = CRLP_Rollup_SVC.getDetailObjectType(rollupType).getDescribe().getName();
        String paymentObject = npe01__OppPayment__c.SObjectType.getDescribe().getName();
        String ocrObject = OpportunityContactRole.SObjectType.getDescribe().getName();
        String pscObject = Partial_Soft_Credit__c.SObjectType.getDescribe().getName();
        String ascObject = Account_Soft_Credit__c.SObjectType.getDescribe().getName();

        String parentKey = CRLP_Rollup_SVC.getParentRelationshipFieldForProcessingJob(rollupType);

        Boolean hasPaymentRollups = CRLP_Rollup_SVC.hasActivePaymentRollupsForSObject(summaryObjectType);

        for (Id key : rollupData.keySet()) {
            SObject detailRecord = rollupData.get(key).get(detailObject)[0];
            detailRecords.add(detailRecord);
            switch on rollupType {
                when AccountHardCredit, ContactHardCredit {
                    if (hasPaymentRollups) {
                        relatedRecords.put((Id)detailRecord.get('Id'), rollupData.get(key).get(paymentObject));
                    }
                }
                when ContactSoftCredit, AccountContactSoftCredit {
                    // TODO Convert OCR's to PartialSoftCredit records
                    // TODO STrip out OCR's not related to the parent Contact or Account
                    List<OpportunityContactRole> ocrRecords = rollupData.get(key).get(ocrObject);
                    List<Partial_Soft_Credit__c> partialSoftCreditRecords = rollupData.get(key).get(pscObject);
                    List<SObject> pscDetails = buildPartialSoftCreditRecordsFromOCRs(parentId,
                            (Opportunity)detailRecord, ocrRecords, partialSoftCreditRecords);
                    relatedRecords.put((Id)detailRecord.get('Id'), pscDetails);
                }
                when AccountSoftCredit {
                    // TODO STrip out AccountSoftCredit records not related to the parent Account
                    relatedRecords.put((Id)detailRecord.get('Id'), rollupData.get(key).get(ascObject));
                }
                when GAU {
                    // TODO Get Allocation records and strip out anything not for the specified GAU ParentId
                }
            }
        }

    }

    /********************************************************************************************************
     * @description Soft Credit roll-ups work by querying the OCR object as the main object, but sending
     * PartialSoftCredit records as the detail records for the rollups. This is because PSC has a custom field
     * for Amount and generally the rule is that every Donation has an OCR record, but may or may not have a PSC
     * record. This method creates non-committed PartialSoftCredit records where one doesn't already exist to
     * use for the rollups process.
     * @param parentId Summary Record Id (Account or Contact)
     * @param opp Opportunity record
     * @param ocrRecords OpportunityContactRole records for the Opp
     * @param partialSoftCreditRecords PartialSoftCredit records for the Opp
     * @return List<Partial_Soft_Credit__c>
     */
    private List<Partial_Soft_Credit__c> buildPartialSoftCreditRecordsFromOCRs(Id parentId, Opportunity opp,
            List<OpportunityContactRole> ocrRecords, List<Partial_Soft_Credit__c> partialSoftCreditRecords) {

        List<Partial_Soft_Credit__c> pscDetailRecords = new List<Partial_Soft_Credit__c>();
        for (OpportunityContactRole ocr : ocrRecords) {
            Partial_Soft_Credit__c matchedPSC = matchOrCreatePartialSoftCredit(opp, ocr, partialSoftCreditRecords);
            pscDetailRecords.add(matchedPSC);
        }

        return pscDetailRecords;
    }

    /**
     * @description For the given Opportunity and OpportunityContactRole, either match the OCR to an existing
     * partialSoftCredit record or create a new 'dummy' one that can be used for the Soft Credit Rollup job.
     * @param opp Opportunity
     * @param ocrRecord OpportunityContactRole
     * @param partialSoftCreditRecords PartialSoftCredit records to match against
     * @return Partial_Soft_Credit__c
     */
    private Partial_Soft_Credit__c matchOrCreatePartialSoftCredit(Opportunity opp, OpportunityContactRole ocrRecord,
            List<Partial_Soft_Credit__c> partialSoftCreditRecords) {

        // Find the matching PartialSoftCredit record for the OCR record; if there is one
        Partial_Soft_Credit__c matchedPSC;
        for (Partial_Soft_Credit__c psc : partialSoftCreditRecords) {
            if (psc.Contact__c == ocrRecord.ContactId) {
                matchedPSC = psc.clone(true, true, true, true);
                matchedPSC.Opportunity__r = opp;
                break;
            }
        }
        if (matchedPSC == null) {
            // If there is no matched PartialSoftCredit record for this OCR, create a new one (not committed)
            // and set the Amount to the full Amount value from the Opportunity record.
            matchedPSC = new Partial_Soft_Credit__c(
                    Opportunity__c = opp.Id,
                    Opportunity__r = opp,
                    Contact__r = ocrRecord.Contact, // TODO This may need to an additional query to get Contact.AccountId
                    Contact__c = ocrRecord.ContactId,
                    Contact_Role_ID__c = ocrRecord.Id,
                    Role_Name__c = ocrRecord.Role,
                    Amount__c = opp.Amount
            );
            if (UserInfo.isMultiCurrencyOrganization()) {
                matchedPSC.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
            }
        }

        return matchedPSC;
    }

}