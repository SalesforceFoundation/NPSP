import { createElement } from 'lwc';
import rd2RecurringDonation from '../rd2RecurringDonation';
const MOCK_DATA = require('./data/rd2RecurringDonationData.json');

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

});