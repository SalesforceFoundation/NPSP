import {LightningElement, api, track} from 'lwc';
import {fireEvent} from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';
import {
    apiNameFor,
    isEmpty,
    isNotEmpty,
    isNumeric
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

    _totalAmountFromState;
    @api
    get widgetDataFromState(){}
    set widgetDataFromState(value) {
        if (this._totalAmountFromState === value[this.donationAmountFieldApiName]) {
            return;
        }
        this._totalAmountFromState = value[this.donationAmountFieldApiName];
        this.reallocateAmountByPercent();
    }

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    reallocateAmountByPercent() {
        const percentValue = this.rowRecord[this.allocationPercentageFieldApiName];
        if(isNumeric(percentValue) && percentValue >= 0) {
            this.handleFieldValueChange({
                detail:
                {
                    fieldApiName: this.allocationAmountFieldApiName,
                    value: this.calculateAmountFromPercent(percentValue)
                }
            });
        }
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
            dependentFieldChanges = {...
                {[this.allocationAmountFieldApiName]: this.calculateAmountFromPercent(changedField.value)}
            };
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
    }

    disablePercentFieldIfAmountHasValue(changedField) {
        let percentFieldElement = this.template.querySelector(
    `[data-fieldname=${this.allocationPercentageFieldApiName}]`
        );
        if(isNumeric(changedField.value) &&
            changedField.value > 0 &&
            !percentFieldElement.disabled &&
            isNotEmpty(percentFieldElement.value)) {

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
        const totalInCents = this._totalAmountFromState * 100;

        return Math.round(totalInCents * percentDecimal) / 100
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