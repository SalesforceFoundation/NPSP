import {LightningElement, api, track} from 'lwc';
import {fireEvent} from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';
import {
    apiNameFor,
    isEmpty,
    isNumeric,
    deepClone, debouncify
} from 'c/utilCommon';

import DI_DONATION_AMOUNT_FIELD from '@salesforce/schema/DataImport__c.Donation_Amount__c';

import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';
import AMOUNT_FIELD from '@salesforce/schema/Allocation__c.Amount__c';
import PERCENT_FIELD from '@salesforce/schema/Allocation__c.Percent__c';
import GAU_FIELD from '@salesforce/schema/Allocation__c.General_Accounting_Unit__c';

const ALLOCATION_AMOUNT = `${ALLOCATION_OBJECT.objectApiName}.${AMOUNT_FIELD.fieldApiName}`;
const ALLOCATION_PERCENT = `${ALLOCATION_OBJECT.objectApiName}.${PERCENT_FIELD.fieldApiName}`;
const ALLOCATION_GAU = `${ALLOCATION_OBJECT.objectApiName}.${GAU_FIELD.fieldApiName}`;
const DATA_FIELD_NAME_SELECTOR = 'data-fieldname';

export default class GeFormWidgetRowAllocation extends LightningElement {
    @api rowIndex;
    @api rowRecord;
    @api fieldList;
    @api disabled;
    @api widgetDataFromState;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    /**
     * If the total amount is changed, any GAU allocated by percent must be re-allocated to match the total value.
     * Call this method from the parent component on every allocation.
     */
    @api
    reallocateByPercent(totalDonation) {
        const percent = this.rowRecord[this.allocationPercentageFieldApiName];
        if(isNumeric(percent) && percent >= 0) {
            const detail = {
                fieldApiName: this.allocationPercentageFieldApiName,
                value: percent
            };
            this.handleFieldValueChange({ detail }, totalDonation);
        }
    }

    /**
     * Calculate what amount is X percent of the total donation amount, rounded down to two decimal places.
     * @param percentValue
     * @param total
     * @return {Number}
     */
    calculateAmount(percentValue, total) {
        const factor = +percentValue / 100; // force conversion to number with + prefix operator
        const totalInCents = total * 100; // convert to cents instead of dollars, avoids floating point problems
        const amountInCents = Math.round(totalInCents * factor);
        return (amountInCents / 100);
    }

    handleFieldValueChange = (event) => {
        let changedField = {};
        let dependentFieldChanges = {};
        // Handle event from a DOM element
        if (event.target && event.target.hasAttribute(DATA_FIELD_NAME_SELECTOR)) {
            changedField = {
                fieldApiName: event.target.getAttribute(DATA_FIELD_NAME_SELECTOR),
                value: event.target.value
            }
        // Handle when the function is called from other functions
        } else {
            changedField = event.detail;
        }

        if (changedField.fieldApiName === this.allocationAmountFieldApiName) {
            this.disablePercentFieldIfAmountHasValue(changedField);
        }

        if (changedField.fieldApiName === this.allocationPercentageFieldApiName) {
            this.disableAmountFieldIfPercentHasValue(changedField);
            dependentFieldChanges = {...this.calculateAmountFromPercent(changedField.value)};
        }

        this.dispatchEvent(new CustomEvent('rowvaluechange', {
            detail: {
                rowIndex: this.rowIndex,
                changedFieldAndValue: {
                    [changedField.fieldApiName] : changedField.value,
                    ...dependentFieldChanges
                }
            }
        }));
        // if(event.detail.targetFieldName === ALLOCATION_PERCENT) {
        //     // payload = this.handlePercentChange(event.detail, totalForCalculation);
        // }
        // if(isNotEmpty(payload)) {
        //     // notify listeners of the new allocation values
        //     fireEvent(null, 'allocationValueChange', {rowIndex: this.rowIndex, payload});
        // }
    }

    disablePercentFieldIfAmountHasValue(changedField) {
        let percentFieldElement = this.template.querySelector(
    `[data-fieldname=${this.allocationPercentageFieldApiName}]`
        );
        if(isNumeric(changedField.value) && changedField.value > 0 && !percentFieldElement.disabled) {
            percentFieldElement.disabled = true;
        } else if(isEmpty(changedField.value) || changedField.value === 0) {
            percentFieldElement.disabled = false;
        }
    }

    disableAmountFieldIfPercentHasValue(changedField) {
        let amountFieldElement = this.template.querySelector(
            `[data-fieldname=${this.allocationAmountFieldApiName}]`
        );
        if(isNumeric(changedField.value) && changedField.value > 0 && !amountFieldElement.disabled) {
            amountFieldElement.disabled = true;
        } else if(isEmpty(changedField.value) || changedField.value === 0) {
            amountFieldElement.disabled = false;
        }
    }

    calculateAmountFromPercent(percentValue) {
        const percentDecimal = parseFloat(percentValue) / 100;
        // convert to cents instead of dollars, avoids floating point problems
        const totalInCents = this.widgetDataFromState[this.donationAmountFieldApiName] * 100;

        return {
            [this.allocationAmountFieldApiName] : Math.round(totalInCents * percentDecimal) / 100
        }
    }

    remove() {
        const { rowIndex, rowRecord } = this;
        this.dispatchEvent(new CustomEvent('remove', { detail: { rowIndex, rowRecord } }));
    }

    get isRemovable() {
        return this.disabled !== true;
    }

    get percentCustomLabel() {
        return this.CUSTOM_LABELS.commonPercent;
    }

    get donationAmountFieldApiName() {
        return apiNameFor(DI_DONATION_AMOUNT_FIELD);
    }

    get allocationObjectApiName() {
        return apiNameFor(ALLOCATION_OBJECT);
    }

    get gauFieldApiName() {
        return apiNameFor(GAU_FIELD);
    }

    get gauValue() {
        return this.rowRecord[apiNameFor(GAU_FIELD)];
    }

    get allocationAmountFieldApiName() {
        return apiNameFor(AMOUNT_FIELD);
    }

    get amountValue() {
        return this.rowRecord[apiNameFor(AMOUNT_FIELD)];
    }

    get allocationPercentageFieldApiName() {
        return apiNameFor(PERCENT_FIELD);
    }

    get percentValue() {
        return this.rowRecord[apiNameFor(PERCENT_FIELD)];
    }

    get qaLocatorDeleteRow() {
        return `button ${this.CUSTOM_LABELS.commonDelete} ${this.rowIndex}`;
    }
}