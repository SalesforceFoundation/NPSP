import { createElement } from 'lwc';

import rd2StatusAutomationSettings from 'c/rd2StatusAutomationSettings';
import getAutomationSettings from '@salesforce/apex/RD2_StatusAutomationSettings_CTRL.getAutomationSettings';
import saveStatusAutomationSettings from '@salesforce/apex/RD2_StatusAutomationSettings_CTRL.saveStatusAutomationSettings';

const mockStatusAutomationView = require('./data/statusAutomationView.json');

jest.mock('@salesforce/apex/RD2_StatusAutomationSettings_CTRL.getAutomationSettings',
    () => ({ default : jest.fn() }),
    { virtual : true}
);

jest.mock('@salesforce/apex/RD2_StatusAutomationSettings_CTRL.saveStatusAutomationSettings',
    () => ({ default : jest.fn() }),
    { virtual : true}
);

describe('c-rd2-status-automation-settings', () => {
    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('All UI should load correctly', async () => {
        const component = createElement('c-rd2-status-automation-settings', { is: rd2StatusAutomationSettings });
        saveStatusAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        getAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        document.body.appendChild(component);
        await flushPromises();

        const header = component.shadowRoot.querySelector('h3');
        expect(header).not.toBeNull();
        expect(header.textContent).toBe('c.RD2_StatusAutomationConfigurationSection');
        expect(editButton(component).title).toBe('c.stgBtnEdit');
        expect(allReadOnlyValue(component)).toHaveLength(5);
    });

    it('Edit form should loaded once edit button is clicked', async () => {
        const component = createElement('c-rd2-status-automation-settings', { is: rd2StatusAutomationSettings });
        saveStatusAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        getAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        document.body.appendChild(component);
        await flushPromises();

        editButton(component).click();
        await flushPromises();

        expect(editButton(component)).toBeFalsy();
        expect(saveButton(component)).toBeTruthy();
        expect(saveButton(component).title).toBe('c.stgBtnSave');
        expect(cancelButton(component)).toBeTruthy();
        expect(cancelButton(component).title).toBe('c.stgBtnCancel');
        expect(allReadOnlyValue(component)).toHaveLength(1);
        expect(lapsedDaysInput(component)).toBeTruthy();
        expect(lapsedDaysInput(component).label).toBe('c.RD2_StatusAutomationDaysForLapsed');
        expect(closedDaysInput(component).label).toBe('c.RD2_StatusAutomationDaysForClosed');
    });

    it('When editing and cancel button is clicked, edit button should reappear', async () => {
        const component = createElement('c-rd2-status-automation-settings', { is: rd2StatusAutomationSettings });
        saveStatusAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        getAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        document.body.appendChild(component);
        await flushPromises();

        editButton(component).click();
        await flushPromises();

        cancelButton(component).click();
        await flushPromises();

        const header = component.shadowRoot.querySelector('h3');
        expect(header).not.toBeNull();
        expect(header.textContent).toBe('c.RD2_StatusAutomationConfigurationSection');
        expect(editButton(component).title).toBe('c.stgBtnEdit');
        expect(allReadOnlyValue(component)).toHaveLength(5);
        expect(lapsedDaysInput(component)).toBeFalsy;
        expect(closedDaysInput(component)).toBeFalsy;
    });

    it('After saving, edit button should reappear', async () => {
        const component = createElement('c-rd2-status-automation-settings', { is: rd2StatusAutomationSettings });
        saveStatusAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        getAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        document.body.appendChild(component);
        await flushPromises();

        editButton(component).click();
        await flushPromises();

        saveButton(component).click();
        await flushPromises();

        const header = component.shadowRoot.querySelector('h3');
        expect(header).not.toBeNull();
        expect(header.textContent).toBe('c.RD2_StatusAutomationConfigurationSection');
        expect(editButton(component).title).toBe('c.stgBtnEdit');
        expect(allReadOnlyValue(component)).toHaveLength(5);
        expect(lapsedDaysInput(component)).toBeFalsy;
        expect(closedDaysInput(component)).toBeFalsy;
    });


    it('when rd2 is disabled, renders the disabled state', async () => {
        const component = createElement('c-rd2-status-automation-settings', { is: rd2StatusAutomationSettings });
        saveStatusAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        mockStatusAutomationView.rd2Enabled = false;
        getAutomationSettings.mockResolvedValue(mockStatusAutomationView);
        
        document.body.appendChild(component);
        await flushPromises();

        const illustration = component.shadowRoot.querySelector('c-util-illustration');
        expect(illustration).toBeTruthy();
    });
});

const cancelButton = (component) => {
    return component.shadowRoot.querySelector('lightning-button[data-id="cancelButton"]');
}
const editButton = (component) => {
    const button = component.shadowRoot.querySelector('lightning-button[data-id="editButton"]');
    return button;
}

const saveButton = (component) => {
    return component.shadowRoot.querySelector('lightning-button[data-id="saveButton"]');
}

const allReadOnlyValue = (component) => {
    return component.shadowRoot.querySelectorAll('span');
}

const lapsedDaysInput = (component) => {
    return component.shadowRoot.querySelector("lightning-input[data-id=lapsedDaysInput]");
}

const closedDaysInput = (component) => {
    return component.shadowRoot.querySelector("lightning-input[data-id=closedDaysInput]")
}