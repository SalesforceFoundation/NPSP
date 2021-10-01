import RdScheduleVisualizer from 'c/rdScheduleVisualizer';
import { getRecord } from 'lightning/uiRecordApi';
import { createElement } from 'lwc';
import getInstallments from '@salesforce/apex/RD2_VisualizeScheduleController.getInstallments';

const getInstallmentsResponse = require('./data/getInstallments.json');
const getInstallmentsErrorResponse = require('./data/getInstallmentsError.json');

jest.mock('@salesforce/apex/RD2_VisualizeScheduleController.getInstallments',
    () => {
        return {
            default: jest.fn()
        }
    },
    {virtual: true}
);
const FAKE_RD2_ID = '00A_fake_rd2_id';

afterEach(() => {
    clearDOM();
    jest.clearAllMocks();
});

describe('rendering a schedule', () => {

    let element;

    beforeEach(() => {
        element = createScheduleVisualizer();
    });

    it('renders a list of installments', async () => {

        getInstallments.mockResolvedValue(getInstallmentsResponse);

        getRecord.emit({}, ({recordId}) => recordId === FAKE_RD2_ID);

        await flushPromises();

        const lightningDatatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(lightningDatatable).toBeTruthy();
        expect(lightningDatatable.isLoading).toBeFalsy();
        expect(lightningDatatable.data.length).toBe(12);
        expect(lightningDatatable.data).toMatchObject(getInstallmentsResponse.dataTable.records);
    });

    it('passes column information to lightning-datatable', async () => {

        getInstallments.mockResolvedValue(getInstallmentsResponse);

        getRecord.emit({}, ({recordId}) => recordId === FAKE_RD2_ID);

        await flushPromises();

        const lightningDatatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(lightningDatatable).toBeTruthy();
        expect(lightningDatatable.columns.length).toBe(3);
        expect(lightningDatatable.columns).toMatchObject(getInstallmentsResponse.dataTable.columns);
    });

    it('highlights skipped installments', async () => {
        getInstallmentsResponse.dataTable.records[0].isSkipped = true;
        getInstallmentsResponse.dataTable.records[1].isSkipped = true;

        getInstallments.mockResolvedValue(getInstallmentsResponse);

        getRecord.emit({}, ({recordId}) => recordId === FAKE_RD2_ID);

        await flushPromises();

        const lightningDatatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(lightningDatatable.selectedRows).toContain(1);
        expect(lightningDatatable.selectedRows).toContain(2);
        expect(lightningDatatable.selectedRows.length).toBe(2);
    });

});

describe('error states', () => {

    let element;

    beforeEach(() => {
        element = createScheduleVisualizer();
        getInstallments.mockRejectedValue(getInstallmentsErrorResponse);
    });

    it('renders a provided error message', async () => {
        getRecord.emit({}, ({recordId}) => recordId === FAKE_RD2_ID);

        await flushPromises();

        const errorSpan = element.shadowRoot.querySelector('div[data-qa-locator="error"] span');
        expect(errorSpan).toBeTruthy();
        expect(errorSpan.textContent).toBe("You must enable Enhanced Recurring Donations to use this component.");
    });

    it('does not render lightning-datatable', async () => {
        getRecord.emit({}, ({recordId}) => recordId === FAKE_RD2_ID);

        await flushPromises();
        const lightningDatatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(lightningDatatable).toBeFalsy();
    });
});

const createScheduleVisualizer = () => {

    const element = createElement('c-rd-schedule-visualizer', { is: RdScheduleVisualizer });
    element.recordId = FAKE_RD2_ID;
    element.displayNum = 12;
    document.body.appendChild(element);
    return element;
}