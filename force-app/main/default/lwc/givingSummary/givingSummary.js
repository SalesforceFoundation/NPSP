import { api, LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import donationHistoryGivingSummaryTitle from '@salesforce/label/c.donationHistoryGivingSummaryTitle';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';
import donationHistoryLabelLifetime from '@salesforce/label/c.donationHistoryLabelLifetime';
import donationHistoryLabelThisYear from '@salesforce/label/c.donationHistoryLabelThisYear';
import donationHistoryLabelPreviousYear from '@salesforce/label/c.donationHistoryLabelPreviousYear';
import TOTAL_AMOUNT from '@salesforce/schema/Contact.npo02__TotalOppAmount__c';
import AMOUNT_CURRENT_YEAR from '@salesforce/schema/Contact.npo02__OppAmountThisYear__c';
import AMOUNT_LAST_YEAR from '@salesforce/schema/Contact.npo02__OppAmountLastYear__c';
import FORM_FACTOR from '@salesforce/client/formFactor';

const FormFactorType = Object.freeze({
    Large: 'Large',
    Medium: 'Medium',
    Small: 'Small',
});

const MOBILE_CLASSES = 'slds-text-align_center slds-border_bottom slds-text-heading_small slds-var-p-around_medium';
const DESKTOP_CLASSES = 'slds-text-align_center slds-border_right slds-text-heading_small';
const FIELDS = [TOTAL_AMOUNT, AMOUNT_CURRENT_YEAR, AMOUNT_LAST_YEAR];

export default class GivingSummary extends LightningElement {
    labels = {
        donationHistoryGivingSummaryTitle,
        donationHistoryLabelLifetime,
        donationHistoryLabelThisYear,
        donationHistoryLabelPreviousYear,
        commonUnknownError
    };

    lifetimeSummary = 0;
    thisYear = 0;
    previousYear = 0;
    
    contact;
    @api contactId;

    errorMessage=false;
    
    formFactor = FORM_FACTOR;

    @wire(getRecord, { recordId: '$contactId', fields: FIELDS})
        wiredRecord({ error, data }) {
            if (error) {
                this.errorMessage=true;
            } else if (data) {
                this.contact = data;
                this.lifetimeSummary = getFieldValue(this.contact, TOTAL_AMOUNT);
                this.thisYear = getFieldValue(this.contact, AMOUNT_CURRENT_YEAR);
                this.previousYear = getFieldValue(this.contact, AMOUNT_LAST_YEAR);
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
