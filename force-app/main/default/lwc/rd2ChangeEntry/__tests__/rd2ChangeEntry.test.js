import { createElement } from 'lwc';
import Rd2ChangeEntry from 'c/rd2ChangeEntry';


const getChangeEntry = () => {
    return {
        "changeDate": "2021-08-05",
        "fields": [
            {
                "displayType": "MONEY",
                "label": "Amount",
                "oldValue": 72
            },
            {
                "displayType": "MONEY",
                "label": "Annual Value",
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
       component.changeEntry = getChangeEntry();

       document.body.appendChild(component);

       const items = component.shadowRoot.querySelectorAll('c-rd2-change-entry-item');
       expect(items).toHaveLength(3);
    });

    it('renders date from change entry', () => {
        const component = createElement('c-rd2-change-entry', { is: Rd2ChangeEntry });
        component.changeEntry = getChangeEntry();

        document.body.appendChild(component);

        const dateTimeComponent = component.shadowRoot.querySelector('lightning-formatted-date-time');
        expect(dateTimeComponent.value).toBe('2021-08-05');
    });
})