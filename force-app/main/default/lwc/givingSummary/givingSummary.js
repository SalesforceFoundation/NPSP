import { api, LightningElement } from 'lwc';
import donorsGivenSummary from '@salesforce/label/c.donorsGivenSummary';
import donorsLifetime from '@salesforce/label/c.donorsLifetime';
import donorsThisYear from '@salesforce/label/c.donorsThisYear';
import donorsPreviousYear from '@salesforce/label/c.donorsPreviousYear';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getContact from '@salesforce/apex/GivingSummaryController.getContactForUser'
import pscManageSoftCreditsContactMissing from '@salesforce/label/c.pscManageSoftCreditsContactMissing';
const FormFactorType = Object.freeze({
    Large: 'Large',
    Medium: 'Medium',
    Small: 'Small',
});

const MOBILE_CLASSES = 'slds-text-align_center slds-border_bottom slds-text-heading_small slds-var-p-around_medium';
const DESKTOP_CLASSES = 'slds-text-align_center slds-border_right slds-text-heading_small';
export default class GivingSummary extends LightningElement {
    labels = {
        donorsGivenSummary,
        donorsLifetime,
        donorsThisYear,
        donorsPreviousYear,
    };

    lifetimeSummary = 0;
    thisYear = 0;
    previousYear = 0;

    @api
    contactId

    formFactor = FORM_FACTOR;

    connectedCallback() {
        getContact({contactId: this.contactId}).then(contact => this.parseContact(contact));
        
    }

    /**
     * get the contact from the database and populate the filds that are going to be populated.
     * @param {*} contact theContact to parse
     */
    parseContact(contact) {
        this.lifetimeSummary = contact.npo02__TotalOppAmount__c;
        this.thisYear = contact.npo02__OppAmountThisYear__c;
        this.previousYear = contact.npo02__OppAmountLastYear__c;
    }
    /**
     * @description Returns the classes to be applied to the rows accordling if it is mobile or desktop
     */
    get rowClasses() {
        if (this.isMobile) {
            return MOBILE_CLASSES;
        }
        return DESKTOP_CLASSES
    }

    /**
     * @description returns the classes of the last row if it is mobile or desktop
     */
    get lastElementClasses() {
        if (this.isMobile) {
            return 'slds-text-align_center slds-text-heading_small slds-var-p-around_medium';
        }
        return 'slds-text-align_center slds-text-heading_small';
    }
    /**
     * @description Returns wether we are running in mobile or desktop
     * @returns True if it is mobile
     */
    get isMobile() {
        return this.formFactor === FormFactorType.Small;
    }
}
