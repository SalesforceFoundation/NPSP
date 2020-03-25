import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import GeFormService from 'c/geFormService';
import { showToast, handleError } from 'c/utilTemplateBuilder';
import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import DI_PAYMENT_AUTHORIZE_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';

const PAYMENT_AUTHORIZE_TOKEN__C = DI_PAYMENT_AUTHORIZE_TOKEN_FIELD.fieldApiName;

export default class GeGiftEntryFormApp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api sObjectName;

    @track isPermissionError;

    get isBatchMode() {
        return this.sObjectName &&
            this.sObjectName === DATA_IMPORT_BATCH_OBJECT.objectApiName;
    }

    handleBatchSubmit(event) {
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        const dataImportRecord = event.detail.dataImportRecord;
        GeFormService.saveAndDryRun(this.recordId, dataImportRecord)
            .then(dataImportModel => {
                Object.assign(dataImportModel.dataImportRows[0],
                    dataImportModel.dataImportRows[0].record);
                table.upsertData(dataImportModel.dataImportRows[0], 'Id');
                table.setTotalCount(dataImportModel.totalCountOfRows);
                table.setTotalAmount(dataImportModel.totalAmountOfRows);
                event.detail.success(); //Re-enable the Save button
            })
            .catch(error => {
                event.detail.error(error);
            });
    }

    /*******************************************************************************
    * @description Handles a single gift entry submit. Checks to see if a payment
    * needs to be made and processes the Data Import record.
    *
    * @param {object} event: Custom Event containing the Data Import record and an
    * callback for handling and displaying errors in the form.
    */
    handleSingleSubmit = async (event) => {
        console.log('*** handleSingleSubmit');
        try {
            let { dataImportRecord, errorCallback } = event.detail;

            const hasPaymentToProcess = dataImportRecord[PAYMENT_AUTHORIZE_TOKEN__C];
            if (hasPaymentToProcess) {
                dataImportRecord =
                    await GeFormService.handlePaymentProcessing(dataImportRecord, errorCallback);
            }

            if (dataImportRecord) {
                const hasUserSelectedDonation = this.selectedDonationDataImportFieldValues ? true : false;
                await this.processDataImport(dataImportRecord, hasUserSelectedDonation);
            }
        } catch (error) {
            handleError(error);
        }
    }

    /*******************************************************************************
    * @description Sends the Data Import into BDI for processing and navigates to
    * the opportunity record detail page on success.
    *
    * @param {object} dataImportRecord: A DataImport__c record
    * @param {boolean} hasUserSelectedDonation: True if a selection had been made in
    * the 'Review Donations' modal and BDI needs to attempt a match.
    */
    processDataImport = async (dataImportRecord, hasUserSelectedDonation) => {
        console.log('*** processDataImport: ', dataImportRecord);
        const opportunityId =
            await GeFormService.handleProcessDataImport(dataImportRecord, hasUserSelectedDonation)
                .catch((error) => {
                    showToast(`Error`, `${error}`, 'error', 'sticky');
                });

        this.navigateToRecordPage(opportunityId);
    }

    handleSectionsRetrieved(event) {
        const formSections = event.target.sections;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.handleSectionsRetrieved(formSections);
    }

    handleBatchDryRun() {
        //toggle the spinner on the form
        const form = this.template.querySelector('c-ge-form-renderer');
        const toggleSpinner = function () {
            form.showSpinner = !form.showSpinner
        };
        form.showSpinner = true;

        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.runBatchDryRun(toggleSpinner);
    }

    handleLoadData(event) {
        const form = this.template.querySelector('c-ge-form-renderer');
        form.reset();
        form.load(event.detail);
    }

    handlePermissionErrors() {
        this.isPermissionError = true;
    }
    handleEditBatch() {
        this.dispatchEvent(new CustomEvent('editbatch'));
    }

    handleReviewDonationsModal(event) {
        this.dispatchEvent(new CustomEvent('togglereviewdonationsmodal', { detail: event.detail }));
    }

    navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}