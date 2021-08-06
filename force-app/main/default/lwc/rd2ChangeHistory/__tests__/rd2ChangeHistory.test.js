import { createElement } from 'lwc';
import Rd2ChangeHistory from 'c/rd2ChangeHistory';
import getChangeHistory from '@salesforce/apex/RD2_ChangeHistoryController.getChangeHistory';
import commonViewMore from '@salesforce/label/c.commonViewMore';

import { getNavigateCalledWith } from "lightning/navigation";

const mockChangeHistoryView = require('./data/changeHistoryView.json');

jest.mock('@salesforce/apex/RD2_ChangeHistoryController.getChangeHistory',
    () => ({ default : jest.fn() }),
    { virtual: true }
);

describe('c-rd2-change-entry-item', () => {

    afterEach(() => {
        clearDOM();
    });

    it('when additional records present renders view more link', async () => {
        const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeHistory });
        getChangeHistory.mockResolvedValue(mockChangeHistoryView);
        document.body.appendChild(component);
        await flushPromises();

        const aTag = component.shadowRoot.querySelector('a');
        expect(aTag.textContent).toBe(commonViewMore);

    });

    it('view more link onclick navigates to related list', async () => {
        const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeHistory });
        getChangeHistory.mockResolvedValue(mockChangeHistoryView);
        document.body.appendChild(component);
        await flushPromises();

        const aTag = component.shadowRoot.querySelector('a');

        aTag.click();

        const { pageReference } = getNavigateCalledWith();

        expect(pageReference.type).toBe('standard__recordRelationshipPage');
        expect(pageReference.attributes.recordId).toBe(component.recordId);
        expect(pageReference.attributes.objectApiName).toBe('npe03__Recurring_Donation__c');
        expect(pageReference.attributes.relationshipApiName).toBe('RDChangeHistory__r');
        expect(pageReference.attributes.actionName).toBe('view');
    })
});




