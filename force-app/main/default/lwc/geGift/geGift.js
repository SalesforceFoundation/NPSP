import PAYMENT_AUTHORIZE_TOKEN from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import SoftCredits from './geSoftCredits';

class Gift {
    softCredits = new SoftCredits();
    _fields = {};

    constructor(giftView) {
        if (giftView) {
            this._fields = giftView.fields;
            this.softCredits = new SoftCredits(giftView.softCredits.all);
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

    addNewSoftCredit(softCredit) {
        this.softCredits.addNew();
    }

    removeSoftCredit(key) {
        this.softCredits.remove(key);
    }

    updateSoftCredit(softCredit) {
        this.softCredits.update(softCredit);
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
            softCredits: [ ...this.softCredits.all() ]
        }
    }

    state() {
        return {
            fields: { ...this._fields },
            softCredits: [ ...this.softCredits.all() ]
        }
    }
}

export default Gift;