import { LightningElement, api, track, wire } from 'lwc';
import { showToast, constructErrorMessage, isNull } from 'c/utilCommon';
import { getRecord } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.Name';

import header from '@salesforce/label/c.RD2_PauseHeader';
import description from '@salesforce/label/c.RD2_PauseDescription';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import cancelButton from '@salesforce/label/c.stgBtnCancel';
import saveButton from '@salesforce/label/c.stgBtnSave';

import getPausedReason from '@salesforce/apex/RD2_PauseForm_CTRL.getPausedReason';
import getInstallments from '@salesforce/apex/RD2_VisualizeScheduleController.getInstallments';
import savePause from '@salesforce/apex/RD2_PauseForm_CTRL.savePause';

export default class Rd2PauseForm extends LightningElement {

    labels = Object.freeze({
        header,
        description,
        loadingMessage,
        cancelButton,
        saveButton,
    });

    @api recordId;
    recordName;

    @track isLoading = true;
    @track pageHeader = '';

    @track pausedReason = {};

    maxRowDisplay = 12;
    maxRowSelection = 12;
    selectedIds = [];
    @track selectedRowMessage = null;
    @track columns = [];
    @track installments;

    @track error = {};

    /***
    * @description 
    */
    connectedCallback() {
        this.init();
    }

    /***
    * @description Group various calls to Apex
    */
    init = async () => {
        try {
            this.loadInstallments();
            await this.loadPausedReason();

        } catch (error) {
            this.handleError(error);
        }
    }

    /***
    * @description 
    */
    loadInstallments = async () => {
        getInstallments({ recordId: this.recordId, displayNum: this.maxRowDisplay })
            .then(response => {
                this.handleRecords(response);
                this.handleColumns(response);
            })
            .catch(error => {
                this.installments = null;
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /***
    * @description
    */
    @wire(getRecord, {
        recordId: '$recordId',
        fields: NAME_FIELD
    })
    wiredRecord(response) {
        if (response.data) {
            this.recordName = response.data.fields.Name.value;
            this.pageHeader = this.labels.header.replace('{0}', this.recordName);

        } else if (response.error) {
            this.handleError(response.error);
        }
    }

    /***
     * @description Get the installments
     */
    handleRecords(response) {
        if (response && response.dataTable) {
            this.installments = response.dataTable.records;

            if (this.installments) {
                this.selectedIds = [];

                for (let i = 0; i < this.installments.length; i++) {
                    if (this.installments[i].isSkipped === true) {
                        this.selectedIds.push(this.installments[i].installmentNumber);
                    }
                }

                this.refreshSelectedRowMessage();
            }
        }
    }

    /***
     * @description Get the data table columns
     */
    handleColumns(response) {
        if (response && response.dataTable) {
            let tempColumns = response.dataTable.columns;
            this.columns = [];

            for (let i = 0; i < tempColumns.length; i++) {
                if (tempColumns[i].fieldName !== "pauseStatus") {
                    this.columns.push(tempColumns[i]);
                }
            }
        }
    }

    /***
     * @description An event fired on both select and deselect of all and specific records
     */
    handleRowSelection(event) {
        let selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();
        if (isNull(selectedRows)) {
            selectedRows = [];
        }
        const isSelectEvent = this.selectedIds.length < selectedRows.length;

        if (isSelectEvent) {
            this.handleSelect(selectedRows);
        } else {
            this.handleDeselect(selectedRows);
        }

        this.refreshSelectedRowMessage();
    }

    /***
     * @description
     */
    handleSelect(selectedRows) {
        this.selectedIds = [];
        let previousId = null;

        for (let i = 0; i < selectedRows.length; i++) {
            const selectedId = selectedRows[i].installmentNumber;

            this.selectRowsInBetween(previousId, selectedId);
            this.selectedIds.push(selectedId);
            previousId = selectedId;
        }
    }

    /***
     * @description 
     */
    selectRowsInBetween(previousId, selectedId) {
        if (previousId === null) {
            return;
        }

        for (let rowId = previousId + 1; rowId < selectedId; rowId++) {
            this.selectedIds.push(rowId);
        }
    }

    /***
     * @description
     */
    handleDeselect(selectedRows) {
        this.selectedIds = [];
        let previousId = null;

        for (let i = 0; i < selectedRows.length; i++) {
            const selectedId = selectedRows[i].installmentNumber;

            if (previousId === null) {
                previousId = selectedId;
            }

            const isRowGap = selectedId > previousId + 1;
            if (isRowGap === true) {
                return;//ignore this and the rest of selected items
            }

            this.selectedIds.push(selectedId);
            previousId = selectedId;
        }
    }

    /***
     * @description
     */
    refreshSelectedRowMessage() {
        let messageSingular = 'You\'ve selected 1 installment to skip.';//TODO
        let messagePlural = 'You\'ve selected {0} installments to skip.';//TODO
        const selectedCount = this.selectedIds.length;

        this.selectedRowMessage = selectedCount > 0
            ? (selectedCount === 1 ? messageSingular : messagePlural.replace('{0}', selectedCount))
            : null;
    }

    /***
    * @description 
    */
    handleSave() {
        this.clearError();
        this.isLoading = true;

        try {
            const jsonPauseData = JSON.stringify(this.constructPauseData());

            savePause({ jsonData: jsonPauseData })
                .then(() => {
                    this.handleSaveSuccess();
                })
                .catch((error) => {
                    this.handleError(error);
                });
        } catch (error) {
            this.handleError(error);
        }
    }

    /***
    * @description 
    */
    handleSaveSuccess() {
        let message = 'Pause on Recurring Donation {0} has been saved';//TODO
        message = message.replace('{0}', this.recordName);
        showToast(message, '', 'success', []);

        this.closeModal();
    }

    /***
    * @description
    */
    loadPausedReason = async () => {
        getPausedReason({ recurringDonationId: this.recordId })
            .then(response => {
                this.pausedReason = JSON.parse(response);
            })
            .catch(error => {
                this.handleError(error);
            });
    }

    /***
    * @description
    */
    handlePausedReasonChange(event) {
        this.pausedReason.value = event.detail.value;
    }

    /***
    * @description
    */
    constructPauseData() {
        let pauseData = {};
        pauseData.recurringDonationId = this.recordId;

        let installmentById = this.installments.reduce(function (map, installment) {
            map[installment.installmentNumber] = installment.donationDate;
            return map;
        }, {});

        const firstSelectedId = this.selectedIds[0];
        pauseData.startDate = installmentById[firstSelectedId];

        const lastSelectedId = this.selectedIds[this.selectedIds.length - 1];
        pauseData.resumeAfterDate = installmentById[lastSelectedId];

        pauseData.pausedReason = this.pausedReason.value;

        return pauseData;
    }

    /***
    * @description 
    */
    handleCancel() {
        this.closeModal();
    }

    /***
    * @description
    */
    closeModal() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }

    /**
    * @description Clears the error notification
    */
    clearError() {
        this.error = {};
    }

    /***
    * @description Handle component display when an error occurs
    * @param error: Error Event
    */
    handleError(error) {
        this.isLoading = false;

        this.error = constructErrorMessage(error);

        this.template.querySelector(".slds-modal__header").scrollIntoView();

        console.log('Error: ' + JSON.stringify(this.error));//TODO
    }
}