import {LightningElement, api, track, wire} from 'lwc';
import {isNotEmpty, debouncify, isUndefined} from 'c/utilCommon';
import GeFormService from 'c/geFormService';
import GeLabelService from 'c/geLabelService';
import {getObjectInfo} from "lightning/uiObjectInfoApi";
import { fireEvent } from 'c/pubsubNoPageRef';
import DI_DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DONOR_FIELD from '@salesforce/schema/DataImport__c.Donation_Donor__c';
import DONATION_RECORD_TYPE_NAME from '@salesforce/schema/DataImport__c.Donation_Record_Type_Name__c';
import ACCOUNT1_IMPORTED from '@salesforce/schema/DataImport__c.Account1Imported__c';
import CONTACT1_IMPORTED from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import PRIMARY_CONTACT from '@salesforce/schema/Opportunity.Primary_Contact__c';
import DATA_IMPORT from '@salesforce/schema/DataImport__c';
import RECORD_TYPE_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';
import OPPORTUNITY from '@salesforce/schema/Opportunity';

import {
    DI_DONATION_DONOR_INFO,
    CONTACT_FIRST_NAME_INFO,
    CONTACT_LAST_NAME_INFO,
    ACCOUNT_NAME_INFO,
    DI_ACCOUNT1_IMPORTED_INFO,
    DI_CONTACT1_IMPORTED_INFO
} from "c/utilTemplateBuilder";

const LOOKUP_TYPE = 'REFERENCE';
const PICKLIST_TYPE = 'PICKLIST';
const TEXT_AREA_TYPE = 'TEXTAREA';
const BOOLEAN_TYPE = 'BOOLEAN';
const DELAY = 300;
const RICH_TEXT_FORMATS = [
    'font', 'size', 'bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align', 'link', 'clean', 'table', 'header'
];
const CURRENCY = 'currency';
const PERCENT = 'percent';
const DECIMAL = 'decimal';
const DATE = 'date';
const DATETIME = 'datetime-local';
const CHECKBOX = 'checkbox';

export default class GeFormField extends LightningElement {
    @track value;
    @track picklistValues = [];
    @track objectDescribeInfo;
    @track richTextValid = true;
    @track _disabled = false;
    @api element;
    @api targetFieldName;
    _defaultValue = null;
    _recordTypeId;

    richTextFormats = RICH_TEXT_FORMATS;
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    handleValueChangeSync = (event) => {
        this.value = this.getValueFromChangeEvent(event);
        const detail = {
            element: this.element,
            value: this.value,
            targetFieldName: this.targetFieldName
        };
        const evt = new CustomEvent('valuechange', {detail, bubbles: true});
        this.dispatchEvent(evt);

        if (this.isLookup) {
            const objMappingDevName =
                GeFormService.importedRecordFieldNames.includes(this.fieldApiName) ?
                    GeFormService.getObjectMappingWrapperByImportedFieldName(this.fieldApiName)
                        .DeveloperName :
                    this.objectMappingDevName;
            const lookupDetail = {
                ...event.detail,
                fieldApiName: this.element.fieldApiName,
                value: this.value,
                objectMappingDevName: objMappingDevName
            };
            const selectRecordEvent = new CustomEvent('lookuprecordselect', { detail: lookupDetail });
            this.dispatchEvent(selectRecordEvent);
        }

        if (this.isPicklist) {
            this.handlePicklistChange();
        }

        if(this.isRichText) {
            this.checkRichTextValidity();
        }

        if(this.sourceFieldAPIName === DI_DONATION_AMOUNT.fieldApiName) {
            // fire event for reactive widget component containing the Data Import field API name and Value
            // currently only used for the Donation Amount.
            fireEvent(null, 'widgetData', { donationAmount: this.value });
        }

        if (this.isValidNameOnCardField) {
            const evt = new CustomEvent('creditcardvaluechange');
            this.dispatchEvent(evt);
        }
    };

