import { createElement } from 'lwc';
import PotentialDuplicates from 'c/potentialDuplicates';
import lblPotentialDuplicatesFoundNone from '@salesforce/label/c.potentialDuplicatesFoundNone';
import lblPotentialDuplicatesFoundOne from '@salesforce/label/c.potentialDuplicatesFoundOne';
import lblPotentialDuplicatesFoundMultiple from '@salesforce/label/c.potentialDuplicatesFoundMultiple';

const createComponentForTest = (config = {}) => {
    const el = createElement('c-potential-duplicates', {
        is: PotentialDuplicates
    });
    Object.assign(el, config);
    el.displayCard = true;
    document.body.appendChild(el);
    return el;
};

describe('c-potential-duplicates', () => {
    it('renders the component with no link', () => {
       const component = createComponentForTest();

    //    const duplicateLink = component.shadowRoot.querySelector('data-qa-locator="viewDuplicatesURL"');
       const heading = component.shadowRoot.querySelector('h1');
       expect(heading.textContent).toBe(lblPotentialDuplicatesFoundNone);
       const duplicateLink = component.shadowRoot.querySelector('[data-qa-locator="viewDuplicatesURL"]');
       expect(duplicateLink).toBeFalsy();
    });
    it('renders the component with a duplicate link', () => {
        
        // TODO: Mock getDuplicates to return a string
        const component = createComponentForTest();
 
        const heading = component.shadowRoot.querySelector('h1');
        expect(heading.textContent).toBe(lblPotentialDuplicatesFoundOne);
        const duplicateLink = component.shadowRoot.querySelector('[data-qa-locator="viewDuplicatesURL"]');
        expect(duplicateLink).toBeTruthy();
     });
})