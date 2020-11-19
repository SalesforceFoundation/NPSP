import {LightningElement, api, track, wire} from 'lwc';
import {
    isNumeric,
    isNotEmpty,
    isEmpty,
    isEmptyObject,
    apiNameFor, debouncify
} from 'c/utilCommon';

import GeFormService from 'c/geFormService';
import GeLabelService from 'c/geLabelService';

import DI_DONATION_AMOUNT_FIELD from '@salesforce/schema/DataImport__c.Donation_Amount__c';

import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';
import DATA_IMPORT_ADDITIONAL_JSON_FIELD from '@salesforce/schema/DataImport__c.Additional_Object_JSON__c'
import GENERAL_ACCOUNTING_UNIT_FIELD from '@salesforce/schema/Allocation__c.General_Accounting_Unit__c';
import AMOUNT_FIELD from '@salesforce/schema/Allocation__c.Amount__c';
import PERCENT_FIELD from '@salesforce/schema/Allocation__c.Percent__c';

import ALLOC_DEFAULT_FIELD from '@salesforce/schema/Allocations_Settings__c.Default__c';
import ALLOC_DEFAULT_ALLOCATIONS_ENABLED_FIELD from '@salesforce/schema/Allocations_Settings__c.Default_Allocations_Enabled__c';

const GENERAL_ACCOUNT_UNIT = GENERAL_ACCOUNTING_UNIT_FIELD.fieldApiName;
const ALLOC_SETTINGS_DEFAULT = ALLOC_DEFAULT_FIELD.fieldApiName;
const ALLOC_SETTINGS_DEFAULT_ALLOCATIONS_ENABLED = ALLOC_DEFAULT_ALLOCATIONS_ENABLED_FIELD.fieldApiName;

