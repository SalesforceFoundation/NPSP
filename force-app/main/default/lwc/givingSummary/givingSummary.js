import { api, LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import donorsGivingSummary from '@salesforce/label/c.donorsGivingSummary';
import donorsLifetime from '@salesforce/label/c.donorsLifetime';
import donorsThisYear from '@salesforce/label/c.donorsThisYear';
import flsReadAccessError from '@salesforce/label/c.flsReadAccessError';
import donorsPreviousYear from '@salesforce/label/c.donorsPreviousYear';
import FORM_FACTOR from '@salesforce/client/formFactor';

const FormFactorType = Object.freeze({
    Large: 'Large',
    Medium: 'Medium',
    Small: 'Small',
});

const MOBILE_CLASSES = 'slds-text-align_center slds-border_bottom slds-text-heading_small slds-var-p-around_medium';
const DESKTOP_CLASSES = 'slds-text-align_center slds-border_right slds-text-heading_small';
const FIELDS = ['Contact.npo02__TotalOppAmount__c', 'Contact.npo02__OppAmountThisYear__c', 'Contact.npo02__OppAmountLastYear__c'];

export default class GivingSummary extends LightningElement {
    labels = {
        donorsGivingSummary,
        donorsLifetime,
        donorsThisYear,
        donorsPreviousYear,
        flsReadAccessError
    };

    lifetimeSummary = 0;
    thisYear = 0;
    previousYear = 0;
    
    contact;
    @api contactId;

    message;
    
    formFactor = FORM_FACTOR;

    @wire(getRecord, { recordId: '$contactId', fields: FIELDS})
        wiredRecord({ error, data }) {
            if (error) {
                    this.message = 'Unknown error';
                if (Array.isArray(error.body)) {
                    this.message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.message = error.body.message;
                }
            } else if (data) {
                this.contact = data;
                this.lifetimeSummary = this.contact.fields.npo02__TotalOppAmount__c.value;
                this.thisYear = this.contact.fields.npo02__OppAmountThisYear__c.value;
                this.previousYear = this.contact.fields.npo02__OppAmountLastYear__c.value;
            }
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
