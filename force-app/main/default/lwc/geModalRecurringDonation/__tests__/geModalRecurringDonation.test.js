import { createElement } from 'lwc';
import GeModalRecurringDonation from 'c/GeModalRecurringDonation';

describe('c-ge-modal-recurring-donation', () => {
    afterEach(() => {
        clearDOM();
    });

    const setup = (cancelCallback, createRecurrenceCallback) => {
        const modalElement = createElement('c-ge-modal-recurring-donation', {
            is: GeModalRecurringDonation
        });
        modalElement.cancelCallback = cancelCallback;
        modalElement.createRecurrenceCallback = createRecurrenceCallback;
        document.body.appendChild(modalElement);
        return modalElement;
    }

    describe('render behavior', () => {
        it('renders rd2EntryFormScheduleSection component', async () => {
            const modalElement = setup();
            await flushPromises();

            const scheduleComponent = modalElement.shadowRoot.querySelector('[data-id="scheduleComponent"]');

            expect(scheduleComponent).toBeDefined();
        });

        it('renders cancel and create recurrence buttons', async () => {
            const modalElement = setup();
            await flushPromises();

            const buttons = modalElement.shadowRoot.querySelectorAll('lightning-button');
            const cancelButton = buttons[0];
            const createRecurrenceButton = buttons[1];
            console.log(buttons);

            expect(buttons.length).toBe(2);
            expect(cancelButton).toBeDefined();
            expect(cancelButton.label).toBe('Cancel');
            expect(createRecurrenceButton).toBeDefined();
            expect(createRecurrenceButton.label).toBe('Create Recurrence');
        });
    });

    describe('callback behavior', () => {
        it('calls provided callback for cancel button', async () => {
            const mockCancelButtonCallback = jest.fn();
            const modalElement = setup(mockCancelButtonCallback);
            await flushPromises();

            const buttons = modalElement.shadowRoot.querySelectorAll('lightning-button');
            const cancelButton = buttons[0];
            cancelButton.click();

            expect(mockCancelButtonCallback).toHaveBeenCalled();
        });

        it('calls provided callback for create recurrence button', async () => {
            const mockCreateRecurrenceCallback = jest.fn();
            const modalElement = setup(jest.fn(), mockCreateRecurrenceCallback);

            const scheduler = modalElement.shadowRoot.querySelector('[data-id="scheduleComponent"]');
            scheduler.isValid = jest.fn(() => true);
            scheduler.returnValues = jest.fn(() => ({
                dummyField: 'dummyValue'
            }));
            await flushPromises();

            const buttons = modalElement.shadowRoot.querySelectorAll('lightning-button');
            const createRecurrenceButton = buttons[1];
            createRecurrenceButton.click();

            expect(mockCreateRecurrenceCallback).toHaveBeenCalled();
            expect(mockCreateRecurrenceCallback).toHaveBeenCalledWith({
                dummyField: 'dummyValue'
            });
        });
    });
});