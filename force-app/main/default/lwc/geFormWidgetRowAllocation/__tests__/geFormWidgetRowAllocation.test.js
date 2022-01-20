import { createElement } from 'lwc';
import GeFormWidgetRowAllocation from 'c/geFormWidgetRowAllocation';
import GAU_FIELD from '@salesforce/schema/Allocation__c.General_Accounting_Unit__c';

jest.useFakeTimers();

describe('c-geFormWidgetRowAllocation', () => {

    afterEach(clearDOM);

    describe('render behavior', () => {
        it('renders expected base lightning components', async () => {
            const rowElement = createAllocationRowElement();
            document.body.appendChild(rowElement);

            expect(rowElement.shadowRoot.querySelectorAll('lightning-input-field').length).toBe(2);
            expect(rowElement.shadowRoot.querySelectorAll('lightning-input').length).toBe(1);
            expect(rowElement.shadowRoot.querySelectorAll('lightning-button').length).toBe(1);
        });

        it('places focus on the GAU lookup field', async () => {
            const rowElement = createAllocationRowElement();
            document.body.appendChild(rowElement);

            const gauLookup = queryLightningInputField(rowElement, GAU_FIELD.fieldApiName);
            gauLookup.focus = jest.fn();

            await Promise.resolve();
            jest.runOnlyPendingTimers();
            expect(gauLookup.focus).toHaveBeenCalled();
        });

        it('does not place focus on the GAU lookup field on existing allocations', async () => {
            const rowElement = createAllocationRowElement({
                record: {
                    id: 'dummy_id',
                    [GAU_FIELD.fieldApiName]: {
                        value: 'dummy_value'
                    }
                }
            });
            document.body.appendChild(rowElement);

            const gauLookup = queryLightningInputField(rowElement, GAU_FIELD.fieldApiName);
            gauLookup.focus = jest.fn();

            await Promise.resolve();
            jest.runOnlyPendingTimers();
            expect(gauLookup.focus).not.toHaveBeenCalled();
        });
    });
});

function createAllocationRowElement(row) {
    const element = createElement('c-geFormWidgetRowAllocation', {
        is: GeFormWidgetRowAllocation
    });
    element.row = {
        record: {}
    }
    if (row) element.row = row;
    return element;
}

function queryLightningInputField(rowElement, dataFieldName) {
    const inputFields = rowElement
        .shadowRoot
        .querySelectorAll(`lightning-input-field[data-fieldname="${dataFieldName}"]`);
    return inputFields[0];
}