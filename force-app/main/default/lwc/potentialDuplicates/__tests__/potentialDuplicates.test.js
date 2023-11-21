import { createElement } from 'lwc';
import PotentialDuplicates from 'c/potentialDuplicates';
import getDuplicates from '@salesforce/apex/PotentialDuplicates.getDuplicates';
import lblPotentialDuplicatesFoundNone from '@salesforce/label/c.potentialDuplicatesFoundNone';
import lblPotentialDuplicatesFoundOne from '@salesforce/label/c.potentialDuplicatesFoundOne';
import lblPotentialDuplicatesFoundMultiple from '@salesforce/label/c.potentialDuplicatesFoundMultiple';
import lblViewDuplicates from '@salesforce/label/c.viewDuplicates';

jest.mock('@salesforce/apex/PotentialDuplicates.getDuplicates',
    () => ({ default : jest.fn() }),
    { virtual: true }
);

const createComponentForTest = () => {
    const el = createElement('c-potential-duplicates', {
        is: PotentialDuplicates
    });
    Object.assign(el);
    el.recordId = 'fakeId';
    el.displayCard = true;
    document.body.appendChild(el);
    return el;
};

describe('Potential Duplicates Component', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('renders the component with no link', async () => {
        getDuplicates.mockResolvedValue({});
        const el = createComponentForTest();
        await flushPromises();

        const heading = el.shadowRoot.querySelector('h1');
        expect(heading.textContent).toBe(lblPotentialDuplicatesFoundNone);
        const duplicateLink = el.shadowRoot.querySelector('[data-qa-locator="viewDuplicatesURL"]');
        expect(duplicateLink).toBeFalsy();
    });

    it('renders the component with a duplicate link', async () => {
        getDuplicates.mockResolvedValue({"setOfMatches" : "anotherId"});
        const el = createComponentForTest();
        await flushPromises();

        expect(getDuplicates).toHaveBeenCalled();
        const heading = el.shadowRoot.querySelector('h1');
        expect(heading.textContent).toBe(lblPotentialDuplicatesFoundOne);
        const duplicateLink = el.shadowRoot.querySelector('[data-qa-locator="viewDuplicatesURL"] a');
        expect(duplicateLink).not.toBeNull();
        expect(duplicateLink.textContent).toBe(lblViewDuplicates);
     });

     it('text changes for multiple duplicates', async () => {
        getDuplicates.mockResolvedValue({"setOfMatches" : "anotherId,moreIds,lastId"});
        const el = createComponentForTest();
        await flushPromises();

        expect(getDuplicates).toHaveBeenCalled();
        const heading = el.shadowRoot.querySelector('h1');
        expect(heading.textContent).toBe(lblPotentialDuplicatesFoundMultiple);
        const duplicateLink = el.shadowRoot.querySelector('[data-qa-locator="viewDuplicatesURL"] a');
        expect(duplicateLink).not.toBeNull();
        expect(duplicateLink.textContent).toBe(lblViewDuplicates);
     });

     it('renders an error when callout fails', async () => {
        getDuplicates.mockRejectedValue({"status" : "fail", "body" : {"message" : "test"}});
        const el = createComponentForTest();
        await flushPromises();

        const heading = el.shadowRoot.querySelector('h1');
        expect(heading.textContent).toBe(lblPotentialDuplicatesFoundNone);
        const error = el.shadowRoot.querySelector('[data-qa-locator="error"]');
        expect(error).not.toBeNull();
    });
})