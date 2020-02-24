import {LightningElement, api, track, wire} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import GeFormService from 'c/geFormService';
import GeLabelService from 'c/geLabelService';
import { isNumeric, isNotEmpty } from 'c/utilCommon';
import { registerListener } from 'c/pubsubNoPageRef';

import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';
import DI_ADDITIONAL_OBJECT from '@salesforce/schema/DataImport__c.Additional_Object_JSON__c'
import GENERAL_ACCOUNTING_UNIT_FIELD from '@salesforce/schema/Allocation__c.General_Accounting_Unit__c';
import AMOUNT_FIELD from '@salesforce/schema/Allocation__c.Amount__c';
import PERCENT_FIELD from '@salesforce/schema/Allocation__c.Percent__c';
const GENERAL_ACCOUNT_UNIT = GENERAL_ACCOUNTING_UNIT_FIELD.fieldApiName;

import ALLOC_DEFAULT_FIELD from '@salesforce/schema/Allocations_Settings__c.Default__c';
import ALLOC_DEFAULT_ALLOCATIONS_ENABLED_FIELD from '@salesforce/schema/Allocations_Settings__c.Default_Allocations_Enabled__c';
const ALLOC_SETTINGS_DEFAULT = ALLOC_DEFAULT_FIELD.fieldApiName;
const ALLOC_SETTINGS_DEFAULT_ALLOCATIONS_ENABLED = ALLOC_DEFAULT_ALLOCATIONS_ENABLED_FIELD.fieldApiName;

export default class GeFormWidgetAllocation extends LightningElement {
    @api element;
    @track alertBanner = {}; // { level: ('error', 'warning'), message: String }
    @track rowList = [];
    @track fieldList = [];
    @track allocationSettings;
    @track _totalAmount;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    
    // need labels for field list
    @wire(getObjectInfo, { objectApiName: ALLOCATION_OBJECT })
    wiredObjectInfo({data}) {
        // Represents the fields in a row of the widget
        if(data) {
            this.fieldList = [
                {
                    mappedField: `${ALLOCATION_OBJECT.objectApiName}.${GENERAL_ACCOUNTING_UNIT_FIELD.fieldApiName}`,
                    size: 4,
                    element: {
                        required: true,
                        customLabel: data.fields[GENERAL_ACCOUNTING_UNIT_FIELD.fieldApiName].label
                    }
                },
                {
                    mappedField: `${ALLOCATION_OBJECT.objectApiName}.${AMOUNT_FIELD.fieldApiName}`,
                    size: 3,
                    element: {
                        customLabel: data.fields[AMOUNT_FIELD.fieldApiName].label,
                    }
                },
                {
                    mappedField: `${ALLOCATION_OBJECT.objectApiName}.${PERCENT_FIELD.fieldApiName}`,
                    size: 3,
                    element: {
                        customLabel: data.fields[PERCENT_FIELD.fieldApiName].label
                    }
                }
            ];
        }
    }

    /**
    * @description Initializes the component
    */
    connectedCallback() {
        registerListener('allocationValueChange', this.handleValueChange, this);
        this.init();
    }


    init = async () => {
        if(!this.allocationSettings) {
            this.allocationSettings = await GeFormService.getAllocationSettings();
        }
        if(this.hasDefaultGAU) {
            this.addRow(true);
        }
    };

    @api
    get totalAmount() {
       return this._totalAmount;
    }

    /**
     * Handle changes in the total donation amount.
     * @param value
     */
    set totalAmount(value) {
        this._totalAmount = value;
        if(value >= 0) {
            // handle percentage allocations first
            // value updates don't propagate down to child nodes, so we need to pass the new Total Amount down
            this.reallocateByPercent(value);
            if(this.hasDefaultGAU) {
                // assign remainder to default GAU if enabled
                this.allocateDefaultGAU();
            }
            this.validate();
        }
    }

    /**
     * Expected to return true if widget fields are valid, false otherwise
     * Currently only check to see if the GAU Lookup is filled in
     * @return Boolean
     */
    @api
    isValid() {
        const rows = this.template.querySelectorAll('c-ge-form-widget-row-allocation');
        for(const row of rows) {
            if(!row.isValid()) {
                return false;
            }
        }
        return true;
    }

