import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { fireEvent } from 'c/pubsubNoPageRef';

import getAllFormTemplates from '@salesforce/apex/FORM_ServiceGiftEntry.getAllFormTemplates';

import GeLabelService from 'c/geLabelService';

import DATA_IMPORT_BATCH_INFO from '@salesforce/schema/DataImportBatch__c';
import DATA_IMPORT_BATCH_ID_INFO from '@salesforce/schema/DataImportBatch__c.Id';
import DATA_IMPORT_BATCH_FORM_TEMPLATE_INFO from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import FORM_TEMPLATE_ID_INFO from '@salesforce/schema/Form_Template__c.Id';
import FORM_TEMPLATE_NAME_INFO from '@salesforce/schema/Form_Template__c.Name';

const NAME = 'name';
const ID = 'id';
const MAX_STEPS = 2;
const SAVE = 'save';
const CANCEL = 'cancel';

export default class geBatchWizard extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api recordId;
    @api dedicatedListenerEventName;

    @track step = 0;
    @track templates;
    @track selectedTemplate;
    @track sections;
    @track isLoading = true;

    dataImportBatchFieldInfos;
    dataImportBatchInfo;
    dataImportBatchRecord;
    templatesById = {};
    templateOptions;
    isLoaded = false;

    headers = {
        0: this.CUSTOM_LABELS.geHeaderBatchSelectTemplate,
        1: this.CUSTOM_LABELS.geHeaderBatchEnterInfo,
        2: this.CUSTOM_LABELS.geHeaderBatchSetDefaultValues
    }

    steps = {
        first: 0,
        second: 1,
        third: 2
    }

    get showBackButton() {
        return this.step > 0 ? true : false;
    }

    get showSaveButton() {
        return this.step === 2 ? true : false;
    }

    get isNextButtonDisabled() {
        if (this.step === 0) {
            return !this.selectedTemplateId ? true : false;
        } else if (this.step === 1) {
            return false;
        }
    }

    get selectedBatchHeaderFields() {
        return this.selectedTemplate && this.selectedTemplate.batchHeaderFields ?
            this.selectedTemplate.batchHeaderFields :
            [];
    }

    get header() {
        return this.headers[this.step];
    }

    get cssClassStep0() {
        return this.header === this.headers[0] ? 'slds-size_1-of-1 step-0' : 'slds-hide';
    }

    get cssClassStep1() {
        return this.header === this.headers[1] ? 'slds-size_1-of-1' : 'slds-hide';
    }

    get cssClassStep2() {
        return this.header === this.headers[2] ? 'slds-size_1-of-1' : 'slds-hide';
    }

    get selectedTemplateId() {
        return this.selectedTemplate && this.selectedTemplate[ID] ? this.selectedTemplate[ID] : undefined;
    }

    get dataImportBatchName() {
        return DATA_IMPORT_BATCH_INFO && DATA_IMPORT_BATCH_INFO.objectApiName ? DATA_IMPORT_BATCH_INFO.objectApiName : undefined;
    }

    /*******************************************************************************
    * @description Retrieves the target object's describe data. Used to get the
    * picklist options for picklist fields. See component geFormFieldPicklist.
    *
    * @param {string} targetObjectApiName: Field's object api name.
    */
    @wire(getObjectInfo, { objectApiName: '$dataImportBatchName' })
    wiredDataImportBatchInfo(response) {
        if (response.data) {
            console.log('DataImportBatchInfo: ', response.data);
            this.dataImportBatchInfo = response.data;

            this.dataImportBatchFieldInfos =
                Object.keys(this.dataImportBatchInfo.fields).map((fieldApiName) => {
                    return {
                        fieldApiName: fieldApiName,
                        objectApiName: this.dataImportBatchInfo.apiName
                    }
                });
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$dataImportBatchFieldInfos' })
    wiredDataImportBatchRecord(response) {
        if (response.data) {
            console.log('DataImportBatchRecord: ', response.data);
            this.dataImportBatchRecord = response.data;
            let templateId = this.dataImportBatchRecord.fields.npsp__Form_Template__c.value;
            console.log('TEMPLATE ID: ', templateId);
            this.selectedTemplate = this.templatesById[templateId];
            console.log('this.selectedTemplate: ', this.selectedTemplate);
            //this.setValuesForSelectedBatchHeaderFields(response.data.fields);
        }
    }

    setValuesForSelectedBatchHeaderFields(allFields) {
        console.log('**********************--- setValuesForSelectedBatchHeaderFields');
        this.selectedBatchHeaderFields.map(batchHeaderField => {
            let queriedField = allFields[batchHeaderField.apiName];
            console.log('batchHeaderField: ', batchHeaderField);
            console.log('queriedField: ', queriedField);
            if (queriedField && queriedField.displayValue) {
                // TODO: May not be a good idea to set lightning-input values to displayValue
                // i.e. A currency displayValue looks like $0.00 which when provided as the
                // value for a lightning-input[type='number'] causes a NaN result
                //batchHeaderField.defaultValue = queriedField.displayValue;
                batchHeaderField.defaultValue = queriedField.value;
            } else if (queriedField && queriedField.value) {
                batchHeaderField.defaultValue = queriedField.value;
            }
        });
    }

    renderedCallback() {
        if (this.isLoaded === false) {
            this.init();
            this.isLoaded = true;
        }
    }

    init = async () => {
        this.templates = await getAllFormTemplates();

        this.templateOptions = this.templates.map(template => {
            this.templatesById[template[ID]] = template;
            return { label: template[NAME], value: template[ID] }
        });

        /*const batchHeaderFieldsInfo = [];
        Object.keys(this.dataImportBatchInfo.fields).map((fieldApiName) => {
            batchHeaderFieldsInfo.push({
                fieldApiName: fieldApiName,
                objectApiName: this.dataImportBatchInfo.apiName
            })
        });*/

        console.log('***************************--- init');
        console.log('recordId: ', this.recordId);
        console.log('DATA_IMPORT_BATCH_ID_INFO: ', DATA_IMPORT_BATCH_ID_INFO);
        console.log('dataImportBatchFieldInfos: ', this.dataImportBatchFieldInfos);
        console.log('this.selectedBatchHeaderFields: ', this.selectedBatchHeaderFields);

        this.isLoading = false;
    }

    handleNext() {
        if (this.step < MAX_STEPS) {
            this.step += 1;
        }
    }

    handleBack() {
        if (this.showBackButton || this.step > 0) {
            this.step -= 1;
        }
    }

    handleTemplateChange(event) {
        console.log('******************************--- handleTemplateChange');
        this.selectedTemplate = this.templatesById[event.detail.value];
        console.log('this.selectedTemplate: ', this.selectedTemplate);
        console.log('sections: ', this.selectedTemplate.layout.sections);
        if (this.recordId && this.dataImportBatchRecord && this.dataImportBatchRecord.fields) {
            this.setValuesForSelectedBatchHeaderFields(this.dataImportBatchRecord.fields);
        }
        this.sections = this.selectedTemplate.layout.sections;
        console.log('sections: ', this.sections);
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the save action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleSave() {
        const payload = { values: this.values, name: this.name };
        const detail = { action: SAVE, payload: payload };
        if (this.dedicatedListenerEventName) {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
        } else {
            this.dispatchEvent(new CustomEvent(SVGFEFuncAElement, { detail: payload }));
        }
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the cancel action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleCancel() {
        console.log('************--- handleCancel');
        if (this.dedicatedListenerEventName) {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, { action: CANCEL });
        } else {
            this.dispatchEvent(new CustomEvent(CANCEL, { detail: {} }));
        }
    }
}