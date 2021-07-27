import PAYMENT_AUTHORIZE_TOKEN from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';

class Gift {
    _softCredits = {};
    _fields = {};

    constructor(giftView) {
        if (giftView) {
            this._fields = giftView.fields;
            this._softCredits = giftView.softCredits;
        }
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

    state() {
        return {
            fields: { ...this._fields },
            softCredits: { ...this._softCredits }
        }
    }
}

export default Gift;