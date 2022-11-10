import getGiftView from '@salesforce/apex/GE_GiftEntryController.getGiftView';
import saveSingleGift from '@salesforce/apex/GE_GiftEntryController.saveSingleGift';

import FAILURE_INFORMATION from '@salesforce/schema/DataImport__c.FailureInformation__c';
import STATUS from '@salesforce/schema/DataImport__c.Status__c';
import DONATION_IMPORTED from '@salesforce/schema/DataImport__c.DonationImported__c';
import PAYMENT_AUTHORIZE_TOKEN from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import PAYMENT_STATUS from '@salesforce/schema/DataImport__c.Payment_Status__c';
import PAYMENT_ELEVATE_ID from '@salesforce/schema/DataImport__c.Payment_Elevate_ID__c';
import DATA_IMPORT_RECURRING_DONATION_ELEVATE_ID
    from '@salesforce/schema/DataImport__c.Recurring_Donation_Elevate_Recurring_ID__c';

import SoftCredits from './geSoftCredits';
import GiftScheduleService from './geScheduleService';
import { GIFT_STATUSES, PAYMENT_STATUSES } from 'c/geConstants';

class Gift {
    _softCredits = new SoftCredits();
    _schedule = {};
    _fields = {};
    _hasConvertedToOneTimeBatchItemType = false;
    _hasConvertedToRecurringBatchItemType = false;

    constructor(giftView) {
        this._init(giftView);
    }

    _init(giftView) {
        if (giftView) {
            this._fields = giftView.fields;
            this._softCredits = new SoftCredits(giftView.softCredits?.all || giftView.softCredits || []);
            if (giftView.processedSoftCredits) {
                this._softCredits.addProcessedSoftCredits(giftView.processedSoftCredits)
            }

            const giftScheduleService = new GiftScheduleService();
            this._schedule = giftScheduleService.retrieveScheduleFromFields(this._fields);
        }
    }

    idToRemove() {
        let id;
        if (this.hasConvertedToElevateRecurringType()) {
            id = this._fields[PAYMENT_ELEVATE_ID.fieldApiName];
        } else if (this.hasConvertedToElevateOneTimeType()) {
            id = this._fields[DATA_IMPORT_RECURRING_DONATION_ELEVATE_ID.fieldApiName];
        } else {
            id = this._fields[PAYMENT_ELEVATE_ID.fieldApiName] ? this._fields[PAYMENT_ELEVATE_ID.fieldApiName] :
                       this._fields[DATA_IMPORT_RECURRING_DONATION_ELEVATE_ID.fieldApiName]
        }
        return id;
    }

    id() {
        return this._fields.Id;
    }

    hasSchedule() {
        return Object.keys(this._schedule).length > 0;
    }

    isImported() {
        return this._fields[STATUS.fieldApiName] === GIFT_STATUSES.IMPORTED;
    }

    hasCommitmentId() {
        return !!this._fields[DATA_IMPORT_RECURRING_DONATION_ELEVATE_ID.fieldApiName];
    }

    addSchedule(scheduleData) {
        this._schedule = scheduleData;
        const giftScheduleService = new GiftScheduleService();
        this._fields = giftScheduleService.addScheduleTo(this._fields, scheduleData);
        this._hasConvertedToOneTimeBatchItemType = false;
        this._hasConvertedToRecurringBatchItemType = true;
    }

    removeSchedule() {
        const giftScheduleService = new GiftScheduleService();
        this._fields = giftScheduleService.removeScheduleFromFields(this._fields);
        this._schedule = {};
        this._hasConvertedToOneTimeBatchItemType = true;
        this._hasConvertedToRecurringBatchItemType = false;
    }

    isFailed() {
        return this._fields[STATUS.fieldApiName] ===
            GIFT_STATUSES.FAILED;
    }

    status() {
        return this._fields[STATUS.fieldApiName]
    }

    failureInformation() {
        return this._fields[FAILURE_INFORMATION.fieldApiName];
    }

    donationId() {
        return this._fields[DONATION_IMPORTED.fieldApiName];
    }

    updateFieldsWith(changes) {
        this._fields = {
            ...this._fields,
            ...changes
        };
    }

    removeField(field) {
        delete this._fields[field];
    }

    addNewSoftCredit() {
        this._softCredits.addNew();
    }

    removeSoftCredit(key) {
        this._softCredits.remove(key);
    }

    updateSoftCredit(softCredit) {
        this._softCredits.update(softCredit);
    }

    addProcessedSoftCredits(processedSoftCredits) {
        this._softCredits.addProcessedSoftCredits(processedSoftCredits);
    }

    clearProcessedSoftCredits() {
        this._softCredits.clearProcessedSoftCredits();
    }

    hasProcessedSoftCredits() {
        return this._softCredits.hasProcessedSoftCredits();
    }

    softCredits() {
        return this._softCredits;
    }

    getFieldValue(field) {
        return this._fields[field];
    }

    hasConvertedToElevateRecurringType() {
        return this._hasConvertedToRecurringBatchItemType;
    }

    hasConvertedToElevateOneTimeType() {
        return this._hasConvertedToOneTimeBatchItemType;
    }

    asDataImport() {
        let dataImportRecord = { ...this._fields };
        delete dataImportRecord[undefined];
        for (const key of Object.keys(dataImportRecord)) {
            if (key.includes('__r'
                || key === undefined)
                || key === PAYMENT_AUTHORIZE_TOKEN.fieldApiName) {
                delete dataImportRecord[key];
            }
        }
        return dataImportRecord;
    }

    forSave() {
        return {
            fields: this.asDataImport(),
            softCredits: [ ...this._softCredits.forSave() ],
            schedule: this._schedule
        }
    }

    async save() {
        await saveSingleGift({ inboundGift: this.forSave() });
    }

    async refresh() {
        const latestGiftView = await getGiftView({ dataImportId: this.id() })
            .catch(error => { throw error });
        this._init(latestGiftView);
    }

    state() {
        return {
            fields: { ...this._fields },
            softCredits: JSON.stringify([ ...this._softCredits.unprocessedSoftCredits() ]),
            processedSoftCredits: JSON.stringify([ ...this._softCredits.processedSoftCredits() ]),
            schedule: { ...this._schedule },
            hasConvertedToRecurringBatchItemType: this._hasConvertedToRecurringBatchItemType,
            hasConvertedToElevateOneTimeBatchItemType: this._hasConvertedToOneTimeBatchItemType
        }
    }

    hasElevateRemovableStatus() {
        return this.getFieldValue(STATUS.fieldApiName) !== GIFT_STATUSES.IMPORTED && (
                (
                    this.getFieldValue(PAYMENT_ELEVATE_ID.fieldApiName) &&
                    this.getFieldValue(PAYMENT_STATUS.fieldApiName) === PAYMENT_STATUSES.AUTHORIZED ||
                    this.getFieldValue(PAYMENT_STATUS.fieldApiName) === PAYMENT_STATUSES.PENDING
                ) ||
                this.hasCommitmentId()
            );
    }
}

export default Gift;