    handleValueChange = debouncify(this.handleValueChangeSync.bind(this), DELAY);

    handlePicklistChange() {
        if (this.fieldApiName === DONATION_DONOR_FIELD.fieldApiName) {
            const changeDonationDonorEvent = new CustomEvent(
                'changedonationdonor',
                {detail: {value: this.value}});
            this.dispatchEvent(changeDonationDonorEvent);
        }
    }

    /**
     * Retrieve object metadata. Used to configure how fields are displayed on the form.
     */
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo(response) {
        if(response.data) {
            this.objectDescribeInfo = response.data;
        }
    }

    connectedCallback() {
        const { defaultValue, recordValue } = this.element;

        if(recordValue) {

            // set the record value to the element value
            this.value = recordValue;
        } else if(defaultValue) {

            // Set the default value if there is one
            // and no record value.
            this._defaultValue = defaultValue;
            this.value = defaultValue;
            this.handlePicklistChange();
        }
    }

    getValueFromChangeEvent(event) {
        if(this.fieldType === BOOLEAN_TYPE) {
            return event.detail.checked.toString();
        } else if(this.isRichText) {
            return event.target.value;
        } else if(this.isLookup && event.detail.value) {
            const val = event.detail.value;
            if(typeof val === 'string') {
                return val;
            } else if(Array.isArray(val)) {
                return val[0] ? val[0] : null;
            }
        }

        return event.detail.value;
    }

    /**
     * TRUE when a field is required and filled in correctly, or not required at all.
     * @returns {boolean}
     */
    @api
    isValid() {
        // We need to check for invalid values, regardless if the field is required
        let fieldIsValid = this.checkFieldValidity();

        if(this.element !== null && this.element.required) {
            return isNotEmpty(this.value)
                && this.value !== this.CUSTOM_LABELS.commonLabelNone
                && fieldIsValid;
        }

        return fieldIsValid;
    }

    /**
     * TRUE when a field is filled in, and is the correct format.
     * @returns {boolean}
     */
    checkFieldValidity() {
        // TODO: Handle other input types, if needed
        const inputField = this.template.querySelector('[data-id="inputComponent"]');
        if(typeof inputField !== 'undefined'
            && inputField !== null
            && typeof inputField.reportValidity === 'function'
            && typeof inputField.checkValidity === 'function') {
                inputField.reportValidity();
                return inputField.checkValidity();
        } else if(this.isRichText) {
            this.checkRichTextValidity();
            if(!this.richTextValid) {
                // workaround, field will not display as invalid if it is untouched
                inputField.focus();
                inputField.blur();
            }
            return this.richTextValid;
        }
        return true;
    }

    checkRichTextValidity() {
        if(this.element.required) {
            const isValid = isNotEmpty(this.value) && this.value.length > 0;
            this.richTextValid = isValid;
            return isValid;
        }
        return true;
    }

    @api
    disable() {
        this._disabled = true;
    }

    @api
    enable() {
        this._disabled = false;
    }

    @api
    get fieldAndValue() {
        let fieldAndValue = {};

        // KIET TBD: This is where we are keeping the field mapping
        // CMT record name at, element.value. 
        // However, it may change to the array dataImportFieldMappingDevNames
        // If so, we need to update this to reflect that.
        // In the Execute Anonymous code, both fields are populated.

        if (this.value &&
            this.sourceFieldAPIName === DONATION_RECORD_TYPE_NAME.fieldApiName &&
            Object.keys(this.objectDescribeInfo.recordTypeInfos).includes(this.value)) {
            // value is the RecordType Id, but the DataImport's source field expects
            // the RecordType Name
            fieldAndValue[this.formElementName] =
                this.objectDescribeInfo.recordTypeInfos[this.value].name;
        } else if (this.isPicklist){
            // If the displayed value of the picklist is '--None--' treat the value as blank.
            fieldAndValue[this.formElementName] =
                (this.value === this.CUSTOM_LABELS.commonLabelNone) ? '' : this.value;
        } else {
            fieldAndValue[this.formElementName] = this.value;
        }

        return fieldAndValue;
    }

