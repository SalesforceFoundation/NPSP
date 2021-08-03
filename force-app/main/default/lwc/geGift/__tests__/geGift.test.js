import Gift from 'c/geGift';

const mockGiftView = require('../../../../../../tests/__mocks__/apex/data/giftView.json');
const DUMMY_GIFT_VIEW = { "Contact1Imported__c": "0032F00000iz5YhQAI", "Contact1Imported__r": { "Id": "0032F00000iz5YhQAI", "Name": "Gloria Howell" }, "Contact1_Firstname__c": "Gloria", "Contact1_Lastname__c": "Howell", "Contact1_Preferred_Email__c": "Personal", "DonationImportStatus__c": "Dry Run - Matched None", "Donation_Amount__c": 55, "Donation_Date__c": "2021-07-23", "Donation_Donor__c": "Contact1", "Id": "a0U2F000002HwNrUAK", "NPSP_Data_Import_Batch__c": "a0T2F00000307TAUAY", "NPSP_Data_Import_Batch__r": { "Id": "a0T2F00000307TAUAY", "Name": "Test Batch 0" }, "Payment_Method__c": "Check", "Status__c": "Dry Run - Validated" };
const DUMMY_DATA_IMPORT = { "Contact1Imported__c": "0032F00000iz5YhQAI", "Contact1_Firstname__c": "Gloria", "Contact1_Lastname__c": "Howell", "Contact1_Preferred_Email__c": "Personal", "DonationImportStatus__c": "Dry Run - Matched None", "Donation_Amount__c": 55, "Donation_Date__c": "2021-07-23", "Donation_Donor__c": "Contact1", "Id": "a0U2F000002HwNrUAK", "NPSP_Data_Import_Batch__c": "a0T2F00000307TAUAY", "Payment_Method__c": "Check", "Status__c": "Dry Run - Validated" };

describe('ge-gift', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('should initialize with expected properties', async () => {
        const gift = new Gift(mockGiftView);

        expect(gift.state().fields).toEqual(DUMMY_GIFT_VIEW);
        expect(gift.state().softCredits.all.length).toBe(0);
    });

    it('should return the expected id', async () => {
        const gift = new Gift(mockGiftView);

        expect(gift.id()).toEqual('a0U2F000002HwNrUAK');
    });

    it('should return object without relationship fields', async () => {
        const gift = new Gift(mockGiftView);

        expect(gift.asDataImport()).toEqual(DUMMY_DATA_IMPORT);
    });

    it('should return remove indicated field from internal property', async () => {
        const gift = new Gift(mockGiftView);

        gift.removeField('Contact1Imported__c');

        expect(Object.keys(gift.state().fields)).not.toContain('Contact1Imported__c');
    });

    it('should return a object in the shape of InboundGiftDTO.cls', async () => {
        const gift = new Gift(mockGiftView);
        expect(gift.forSave()).toEqual({
            "fields": {
                "Contact1Imported__c": "0032F00000iz5YhQAI",
                "Contact1_Firstname__c": "Gloria",
                "Contact1_Lastname__c": "Howell",
                "Contact1_Preferred_Email__c": "Personal",
                "DonationImportStatus__c": "Dry Run - Matched None",
                "Donation_Amount__c": 55,
                "Donation_Date__c": "2021-07-23",
                "Donation_Donor__c": "Contact1",
                "Id": "a0U2F000002HwNrUAK",
                "NPSP_Data_Import_Batch__c": "a0T2F00000307TAUAY",
                "Payment_Method__c": "Check",
                "Status__c": "Dry Run - Validated",
            },
            "softCredits": [],
        });
    });

    it('should list of soft credits', async () => {
        const gift = new Gift({
            fields: {
                Id: 'dummy_gift_id'
            },
            softCredits: {
                all: [
                    { Role: 'dummy_role_0', ContactId: 'dummy_contact_id_0'},
                    { Role: 'dummy_role_1', ContactId: 'dummy_contact_id_1'}
                ]
            }
        });

        expect(gift.softCredits().length).toEqual(2);
    });
});