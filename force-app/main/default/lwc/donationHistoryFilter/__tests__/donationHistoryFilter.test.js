import { createElement } from 'lwc';
import DonationHistoryFilter from '../donationHistoryFilter';
import getYearsWithDonation from '@salesforce/apex/DonationHistoryController.getYearsWithDonations'


  jest.mock('@salesforce/apex/DonationHistoryController.getYearsWithDonations', () => {
    return {
        default: jest.fn()
    };
  }, {virtual: true}
  );

  describe('c-donation-history-filter', () => {
    afterEach(()=>{
      // clean mock functions
      clearDOM();
    });
  
    it('renders the dropbox correctly', async () => {
      getYearsWithDonation.mockResolvedValue(["2020", "2018"]);
      const element = createElement('c-donation-history-filter', { is: DonationHistoryFilter});
      
      document.body.appendChild(element);
      
      await flushPromises();
      const dropbox = element.shadowRoot.querySelector('.dropbox');
      expect(dropbox).toBeDefined();
      expect(dropbox.options.length).toBe(4);
      expect(dropbox.options[0].label).toBe('c.donationHistoryLabelLifetime');
      expect(dropbox.options[1].label).toBe('2020');
      expect(dropbox.options[2].label).toBe('2019');
      expect(dropbox.options[3].label).toBe('2018');
      
    });

    it('triggers the handler when the popup is changed', async () => {
      getYearsWithDonation.mockResolvedValue(["2020", "2018"]);
      const element = createElement('c-donation-history-filter', { is: DonationHistoryFilter});
      const handler = jest.fn();
      element.addEventListener('filter', handler);
      document.body.appendChild(element);

      flushPromises()
      const dropbox = element.shadowRoot.querySelector('.dropbox');
      dropbox.dispatchEvent(new CustomEvent("change", {
                  detail: {
                      value: "2020"
                  }
              }));
      expect(handler).toBeCalled();
    });
  });