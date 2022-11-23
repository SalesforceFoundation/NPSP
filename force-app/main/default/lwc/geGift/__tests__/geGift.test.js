import ScheduleDate from '@salesforce/schema/UserProvisioningRequest.ScheduleDate';
import Gift from 'c/geGift';
import { deepClone } from 'c/utilCommon';

const mockGiftView = require('../../../../../../tests/__mocks__/apex/data/giftView.json');
const DUMMY_GIFT_VIEW = { "Contact1Imported__c": "0032F00000iz5YhQAI", "Contact1Imported__r": { "Id": "0032F00000iz5YhQAI", "Name": "Gloria Howell" }, "Contact1_Firstname__c": "Gloria", "Contact1_Lastname__c": "Howell", "Contact1_Preferred_Email__c": "Personal", "DonationImportStatus__c": "Dry Run - Matched None", "Donation_Amount__c": 55, "Donation_Date__c": "2021-07-23", "Donation_Donor__c": "Contact1", "Id": "a0U2F000002HwNrUAK", "NPSP_Data_Import_Batch__c": "a0T2F00000307TAUAY", "NPSP_Data_Import_Batch__r": { "Id": "a0T2F00000307TAUAY", "Name": "Test Batch 0" }, "Payment_Method__c": "Check", "Status__c": "Dry Run - Validated" };
const DUMMY_DATA_IMPORT = { "Contact1Imported__c": "0032F00000iz5YhQAI", "Contact1_Firstname__c": "Gloria", "Contact1_Lastname__c": "Howell", "Contact1_Preferred_Email__c": "Personal", "DonationImportStatus__c": "Dry Run - Matched None", "Donation_Amount__c": 55, "Donation_Date__c": "2021-07-23", "Donation_Donor__c": "Contact1", "Id": "a0U2F000002HwNrUAK", "NPSP_Data_Import_Batch__c": "a0T2F00000307TAUAY", "Payment_Method__c": "Check", "Status__c": "Dry Run - Validated" };
const RD_DATAIMPORT_FIELDS = [
    'Recurring_Donation_Recurring_Type__c',
    'Recurring_Donation_Amount__c',
    'Recurring_Donation_Day_of_Month__c',
    'Recurring_Donation_Installment_Frequency__c',
    'Recurring_Donation_Installment_Period__c',
    'Recurring_Donation_Planned_Installments__c',
    'Recurring_Donation_Effective_Date__c',
    'Recurring_Donation_Date_Established__c',
    'RecurringDonationImportStatus__c',
    'Recurring_Donation_Payment_Method__c',
    'Recurring_Donation_ACH_Last_4__c',
    'Recurring_Donation_End_Date__c',
    'Recurring_Donation_Name__c',
    'Recurring_Donation_Status__c',
    'Recurring_Donation_Status_Reason__c',
    'RecurringDonationImported__c'
];

