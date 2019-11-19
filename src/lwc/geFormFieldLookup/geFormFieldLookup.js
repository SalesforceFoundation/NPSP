import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import doSearch from '@salesforce/apex/GE_LookupController.doSearch';

const DELAY = 300;

export default class GeFormFieldLookup extends LightningElement {
    @api fieldApiName;
    @api objectApiName;
    @api displayValue = '';
    @api label;
    @api required;
    @api id; // unique identifier for this field, used mainly for accessibility

    @track options = [];
    @track objectInfo;
    @track targetObjectInfo;
    @track targetObjectApiName;
    @track value;


    /**
     * Retrieve information about the object the lookup field is defined on.
     * @param response
     */
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo(response) {
        if(response.data) {
            this.objectInfo = response;
            this.targetObjectApiName = this.fieldInfo.referenceToInfos[0].apiName;
        }
    }

    /**
     * Retrieve information about the object the lookup points to.
     * @param response
     */
    @wire(getObjectInfo, { objectApiName: '$targetObjectApiName' })
    wiredTargetObjectInfo(response) {
        this.targetObjectInfo = response;
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
        this.dispatchEvent(new CustomEvent('change', { detail: event.detail }));
    }

    get fieldInfo() {
        if(this.objectInfo && this.objectInfo.data) {
            return this.objectInfo.data.fields[this.fieldApiName];
        }
    }

    get fieldLabel() {
        return this.fieldInfo ? this.fieldInfo.label : null;
    }

    /**
     * Gets the SObject icon for the object that we're looking up to.
     * @returns {string}
     */
    get targetObjectIconName() {
        // TODO: add support for custom objects
        if(this.targetObjectInfo && this.targetObjectInfo.data) {
            if(this.targetObjectInfo.data.themeInfo) {
                const {iconUrl} = this.targetObjectInfo.data.themeInfo;
                const re = /\/(standard|custom)\/([a-zA-Z]+)/;
                const result = re.exec(iconUrl);
                if(result[1] === 'standard') {
                    return 'standard:' + result[2];
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

}