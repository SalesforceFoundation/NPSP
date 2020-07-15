import { LightningElement, api, track } from 'lwc';

import header from '@salesforce/label/c.RD2_PauseHeader';
import description from '@salesforce/label/c.RD2_PauseDescription';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import cancelButton from '@salesforce/label/c.stgBtnCancel';
import saveButton from '@salesforce/label/c.stgBtnSave';

import getInstallments from '@salesforce/apex/RD2_VisualizeScheduleController.getInstallments';

export default class Rd2PauseForm extends LightningElement {

    labels = Object.freeze({
        header,
        description,
        loadingMessage,
        cancelButton,
        saveButton,
    });

    @api recordId;

    maxRowDisplay = 12;
    maxRowSelection = 12;
    selectedIds = [];
    @track isLoading = true;
    @track columns = [];
    @track installments;

    @track error = {};

    /***
    * @description 
    */
    connectedCallback() {
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
     * @description Get the installments
     */
    handleRecords(response) {
        if (response && response.dataTable) {
            this.installments = response.dataTable.records;
        }
    }

    /***
     * @description Get the data table columns
     */
    handleColumns(response) {
        if (response && response.dataTable) {
            this.columns = response.dataTable.columns;
        }
    }

    /***
     * @description An event fired on both select and deselect of all and specific records
     */
    handleRowSelection(event) {
        let selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();
        if (selectedRows === undefined || selectedRows === null) {
            selectedRows = [];
        }
        const isSelectEvent = this.selectedIds.length < selectedRows.length;

        if (isSelectEvent) {
            this.handleSelect(selectedRows);
        } else {
            this.handleDeselect(selectedRows);
        }

        console.log('Selected Rows: ' + JSON.stringify(this.selectedIds));
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
    handleCancel() {
        this.closeModal();
    }

    /***
    * @description 
    */
    handleSave() {
        this.closeModal();
    }

    closeModal() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }

    /***
    * @description Handle component display when an error occurs
    * @param error: Error Event
    */
    handleError(error) {
        this.error.message = this.constructErrorMessage(error);

        this.template.querySelector(".slds-modal__header").scrollIntoView();
    }

    /***
     * @description Parse the error response
     * @param {object} error: Event holding error details
     * @return The error message to render
     */
    constructErrorMessage(error) {
        if (error && error.status && error.body) {
            return error.body.message;
        } else if (error && error.name && error.message) {
            return error.message;
        } else {
            return "";
        }
    }

}