export default class GeFormWidgetAllocation extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    _widgetDataFromState = {};
    @api
    get widgetDataFromState() {
        return this._widgetDataFromState;
    }
    set widgetDataFromState(value) {
        this._widgetDataFromState = value;

        this.loadWidgetDataFromState();
    }

    @api element;
    @track alertBanner = {};
    @track rowList = [];
    @track fieldList = [];
    @track allocationSettings;
    _totalAmount = 0;

    connectedCallback() {
        this.init();
    }

    init = async () => {
        if(!this.allocationSettings) {
            this.allocationSettings = await GeFormService.getAllocationSettings();
        }
        if (this.hasDefaultGAU) {
            this.addRow(true);
        }
    };

    loadWidgetDataFromState() {
        let totalDonationAmount = Number.parseFloat(this.widgetDataFromState[apiNameFor(DI_DONATION_AMOUNT_FIELD)]);
        this.totalAmount = totalDonationAmount === 0 ? null : totalDonationAmount;

        this.reset();

        const additionalObjectJson = this.widgetDataFromState[apiNameFor(DATA_IMPORT_ADDITIONAL_JSON_FIELD)];
        if (isEmpty(additionalObjectJson)) {
            return;
        }

        const widgetData = JSON.parse(additionalObjectJson);
        let rowList = [];
        Object.values(widgetData).forEach(objectDevNameValues => {
            objectDevNameValues.filter(
                objectDevNameValue => objectDevNameValue.attributes.type === apiNameFor(ALLOCATION_OBJECT)
            )
            .forEach(objectDevNameValue => {
                let row = {}
                Object.entries(objectDevNameValue)
                    .filter(([key, value]) => key !== 'attributes')
                    .forEach(([key, value]) => {
                        row[key] = value
                    })
                rowList.push(row);
            })
        });
        this.addRows(rowList);
    }

    get totalAmount() {
        return this._totalAmount;
    }

    set totalAmount(value) {
        this._totalAmount = value;

        this.validate();

    }
    get remainingAmount() {
        if(isNumeric(this.totalAmount) && isNumeric(this.allocatedAmount)) {
            const remainingCents = Math.round(this.totalAmount * 100) - Math.round(this.allocatedAmount * 100);
            // avoid floating point errors by subtracting whole numbers
            return (remainingCents / 100);
        }
        return 0;
    }

    get hasRemainingAmount() {
        return this.allocationSettings[ALLOC_SETTINGS_DEFAULT_ALLOCATIONS_ENABLED] &&
            this.remainingAmount >= 0;
    }

    hasAllocations() {
        return Array.isArray(this.rowList) && this.rowList.length > 0;
    }

    get showRemainingAmount() {
        return this.hasAllocations() &&
            ((this.hasDefaultGAU === false && this.remainingAmount > 0) || this.remainingAmount < 0);
    }

    get isOverAllocated() {
        return this.allocatedAmount > this.totalAmount;
    }

    get isUnderAllocated() {
        return !this.hasDefaultGAU && (this.allocatedAmount < this.totalAmount);
    }

    get allocatedAmount() {
        return this.rowList
            .filter(row => {
                const defaultGAUId = this.allocationSettings[ALLOC_SETTINGS_DEFAULT];
                if(isNotEmpty(defaultGAUId)) {
                    return row.record[GENERAL_ACCOUNT_UNIT] !== defaultGAUId;
                }

                return true;
            })
            .reduce((accumulator, current) => {
                let currentAmount = +current.record[apiNameFor(AMOUNT_FIELD)];

                if (isEmpty(currentAmount)) {
                    const currentPercent = +current.record[apiNameFor(PERCENT_FIELD)];
                    currentAmount = (currentPercent * this.totalAmount) / 100;
                }

                if(isNumeric(currentAmount)) {
                    // prefix + to ensure operand is treated as a number
                    return currentAmount + accumulator;
                }
                return accumulator;
            }, 0);
    }

    handleAddRow() {
        this.addRow(false);
    }

    addRows(rowRecords) {
        rowRecords.forEach(rowRecord => {
            this.addRow(false, rowRecord);
        });
    }

    addRow(isDefaultGAU, rowRecord) {
        let element = {};
        element.key = this.rowList.length;
        const record = { ...rowRecord };
        let row = {};
        if(isDefaultGAU === true) {
            // default GAU should be locked.
            row.isDefaultGAU = true;
            row.disabled = true;
            record[GENERAL_ACCOUNT_UNIT] = this.allocationSettings[ALLOC_SETTINGS_DEFAULT];
        }

        row = {
            ...row,
            record,
            element
        };
        this.rowList.push(row);
    }

    handleRemove(event) {
        this.rowList.splice(event.detail.rowIndex, 1);

        this.fireFormWidgetChange({
            [apiNameFor(DATA_IMPORT_ADDITIONAL_JSON_FIELD)]: JSON.stringify(this.convertRowListToSObjectJSON())
        });
    }

    reset() {
        this.rowList = [];
        if(this.hasDefaultGAU) {
            this.addRow(true);
        }
    }

    handleRowValueChange = (event) => {
        const detail = event.detail;
        const record = this.rowList[detail.rowIndex].record;
        this.rowList[detail.rowIndex].record = {...record, ...detail.changedFieldAndValue};

        this.fireFormWidgetChange({
            [apiNameFor(DATA_IMPORT_ADDITIONAL_JSON_FIELD)]: JSON.stringify(this.convertRowListToSObjectJSON())
        });
    }

    fireFormWidgetChange(fieldAndValue) {
        this.dispatchEvent(new CustomEvent('formwidgetchange', {
           detail: {
               ...fieldAndValue
           }
        }));
    }

    convertRowListToSObjectJSON() {
        let widgetRowValues = [];

        this.rowList.forEach(row => {
            // no need to send back default GAU, automatically allocated by the trigger
            if (row.isDefaultGAU) {
                return;
            }
            widgetRowValues.push({
                attributes: { type: ALLOCATION_OBJECT.objectApiName },
                ...row.record
            });
        });

        return {
            [this.element.dataImportObjectMappingDevName]: widgetRowValues
        };
    }

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
            const errorClass = 'error';
            const warningClass = 'warning';

            switch(this.alertBanner.level) {
                case errorClass:
                    return errorClass;
                case warningClass:
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

    get donationAmountCustomLabel() {
        return GeFormService.donationFieldTemplateLabel;
    }

    get qaLocatorAddNewAllocation() {
        return `button ${this.CUSTOM_LABELS.geAddNewAllocation}`;
    }

    get qaLocatorRemainingAllocationAmount() {
        return `lightning-formatted-number Remaining Allocation Amount`;
    }
}