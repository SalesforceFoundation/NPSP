import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import doSearch from '@salesforce/apex/GE_LookupController.doSearch';
import { isNotEmpty } from 'c/utilCommon';
import { handleError } from 'c/utilTemplateBuilder';

const DELAY = 300;

export default class GeFormFieldLookup extends LightningElement {
    @api fieldApiName;
    @api objectApiName;
    @api displayValue = '';
    @api defaultValue = null;
    _defaultDisplayValue = '';
    @api label;
    @api required;
    @api id; // unique identifier for this field, used mainly for accessibility
    @api variant;
    @api disabled;
    @api qaLocatorBase;


    @track options = [];
    @track value;
    @track targetObjectApiName;
    @track queryFields;
    @track valid = true;
    @track _getRecordId = null;

    connectedCallback() {
        if (this.defaultValue === undefined) {
            this.defaultValue = null;
        }
        this.value = this.defaultValue;
        if (this.value) {
            this._getRecordId = this.value;
        }
        this.dispatchChangeEvent({
            value: this.value,
            displayValue: this.displayValue,
            fieldApiName: this.fieldApiName
        });
    }

    /**
     * Retrieve information about the object the lookup points to.
     */
    @wire(getObjectInfo, { objectApiName: '$targetObjectApiName' })
    wiredTargetObjectInfo(response) {
        if(response.data) {
            this.targetObjectInfo = response;
            this.queryFields = this.getQueryFields();
        }
    }

    @wire(getRecord, {recordId: '$_getRecordId', fields: '$queryFields'})
    wiredGetRecord({error, data}) {
        if (data) {
            this.displayValue = data.fields.Name.value;
            if (data.fields.Id.value === this.defaultValue) {
                this._defaultDisplayValue = this.displayValue;
            }
            let autocomplete = this.template.querySelector('c-ge-autocomplete');
            autocomplete.setValue({value: this.value, displayValue: this.displayValue});
        } else if (error) {
            handleError(error);
        }
    }

    /**
     * Check validity, then update the field with a message if field is invalid.
     */
    @api
    reportValidity() {
        this.valid = this.checkValidity();
        if (!this.valid) {
            this.setCustomValidity();
        }
    }

    /**
     * Check validity without updating the UI
     * @returns {boolean}
     */
    @api
    checkValidity() {
        if(this.required) {
            return isNotEmpty(this.value);
        }
        return true;
    }

    /**
     * Set custom validity - custom since geAutocomplete does not use lightning-input
     * @param errorMessage, custom message for custom validity
     */
    @api
    setCustomValidity(errorMessage) {
        let autocomplete = this.template.querySelector('c-ge-autocomplete');
        autocomplete.setCustomError(errorMessage);
    }

    @api
    clearCustomValidity() {
        let autocomplete = this.template.querySelector('c-ge-autocomplete');
        autocomplete.clearCustomError();
    }

    /**
     * Handle text input change, and retrieve lookup options.
     * @param event
     */
    handleChange(event) {
        window.clearTimeout(this.delayTimeout);
        this.displayValue = event.detail;
        if (this.displayValue && this.displayValue.length > 1) {
            this.delayTimeout = setTimeout(() => this.retrieveLookupOptions(this.displayValue, this.targetObjectApiName), DELAY);
        }
    }

    /**
     * Handle user selecting an option from the dropdown list.
     * @param event
     */
    handleSelect(event) {
        this.displayValue = event.detail.displayValue;
        this.value = event.detail.value;
        this.dispatchChangeEvent({
            value: this.value,
            displayValue: this.displayValue,
            fieldApiName: this.fieldApiName
        });
        this.options = [];
    }

    /**
     * When field loses focus, clear any available options so dropdown closes.
     */
    handleFocusOut() {
        this.options = [];
    }

    /**
     * When field gains focus, re-run search if no option is currently selected.
     */
    handleFocusIn() {
        if(!this.value && this.displayValue && this.displayValue.length > 1) {
            this.retrieveLookupOptions(this.displayValue, this.targetObjectApiName);
        }
    }

    @api
    set objectDescribeInfo(newVal) {
        this._objectDescribeInfo = newVal;
        if(typeof newVal !== 'undefined') {
            // needed for @wire reactive property
            this.targetObjectApiName = this.fieldInfo.referenceToInfos[0].apiName;
        }
    }

    getQueryFields() {
        const fields = ['Id', 'Name'];
        return fields.map(f => `${this.targetObjectApiName}.${f}`);
    }

    get objectDescribeInfo() {
        return this._objectDescribeInfo;
    }

    get fieldInfo() {
        if(this.objectDescribeInfo && this.objectDescribeInfo) {
            return this.objectDescribeInfo.fields[this.fieldApiName];
        }
    }

    /**
     * Gets the SObject icon for the object that we're looking up to.
     * @returns {string}
     */
    get targetObjectIconName() {
        if(this.targetObjectInfo && this.targetObjectInfo.data) {
            if(this.targetObjectInfo.data.themeInfo) {
                const {iconUrl} = this.targetObjectInfo.data.themeInfo;
                const re = /\/(standard|custom)\/([a-zA-Z0-9]+)/;
                const result = re.exec(iconUrl);

                // explicitly handle only standard and custom icon sets
                if(result !== null) {
                    if (result[1] === 'standard') {
                        return 'standard:' + result[2];
                    } else if (result[1] === 'custom') {
                        return 'custom:' + result[2];
                    }
                }
            }
        }
    }

    /**
     * Async function for retrieving lookup options.
     * @param searchValue String to search for.
     * @param sObjectType Object type to search e.g. Account
     * @returns {Promise<void>}
     */
    retrieveLookupOptions = async (searchValue, sObjectType) => {
        this.options = await doSearch({searchValue, sObjectType});
    };

    @api
    setSelected(lookupResult) {
        if (lookupResult.value === null) {
            this.reset();
        } else {
            this.value = lookupResult.value || null;
            this.displayValue = lookupResult.displayValue || null;

            const autocomplete = this.template.querySelector('c-ge-autocomplete');
            autocomplete.setValue({value: this.value, displayValue: this.displayValue});
        }

        if (this.value && !this.displayValue) {
            // Use getRecord to get the displayValue
            this._getRecordId = this.value;
            this.queryFields = this.getQueryFields().splice(0);
        }
    }

    @api
    reset() {
        this.value = this.defaultValue;
        this.displayValue = this._defaultDisplayValue;

        let autocomplete = this.template.querySelector('c-ge-autocomplete');
        autocomplete.setValue({value: this.value, displayValue: this.displayValue});
    }

    dispatchChangeEvent(data) {
        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                value: data.value,
                displayValue: data.displayValue,
                fieldApiName: data.fieldApiName
            }
        }));
    }

}