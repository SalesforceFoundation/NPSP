import {api, LightningElement, track, wire} from 'lwc';
import {debouncify, isNotEmpty, relatedRecordFieldNameFor} from 'c/utilCommon';
import GeFormService from 'c/geFormService';
import GeLabelService from 'c/geLabelService';
import {getObjectInfo, getPicklistValues} from 'lightning/uiObjectInfoApi';
import DONATION_RECORD_TYPE_NAME
    from '@salesforce/schema/DataImport__c.Donation_Record_Type_Name__c';
import ACCOUNT1_IMPORTED
    from '@salesforce/schema/DataImport__c.Account1Imported__c';
import CONTACT1_IMPORTED
    from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import PRIMARY_CONTACT from '@salesforce/schema/Opportunity.Primary_Contact__c';
import DATA_IMPORT from '@salesforce/schema/DataImport__c';
import RECORD_TYPE_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';
import OPPORTUNITY from '@salesforce/schema/Opportunity';

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
    @track _formState;
    @track objectDescribeInfo;
    @track _disabled = false;
    @api element;
    @api targetFieldName;
    _recordTypeId;
    _picklistValues;
    _isRichTextValid = true;

    richTextFormats = RICH_TEXT_FORMATS;
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    get value() {
        return this.valueFromFormState;
    }

    PICKLIST_OPTION_NONE = Object.freeze({
        attributes: null,
        label: this.CUSTOM_LABELS.commonLabelNone,
        validFor: [],
        value: this.CUSTOM_LABELS.commonLabelNone
    });

    handleValueChangeSync = (event) => {
        this.fireFormFieldChangeEvent(
            this.getValueFromChangeEvent(event));
    };
    handleValueChange = debouncify(this.handleValueChangeSync.bind(this), DELAY);

    /**
     * Retrieve object metadata. Used to configure how fields are displayed on the form.
     */
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo(response) {
        if (response.data) {
            this.objectDescribeInfo = response.data;
            this._recordTypeId = this.recordTypeId();
        }
    }

    getValueFromChangeEvent(event) {
        if (this.isPicklist) {
            const value = event.detail.value;
            const isSelectedValueNone =
                value === this.CUSTOM_LABELS.commonLabelNone;
            if (isSelectedValueNone) {
                return null;
            }
        }

        if (this.isCheckbox) {
            return event.detail.checked.toString();
        }

        if (this.isRichText) {
            return event.target.value;
        }

        if (this.isLookup) {
            const val = event.detail.value;
            if (typeof val === 'string') {
                return val;
            } else if (Array.isArray(val)) {
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

        if (this.element !== null && this.element.required) {
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
        if (typeof inputField !== 'undefined'
            && inputField !== null
            && typeof inputField.reportValidity === 'function'
            && typeof inputField.checkValidity === 'function') {
                inputField.reportValidity();
                return inputField.checkValidity();
        } else if (this.isRichText) {
            this.checkRichTextValidity();
            if (!this._isRichTextValid) {
                // workaround, field will not display as invalid if it is untouched
                inputField.focus();
                inputField.blur();
            }
            return this._isRichTextValid;
        }
        return true;
    }

    checkRichTextValidity() {
        if (this.element.required) {
            const isValid = isNotEmpty(this.value) && this.value.length > 0;
            this._isRichTextValid = isValid;
            return isValid;
        }
        return true;
    }

    get isRichTextValid () {
        return this._isRichTextValid;
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
        return (this.fieldMapping && this.fieldMapping.Is_Required && this.fieldType !== BOOLEAN_TYPE) ||
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

    get fieldMapping() {
        return isNotEmpty(this.targetFieldName) ?
            GeFormService.getFieldMappingWrapperFromTarget(this.targetFieldName) :
            GeFormService.getFieldMappingWrapper(this.formElementName);
    }

    get targetFieldDescribeInfo() {
        if (this.objectDescribeInfo && this.objectDescribeInfo.fields) {
            return this.objectDescribeInfo.fields[this.targetFieldApiName];
        }
    }

    get objectMapping() {
        return GeFormService.getObjectMapping(this.targetObjectMappingDevName);
    }

    get fieldType() {
        if (isNotEmpty(this.fieldMapping)) {
            return this.fieldMapping.Target_Field_Data_Type;
        }
    }

    get isLightningInput() {
        return typeof GeFormService.getInputTypeFromDataType(this.fieldType) !== 'undefined';
    }

    get isRichText() {
        if (typeof this.targetFieldDescribeInfo !== 'undefined' && this.fieldType === TEXT_AREA_TYPE) {
            return this.targetFieldDescribeInfo.htmlFormatted;
        }
    }

    /**
     * Special handling for RecordTypeId because we render these fields as picklists instead of lookups.
     */
    get isRecordTypePicklist() {
        return this.fieldType === LOOKUP_TYPE && this.targetFieldApiName === RECORD_TYPE_FIELD.fieldApiName;
    }

    @api
    get isLookup() {
        return this.fieldType === LOOKUP_TYPE && this.targetFieldApiName !== RECORD_TYPE_FIELD.fieldApiName;
    }

    @api
    get isPicklist() {
        return this.fieldType === PICKLIST_TYPE || this.isRecordTypePicklist;
    }

    get isCheckbox() {
        return this.fieldType === BOOLEAN_TYPE;
    }

    get isTextArea() {
        if (typeof this.targetFieldDescribeInfo !== 'undefined' && this.fieldType === TEXT_AREA_TYPE) {
            return !this.targetFieldDescribeInfo.htmlFormatted;
        }
    }

    @api
    get targetObjectMappingDevName() {
        if (isNotEmpty(this.fieldMapping)) {
            return this.fieldMapping.Target_Object_Mapping_Dev_Name;
        }
    }

    get objectApiName() {
        if (typeof this.objectMapping !== 'undefined') {
            return this.objectMapping.Object_API_Name;
        }
    }

    @api
    get targetFieldApiName() {
        if (isNotEmpty(this.fieldMapping)) {
            return this.fieldMapping.Target_Field_API_Name;
        }
    }

    @api
    get sourceFieldAPIName() {
        if (isNotEmpty(this.fieldMapping)) {
            return this.fieldMapping.Source_Field_API_Name;
        }
    }

    // when using lightning-lookup-field, instead of binding to the Data Import fields or donor information
    // we bind to Opportunity.AccountId / Opportunity.Primary_Contact__c
    get lookupFieldApiName() {
        if (this.objectApiName === DATA_IMPORT.objectApiName) {
            if (this.targetFieldApiName === ACCOUNT1_IMPORTED.fieldApiName) {
                return ACCOUNT_ID.fieldApiName;
            } else if (this.targetFieldApiName === CONTACT1_IMPORTED.fieldApiName) {
                return PRIMARY_CONTACT.fieldApiName;
            }
        }
        return this.targetFieldApiName;
    }

    get lookupObjectApiName() {
        if (this.objectApiName === DATA_IMPORT.objectApiName) {
            if (this.targetFieldApiName === ACCOUNT1_IMPORTED.fieldApiName
                || this.targetFieldApiName === CONTACT1_IMPORTED.fieldApiName) {
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

    @api
    get fieldValueAndFieldApiName() {
        let fieldWrapper = { value: this.value, apiName: this.targetFieldApiName };
        let returnMap = {};
        returnMap[ this.targetFieldApiName ] = fieldWrapper;

        return returnMap;
    }

    @api
    setCustomValidity(errorMessage) {
        const inputField = this.template.querySelector('[data-id="inputComponent"]');

        const canSetCustomValidity =
            inputField &&
            typeof inputField.reportValidity === 'function' &&
            typeof inputField.checkValidity === 'function';
        if (canSetCustomValidity) {
            inputField.setCustomValidity(errorMessage);
            inputField.reportValidity();
        }
    }

    @api
    clearCustomValidity() {

        if (!this.isLookup) {
            this.setCustomValidity('');
        }

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

    get qaLocatorBase() {
        const rowIndex = this.getAttribute('data-qa-row');
        if (rowIndex) {
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

    @api
    get formState() {
        return this._formState;
    }

    set formState(formState) {
        this._formState = formState;
        this._recordTypeId = this.recordTypeId();
    }

    get valueFromFormState() {
        const value = this.formState[this.sourceFieldAPIName];

        if (value === undefined) {
           return null;
        }

        const isDonationRecordTypeName =
            this.sourceFieldAPIName === DONATION_RECORD_TYPE_NAME.fieldApiName;
        if (isDonationRecordTypeName) {
            return this.recordTypeIdFor(value);
        }

        if (this.isPicklist && value === null) {
            const hasNoneOptionAvailable =
                this.isValueInOptions(
                    this.CUSTOM_LABELS.commonLabelNone,
                    this.picklistValues
                );
            return hasNoneOptionAvailable ? this.CUSTOM_LABELS.commonLabelNone : '';
        }

        return value;
    }

    fireFormFieldChangeEvent(value) {
        const formFieldChangeEvent = new CustomEvent('formfieldchange', {
            detail:
                {
                    value: value,
                    label: this.isRecordTypePicklist ? this.recordTypeNameFor(value) : value,
                    fieldMappingDevName: this.fieldMappingDevName()
                }
        });
        this.dispatchEvent(formFieldChangeEvent);
    }

    recordTypeNameFor(recordTypeId) {
        return this.objectDescribeInfo &&
            Object.values(this.objectDescribeInfo.recordTypeInfos)
                .find(rtInfo => rtInfo.recordTypeId === recordTypeId)
                .name;
    }

    fieldMappingDevName() {
        return this.element.dataImportFieldMappingDevNames[0];
    }

    recordTypeId() {
        const siblingRecordTypeId =
            this.siblingRecordTypeField() === DONATION_RECORD_TYPE_NAME.fieldApiName ?
                this.recordTypeIdFor(this.siblingRecordTypeValue()) :
                this.siblingRecordTypeValue();

        return siblingRecordTypeId ||
            this.parentRecordRecordTypeId() ||
            this.defaultRecordTypeId() ||
            null;
    }

    defaultRecordTypeId() {
        return this.objectDescribeInfo && this.objectDescribeInfo.defaultRecordTypeId;
    }

    recordTypeIdFor(recordTypeName) {
        if (recordTypeName === null) {
            return null;
        }
        
        const rtInfo = this.objectDescribeInfo &&
            Object.values(this.objectDescribeInfo.recordTypeInfos)
                .find(rtInfo => rtInfo.name === recordTypeName);

        return rtInfo && rtInfo.recordTypeId;
    }

    siblingRecordTypeValue() {
        return this.formState && this.formState[this.siblingRecordTypeField()];
    }

    siblingRecordTypeField() {
        return this.element && this.element.siblingRecordTypeField;
    }

    parentRecordRecordTypeId() {
        return this.parentRecord() &&
            this.parentRecord().recordTypeId;
    }

    parentRecord() {
        return this.formState && this.formState[relatedRecordFieldNameFor(this.parentRecordField())];
    }

    parentRecordField() {
        return this.element &&
            this.element.parentRecordField;
    }

    // ================================================================================
    // Logic formerly in geFormFieldPicklist
    // ================================================================================
    get picklistValues() {
        if (this.targetFieldApiName === 'RecordTypeId') {
            return this.getPicklistOptionsForRecordTypeIds();
        }
        return this._picklistValues;
    }

    set picklistValues(values) {
        this._picklistValues = values;
    }

    get qaLocatorPicklist() {
        return `combobox ${this.qaLocatorBase}`;
    }

    /**
     * Accessor method returns the full object and field api name.
     *
     * Returns null if the current field is a RecordTypeId so that we
     * don't invoke the wired `wiredPicklistValues` function. Instead
     * we retrieve record types objects from `_objectDescribeInfo`
     * and build the picklist options array from there.
     */
    get fullFieldApiNameForStandardPicklists() {
        if (this.isRecordTypeIdLookup || !this.isPicklist) return undefined;
        return `${this.objectApiName}.${this.targetFieldApiName}`;
    }

    get isRecordTypeIdLookup() {
        return this.targetFieldApiName === 'RecordTypeId';
    }

    get accessibleRecordTypes() {
        if (!this.objectDescribeInfo) return [];
        const allRecordTypes = Object.values(this.objectDescribeInfo.recordTypeInfos);
        return allRecordTypes.filter(recordType => recordType.available && !recordType.master);
    }

    @wire(getPicklistValues, {
        fieldApiName: '$fullFieldApiNameForStandardPicklists',
        recordTypeId: '$_recordTypeId'
    })
    wiredPicklistValues({error, data}) {
        if (data) {
            this.picklistValues = [this.PICKLIST_OPTION_NONE, ...data.values];
        }
        if (error) {
            console.error(error);
        }
    }

    isValueInOptions(value, options) {
        if (!options || options.length === 0) return false;
        return options.some(option => {
            return option.value === value;
        });
    }

    getPicklistOptionsForRecordTypeIds() {
        if (!this.accessibleRecordTypes ||
            this.accessibleRecordTypes.length <= 0) {
            return [this.PICKLIST_OPTION_NONE];
        }

        return this.accessibleRecordTypes.map(recordType => {
            return this.createPicklistOption(recordType.name,
                recordType.recordTypeId);
        });
    }

    createPicklistOption = (label, value, attributes = null, validFor = []) => ({
        attributes: attributes,
        label: label,
        validFor: validFor,
        value: value
    });

}
