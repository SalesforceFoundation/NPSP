import { createElement } from 'lwc';
import DonationHistoryTable from '../donationHistoryTable';
import { extended, full } from "@sa11y/preset-rules";
import { setup } from "@sa11y/jest";
const MOCK_DATA = require('./data/donationHistoryTableData.json');

setup();

// Helper function to wait until the microtask queue is empty. This is needed for promise
// timing when calling imperative Apex.
  
  describe('c-donation-history-table', () => {
    afterEach(()=>{
      // clean mock functions
      clearDOM();
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

    it("checks element is accessible", async () => {
        const element = createElement("c-donation-history-table", {
            is: DonationHistoryTable,
        });
        document.body.appendChild(element);
        await expect(element).toBeAccessible(extended);
    });

    it("checks document is fully accessible", async () => {
        const element = createElement("c-donation-history-table", {
            is: DonationHistoryTable,
        });
        document.body.appendChild(element);
        await expect(element).toBeAccessible(full);
    });

  });