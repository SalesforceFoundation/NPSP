import { createElement } from 'lwc';
import rd2EntryForm from 'c/rd2EntryForm';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

import getSetting from '@salesforce/apex/RD2_entryFormController.getRecurringSettings';
import checkRequiredFieldPermissions from '@salesforce/apex/RD2_entryFormController.checkRequiredFieldPermissions';

// Register as Apex wire adapter. Some tests verify that provisioned values trigger desired behavior.
const getAccountListAdapter = registerApexTestWireAdapter(getSetting);

// Realistic data
const mockGetSettings = require('./data/getSettings.json');

describe('c-rd2-entry-form', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        // Prevent data saved on mocks from leaking between tests
        jest.clearAllMocks();
    });

    describe('getSetting @wire data', () => {
        it('renders 1 records', () => {
            const element = createElement('c-rd2-entry-form', {
                is: rd2EntryForm
            });
            document.body.appendChild(element);

            // Emit data from @wire
            getAccountListAdapter.emit(mockGetSettings);

            return Promise.resolve().then(() => {
            });
        });
    });

    /*it('displays unit status with default unitNumber', () => {
        const element = createElement('c-rd2-entry-form', {
            is: rd2EntryForm
        });
        expect(element.unitNumber).toBe(5);
        // Add the element to the jsdom instance
        document.body.appendChild(element);
        // Verify displayed greeting
        const div = element.shadowRoot.querySelector('div');
        expect(div.textContent).toBe('Unit 5 alive!');
    });

    it('displays unit status with updated unitNumber', () => {
        const element = createElement('c-rd2-entry-form', {
            is: rd2EntryForm
        });
        // Add the element to the jsdom instance
        document.body.appendChild(element);
        // Update unitNumber after element is appended
        element.unitNumber = 6
        const div = element.shadowRoot.querySelector('div');
        // Verify displayed unit status
        expect(div.textContent).not.toBe('Unit 6 alive!');
        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return Promise.resolve().then(() => {
            expect(div.textContent).toBe('Unit 6 alive!');
        });
    });

    it('displays unit status with input change event', () => {
        const element = createElement('c-rd2-entry-form', {
            is: rd2EntryForm
        });
        document.body.appendChild(element);
        const div = element.shadowRoot.querySelector('div');
        // Trigger unit status input change
        const inputElement = element.shadowRoot.querySelector('lightning-input');
        inputElement.value = 7;
        inputElement.dispatchEvent(new CustomEvent('change'));
        return Promise.resolve().then(() => {
            expect(div.textContent).toBe('Unit 7 alive!');
        });
    });*/

});
