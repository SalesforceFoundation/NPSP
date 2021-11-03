import { createElement } from 'lwc';
import GeFormWidgetRowAllocation from 'c/geFormWidgetRowAllocation';

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

        it('places focus on the first input field', async () => {
            const rowElement = createAllocationRowElement();
            document.body.appendChild(rowElement);

            const inputFields = rowElement.shadowRoot.querySelectorAll('lightning-input-field');
            const gauLookup = inputFields[0];
            gauLookup.focus = jest.fn();

            await Promise.resolve();
            jest.runOnlyPendingTimers();
            expect(gauLookup.focus).toHaveBeenCalled();
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