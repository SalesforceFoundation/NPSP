import {LightningElement, api, track} from 'lwc';
import {fireEvent, registerListener} from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';
import {isEmpty, isNotEmpty, isNumeric} from 'c/utilCommon';

export default class GeFormWidgetRow extends LightningElement {
    @api rowIndex;
    @api rowRecord;
    @api fieldList;
    @api disabled;
    @api totalAmount;
    @api remainingAmount;
    @api isDefault;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api
    getValues() {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        let widgetFieldAndValues = {};
        if(fields !== null && typeof fields !== 'undefined') {
            fields.forEach(field => {
                widgetFieldAndValues = { ...widgetFieldAndValues, ...(field.fieldAndValue) };
            });
        }
        // console.log(widgetFieldAndValues); 
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
            element.setValue(value);
        }
    }

    /**
     * If the total amount is changed, any GAU allocated by percent must be re-allocated to match the total value.
     * Call this method from the parent component on every allocation.
     */
    @api
    reallocateByPercent(totalDonation) {
        const percent = this.rowRecord['Allocation__c.Percent__c'];
        if(isNumeric(percent) && percent >= 0) {
            const detail = {
                targetFieldName: 'Allocation__c.Percent__c',
                value: percent
            };
            this.handleChange({ detail }, totalDonation);
        }
    }

    /**
     * Calculate what amount is X percent of the total donation amount, rounded down to two decimal places.
     * @param percentValue
     * @param total
     * @return {Number}
     */
    calculateAmount(percentValue, total) {
        const factor = +percentValue / 100;
        const amountInCents = Math.round((total * factor) * 100);
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
        if(isNumeric(value) && value > 0 && !this.isFieldDisabled('Allocation__c.Amount__c')) {
            // if a percent is entered, the amount field should be disabled
            this.disableField('Allocation__c.Amount__c');
        } else if(isEmpty(value) || value === 0) {
            if(this.isFieldDisabled('Allocation__c.Amount__c')) {
                this.enableField('Allocation__c.Amount__c');
            }
        }

        // calculate what percent of the total we should set this row's allocation to
        const amount = this.calculateAmount(value, total);
        this.setFieldValue('Allocation__c.Amount__c', amount);
        // add the allocation amount to the update event
        payload['Allocation__c.Amount__c'] = amount;
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
        if(isNumeric(value) && value > 0 && !this.isFieldDisabled('Allocation__c.Percent__c')) {
            this.disableField('Allocation__c.Percent__c');
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
        if(event.detail.targetFieldName === 'Allocation__c.Percent__c') {
            // handle the percent field being updated
            payload = this.handlePercentChange(event.detail, total);
        } else if(event.detail.targetFieldName === 'Allocation__c.Amount__c') {
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
     *
     * @param fullFieldName e.g. Allocation__c.General_Accounting_Unit__c
     */
    getDefaultForField(fullFieldName) {
       const parts = fullFieldName.split('.');
       if(parts && parts.length === 2) {
           const localFieldName = parts[1];
           return this.rowRecord[localFieldName];
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
                        defaultValue: this.getDefaultForField(f.mappedField)
                    }
                };
            });
        }

        return this.fieldList;
    }

}