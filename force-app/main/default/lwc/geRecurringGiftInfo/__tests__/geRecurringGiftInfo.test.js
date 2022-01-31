import { createElement } from 'lwc';
import GeRecurringGiftInfo from 'c/GeRecurringGiftInfo';

describe('c-ge-modal-recurring-donation', () => {
    afterEach(() => {
        clearDOM();
    });

    const setup = (schedule) => {
        const infoCard = createElement('c-ge-modal-recurring-donation', {
            is: GeRecurringGiftInfo
        });
        infoCard.schedule = schedule;
        document.body.appendChild(infoCard);
        return infoCard;
    }

    describe('render behavior', () => {
        it('renders schedule data', async () => {
            const infoCard = setup({
                RecurringType__c: 'Open',
                StartDate__c: '2020-01-01',
                npe03__Installment_Period__c: 'Monthly'
            });
            await flushPromises();

            const schedule = infoCard.shadowRoot.querySelector('[data-id="scheduleInfo"]');

            expect(schedule).toBeDefined();
            expect(schedule.textContent).toBe('Recurring info: Open, 2020-01-01, Monthly');
        });

        it('renders edit and remove recurrence buttons', async () => {
            const infoCard = setup({ RecurringType__c: 'Open' });
            await flushPromises();

            const buttons = infoCard.shadowRoot.querySelectorAll('lightning-button');
            const editButton = infoCard.shadowRoot.querySelector('[data-id="edit"]');
            const removeRecurrenceButton = infoCard.shadowRoot.querySelector('[data-id="removeSchedule"]');

            expect(buttons.length).toBe(2);
            expect(editButton.label).toBe('c.commonEdit');
            expect(removeRecurrenceButton.label).toBe('c.geRemoveSchedule');
        });
    });

    describe('event behavior', () => {
        it('should dispatch event to parent when edit button is clicked', async () => {
            const mockEventDispatch = jest.fn();
            const infoCard = setup({ RecurringType__c: 'Open' });
            infoCard.dispatchEvent = mockEventDispatch;
            await flushPromises();

            const editButton = infoCard.shadowRoot.querySelector('[data-id="edit"]');
            editButton.click();
            await flushPromises();

            expect(mockEventDispatch).toHaveBeenCalled();
        });

        it('should dispatch event to parent when remove recurrence button is clicked', async () => {
            const mockEventDispatch = jest.fn();
            const infoCard = setup({ RecurringType__c: 'Open' });
            infoCard.dispatchEvent = mockEventDispatch;
            await flushPromises();

            const removeRecurrence = infoCard.shadowRoot.querySelector('[data-id="removeRecurrence"]');
            removeRecurrence.click();
            await flushPromises();

            expect(mockEventDispatch).toHaveBeenCalled();
        });
    });
});