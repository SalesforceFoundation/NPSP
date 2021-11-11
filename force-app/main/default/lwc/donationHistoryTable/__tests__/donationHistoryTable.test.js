import { createElement } from 'lwc';
import DonationHistoryTable from '../donationHistoryTable';
const MOCK_DATA = require('./data/donationHistoryTableData.json');

// Helper function to wait until the microtask queue is empty. This is needed for promise
// timing when calling imperative Apex.
function flushPromises() {
    // eslint-disable-next-line no-undef
    return new Promise((resolve) => setImmediate(resolve));
  }
  
  describe('c-my-profile', () => {
    afterEach(()=>{
      // clean mock functions
      jest.clearAllMocks();
      
      // The jsdom instance is shared across test cases in a single file so reset the DOM
      while(document.body.firstChild) {
          document.body.removeChild(document.body.firstChild);
      }
    });
  
    it('renders table correctly', ()=>{
      const element = createElement('c-donation-history-table', { is: DonationHistoryTable});
      element.data = MOCK_DATA;
      element.canBeUpdated = true;
      document.body.appendChild(element);
      return flushPromises().then(()=>{
        const lightningTable = element.shadowRoot.querySelector('lightning-datatable');
        expect(lightningTable).toBeDefined();
        expect(element).toBeDefined();
      });
    });
    
    it('triggers on load more Handler for infinite scroll', () => {
        const element = createElement('c-donation-history-table', { is: DonationHistoryTable});
        const handler = jest.fn();
        element.data = MOCK_DATA;
        element.addEventListener('onloadmore', handler);
        document.body.appendChild(element);
        return flushPromises().then(() => {
              element.dispatchEvent(new CustomEvent('onloadmore'));
              return flushPromises().then(() => {
                  expect(handler).toHaveBeenCalled();
              });
        });
    });
  });