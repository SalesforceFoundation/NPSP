import {LightningElement, api} from 'lwc';
import {fireEvent} from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';
import {apiNameFor, isEmpty, isNotEmpty, isNumeric} from 'c/utilCommon';

import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';
import AMOUNT_FIELD from '@salesforce/schema/Allocation__c.Amount__c';
import PERCENT_FIELD from '@salesforce/schema/Allocation__c.Percent__c';
import GAU_FIELD from '@salesforce/schema/Allocation__c.General_Accounting_Unit__c';
const ALLOCATION_AMOUNT = `${ALLOCATION_OBJECT.objectApiName}.${AMOUNT_FIELD.fieldApiName}`;
const ALLOCATION_PERCENT = `${ALLOCATION_OBJECT.objectApiName}.${PERCENT_FIELD.fieldApiName}`;
const ALLOCATION_GAU = `${ALLOCATION_OBJECT.objectApiName}.${GAU_FIELD.fieldApiName}`;

export default class GeFormWidgetRowAllocation extends LightningElement {
    @api rowIndex;
    @api rowRecord;
    @api fieldList;
    @api disabled;
    @api totalAmount;
    @api remainingAmount;
    @api widgetDataFromState;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    /**
     * Given a field, set a value on that ge-form-field by calling ge-form-field.setFieldValue
     * @param field Field name to set the value for
     * @param value Value ot set
     */
    @api
    setFieldValue(field, value) {
        const element = this.getFieldByName(field);
        if(element) {
            element.load({value});
        }
    }

    /**
     * If the total amount is changed, any GAU allocated by percent must be re-allocated to match the total value.
     * Call this method from the parent component on every allocation.
     */
    @api
    reallocateByPercent(totalDonation) {
        const percent = this.rowRecord[ALLOCATION_PERCENT];
        if(isNumeric(percent) && percent >= 0) {
            const detail = {
                targetFieldName: ALLOCATION_PERCENT,
                value: percent
            };
            this.handleChange({ detail }, totalDonation);
        }
    }

    @api
    isValid() {
        const gauField = this.getFieldByName(ALLOCATION_GAU);
        return gauField.isValid();
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



    /**
     * Handle field updates inside this allocation row.
     * @param event
     * @param total Optional total amount parameter for when we're reacting to the total donation amount changing
     */
    handleFieldValueChange(event) {
        this.dispatchEvent(new CustomEvent('rowvaluechange', {
            detail: {
                rowIndex: this.rowIndex,
                changedFieldAndValue: {
                    [event.target.fieldName] : event.target.value
                }
            }
        }));

        if (event.target.fieldName === this.allocationAmountFieldApiName) {
            this.disablePercentFieldIfAmountHasValue(event.target);
        }

        if (event.target.fieldName === this.allocationPercentageFieldApiName) {
            this.disableAmountFieldIfPercentHasValue(event.target);
        }

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
    `[data-id=${this.allocationPercentageFieldApiName}]`
        );
        if(isNumeric(changedField.value) && changedField.value > 0 && !percentFieldElement.disabled) {
            percentFieldElement.disabled = true;
        } else if(isEmpty(changedField.value) || changedField.value === 0) {
            percentFieldElement.disabled = false;
        }
    }

    disableAmountFieldIfPercentHasValue(changedField) {
        let amountFieldElement = this.template.querySelector(
            `[data-id=${this.allocationAmountFieldApiName}]`
        );
        if(isNumeric(changedField.value) && changedField.value > 0 && !amountFieldElement.disabled) {
            amountFieldElement.disabled = true;
        } else if(isEmpty(changedField.value) || changedField.value === 0) {
            amountFieldElement.disabled = false;
        }
    }

    /**
     * Handle a change in the percent amount of an Allocation
     * In some cases, we're not changing the percent, but the total donation amount was updated and we need to update it.
     * @param detail    Event Detail
     * @param total  New total to calculate against. Only needed when the total is updating.
     * @returns {{}}
     */
    handlePercentChange(detail, total) {
        const { targetFieldName, value } = detail;
        let payload = { [targetFieldName]: value };

        // calculate what percent of the total we should set this row's allocation to
        const amount = this.calculateAmount(value, total);
        this.setFieldValue({ALLOCATION_AMOUNT, amount});
        // add the allocation amount to the update event
        payload[ALLOCATION_AMOUNT] = amount;
        return payload;
    }

    getFieldByName(fieldName) {
        return this.template.querySelector(`[data-fieldname='${fieldName}']`);
    }

    isFieldDisabled(fieldName) {
        const field = this.getFieldByName(fieldName);
        return field.element.disabled === true;
    }

    disableField(fieldName) {
        const field = this.getFieldByName(fieldName);
        field.disable();
    }

    enableField(fieldName) {
        const field = this.getFieldByName(fieldName);
        field.enable();
    }

    remove() {
        const { rowIndex, rowRecord } = this;
        this.dispatchEvent(new CustomEvent('remove', { detail: { rowIndex, rowRecord } }));
    }

    get isRemovable() {
        return this.disabled !== true;
    }

    get allocationObjectApiName() {
        return apiNameFor(ALLOCATION_OBJECT);
    }

    get gauFieldApiName() {
        return apiNameFor(GAU_FIELD);
    }

    get allocationAmountFieldApiName() {
        return apiNameFor(AMOUNT_FIELD);
    }

    get allocationPercentageFieldApiName() {
        return apiNameFor(PERCENT_FIELD);
    }

    get qaLocatorDeleteRow() {
        return `button ${this.CUSTOM_LABELS.commonDelete} ${this.rowIndex}`;
    }
}