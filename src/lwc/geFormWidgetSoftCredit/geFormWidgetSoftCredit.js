import { LightningElement, api, track } from 'lwc';
import { isNotEmpty } from 'c/utilCommon';

import GeFormService from 'c/geFormService';
import GeLabelService from 'c/geLabelService';

import OPP_CONTACT_ROLE_OBJECT from '@salesforce/schema/OpportunityContactRole';
import DATA_IMPORT_ADDITIONAL_JSON_FIELD from '@salesforce/schema/DataImport__c.Additional_Object_JSON__c'
import ROLE_FIELD from '@salesforce/schema/OpportunityContactRole.Role';
import CONTACT_FIELD from '@salesforce/schema/OpportunityContactRole.ContactId';
import OPPORTUNITY_FIELD from '@salesforce/schema/OpportunityContactRole.OpportunityId';

import getDummySoftCreditsApex from '@salesforce/apex/GE_GiftEntryController.getDummySoftCredits';
import { handleError } from 'c/utilTemplateBuilder';

export default class GeFormWidgetSoftCredit extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api element;
    @track alertBanner = {};
    @track rowList = [];
    @track fieldList = [];

    connectedCallback() {
        this.init();
    }

    init = async () => {
        let dummyRecords = await this.getDummySoftCredits();
        
        dummyRecords.forEach(rowRecord => {
            this.addRow(rowRecord);
        });
    };

    getDummySoftCredits() {
        return new Promise((resolve, reject) => {
            getDummySoftCreditsApex()
                .then(resolve)
                .catch(handleError)
        });
    }

    handleAddRow() {
        // handle add row
    }

    addRow(rowRecord) {
        let element = {};
        element.key = this.rowList.length;
        const record = { ...rowRecord };
        let row = {};

        row = {
            ...row,
            record,
            element
        };
        this.rowList.push(row);
    }

    handleRemove(event) {
        // handle row remove
    }

    reset() {
        // handle reset
    }

    validate() {
        // validate
    }

    get hasAlert() {
        return false;
    }

    get alertIcon() {
        if (isNotEmpty(this.alertBanner.level)) {
            const warningIcon = 'utility:warning';
            const errorIcon = 'utility:error';
            switch(this.alertBanner.level) {
                case 'error':
                    return errorIcon;
                case 'warning':
                    return warningIcon;
                default:
                    return errorIcon;
            }
        }
    }

    get alertClass() {
        if (isNotEmpty(this.alertBanner.level)) {
            const errorClass = 'error';
            const warningClass = 'warning';

            switch(this.alertBanner.level) {
                case errorClass:
                    return errorClass;
                case warningClass:
                    return warningClass;
                default:
                    return errorClass;
            }
        }
    }

    get footerClass() {
        return this.rowList.length > 0 ? 'slds-p-top--medium slds-m-top--medium slds-border--top'
            : 'slds-p-top--medium slds-m-top--medium';
    }

    get qaLocatorAddNewSoftCredit() {
        return `button ${this.CUSTOM_LABELS.geAddNewAllocation}`;
    }
}