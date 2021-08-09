import getGiftView from '@salesforce/apex/GE_GiftEntryController.getGiftView';

import PAYMENT_AUTHORIZE_TOKEN from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import PAYMENT_STATUS from '@salesforce/schema/DataImport__c.Payment_Status__c';

class Gift {
    _softCredits = {};
    _fields = {};

    constructor(giftView) {
        if (giftView) {
            this._fields = giftView.fields;
            this._softCredits = giftView.softCredits;
        }
    }

    _init(giftView) {
        this._fields = giftView.fields;
    }

    id() {
        return this._fields.Id;
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

    getFieldValue(field) {
        return this._fields[field];
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

    async refresh() {
        const latestGiftView = await getGiftView({ dataImportId: this.id() })
            .catch(error => { 
                console.log(error);
                throw error 
            });
        this._init(latestGiftView);
        console.log(`latest gift view = ${JSON.stringify(latestGiftView)}`);
    }


    state() {
        return {
            fields: { ...this._fields },
            softCredits: { ...this._softCredits }
        }
    }

    isAuthorized() {
        return this.getFieldValue(PAYMENT_STATUS.fieldApiName) === 'AUTHORIZED';
    }
}

export default Gift;