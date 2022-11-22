import {createElement} from 'lwc';
import Rd2PauseForm from 'c/rd2PauseForm';
import { mockGetSelectedRows, getSelectedRowsImpl } from "lightning/datatable";
import RD2_PausePermissionRequired from '@salesforce/label/c.RD2_PausePermissionRequired';
import RD2_ElevateNotSupported from '@salesforce/label/c.RD2_ElevateNotSupported';


const mockPauseData = require('./data/getPauseData.json');
const mockGetInstallments = require('./data/getInstallments.json');
const mockWiredRecurringDonation = require('./data/wiredRecurringDonation.json');
const mockSavePauseException = require('./data/savePauseException.json');
const mockScrollIntoView = jest.fn();
const mockHandleClose = jest.fn();
const FAKE_RD2_ID = '00A-fake-rd2-id'

import getPauseData from '@salesforce/apex/RD2_PauseForm_CTRL.getPauseData';
import getInstallments from '@salesforce/apex/RD2_PauseForm_CTRL.getInstallments';
import savePause from '@salesforce/apex/RD2_PauseForm_CTRL.savePause';
import { getRecord } from 'lightning/uiRecordApi';

jest.mock('@salesforce/apex/RD2_PauseForm_CTRL.getPauseData',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/RD2_PauseForm_CTRL.getInstallments',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/RD2_PauseForm_CTRL.savePause',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/label/c.RD2_PauseSelectedInstallmentTextPlural',
    () => {
        return {
            default: 'You\'ve selected {0} installments.'
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/label/c.RD2_PauseFirstDonationDateDynamicText',
    () => {
        return {
            default: 'The first donation date after the pause period will be {0}.'
        };
    },
    { virtual: true }
);

describe('c-rd2-pause-form', () => {
    let component;

    beforeEach(() => {
        component = createElement('c-rd2-pause-form', { is: Rd2PauseForm })
        component.recordId = FAKE_RD2_ID;
        component.addEventListener('close', mockHandleClose);
        window.HTMLElement.prototype.scrollIntoView = mockScrollIntoView;
        mockGetSelectedRows.mockImplementation(getSelectedRowsImpl);
    });

    afterEach(() => {
        clearDOM();
    });

    describe('pause selection', () => {
        beforeEach(async () => {
            getPauseData.mockResolvedValue(JSON.stringify(mockPauseData));
            getInstallments.mockResolvedValue(mockGetInstallments);
            document.body.appendChild(component);
            await flushPromises();

            getRecord.emit(mockWiredRecurringDonation, config => config.recordId === FAKE_RD2_ID);
        });

        it('selects a single installment', () => {
            const controller = new PauseFormTestController(component);
            controller.selectRow(mockGetInstallments.dataTable.records[2].installmentNumber);
            expect(controller.getSelectedRows()).toHaveLength(1);
        });

        it('selects schedule records between two selected rows', async () => {
            const controller = new PauseFormTestController(component);
            await controller.selectRows([2,5]);

            expect(controller.getSelectedRows()).toHaveLength(4);
        });

        it('when any middle schedule record is deselected, automatically clears further records', async () => {
            const controller = new PauseFormTestController(component);
            await controller.selectRows([2,5]);
            expect(controller.getSelectedRows()).toHaveLength(4);

            controller.deselectRow(mockGetInstallments.dataTable.records[4].installmentNumber);
            await flushPromises();
            expect(controller.getSelectedRows()).toHaveLength(2);
        }, 500000);

        it('when first schedule record is deselected, no further records are automatically deselected', async () => {
            const controller = new PauseFormTestController(component);
            await controller.selectRows([2,5]);
            expect(controller.getSelectedRows()).toHaveLength(4);

            controller.deselectRow(mockGetInstallments.dataTable.records[2].installmentNumber);
            await flushPromises();
            expect(controller.getSelectedRows()).toHaveLength(3);
        });

        it('sends paused reason when saving a pause record', async () => {
            savePause.mockResolvedValue({});
            const controller = new PauseFormTestController(component);
            await controller.selectRows([2,5]);
            controller.setPauseReason('Some Fake Reason');
            await flushPromises();

            controller.save();
            const savePauseArgs = JSON.parse(savePause.mock.calls[0][0].jsonPauseData);
            expect(savePauseArgs).toMatchObject({
                rdId: FAKE_RD2_ID,
                pausedReason: {
                    value: "Some Fake Reason"
                }
            });
        });

        it('sends cancel event when cancel button is clicked', () => {
            const controller = new PauseFormTestController(component);
            controller.cancel();
            expect(mockHandleClose).toHaveBeenCalledTimes(1);
        });

        it('displays the number of selected installments', async () => {
            const controller = new PauseFormTestController(component);
            await controller.selectRows([2,5]);

            expect(controller.rowSummaryValue()).toBe("You've selected 4 installments.");
        });

        it('when installment(s) are selected to pause, displays the date donations will resume', async () => {
            const controller = new PauseFormTestController(component);
            await controller.selectRows([2,5]);

            expect(controller.firstDonationDateValue()).toBe('The first donation date after the pause period will be 4/18/2022.');
        });

    });


    describe('error states', () => {

        it('save button deactivates when all pause records deselected', async () => {
            getPauseData.mockResolvedValue(JSON.stringify(mockPauseData));
            getInstallments.mockResolvedValue(mockGetInstallments);
            document.body.appendChild(component);
            await flushPromises();

            getRecord.emit(mockWiredRecurringDonation, config => config.recordId === FAKE_RD2_ID);

            const controller = new PauseFormTestController(component);
            controller.selectRow(mockGetInstallments.dataTable.records[2].installmentNumber);
            controller.setPauseReason('Some Fake Pause Reason');
            expect(controller.getSelectedRows()).toHaveLength(1);
            await flushPromises();

            expect(controller.saveButton().disabled).toBeFalsy();

            controller.deselectRow(mockGetInstallments.dataTable.records[2].installmentNumber);
            await flushPromises();

            expect(controller.saveButton().disabled).toBeTruthy();
        });

        it('displays an error if user does not have access', async () => {
            const controller = new PauseFormTestController(component);
            getPauseData.mockResolvedValue(JSON.stringify({
                ...mockPauseData,
                hasAccess: false
            }));
            getInstallments.mockResolvedValue(mockGetInstallments);
            document.body.appendChild(component);
            await flushPromises();


            expect(controller.utilPageLevelMessage().subtitle).toBe(RD2_PausePermissionRequired);

        });

        it('displays an error if apex class RD2_PauseForm is inaccessible', async () => {
            const controller = new PauseFormTestController(component);
            getPauseData.mockRejectedValue({
                "status": 500,
                "body": {
                    "message": "You do not have access to the Apex class named 'RD2_PauseForm_CTRL'."
                },
                "headers": {}
            });
            getInstallments.mockResolvedValue(mockGetInstallments);
            document.body.appendChild(component);
            await flushPromises();


            expect(controller.utilPageLevelMessage().subtitle).toBe("You do not have access to the Apex class named 'RD2_PauseForm_CTRL'.");

        });

        it('on save, when PauseException encountered, displays error', async () => {
            const controller = new PauseFormTestController(component);
            savePause.mockRejectedValue(mockSavePauseException);
            getPauseData.mockResolvedValue(JSON.stringify(mockPauseData));
            getInstallments.mockResolvedValue(mockGetInstallments);
            document.body.appendChild(component);
            await flushPromises();

            getRecord.emit(mockWiredRecurringDonation, config => config.recordId === FAKE_RD2_ID);

            controller.selectRow(mockGetInstallments.dataTable.records[2].installmentNumber);
            controller.setPauseReason('Some Fake Reason');

            await flushPromises();

            controller.save();

            await flushPromises();

            expect(controller.utilPageLevelMessage().subtitle).toBe('Test exception message.');
        });


        it('when no permission to fields on installments, displays error', async () => {
            const controller = new PauseFormTestController(component);
            savePause.mockRejectedValue(mockSavePauseException);
            getPauseData.mockResolvedValue(JSON.stringify(mockPauseData));
            getInstallments.mockRejectedValue({
                "status": 500,
                "body": {
                    "message": "You don't have permissions to view Upcoming Installments. Please contact your system administrator for more information."
                },
                "headers": {}
            });
            document.body.appendChild(component);

            await flushPromises();

            expect(controller.utilPageLevelMessage().subtitle).toBe('You don\'t have permissions to view Upcoming Installments. Please contact your system administrator for more information.');
        });
    });
});


class PauseFormTestController {
    component;

    constructor(component) {
        this.component = component;
    }

    dataTable() {
        return this.component.shadowRoot.querySelector('lightning-datatable');
    }

    getSelectedRows() {
        return this.dataTable().getSelectedRows();
    }

    setPauseReason(value) {
        const field = this.pausedReason();
        field.value = value;
        field.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    }

    pausedReason() {
        return this.component.shadowRoot.querySelector("[data-id='pausedReason']");
    }

    save() {
        this.saveButton().click();
    }

    saveButton() {
        return this.component.shadowRoot.querySelector("[data-id='saveButton']");
    }

    cancel() {
        this.cancelButton().click();
    }

    cancelButton() {
        return this.component.shadowRoot.querySelector("[data-id='cancelButton']");
    }

    firstDonationDateValue() {
        return this.component.shadowRoot.querySelector("[data-id='firstDonationDateMessage']").value;
    }

    rowSummaryValue() {
        return this.component.shadowRoot.querySelector("[data-id='rowSummary']").value;
    }

    utilPageLevelMessage() {
        return this.component.shadowRoot.querySelector("c-util-page-level-message");
    }

    blockedReasonValue() {
        return this.component.shadowRoot.querySelector("[data-id='blockedReason']").value;
    }

    async selectRows(rowNumbers) {
        for(const rowNumber of rowNumbers) {
            this.selectRow(mockGetInstallments.dataTable.records[rowNumber].installmentNumber);
            await flushPromises();
        }
    }

    selectRow(installmentNumber) {
        const dataTable = this.dataTable();
        const selectedRows = this.dataTable().selectedRows;
        if(selectedRows === null || selectedRows === undefined) {
            dataTable.selectedRows = [ installmentNumber ]
        } else {
            dataTable.selectedRows = [ ...dataTable.selectedRows, installmentNumber ];
        }
        dataTable.dispatchEvent(new CustomEvent('rowselection'))
    }

    deselectRow(installmentNumber) {
        const dataTable = this.dataTable();
        const selectedRowIds = this.dataTable().selectedRows;
        if(selectedRowIds !== null && selectedRowIds !== undefined) {
            dataTable.selectedRows = selectedRowIds.filter(rowId => {
                return rowId !== installmentNumber;
            });
        }

        dataTable.dispatchEvent(new CustomEvent('rowselection'))
    }
}