    /**
     * Expected to return a map of Object API Name to array of records to be created from this widget
     * @return {'GAU_Allocation_1_abc123' : [record1, record2, ...] }
     */
    @api
    returnValues() {
        const rows = this.template.querySelectorAll('c-ge-form-widget-row-allocation');
        let widgetData = {};
        let widgetRowValues = [];

        if(rows !== null && typeof rows !== 'undefined') {
            rows.forEach(row => {
                // no need to send back default GAU, automatically allocated by trigger
                // dataset attributes are always strings
                if(row.dataset.defaultgau !== 'true') {
                    let rowRecord = row.getValues();
                    // need attributes to be able to deserialize this later.
                    const rowWithAttributes = {
                        attributes: { type: ALLOCATION_OBJECT.objectApiName},
                        ...rowRecord
                    };
                    widgetRowValues.push(rowWithAttributes);
                }
            });
        }

        // use custom metadata record name as key
        widgetData[this.element.dataImportObjectMappingDevName] = widgetRowValues;
        return widgetData;
    }

    @api
    reset() {
        this.rowList = [];
        this.init();
    }

    @api
    load(data) {
        const GAU_ALLOCATION_1_KEY = 'gau_allocation_1';
        let dataImportRow = JSON.parse(data[DI_ADDITIONAL_OBJECT.fieldApiName]).dynamicSourceByObjMappingDevName;
        if (!dataImportRow) {
            return;
        }
        let rowList = new Array();
        let fieldMappings = GeFormService.fieldMappings;
        let gauMappingKeys = Object.keys(fieldMappings).filter(key => {
            return key.toLowerCase().includes(GAU_ALLOCATION_1_KEY);
        });
        Object.keys(dataImportRow).forEach(diKey => {
            let properties = {};

            gauMappingKeys.forEach(fieldMappingKey => {
                let sourceField = fieldMappings[fieldMappingKey].Source_Field_API_Name;
                let sourceObj = dataImportRow[diKey].sourceObj;

                if(Object.keys(sourceObj).includes(sourceField)) {
                    let targetField = [fieldMappings[fieldMappingKey].Target_Field_API_Name];
                    let diSourceField = dataImportRow[diKey].sourceObj[fieldMappings[fieldMappingKey].Source_Field_API_Name];
                    
                    properties[targetField] = diSourceField;

                }
            });
            rowList.push(properties);
        });
        
        this.addRows(rowList);
    }

    /**
     * Handle Add Row being clicked
     */
    handleAddRow() {
        this.addRow(false);
    }

    addRows(records) {
        records.forEach(record => {
            this.addRow(false, record);      
        });
    }

    /**
     * Add a new record to the list
     * @param isDefaultGAU {boolean} When initializing the first row, this should be true.
     */
    addRow(isDefaultGAU, properties) {
        let element = {};
        element.key = this.rowList.length;
        const record = { apiName: ALLOCATION_OBJECT.objectApiName, ...properties};
        let row = {};
        if(isDefaultGAU === true) {
            // default GAU should be locked.
            element.disabled = true;
            row.isDefaultGAU = true;
            record[GENERAL_ACCOUNT_UNIT] = this.allocationSettings[ALLOC_SETTINGS_DEFAULT];
        }

        row = {
            ...row,
            record,
            element
        };
        this.rowList.push(row);
    }

    /**
     * Handle an allocation value change event.
     * rowIndex - Index of the record firing the event
     * payload - Object where key is the field that was updated, and value is the updated value
     * @param event { rowIndex: Number, payload: Object }
     */
    handleValueChange(event) {
        const { rowIndex, payload } = event;
        const record = this.rowList[rowIndex].record;
        this.rowList[rowIndex].record = {...record, ...payload}; // update record in rowList with new values

        const hasRemainingAmount =
            this.allocationSettings[ALLOC_SETTINGS_DEFAULT_ALLOCATIONS_ENABLED] &&
            this.remainingAmount >= 0;

        if(hasRemainingAmount) {
            this.allocateDefaultGAU();
        }

        this.validate();
    }

    /**
     * Reallocate all percent-based allocations with the updated donation total.
     * @param totalDonation
     */
    reallocateByPercent(totalDonation) {
        const rows = this.template.querySelectorAll('c-ge-form-widget-row-allocation');
        if(rows.length > 0) {
            rows.forEach(row => row.reallocateByPercent(totalDonation));
        }
    }

    /**
     * Whenever the total amount or any GAU allocation is adjusted and the default GAU amount should be updated
     * with the total of unallocated funds.
     */
    allocateDefaultGAU() {
        const defaultRow = this.template.querySelector('[data-defaultgau=true]');
        defaultRow.setFieldValue(
            `${ALLOCATION_OBJECT.objectApiName}.${AMOUNT_FIELD.fieldApiName}`,
            this.remainingAmount);
    }

    /**
     * Handle removing a GAU from the list.
     * @param event
     */
    handleRemove(event) {
        this.rowList.splice(event.detail.rowIndex, 1);
    }

