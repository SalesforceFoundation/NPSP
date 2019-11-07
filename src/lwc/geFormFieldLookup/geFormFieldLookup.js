import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import doSearch from '@salesforce/apex/GE_LookupController.doSearch';

const DELAY = 300;

export default class GeFormFieldLookup extends LightningElement {
    @api fieldApiName;
    @api objectApiName;
    @api displayValue;

    @track options = [];
    @track objectInfo;
    @track targetObjectInfo;
    @track targetObjectApiName;


    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo(response) {
        if(response.data) {
            this.objectInfo = response;
            this.targetObjectApiName = this.fieldInfo.referenceToInfos[0].apiName;
        }
    }

    @wire(getObjectInfo, { objectApiName: '$targetObjectApiName' })
    wiredTargetObjectInfo(response) {
        this.targetObjectInfo = response;
    }

    handleChange(event) {
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.detail.value;
        if (searchKey && searchKey.length > 1) {
            this.delayTimeout = setTimeout(() => this.retrieveLookupOptions(searchKey, this.targetObjectApiName), DELAY);
        }
    }

    handleSelect(event) {
        this.displayValue = event.detail.displayValue;
        this.value = event.detail.value;
    }

    get fieldInfo() {
        if(this.objectInfo.data) {
            return this.objectInfo.data.fields[this.fieldApiName];
        }
    }

    get targetObjectIconName() {
        if(this.targetObjectInfo.data) {
            const { iconUrl } = this.targetObjectInfo.data.themeInfo;
            const re = /\/(standard|custom)\/([a-zA-Z]+)/;
            const result = re.exec(iconUrl);
            return 'standard:' + result[2];
        }
    }

    retrieveLookupOptions = async (searchValue, sObjectType) => {
        this.options = await doSearch({searchValue, sObjectType});
    };

    get infoJSON() {
        return JSON.stringify(this.objectInfo, null, 2);
    }

}