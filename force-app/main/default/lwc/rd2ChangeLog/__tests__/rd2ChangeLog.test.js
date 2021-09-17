import { createElement } from 'lwc';
import Rd2ChangeLog from 'c/rd2ChangeLog';
import getChangeLog from '@salesforce/apex/RD2_ChangeLogController.getChangeLog';
import commonViewMore from '@salesforce/label/c.commonViewMore';
import commonError from '@salesforce/label/c.commonError';
import rdclNoRecords from '@salesforce/label/c.RDCL_No_Records';

import { getNavigateCalledWith } from "lightning/navigation";

const mockChangeLogView = require('./data/changeLogView.json');

jest.mock('@salesforce/apex/RD2_ChangeLogController.getChangeLog',
    () => ({ default : jest.fn() }),
    { virtual: true }
);

describe('c-rd2-change-entry-item', () => {

    afterEach(() => {
        clearDOM();
    });

    it('when additional records present renders view more link', async () => {
        const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeLog });
        getChangeLog.mockResolvedValue(mockChangeLogView);
        document.body.appendChild(component);
        await flushPromises();

        const aTag = component.shadowRoot.querySelector('a');
        expect(aTag.textContent).toBe(commonViewMore);
    });

    it('view more link onclick navigates to related list', async () => {
        const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeLog });
        getChangeLog.mockResolvedValue(mockChangeLogView);
        document.body.appendChild(component);
        await flushPromises();

        const aTag = component.shadowRoot.querySelector('a');

        aTag.click();

        const { pageReference } = getNavigateCalledWith();

        expect(pageReference.type).toBe('standard__recordRelationshipPage');
        expect(pageReference.attributes.recordId).toBe(component.recordId);
        expect(pageReference.attributes.objectApiName).toBe('npe03__Recurring_Donation__c');
        expect(pageReference.attributes.relationshipApiName).toBe('RDChangeLog__r');
        expect(pageReference.attributes.actionName).toBe('view');
    });

    it('when change log setting is disabled, renders an error state', async () => {
        const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeLog });
        mockChangeLogView.settingEnabled = false;
        getChangeLog.mockResolvedValue(mockChangeLogView);
        document.body.appendChild(component);
        await flushPromises();

        const illustration = component.shadowRoot.querySelector('c-util-illustration');
        expect(illustration).toBeTruthy();
    });

    it('when no records are present, renders empty list state', async () => {
        const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeLog });
        mockChangeLogView.settingEnabled = true;
        mockChangeLogView.changes = [];

        getChangeLog.mockResolvedValue(mockChangeLogView);
        document.body.appendChild(component);
        await flushPromises();

        const illustration = component.shadowRoot.querySelector('c-util-illustration');
        expect(illustration).toBeTruthy();
        expect(illustration.message).toBe(rdclNoRecords);
    });

});




