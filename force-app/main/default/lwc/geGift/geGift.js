import getGiftView from '@salesforce/apex/GE_GiftEntryController.getGiftView';
import saveSingleGift from '@salesforce/apex/GE_GiftEntryController.saveSingleGift';

import PAYMENT_AUTHORIZE_TOKEN from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import FAILURE_INFORMATION from '@salesforce/schema/DataImport__c.FailureInformation__c';
import STATUS from '@salesforce/schema/DataImport__c.Status__c';
import DONATION_IMPORTED from '@salesforce/schema/DataImport__c.DonationImported__c';
import SoftCredits from './geSoftCredits';

class Gift {
    _softCredits = new SoftCredits();
    _fields = {};

    constructor(giftView) {
        if (giftView) {
            this._init(giftView);
        }
    }

    _init(giftView) {
        this._fields = giftView.fields;
        this._softCredits = new SoftCredits(giftView.softCredits.all || giftView.softCredits || []);
    }

    id() {
        return this._fields.Id;
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
            softCredits: [ ...this._softCredits.all() ]
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
            softCredits: [ ...this._softCredits.unprocessedSoftCredits() ],
            processedSoftCredits: [ ...this._softCredits.processedSoftCredits() ]
        }
    }
}

export default Gift;