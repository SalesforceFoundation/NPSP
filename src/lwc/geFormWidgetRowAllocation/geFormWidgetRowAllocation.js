import {LightningElement, api, track} from 'lwc';
import {fireEvent} from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';
import {
    apiNameFor,
    isEmpty,
    isNumeric
} from 'c/utilCommon';

import DI_DONATION_AMOUNT_FIELD from '@salesforce/schema/DataImport__c.Donation_Amount__c';

import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';
import AMOUNT_FIELD from '@salesforce/schema/Allocation__c.Amount__c';
import PERCENT_FIELD from '@salesforce/schema/Allocation__c.Percent__c';
import GAU_FIELD from '@salesforce/schema/Allocation__c.General_Accounting_Unit__c';

const DATA_FIELD_NAME_SELECTOR = 'data-fieldname';

export default class GeFormWidgetRowAllocation extends LightningElement {
    @api rowIndex;
    @api row;
    @api fieldList;
    @api disabled;

    _remainingAmount;
    @api
    get remainingAmount() {
        return this._remainingAmount;
    }
    set remainingAmount(value) {
        if (value === this._remainingAmount || value === 0 || isEmpty(value)) {
            return;
        }

        this._remainingAmount = value;

        if (this.row.isDefaultGAU) {
            this.handleFieldValueChange({
               detail: {
                    fieldApiName: this.allocationAmountFieldApiName,
                    value: this.remainingAmount
               }
            });
        }
    }

    _totalAmountFromState;
    _widgetDataFromState;
    @api
    get widgetDataFromState(){
        return this._widgetDataFromState;
    }
    set widgetDataFromState(value) {
        this._widgetDataFromState = value;

        this._totalAmountFromState = value[this.donationAmountFieldApiName];
        this.reallocateAmountByPercent();
    }

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    reallocateAmountByPercent() {
        const percentValue = this.row.record[this.allocationPercentageFieldApiName];
        if(isNumeric(percentValue) && percentValue >= 0) {
            this.handleFieldValueChange({
                detail: {
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

        if (changedField.fieldApiName === this.allocationPercentageFieldApiName) {
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

    calculateAmountFromPercent(percentValue) {
        const percentDecimal = parseFloat(percentValue) / 100;
        // convert to cents instead of dollars, avoids floating point problems
        const totalInCents = this._totalAmountFromState * 100;

        return Math.round(totalInCents * percentDecimal) / 100
    }

    remove() {
        const { rowIndex, row } = this;
        this.dispatchEvent(new CustomEvent('remove', { detail: { rowIndex, row } }));
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
        return this.row.record[apiNameFor(GAU_FIELD)];
    }

    get allocationAmountFieldApiName() {
        return apiNameFor(AMOUNT_FIELD);
    }

    get amountValue() {
        return this.row.record[apiNameFor(AMOUNT_FIELD)];
    }

    get allocationPercentageFieldApiName() {
        return apiNameFor(PERCENT_FIELD);
    }

    get percentValue() {
        return this.row.record[apiNameFor(PERCENT_FIELD)];
    }

    get shouldDisablePercent() {
        if (isEmpty(this.row.record[apiNameFor(PERCENT_FIELD)]) &&
            Number.parseFloat(this.row.record[apiNameFor(AMOUNT_FIELD)]) > 0) {
            return true;
        }
    }
    get shouldDisableAmount() {
        if (!isEmpty(this.row.record[apiNameFor(PERCENT_FIELD)]) &&
            Number.parseFloat(this.row.record[apiNameFor(PERCENT_FIELD)]) > 0) {

            return true;
        }
    }

    get qaLocatorDeleteRow() {
        return `button ${this.CUSTOM_LABELS.commonDelete} ${this.rowIndex}`;
    }

    get qaLocatorGAU() {
        return `autocomplete General Accounting Unit ${this.rowIndex}`;
    }

    get qaLocatorAllocationAmount() {
        return `input Amount ${this.rowIndex}`;
    }

    get qaLocatorAllocationPercent() {
        return `input ${this.percentCustomLabel} ${this.rowIndex}`;
    }
}