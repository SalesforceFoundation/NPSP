import { createElement } from 'lwc';
import rd2RecurringDonation from '../rd2RecurringDonation';
import { extended, full } from "@sa11y/preset-rules";
import { setup } from "@sa11y/jest";

const MOCK_DATA = require('./data/rd2RecurringDonationData.json');

setup();

// Helper function to wait until the microtask queue is empty. This is needed for promise
// timing when calling imperative Apex.
  
  describe('c-rd2-recurring-donation', () => {
    afterEach(()=>{
      // clean mock functions
      clearDOM();
    });
  
    it('renders table correctly', ()=>{
      const element = createElement('c-rd2-recurring-donation', { is: rd2RecurringDonation});
      element.data = MOCK_DATA;
      element.canBeUpdated = true;
      document.body.appendChild(element);
      return flushPromises().then(()=>{
        const lightningTable = element.shadowRoot.querySelector('table');
        expect(lightningTable).toBeDefined();
        expect(element).toBeDefined();
      });
    });

    it('renders table without modal', ()=>{
        const element = createElement('c-rd2-recurring-donation', { is: rd2RecurringDonation});
        element.data = MOCK_DATA;
        element.canBeUpdated = true;
        element.openStopRecurringDonation = false;
        document.body.appendChild(element);
        return flushPromises().then(()=>{
          const stopRecurringDonationModal = element.shadowRoot.querySelector('c-stop-recurring-donation-modal');
          expect(stopRecurringDonationModal).toBeNull();
          expect(element).toBeDefined();
        });
      });

      it('renders table with modal', ()=>{
        const element = createElement('c-rd2-recurring-donation', { is: rd2RecurringDonation});
        element.data = MOCK_DATA;
        element.canBeUpdated = true;
        element.openStopRecurringDonation = true;
        document.body.appendChild(element);
        return flushPromises().then(()=>{
          const stopRecurringDonationModal = element.shadowRoot.querySelector('c-stop-recurring-donation-modal');
          expect(stopRecurringDonationModal).toBeDefined();
          expect(element).toBeDefined();
        });
      });

      it("checks element is accessible", async () => {
        const element = createElement("c-rd2-recurring-donation", {
            is: rd2RecurringDonation,
        });
        document.body.appendChild(element);
        await expect(element).toBeAccessible(extended);
    });

    it("checks document is fully accessible", async () => {
        const element = createElement("c-rd2-recurring-donation", {
            is: rd2RecurringDonation,
        });
        document.body.appendChild(element);
        await expect(element).toBeAccessible(full);
    });

});