    get formElementName() {
        return this.element.componentName ? this.element.componentName : this.element.dataImportFieldMappingDevNames[0];
    }

    get inputType() {
        return GeFormService.getInputTypeFromDataType(this.fieldType);
    }

    get formatter() {
        return GeFormService.getNumberFormatterByDescribeType(this.fieldType);
    }

    get required() {
        return (this.fieldInfo && this.fieldInfo.Is_Required && this.fieldType !== BOOLEAN_TYPE) || 
            (this.element && this.element.required);
    }

    get disabled() {
        return this._disabled || (this.element && this.element.disabled);
    }

    get granularity() {
        if (this.formatter) {
            switch (this.fieldType.toLowerCase()) {
                case CURRENCY: return '0.01';
                case PERCENT: return '0.01';
                case DECIMAL: return '0.001';
                default: return 'any';
            }
        }
        return undefined;
    }

    get fieldInfo() {
        return isNotEmpty(this.targetFieldName) ?
            GeFormService.getFieldMappingWrapperFromTarget(this.targetFieldName) :
            GeFormService.getFieldMappingWrapper(this.formElementName);
    }

    get fieldDescribeInfo() {
        if(this.objectDescribeInfo) {
            return this.objectDescribeInfo.fields[this.fieldApiName];
        }
    }

    get objectInfo() {
        return GeFormService.getObjectMappingWrapper(this.objectMappingDevName);
    }

    get fieldType() {
        if(isNotEmpty(this.fieldInfo)) {
            return this.fieldInfo.Target_Field_Data_Type;
        }
    }

    get isLightningInput() {
        return typeof GeFormService.getInputTypeFromDataType(this.fieldType) !== 'undefined';
    }

    get isRichText() {
        if(typeof this.fieldDescribeInfo !== 'undefined' && this.fieldType === TEXT_AREA_TYPE) {
            return this.fieldDescribeInfo.htmlFormatted;
        }
    }

    get isLookupRecordType() {
        return this.fieldType === LOOKUP_TYPE && this.fieldApiName === RECORD_TYPE_FIELD.fieldApiName;
    }

    @api
    get isLookup() {
        return this.fieldType === LOOKUP_TYPE && this.fieldApiName !== RECORD_TYPE_FIELD.fieldApiName;
    }

    @api
    get isPicklist() {
        return this.fieldType === PICKLIST_TYPE;
    }

    get isTextArea() {
        if(typeof this.fieldDescribeInfo !== 'undefined' && this.fieldType === TEXT_AREA_TYPE) {
            return !this.fieldDescribeInfo.htmlFormatted;
        }
    }

    @api
    get objectMappingDevName() {
        if(isNotEmpty(this.fieldInfo)) {
            return this.fieldInfo.Target_Object_Mapping_Dev_Name;
        }
    }

    get objectApiName() {
        if(typeof this.objectInfo !== 'undefined') {
            return this.objectInfo.Object_API_Name;
        }
    }

    @api
    get fieldApiName() {
        if(isNotEmpty(this.fieldInfo)) {
            return this.fieldInfo.Target_Field_API_Name;
        }
    }

    @api
    get sourceFieldAPIName() {
        if(isNotEmpty(this.fieldInfo)) {
            return this.fieldInfo.Source_Field_API_Name;
        }
    }

    // when using lightning-lookup-field, instead of binding to the Data Import fields or donor information
    // we bind to Opportunity.AccountId / Opportunity.Primary_Contact__c
    get lookupFieldApiName() {
        if (this.objectApiName === DATA_IMPORT.objectApiName) {
            if (this.fieldApiName === ACCOUNT1_IMPORTED.fieldApiName) {
                return ACCOUNT_ID.fieldApiName;
            } else if (this.fieldApiName === CONTACT1_IMPORTED.fieldApiName) {
                return PRIMARY_CONTACT.fieldApiName;
            }
        }
        return this.fieldApiName;
    }

