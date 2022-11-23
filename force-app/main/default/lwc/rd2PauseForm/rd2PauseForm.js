import { LightningElement, api, track, wire } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { showToast, constructErrorMessage, isNull } from 'c/utilCommon';
import { getRecord } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.Name';

import header from '@salesforce/label/c.RD2_PauseHeader';
import description from '@salesforce/label/c.RD2_PauseDescription';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import cancelButton from '@salesforce/label/c.stgBtnCancel';
import saveButton from '@salesforce/label/c.stgBtnSave';
import okButton from '@salesforce/label/c.stgLabelOK';
import selectedRowsSummaryPlural from '@salesforce/label/c.RD2_PauseSelectedInstallmentTextPlural';
import selectedRowsSummarySingular from '@salesforce/label/c.RD2_PauseSelectedInstallmentTextSingular';
import firstDonationDateMessage from '@salesforce/label/c.RD2_PauseFirstDonationDateDynamicText';
import saveSuccessMessage from '@salesforce/label/c.RD2_PauseSaveSuccessMessage';
import deactivationSuccessMessage from '@salesforce/label/c.RD2_PauseDeactivationSuccessMessage';
import rdClosedMessage from '@salesforce/label/c.RD2_PauseClosedRDErrorMessage';
import elevateNotSupported from '@salesforce/label/c.RD2_ElevateNotSupported';
import permissionRequired from '@salesforce/label/c.RD2_PausePermissionRequired';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';

import getPauseData from '@salesforce/apex/RD2_PauseForm_CTRL.getPauseData';
import getInstallments from '@salesforce/apex/RD2_PauseForm_CTRL.getInstallments';
import savePause from '@salesforce/apex/RD2_PauseForm_CTRL.savePause';

export default class Rd2PauseForm extends LightningElement {

    labels = Object.freeze({
        header,
        description,
        loadingMessage,
        cancelButton,
        elevateNotSupported,
        saveButton,
        okButton,
        selectedRowsSummaryPlural,
        selectedRowsSummarySingular,
        saveSuccessMessage,
        deactivationSuccessMessage,
        rdClosedMessage,
        firstDonationDateMessage,
        permissionRequired,
        insufficientPermissions
    });

    @api recordId;
    recordName;

    @track isLoading = true;
    @track permissions = {
        hasAccess: false,
        isBlocked: false,
        blockedReason: ''
    };
    @track isSaveDisplayed;
    @track isSaveDisabled = false;
    @track pageHeader = '';
    @track pausedReason = {};
    scheduleId;

    @track columns = [];
    @track installments;

    numberOfInstallments = 13;
    maxRowDisplay = 12;
    maxRowSelection = 12;
    selectedIds = [];
    @track selectedRowsSummary = null;
    firstDonationDateBoundary = null;
    @track firstDonationDateMessage = null;

    @track error = {};

    /***
    * @description Initializes the component
    */
    connectedCallback() {
        this.init();
    }

    /***
    * @description Groups various calls to Apex:
    * - Loads installments
    * - Waits for latest pause data (if any) and initializes the Paused Reason
    */
    init = async () => {
        try {
            this.loadInstallments();
            await this.loadPauseData();

        } catch (error) {
            this.handleError(error);
        }
    }

    /***
    * @description Loads installments and sets datatable columns and records.
    * If the user does not have permission to create/edit RD, then installments are not rendered.
    */
    loadInstallments = async () => {
        getInstallments({ recordId: this.recordId, numberOfInstallments: this.numberOfInstallments })
            .then(response => {
                this.handleRecords(response);
                this.handleColumns(response);
            })
            .catch(error => {
                this.installments = null;

                if (this.permissions.isBlocked !== true && this.permissions.hasAccess !== false) {
                    this.handleError(error);
                }
            });
    }

