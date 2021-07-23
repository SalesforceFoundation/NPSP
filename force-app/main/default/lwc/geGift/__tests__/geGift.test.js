import Gift from 'c/geGift';

const giftView = require('./data/giftView.json');

describe('ge-gift', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('should initialize with expected properties', async () => {
        const gift = new Gift(giftView);

        await flushPromises();

        expect(gift.fields).toEqual({"Contact1Imported__c": "0032F00000iz5YhQAI", "Contact1Imported__r": {"Id": "0032F00000iz5YhQAI", "Name": "Gloria Howell"}, "Contact1_Firstname__c": "Gloria", "Contact1_Lastname__c": "Howell", "Contact1_Preferred_Email__c": "Personal", "DonationImportStatus__c": "Dry Run - Matched None", "Donation_Amount__c": 55, "Donation_Date__c": "2021-07-23", "Donation_Donor__c": "Contact1", "Id": "a0U2F000002HwNrUAK", "NPSP_Data_Import_Batch__c": "a0T2F00000307TAUAY", "NPSP_Data_Import_Batch__r": {"Id": "a0T2F00000307TAUAY", "Name": "Test Batch 0"}, "Payment_Method__c": "Check", "Status__c": "Dry Run - Validated"});
        expect(gift.softCredits.all.length).toBe(0);
    });
});