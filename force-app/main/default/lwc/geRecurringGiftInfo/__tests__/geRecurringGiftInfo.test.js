import { createElement } from 'lwc';
import GeRecurringGiftInfo from 'c/geRecurringGiftInfo';

import RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import EFFECTIVE_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';
import INSTALLMENTS from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c';
import DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DATE from '@salesforce/schema/DataImport__c.Donation_Date__c';

// Mock custom labels with parameters to assert values are replaced with expected values
jest.mock("@salesforce/label/c.geOpenEndedGiftSchedule", () => {
    return { default: 'Recurring Schedule Information: {0} {1} donation starting on {2}.' };
}, { virtual: true });

jest.mock("@salesforce/label/c.geFixedGiftSchedule", () => {
    return {
        default: 'Recurring Schedule Information: {0} {1} donation starting on {2} and ending after {3} installments.'
    };
}, { virtual: true });

const dataImportFields = {
    donationAmount: DONATION_AMOUNT.fieldApiName,
    donationDate: DONATION_DATE.fieldApiName
}
const scheduleFields = {
    recurringType: RECURRING_TYPE.fieldApiName,
    installmentPeriod: INSTALLMENT_PERIOD.fieldApiName,
    effectiveDate: EFFECTIVE_DATE.fieldApiName,
    installments: INSTALLMENTS.fieldApiName
}

describe('c-ge-modal-recurring-donation', () => {
    afterEach(() => {
        clearDOM();
    });

    const setup = (donationAmount, donationDate, schedule) => {
        const infoCard = createElement('c-ge-modal-recurring-donation', {
            is: GeRecurringGiftInfo
        });
        if (!schedule) {
            infoCard.schedule = {
                [scheduleFields.recurringType]: 'Open',
                [scheduleFields.effectiveDate]: '2022-01-31',
                [scheduleFields.installmentPeriod]: 'Monthly'
            }
        } else {
            infoCard.schedule = schedule;
        }
        infoCard.giftInView = {
            fields: {
                [dataImportFields.donationAmount]: donationAmount,
                [dataImportFields.donationDate]: donationDate
            },
            schedule: schedule
        }
        document.body.appendChild(infoCard);
        return infoCard;
    }

    describe('render behavior', () => {
        it('renders header text', async () => {
            const infoCard = setup();
            await flushPromises();

            const header = infoCard.shadowRoot.querySelector('[data-id="scheduleHeader"]');

            expect(header).toBeDefined();
            expect(header.textContent).toBe('c.geRecurringScheduleInformation');
        });

        it('renders expected text for open ended schedules', async () => {
            const infoCard = setup(
                100,
                '2022-01-31',
                {
                    [scheduleFields.recurringType]: 'Open',
                    [scheduleFields.effectiveDate]: '2022-01-31',
                    [scheduleFields.installmentPeriod]: 'Monthly'
                }
            );
            await flushPromises();

            const schedule = infoCard.shadowRoot.querySelector('[data-id="scheduleInfo"]');

            expect(schedule).toBeDefined();
            expect(schedule.textContent)
                .toBe('Recurring Schedule Information: $100.00 monthly donation starting on January 31, 2022.');
        });

        it('renders expected text for fixed schedules', async () => {
            const infoCard = setup(
                100,
                '2022-01-31',
                {
                    [scheduleFields.recurringType]: 'Fixed',
                    [scheduleFields.effectiveDate]: '2022-01-31',
                    [scheduleFields.installmentPeriod]: 'Monthly',
                    [scheduleFields.installments]: '12'
                }
            );
            await flushPromises();

            const schedule = infoCard.shadowRoot.querySelector('[data-id="scheduleInfo"]');

            expect(schedule).toBeDefined();
            expect(schedule.textContent)
                .toBe('Recurring Schedule Information: $100.00 monthly donation starting on January 31, 2022 '
                + 'and ending after 12 installments.');
        });

        it('renders empty string for incomplete gift view', async () => {
            const infoCard = setup(
                100,
                '2022-01-31',
                {
                    [scheduleFields.recurringType]: 'INVALID',
                    [scheduleFields.effectiveDate]: 'INVALID',
                    [scheduleFields.installmentPeriod]: 'INVALID'
                }
            );
            await flushPromises();

            const schedule = infoCard.shadowRoot.querySelector('[data-id="scheduleInfo"]');

            expect(schedule).toBeDefined();
            expect(schedule.textContent).toBe('');
        });

        it('renders 0 for NaN donation amount', async () => {
            const infoCard = setup(
                undefined,
                '2022-01-31',
                {
                    [scheduleFields.recurringType]: 'Open',
                    [scheduleFields.effectiveDate]: '2022-01-31',
                    [scheduleFields.installmentPeriod]: 'Monthly',
                }
            );
            await flushPromises();

            const schedule = infoCard.shadowRoot.querySelector('[data-id="scheduleInfo"]');

            expect(schedule).toBeDefined();
            expect(schedule.textContent)
                .toBe('Recurring Schedule Information: $0.00 monthly donation starting on January 31, 2022.');
        });

        it('renders edit and remove recurrence buttons', async () => {
            const infoCard = setup();
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
            const infoCard = setup();
            infoCard.dispatchEvent = mockEventDispatch;
            await flushPromises();

            const editButton = infoCard.shadowRoot.querySelector('[data-id="edit"]');
            editButton.click();
            await flushPromises();

            expect(mockEventDispatch).toHaveBeenCalled();
        });

        it('should dispatch event to parent when remove recurrence button is clicked', async () => {
            const mockEventDispatch = jest.fn();
            const infoCard = setup();
            infoCard.dispatchEvent = mockEventDispatch;
            await flushPromises();

            const removeRecurrence = infoCard.shadowRoot.querySelector('[data-id="removeSchedule"]');
            removeRecurrence.click();
            await flushPromises();

            expect(mockEventDispatch).toHaveBeenCalled();
        });
    });
});