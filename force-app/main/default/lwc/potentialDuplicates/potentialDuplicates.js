import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getCurrentNamespace, showToast } from 'c/utilCommon';

import lblPotentialDuplicatesFoundNone from '@salesforce/label/c.potentialDuplicatesFoundNone';
import lblPotentialDuplicatesFoundOne from '@salesforce/label/c.potentialDuplicatesFoundOne';
import lblPotentialDuplicatesFoundMultiple from '@salesforce/label/c.potentialDuplicatesFoundMultiple';
import lblViewDuplicates from '@salesforce/label/c.viewDuplicates';

import getDuplicates from '@salesforce/apex/PotentialDuplicates.getDuplicates';

export default class PotentialDuplicates extends NavigationMixin(LightningElement) {

    @api recordId;
    @api displayCard;
    @api displayToast;

    @track isEnabled = true;
    @track duplicateCount;
    @track error;
    lblTitle = lblPotentialDuplicatesFoundNone;
    lblViewDuplicatesLink = lblViewDuplicates;
    viewDuplicatesURL;

    connectedCallback() {
        if (this.recordId) {
            getDuplicates({ recordId: this.recordId })
                .then(response => {
                    this.handleDuplicates(response);
                    this.error = null;
                })
                .catch(error => {
                    this.error = this.handleError(error);
                });
        }
    }

    handleDuplicates(response) {
        this.duplicateCount = 0;
        if (response && response.setOfMatches) {
            this.duplicateIdsParam = this.recordId + ',' + response.setOfMatches;
            this.duplicateCount = response.setOfMatches.split(',').length;
        }
        this.generateDuplicatesURL();
        this.updateTitle();
        this.handleToast();
    }

    handleError(error) {
        if (error && error.status && error.body) {
            return error.body.message;
        } else if (error && error.name && error.message) {
            return error.message;
        }
        return "";
    }

    handleToast() {
        if (this.displayToast && this.duplicateCount > 0) {
            let messageData = [{
                "url": this.viewDuplicatesURL,
                "label": this.lblViewDuplicatesLink,
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
    }

    generateDuplicatesURL() {
        if (this.duplicateCount > 0) {
            const contactMerge = 'CON_ContactMerge';
            const namespace = getCurrentNamespace();
            const contactMergePage = namespace ? `${namespace}__${contactMerge}` : contactMerge;
            this.viewDuplicatesURL = "/apex/" + contactMergePage + "?searchIds=" + this.duplicateIdsParam;
        }
        else {
            this.viewDuplicatesURL = "";
        }
    }

    navigateToContactMerge() {
        this[NavigationMixin.GenerateUrl]({
            type: "standard__webPage",
            attributes: {
                url: this.viewDuplicatesURL
            }
        }).then(generatedUrl => {
            window.location.assign(generatedUrl);
        });
    }
}