    get lookupObjectApiName() {
        if(this.objectApiName === DATA_IMPORT.objectApiName) {
            if(this.fieldApiName === ACCOUNT1_IMPORTED.fieldApiName
                || this.fieldApiName === CONTACT1_IMPORTED.fieldApiName) {
                return OPPORTUNITY.objectApiName;
            }
        }

        return this.objectApiName;
    }

    @api
    get fieldLabel() {
        return this.element.customLabel;
    }

    @api
    get fieldValueAndLabel() {

        let fieldWrapper = { value: this.value, label: this.fieldLabel };
        let returnMap = {};
        returnMap[ this.sourceFieldAPIName ] = fieldWrapper;

        return returnMap;

    }

    get isValidNameOnCardField() {
        return (
            this.element.fieldApiName === DI_DONATION_DONOR_INFO.fieldApiName ||
            this.element.fieldApiName === CONTACT_FIRST_NAME_INFO.fieldApiName ||
            this.element.fieldApiName === CONTACT_LAST_NAME_INFO.fieldApiName ||
            this.element.fieldApiName === ACCOUNT_NAME_INFO.fieldApiName ||
            this.element.fieldApiName === DI_CONTACT1_IMPORTED_INFO.fieldApiName ||
            this.element.fieldApiName === DI_ACCOUNT1_IMPORTED_INFO.fieldApiName
        );
    }

    @api
    get fieldValueAndFieldApiName() {
        let fieldWrapper = { value: this.value, apiName: this.fieldApiName };
        let returnMap = {};
        returnMap[ this.fieldApiName ] = fieldWrapper;

        return returnMap;
    }

    @api
    setCustomValidity(errorMessage) {

        let inputField = this.template.querySelector('[data-id="inputComponent"]');
        inputField.setCustomValidity(errorMessage);
        inputField.reportValidity();

    }

    @api
    clearCustomValidity() {

        if (!this.isLookup) {
            this.setCustomValidity('');
        }

    }

    /**
     * Load a value into the form field.
     * @param data  An sObject potentially containing a value to load.
     * */
    @api
    load(data) {
        let value;
        if (data.hasOwnProperty(this.sourceFieldAPIName)) {
            value = data[this.sourceFieldAPIName];
            if (value === null || value.value === null) {
                this.reset();
            } else {
                this.value = value.value || value;

                if (this.isLookupRecordType || this.isLookup) {
                    if (value && !value.displayName) {
                        // If the RecordTypeId field for a target record is being
                        // loaded with only the Id (like when a Lookup field is
                        // selected/populated on the form), get the RecordType Name
                        // and pass it with the Id to loadLookup
                        data[this.sourceFieldAPIName] = {
                            value: value,
                            displayValue: this.getRecordTypeNameById(value)
                        };
                    }
                    this.loadLookUp(data, this.value);
                }
            }

            if (this.sourceFieldAPIName === DI_DONATION_AMOUNT.fieldApiName) {
                // fire event for reactive widget component containing the Data Import field API name and Value
                // currently only used for the Donation Amount.
                fireEvent(null, 'widgetData', {donationAmount: this.value});
            }

        } else if (!isUndefined(data.value)) {
            // When the geFormField cmp is used inside of geFormWidgetAllocation,
            // geFormWidgetAllocation selects the field cmp to load a value into manually,
            // and passes an {value: <value>} object.  To support that case this block
            // loads the value directly even though data does not have a property for
            // this.sourceFieldAPIName
           this.value = data.value;
        } else {
            // Property isn't defined.  Don't do anything.
            return false;
        }
    }