describe('ge-gift', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it ('removable elevate status should return false for imported status', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Status__c = 'Imported';

        const gift = new Gift(mockGiftViewTest);
        expect(gift.hasElevateRemovableStatus()).toEqual(false);
    });

    it ('removable elevate status should return false for missing elevate payment id', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Payment_Status__c = 'AUTHORIZED';
        mockGiftViewTest.fields.Status__c = 'Dry Run - Validated';

        const gift = new Gift(mockGiftViewTest);
        expect(gift.hasElevateRemovableStatus()).toEqual(false);
    });

    it ('removable elevate status should return false for incorrect payment status', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Payment_Status__c = 'CAPTURED';
        mockGiftViewTest.fields.Status__c = 'Dry Run - Validated';

        const gift = new Gift(mockGiftViewTest);
        expect(gift.hasElevateRemovableStatus()).toEqual(false);
    });

    it ('removable elevate status should return false for missing payment status', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Payment_Elevate_ID__c = 'DUMMY_PAYMENT_ID';
        mockGiftViewTest.fields.Status__c = 'Dry Run - Validated';

        const gift = new Gift(mockGiftViewTest);
        expect(gift.hasElevateRemovableStatus()).toEqual(false);
    });

    it ('removable elevate status should return true with commitment id', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Recurring_Donation_Elevate_Recurring_ID__c = 'DUMMY_RECURRING_ID';

        const gift = new Gift(mockGiftViewTest);
        expect(gift.hasElevateRemovableStatus()).toEqual(true);
    });

    it ('removable elevate status should return true with authorized status', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Payment_Status__c = 'AUTHORIZED';
        mockGiftViewTest.fields.Payment_Elevate_ID__c = 'DUMMY_PAYMENT_ID';
        mockGiftViewTest.fields.Status__c = 'Dry Run - Validated';

        const gift = new Gift(mockGiftViewTest);
        expect(gift.hasElevateRemovableStatus()).toEqual(true);
    });

    it ('removable elevate status should return true with pending status', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Payment_Status__c = 'PENDING';
        mockGiftViewTest.fields.Payment_Elevate_ID__c = 'DUMMY_PAYMENT_ID';
        mockGiftViewTest.fields.Status__c = 'Dry Run - Validated';

        const gift = new Gift(mockGiftViewTest);
        expect(gift.hasElevateRemovableStatus()).toEqual(true);
    });

    it ('should return recurring id when converted to one-time gift type on remove action', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Payment_Elevate_ID__c = 'DUMMY_PAYMENT_ID';
        mockGiftViewTest.fields.Recurring_Donation_Elevate_Recurring_ID__c = 'DUMMY_RECURRING_ID';

        const gift = new Gift(mockGiftViewTest);
        gift.removeSchedule({});
        
        expect(gift._hasConvertedToOneTimeBatchItemType).toEqual(true);
        expect(gift.idToRemove()).toEqual('DUMMY_RECURRING_ID');
    });

    it ('should return payment id when converted to recurring gift type on remove action', async () => {
        const mockGiftViewTest = deepClone(mockGiftView);
        mockGiftViewTest.fields.Payment_Elevate_ID__c = 'DUMMY_PAYMENT_ID';
        mockGiftViewTest.fields.Recurring_Donation_Elevate_Recurring_ID__c = 'DUMMY_RECURRING_ID';

        const gift = new Gift(mockGiftViewTest);
        gift.addSchedule({});

        expect(gift._hasConvertedToRecurringBatchItemType).toEqual(true);
        expect(gift.idToRemove()).toEqual('DUMMY_PAYMENT_ID');
    });

    it('should initialize with expected properties', async () => {
        const gift = new Gift(mockGiftView);
        const giftState = gift.state();

        expect(giftState.fields).toEqual(DUMMY_GIFT_VIEW);
        expect(JSON.parse(giftState.softCredits).length).toBe(0);
        expect(JSON.parse(giftState.processedSoftCredits).length).toBe(0);
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
        const gift = new Gift(deepClone(mockGiftView));

        gift.removeField('Contact1Imported__c');

        expect(Object.keys(gift.state().fields)).not.toContain('Contact1Imported__c');
    });

    it('should return an object in the shape of InboundGiftDTO.cls', async () => {
        const gift = new Gift(deepClone(mockGiftView));

        const inboundGiftDTO = gift.forSave();
        expect(Object.keys(inboundGiftDTO)).toContain('fields');
        expect(Object.keys(inboundGiftDTO.fields).length).toEqual(12);
        expect(Object.keys(inboundGiftDTO)).toContain('softCredits');
        expect(inboundGiftDTO.softCredits.length).toEqual(0);
    });

    it('should add 2 soft credits to the gift', async () => {
        const gift = new Gift(deepClone(mockGiftView));
        gift.addNewSoftCredit();
        gift.addNewSoftCredit();
        gift.addNewSoftCredit();

        gift.updateSoftCredit({
            key: 0,
            Role: 'Influencer',
            ContactId: 'DUMMY_CONTACT_ID_0'
        });

        gift.updateSoftCredit({
            key: 1,
            Role: '',
            ContactId: ''
        });

        gift.updateSoftCredit({
            key: 2,
            Role: 'Honoree',
            ContactId: 'DUMMY_CONTACT_ID_1'
        });

        const inboundGiftDTO = gift.forSave();
        expect(Object.keys(inboundGiftDTO)).toContain('softCredits');
        expect(inboundGiftDTO.softCredits.length).toEqual(2);
    });

    it('should return list of 3 soft credits and 2 processed soft credits', async () => {
        const gift = new Gift({
            fields: {
                Id: 'dummy_gift_id'
            },
            softCredits: {
                all: [
                    { Role: 'dummy_role_0', ContactId: 'dummy_contact_id_0'},
                    { Role: 'dummy_role_1', ContactId: 'dummy_contact_id_1'},
                    { Role: 'dummy_role_3', ContactId: 'dummy_contact_id_2'}
                ]
            }
        });

        const processedSoftCredits = [
            { Id: 'dummy_ocr_id_0', Role: 'dummy_role_0', ContactId: 'dummy_contact_id_3'},
            { Id: 'dummy_ocr_id_1', Role: 'dummy_role_0', ContactId: 'dummy_contact_id_4'},
        ]
        gift.addProcessedSoftCredits(processedSoftCredits);

        expect(gift.softCredits().unprocessedSoftCredits().length).toEqual(3);
        expect(gift.softCredits().processedSoftCredits().length).toEqual(2);
    });

    it('should have a schedule', async () => {
        const gift = new Gift({
            fields: {
                Id: 'dummy_gift_id'
            }
        });
        const dummySchedule = {
            RecurringType__c: 'Open',
        }

        gift.addSchedule(dummySchedule);
        const hasSchedule = gift.hasSchedule();
        const inboundGiftDTO = gift.forSave();

        expect(hasSchedule).toBeTruthy();
        expect(inboundGiftDTO.schedule).toBe(dummySchedule);
    });

    it('should have schedule fields removed', async () => {
        let fields = {};
        RD_DATAIMPORT_FIELDS.forEach((fieldName) => {
            fields[fieldName] = 'TEST_FIELD_VALUE'
        });
        const gift = new Gift({
            fields: fields
        });
        gift.removeSchedule();

        for (const fieldName of RD_DATAIMPORT_FIELDS) {
            expect(gift.getFieldValue(fieldName)).toBeNull;
        }
    });

    it('should not have a schedule', async () => {
        const gift = new Gift({
            fields: {
                Id: 'dummy_gift_id'
            }
        });

        const hasSchedule = gift.hasSchedule();

        expect(hasSchedule).toBeFalsy();
    });
});