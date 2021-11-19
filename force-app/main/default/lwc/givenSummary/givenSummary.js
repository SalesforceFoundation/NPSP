import { LightningElement } from 'lwc';
import donorsGivenSummary from '@salesforce/label/c.donorsGivenSummary';
import donorsLifetime from '@salesforce/label/c.donorsLifetime';
import donorsThisYear from '@salesforce/label/c.donorsThisYear';
import donorsPreviousYear from '@salesforce/label/c.donorsPreviousYear';
import FORM_FACTOR from '@salesforce/client/formFactor';

const FormFactorType = Object.freeze({
    Large: 'Large',
    Medium: 'Medium',
    Small: 'Small',
});

export default class GivenSummary extends LightningElement {
    labels = {
        donorsGivenSummary,
        donorsLifetime,
        donorsThisYear,
        donorsPreviousYear,
    };

    formFactor = FORM_FACTOR;

    /**
     * @description Returns the classes to be applied to the rows accordling if it is mobile or desktop
     */
    get rowClasses() {
        if (this.isMobile) {
            return 'slds-text-align_center slds-border_bottom slds-text-heading_small slds-var-p-around_medium';
        }
        return 'slds-text-align_center slds-border_right slds-text-heading_small';
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
