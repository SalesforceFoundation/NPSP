import {LightningElement, api, track} from 'lwc';
import {fireEvent, registerListener} from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';
import {isEmpty, isNotEmpty, isNumeric} from 'c/utilCommon';
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

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api
    getValues() {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        let widgetFieldAndValues = {};
        if(fields !== null && typeof fields !== 'undefined') {
            fields.forEach(field => {
                const { fieldAndValue } = field;
                // convert full field names to local field names for processing
                Object.entries(fieldAndValue).forEach(([fieldName,fieldValue]) => {
                    const localFieldName = this.getLocalFieldName(fieldName);
                    if(isNotEmpty(fieldValue)) {
                        // no need to populate fields with values that are blank / empty
                        widgetFieldAndValues = {...widgetFieldAndValues, ...{[localFieldName]: fieldValue}};
                    }
                });
            });
        }
        return widgetFieldAndValues;
    }

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
     * Handle a change in the percent amount of an Allocation
     * In some cases, we're not changing the percent, but the total donation amount was updated and we need to update it.
     * @param detail    Event Detail
     * @param total  New total to calculate against. Only needed when the total is updating.
     * @returns {{}}
     */
    handlePercentChange(detail, total) {
        const { targetFieldName, value } = detail;
        let payload = { [targetFieldName]: value };
        if(isNumeric(value) && value > 0 && !this.isFieldDisabled(ALLOCATION_AMOUNT)) {
            // if a percent is entered, the amount field should be disabled
            this.disableField(ALLOCATION_AMOUNT);
        } else if(isEmpty(value) || value === 0) {
            if(this.isFieldDisabled(ALLOCATION_AMOUNT)) {
                this.enableField(ALLOCATION_AMOUNT);
            }
        }

        // calculate what percent of the total we should set this row's allocation to
        const amount = this.calculateAmount(value, total);
        this.setFieldValue(ALLOCATION_AMOUNT, amount);
        // add the allocation amount to the update event
        payload[ALLOCATION_AMOUNT] = amount;
        return payload;
    }

    /**
     * When the amount in a GAU Allocation is updated, the percent field should be disabled.
     * @param detail    Detail parameter from the change event in the ge-form-field
     * @returns Object where keys are field names, and values are field values
     */
    handleAmountChange(detail) {
        const { targetFieldName, value } = detail;
        let payload = { [targetFieldName]: value };
        if(isNumeric(value) && value > 0 && !this.isFieldDisabled(ALLOCATION_PERCENT)) {
            this.disableField(ALLOCATION_PERCENT);
        } else if(isEmpty(value) || value === 0) {
            this.enableField(ALLOCATION_PERCENT);
        }

        return payload;
    }

    /**
     * Handle field updates inside this allocation row.
     * @param event
     * @param total Optional total amount parameter for when we're reacting to the total donation amount changing
     */
    handleChange(event, total) {
        let payload;
        // if a total was passed in, use it for calculating percent allocations, otherwise use this.totalAmount
        const totalForCalculation = isNumeric(total) ? total : this.totalAmount;
        if(event.detail.targetFieldName === ALLOCATION_PERCENT) {
            // handle the percent field being updated
            payload = this.handlePercentChange(event.detail, totalForCalculation);
        } else if(event.detail.targetFieldName === ALLOCATION_AMOUNT) {
            // handle the Amount field being updated
            payload = this.handleAmountChange(event.detail);
        }

        if(isNotEmpty(payload)) {
            // notify listeners of the new allocation values
            fireEvent(null, 'allocationValueChange', {rowIndex: this.rowIndex, payload});
        }
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
        field.element =  {...field.element, disabled: true};
    }

    enableField(fieldName) {
        const field = this.getFieldByName(fieldName);
        field.element =  {...field.element, disabled: false};
    }

    remove() {
        const { rowIndex, rowRecord } = this;
        this.dispatchEvent(new CustomEvent('remove', { detail: { rowIndex, rowRecord } }));
    }

    get isRemovable() {
        return this.disabled !== true;
    }

    /**
     * If a value is populated for the field in this.rowRecord, return it.
     * @param fullFieldName e.g. Allocation__c.General_Accounting_Unit__c
     */
    getDefaultForField(fullFieldName) {
        const localFieldName = this.getLocalFieldName(fullFieldName);
        if (localFieldName) {
            return this.rowRecord[localFieldName];
        }
    }

    /**
     * Extract the local field name from a full field name
     * @param fullFieldName example: 'Allocation__c.General_Accounting_Unit__c'
     * @return {*|string}   example: 'General_Accounting_Unit__c'
     */
    getLocalFieldName(fullFieldName) {
        const parts = fullFieldName.split('.');
        if(parts && parts.length === 2) {
            return parts[1];
        }
    }

    /**
     * Merge row-level properties with field level properties.
     * If the whole row is disabled (default GAU) then all fields in the row should be disabled
     */
    get mergedFieldList() {
        if(this.disabled) {
            return this.fieldList.map(f => {
                const { element } = f;
                return {
                    ...f,
                    element: {
                        ...element,
                        disabled: true,
                        defaultValue: this.getDefaultForField(f.mappedField) // only needed for default GAU for now
                    }
                };
            });
        }

        return this.fieldList;
    }

}