    /***
    * @description Load active current/future Pause.
    * Sets Paused Reason field.
    * If the user does not have permission to create/edit RD, then pause details are not rendered.
    */
    loadPauseData = async () => {
        getPauseData({ rdId: this.recordId })
            .then(response => {
                const pauseData = JSON.parse(response);
                this.permissions.hasAccess = pauseData.hasAccess;
                this.permissions.isBlocked = pauseData.isRDClosed;
                if (!this.permissions.hasAccess) {
                    this.error.detail = this.labels.permissionRequired;
                    this.handleErrorDisplay();
                } else {
                    this.pausedReason = pauseData.pausedReason;
                    this.scheduleId = pauseData.scheduleId;
                }

                if (this.permissions.isBlocked) {
                    this.permissions.blockedReason = this.labels.rdClosedMessage;
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
                this.handleButtonsDisplay();
            });
    }

    /***
    * @description Loads the Recurring Donation name asynchronously
    */
    @wire(getRecord, {
        recordId: '$recordId',
        fields: NAME_FIELD
    })
    wiredRecurringDonation(response) {
        if (response.data) {
            this.recordName = response.data.fields.Name.value;
            this.pageHeader = this.labels.header.replace('{0}', this.recordName);

        } else if (response.error) {
            this.handleError(response.error);
        }
    }

    /***
     * @description Sets installment datatable records
     */
    handleRecords(response) {
        if (response && response.dataTable) {
            this.installments = response.dataTable.records;

            if (this.installments) {
                if (this.installments.length > this.maxRowDisplay) {
                    //Remove the last installment in order to display maximum
                    //number of rows that should be displayed.

                    //Save the installment date to help with the first donation date calculations
                    //when all displayed installments are selected
                    this.firstDonationDateBoundary = this.installments.pop().donationDate;
                }

                //Get selected installments to skip
                this.selectedIds = [];
                for (let i = 0; i < this.installments.length; i++) {
                    if (this.installments[i].isSkipped === true) {
                        this.selectedIds.push(this.installments[i].installmentNumber);
                    }
                }

                this.refreshSummaries();
            }
        }
    }

    /***
     * @description Sets installment datatable columns
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
     * @description Handles the row selection event fired on
     * both select and deselect of all and individual installments
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

        this.refreshSummaries();
    }

    /***
     * @description Handles select event on an installment or select all event
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
     * @description Selects installments in between selected rows
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
     * @description Handles deselect event on an installment or deselect all event
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
     * @description Refreshes notification messages displayed
     * based on the currently selected installments to skip
     */
    refreshSummaries() {
        this.refreshSelectedRowsSummary();
        this.refreshFirstDonationDate();
    }

    /***
     * @description Constructs the installment selection summary message
     * notifying user how many installments has been selected
     */
    refreshSelectedRowsSummary() {
        const selectedCount = this.selectedIds.length;

        if (selectedCount > 0) {
            this.selectedRowsSummary = selectedCount === 1
                ? this.labels.selectedRowsSummarySingular
                : this.labels.selectedRowsSummaryPlural.replace('{0}', selectedCount);
        } else {
            this.selectedRowsSummary = null;
        }

        this.refreshSaveButton();
    }

    /***
     * @description Constructs the message displaying the date
     * of the first installment *after* the pause ends.
     * If the pause does not exist or it is being deactivated, no date message is displayed.
     * If all 12 installments are selected, then first donation date is
     * the date of the 13th installment that is not displayed.
     */
    refreshFirstDonationDate() {
        this.firstDonationDateMessage = null;
        let firstDateAfterPause = null;

        if (this.installments && this.selectedIds && this.selectedIds.length > 0) {
            const lastSelectedId = this.selectedIds[this.selectedIds.length - 1];

            if (lastSelectedId < this.installments.length) {
                firstDateAfterPause = this.installments[lastSelectedId].donationDate;

            } else if (lastSelectedId == this.installments.length) {
                firstDateAfterPause = this.firstDonationDateBoundary;
            }

            if (firstDateAfterPause !== null) {
                //Helps with converting the date into the format according to the user’s language.
                const dateTimeFormat = new Intl.DateTimeFormat(LOCALE);

                //Convert the date 'YYYY-MM-DD' into the local time by appending ' 00:00',
                //to keep the date value as specified in the string (no date offset due to timezone).
                const date = new Date(firstDateAfterPause + ' 00:00');

                this.firstDonationDateMessage = this.labels.firstDonationDateMessage.replace(
                    '{0}', dateTimeFormat.format(date)
                );
            }
        }
    }

    /***
    * @description Handles button display. In the case of permission, field visibility
    * or RD closed error, [OK] button is displayed and [Save] button is not displayed.
    */
    handleButtonsDisplay() {
        this.isSaveDisplayed = !this.isLoading && this.permissions.hasAccess && !this.permissions.isBlocked;

        // Disable data display and Save button when installments are not returned
        if (this.installments == null && this.isSaveDisplayed) {
            this.isSaveDisplayed = false;
            this.hasAccess = false;
        }

        this.refreshSaveButton();
    }

    /***
     * @description Rechecks if the [Save] button should be displayed
     */
    refreshSaveButton() {
        if (isNull(this.scheduleId)) {
            this.isSaveDisabled = (this.pausedReason && isNull(this.pausedReason.value))
                || (this.selectedIds.length == 0);
        } else {
            this.isSaveDisabled = false;
        }
    }

    /***
    * @description Save pause: Inserts new pause (if any) and deactivates the old one.
    */
    handleSave() {
        this.clearError();

        const pausedReasonField = this.template.querySelector("[data-id='pausedReason']");
        if (pausedReasonField && !pausedReasonField.reportValidity()) {
            return;
        }

        this.isLoading = true;
        try {
            const jsonData = JSON.stringify(this.constructPauseData());

            savePause({ jsonPauseData: jsonData })
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
    * @description Displays message that the pause save has been successful
    * and closes the modal.
    */
    handleSaveSuccess() {
        const message = this.selectedIds.length > 0
            ? this.labels.saveSuccessMessage.replace('{0}', this.recordName)
            : this.labels.deactivationSuccessMessage.replace('{0}', this.recordName);
        showToast(message, '', 'success', []);

        const closeEvent = new CustomEvent('save');
        this.dispatchEvent(closeEvent);
    }

    /***
    * @description Records the latest Paused Reason value
    * and checks if the [Save] button should be enabled.
    */
    handlePausedReasonChange(event) {
        this.pausedReason.value = event.detail.value;

        const pausedReasonField = this.template.querySelector("[data-id='pausedReason']");
        pausedReasonField.reportValidity();

        this.refreshSaveButton();
    }

    /***
    * @description Constructs pause data to be sent to the Apex method when user clicks [Save]
    */
    constructPauseData() {
        let pauseData = {};
        pauseData.rdId = this.recordId;

        let installmentById = this.installments.reduce(function (map, installment) {
            map[installment.installmentNumber] = installment.donationDate;
            return map;
        }, {});

        const firstSelectedId = this.selectedIds[0];
        pauseData.startDate = installmentById[firstSelectedId];

        const lastSelectedId = this.selectedIds[this.selectedIds.length - 1];
        pauseData.resumeAfterDate = installmentById[lastSelectedId];

        pauseData.pausedReason = {};
        pauseData.pausedReason.value = this.pausedReason.value;

        return pauseData;
    }

    /***
    * @description Closes the pause modal on save
    */
    handleCancel() {
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
    * @description Handle error
    * @param error: Error Event
    */
    handleError(error) {
        this.isLoading = false;

        this.error = constructErrorMessage(error);

        this.handleErrorDisplay();
    }


    /***
    * @description Handle component display when an error occurs
    * @param error: Error Event
    */
    handleErrorDisplay() {
        const errorDetail = this.error.detail;

        const isApexClassDisabled = errorDetail && errorDetail.includes("RD2_PauseForm_CTRL");
        if (isApexClassDisabled) {
            this.permissions.hasAccess = false;
        }

        if (errorDetail && this.permissions.hasAccess === false) {
            this.error.header = this.labels.insufficientPermissions;
        }

        this.template.querySelector(".slds-modal__header").scrollIntoView();
    }
}