    /**
     * Loads a value into a look-up field
     * @param data An sObject potentially containing a value to load.
     * @param value A form field value
     */
    loadLookUp(data, value) {
        const lookup = this.template.querySelector('[data-id="inputComponent"]');
        lookup.reset();
        if(this.isLookup) {
            lookup.value = value;
        } else if(this.isLookupRecordType) {

            let displayValue;
            const relationshipFieldName = this.sourceFieldAPIName.replace('__c', '__r');

            if (data[relationshipFieldName] &&
                data[relationshipFieldName]['Name']) {
                displayValue = data[relationshipFieldName].Name;

            } else if (data[this.sourceFieldAPIName] &&
                data[this.sourceFieldAPIName]['displayValue']) {
                displayValue = data[this.sourceFieldAPIName].displayValue;

            } else if (data.displayValue) {
                displayValue = data.displayValue;

            }

            lookup.setSelected({value, displayValue});
        }
    }

    @api
    reset(setDefaults = true) {
        if (setDefaults) {
            this.value = this._defaultValue;
        } else {
            this.value = null;
        }

        // reset lookups and recordtype fields
        if (this.isLookupRecordType || this.isLookup) {
            const lookup = this.template.querySelector('[data-id="inputComponent"]');
            lookup.reset(setDefaults);
            if(this.isLookupRecordType) {
                // Using setTimeout here ensures that this recordTypeId
                // will be set on sibling fields after they are reset by queueing the event.
                setTimeout(() => {
                    this.fireLookupRecordSelectEvent();
                }, 0);
            }
        }

        if (this.isPicklist) {
            this.template.querySelector('c-ge-form-field-picklist').reset();
            this.handlePicklistChange();
        }
    }

    @api
    set recordTypeId(id) {
        this._recordTypeId = id;
        this.setRecordTypeIdOnChildComponents();
    }

    get recordTypeId() {
        return this._recordTypeId;
    }

    setRecordTypeIdOnChildComponents() {
        if (this.isPicklist) {
            this.template.querySelector('c-ge-form-field-picklist')
                .recordTypeId = this.recordTypeId;
        }
    }

    fireLookupRecordSelectEvent() {
        this.dispatchEvent(new CustomEvent(
            'lookuprecordselect',
            {
                detail: {
                    value: this.value,
                    displayValue: this.value,
                    fieldApiName: this.fieldApiName,
                    objectMappingDevName: this.objectMappingDevName
                }
            }
        ));
    }

    /**
     * @description Returns the name of the RecordType that corresponds to a RecordType Id.
     *              This method references this component's objectInfo.recordTypeInfos
     *              property.
     * @param Id The Id of the RecordType.
     * @returns {string|null} The name of the RecordType or null if the RecordType was
     *          not found.
     */
    getRecordTypeNameById(Id) {
        if (this.objectDescribeInfo &&
            this.objectDescribeInfo.recordTypeInfos &&
            this.objectDescribeInfo.recordTypeInfos[Id]) {
            return this.objectDescribeInfo.recordTypeInfos[Id].name;
        } else {
            return null;
        }
    }

    renderedCallback() {
        if (this.value && this.isLookup) {
            // If this field is a Lookup and has a value when connected,
            // fire event so that the form knows to populate related fields
            // and set recordTypeId on sibling fields.
            this.fireLookupRecordSelectEvent();
        }
    }

    get qaLocatorBase() {
        const rowIndex = this.getAttribute('data-qa-row');
        if(rowIndex) {
            return `${this.fieldLabel} ${rowIndex}`;
        } else {
            return this.fieldLabel;
        }
    }

    get qaLocatorInputPrefix() {
        switch (this.inputType) {
            case DATE:
            case DATETIME:
                return 'datetime';
            case CHECKBOX:
                return this.inputType;
            default:
                return 'input';
        }
    }

    get qaLocatorInput() {
        return `${this.qaLocatorInputPrefix} ${this.qaLocatorBase}`;
    }

    get qaLocatorLookup() {
        return `autocomplete ${this.qaLocatorBase}`;
    }

    get qaLocatorRichText() {
        return `richtext ${this.qaLocatorBase}`;
    }

    get qaLocatorTextArea() {
        return `textarea ${this.qaLocatorBase}`;
    }

}