import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { showToast } from 'c/utilCommon';

import FIELD_NAME from '@salesforce/schema/Contact.Name';

import lblPotentialDuplicatesFoundNone from '@salesforce/label/c.potentialDuplicatesFoundNone';
import lblPotentialDuplicatesFoundOne from '@salesforce/label/c.potentialDuplicatesFoundOne';
import lblPotentialDuplicatesFoundMultiple from '@salesforce/label/c.potentialDuplicatesFoundMultiple';

import getDuplicates from '@salesforce/apex/PotentialDuplicates.getDuplicates';

export default class PotentialDuplicates extends NavigationMixin(LightningElement) {

    @api recordId;
    @api displayCard;
    @api displayToast;

    @track isEnabled = true;
    @track duplicateCount;
    @track error;
    @track lblTitle = lblPotentialDuplicatesFoundNone;
    @track viewDuplicatesURL;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ FIELD_NAME ]
    })
    wireRecordChange() {
        if (this.recordId) {
            console.log('wireRecordChange');
            getDuplicates({ recordId: this.recordId })
                .then(response => {
                    this.handleDuplicates(response);
                    this.error = null;
                })
                .catch(error => {
                    this.schedules = null;
                    this.error = this.handleError(error);
                });
        }
    }

    handleDuplicates(response) {
        this.duplicateCount = 0;
        if (response && response.setOfMatches) {
            this.duplicateCount = response.setOfMatches.split(',').length;
            this.duplicateIdsParam = this.recordId + ',' + response.setOfMatches;
        }
        this.updateTitle();
        this.handleToast();
    }

    handleError(error) {
        if (error && error.status && error.body) {
            return error.body.message;
        } else if (error && error.name && error.message) {
            return error.message;
        } else {
            return "";
        }
    }

    handleToast() {
        if (this.duplicateCount > 0) {
            let messageData = [{
                "url": this.viewDuplicatesURL,
                "label": "View Duplicates",
            }];
            showToast("", this.lblTitle + " {0}", "info", "sticky", messageData);
        }
    }

    updateTitle() {
        switch (this.duplicateCount) {
            case 0:
                this.lblTitle = lblPotentialDuplicatesFoundNone;
                break;
            case 1:
                this.lblTitle = lblPotentialDuplicatesFoundOne;
                break;
            default:
                this.lblTitle = lblPotentialDuplicatesFoundMultiple.replace("{0}", this.duplicateCount.toString());
        }
        this.generateDuplicatesURL();
    }

    generateDuplicatesURL() {
        if (this.duplicateCount > 0) {
            this.viewDuplicatesURL = "/apex/CON_ContactMerge?searchIds=" + this.duplicateIdsParam;
        }
        else {
            this.viewDuplicatesURL = '';
        }
    }

    navigateToContactMerge() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: this.viewDuplicatesURL
            }
        }).then(generatedUrl => {
            window.location.assign(generatedUrl);
        });
    }

    get viewDuplicatesURL() {
        return this.viewDuplicatesURL;
    }

    get lblTitle() {
        return this.lblTitle;
    }
}