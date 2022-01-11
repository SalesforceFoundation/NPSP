import { createElement } from 'lwc';
import DonationHistoryFilter from '../donationHistoryFilter';
import getYearsWithDonation from '@salesforce/apex/DonationHistoryController.getYearsWithDonations'


  jest.mock('@salesforce/apex/DonationHistoryController.getYearsWithDonations', () => {
    return {
        default: jest.fn()
    };
  }, {virtual: true}
  );

  describe('c-donation-history-table', () => {
    afterEach(()=>{
      // clean mock functions
      clearDOM();
    });
  
    it('renders the dropbox correctly', ()=>{
      getYearsWithDonation.mockResolvedValue(["2020", "2018"]);
      const element = createElement('c-donation-history-filter', { is: DonationHistoryFilter});
      
      document.body.appendChild(element);
      return flushPromises().then(()=>{
        const dropbox = element.shadowRoot.querySelector('.dropbox');
        expect(dropbox).toBeDefined();
        expect(dropbox.options.length).toBe(4);
        expect(dropbox.options[0].label).toBe('c.donationHistoryLabelLifetime');
        expect(dropbox.options[1].label).toBe('2020');
        expect(dropbox.options[2].label).toBe('2019');
        expect(dropbox.options[3].label).toBe('2018');
      });
    });
  });