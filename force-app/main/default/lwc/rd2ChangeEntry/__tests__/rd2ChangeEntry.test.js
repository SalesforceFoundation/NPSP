import { createElement } from 'lwc';
import Rd2ChangeEntry from 'c/rd2ChangeEntry';


const getChangeEntry = () => {
    return {
        "changeDate": "2021-08-05",
        "changeType": "Upgrade",
        "fields": [
            {
                "displayType": "MONEY",
                "label": "Amount",
                "newValue": 100,
                "oldValue": 72
            },
            {
                "displayType": "MONEY",
                "label": "Annual Value",
                "newValue": 100,
                "oldValue": 72
            },
            {
                "displayType": "LOOKUP",
                "label": "Campaign",
                "newId": "701P0000000a2PHIAY",
                "newValue": "First Campaign"
            }
        ]
    }
};

describe('c-rd2-change-entry', () => {
    it('renders three change entry items', () => {
       const component = createElement('c-rd2-change-entry', { is: Rd2ChangeEntry });
       component.entryItem = getChangeEntry();

       document.body.appendChild(component);

       const items = component.shadowRoot.querySelectorAll('c-rd2-change-entry-item');
       expect(items).toHaveLength(3);
    });

    it('renders date from change entry', () => {
        const component = createElement('c-rd2-change-entry', { is: Rd2ChangeEntry });
        component.entryItem = getChangeEntry();

        document.body.appendChild(component);

        const dateTimeComponent = component.shadowRoot.querySelector('lightning-formatted-date-time');
        expect(dateTimeComponent.value).toBe('2021-08-05');
    });

    it('applies styling to upgrades', () => {
        const component = createElement('c-rd2-change-entry', { is: Rd2ChangeEntry });
        component.entryItem = getChangeEntry();

        document.body.appendChild(component);

        const badgeComponent = component.shadowRoot.querySelector('lightning-badge');
        expect(badgeComponent.classList).toContain('slds-theme_success');
    });

    it('applies styling to downgrades', () => {
        const component = createElement('c-rd2-change-entry', { is: Rd2ChangeEntry });
        const changeEntry = getChangeEntry();
        changeEntry.changeType = 'Downgrade';
        component.entryItem = changeEntry;

        document.body.appendChild(component);

        const badgeComponent = component.shadowRoot.querySelector('lightning-badge');
        expect(badgeComponent.classList).toContain('slds-theme_error');
    });
})