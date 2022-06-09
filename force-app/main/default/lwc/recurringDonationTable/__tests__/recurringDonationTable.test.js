import { createElement } from 'lwc';
import recurringDonationTable from '../recurringDonationTable';
const MOCK_DATA = require('./data/recurringDonationTableData.json');

// Helper function to wait until the microtask queue is empty. This is needed for promise
// timing when calling imperative Apex.
  
  describe('c-recurring-donation-table', () => {
    afterEach(()=>{
      // clean mock functions
      clearDOM();
    });
  
    it('renders table correctly', ()=>{
      const element = createElement('c-recurring-donation-table', { is: recurringDonationTable});
      element.data = MOCK_DATA;
      element.canBeUpdated = true;
      document.body.appendChild(element);
      return flushPromises().then(()=>{
        const lightningTable = element.shadowRoot.querySelector('lightning-datatable');
        expect(lightningTable).toBeDefined();
        expect(element).toBeDefined();
      });
    });
    
  });