    /**
     * Check for under-allocation and over-allocation, display appropriate error or warning message.
     * @return {Boolean} True when component valid
     */
    validate() {
        const message = GeLabelService.format(
            this.CUSTOM_LABELS.geErrorAmountDoesNotMatch,
            [this.donationAmountCustomLabel]);

        if(this.isUnderAllocated) {
            // if no default GAU and under-allocated, display warning
            this.alertBanner = {
                message,
                level: 'warning'
            };
            return false;
        } else if(this.isOverAllocated) {
            // if over-allocated, display error
            this.alertBanner = {
                message,
                level: 'error'
            };
            return false;
        } else {
            // if valid, return true and wipe error message
            this.alertBanner = {};
            return true;
        }
    }

    hasAllocations() {
        return Array.isArray(this.rowList) && this.rowList.length > 0;
    }

    /**
     * @return {boolean} TRUE when the total amount allocated is more then the total donation
     */
    get isOverAllocated() {
        return this.allocatedAmount > this.totalAmount;
    }

    /**
     * @return {boolean} TRUE when no default GAU is present, and
     * the total amount allocated is less than the total donation amount
     */
    get isUnderAllocated() {
        return !this.hasDefaultGAU && (this.allocatedAmount < this.totalAmount);
    }

    get allocatedAmount() {
        const amount = this.rowList
            .filter(row => {
                const defaultGAUId = this.allocationSettings[ALLOC_SETTINGS_DEFAULT];
                if(isNotEmpty(defaultGAUId)) {
                    // don't include default GAU when calculating remaining amount if one is defined.
                    return row.record[GENERAL_ACCOUNT_UNIT] !== defaultGAUId;
                }

                return true;
            })
            .reduce((accumulator, current) => {
                let fullFieldName = `${ALLOCATION_OBJECT.objectApiName}.${AMOUNT_FIELD.fieldApiName}`;
                let localFieldName = AMOUNT_FIELD.fieldApiName;
                let currentKey = current.record.hasOwnProperty(fullFieldName) ? fullFieldName : localFieldName;
                
                const currentAmount = current.record[currentKey];

                if(isNumeric(currentAmount)) {
                    // prefix + to ensure operand is treated as a number
                    return (+currentAmount + accumulator);
                }
                return accumulator;
        }, 0);

        return amount;
    }

    /**
     * Show remaining amount when under-allocated and no default GAU is present, or when over-allocated.
     * @return {boolean}
     */
    get showRemainingAmount() {
        return this.hasAllocations() &&
            ((this.hasDefaultGAU === false && this.remainingAmount > 0) || this.remainingAmount < 0);
    }

    /**
     * Remaining amount that can be allocated into non-default GAU. If default GAU is present, this
     * is the amount allocated to the default GAU.
     * @return {number}
     */
    get remainingAmount() {
        if(isNumeric(this.totalAmount) && isNumeric(this.allocatedAmount)) {
            const remainingCents = Math.round(this.totalAmount * 100) - Math.round(this.allocatedAmount * 100);
            // avoid floating point errors by subtracting whole numbers
            return (remainingCents / 100)
        }
        return 0;
    }

    get hasDefaultGAU() {
        return this.allocationSettings
            && this.allocationSettings[ALLOC_SETTINGS_DEFAULT_ALLOCATIONS_ENABLED] === true;
    }

    get hasAlert() {
        return this.hasAllocations() && isNotEmpty(this.alertBanner.message);
    }

    get alertIcon() {
        if(isNotEmpty(this.alertBanner.level)) {
            const warningIcon = 'utility:warning';
            const errorIcon = 'utility:error';
            switch(this.alertBanner.level) {
                case 'error':
                    return errorIcon;
                case 'warning':
                    return warningIcon;
                default:
                    return errorIcon;
            }
        }
    }

    get alertClass() {
        if(isNotEmpty(this.alertBanner.level)) {
            const warningClass = 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_warning';
            const errorClass = 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_error';
            switch(this.alertBanner.level) {
                case 'error':
                    return errorClass;
                case 'warning':
                    return warningClass;
                default:
                    return errorClass;
            }
        }
    }

    get footerClass() {
        return this.rowList.length > 0 ? 'slds-p-top--medium slds-m-top--medium slds-border--top'
            : 'slds-p-top--medium slds-m-top--medium';
    }

    /**
     * TODO: Retrieve the custom label for donation amount from the form template JSON
     */
    get donationAmountCustomLabel() {
        return GeFormService.donationFieldTemplateLabel;
    }

}