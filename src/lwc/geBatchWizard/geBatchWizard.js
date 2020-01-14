import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    createRecord,
    getRecord,
    getRecordCreateDefaults,
    generateRecordInputForCreate
} from 'lightning/uiRecordApi';
import { fireEvent } from 'c/pubsubNoPageRef';
import { handleError } from 'c/utilTemplateBuilder';
import { checkNestedProperty, getNestedProperty } from 'c/utilCommon';
import GeLabelService from 'c/geLabelService';

import getAllFormTemplates from '@salesforce/apex/FORM_ServiceGiftEntry.getAllFormTemplates';

import DATA_IMPORT_BATCH_INFO from '@salesforce/schema/DataImportBatch__c';
import DATA_IMPORT_BATCH_ID_INFO from '@salesforce/schema/DataImportBatch__c.Id';
import DATA_IMPORT_BATCH_FORM_TEMPLATE_INFO from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import DATA_IMPORT_BATCH_VERSION_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Gift_Entry_Version__c';
import DATA_IMPORT_BATH_GIFT_INFO from '@salesforce/schema/DataImportBatch__c.GiftBatch__c';
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
    @track selectedTemplateId;
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
        if (this.step === 1 && this.isEditMode) {
            return false;
        }
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
        return false;
    }

    get selectedBatchHeaderFields() {
        return checkNestedProperty(this.selectedTemplate, 'batchHeaderFields') ?
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

    get selectedTemplate() {
        if (this.selectedTemplateId && this.templatesById) {
            return this.templatesById[this.selectedTemplateId];
        }
        return undefined;
    }

    get formSections() {
        return getNestedProperty(this.selectedTemplate, 'layout', 'sections');
    }

    get isEditMode() {
        return this.recordId ? true : false;
    }

    get dataImportBatchName() {
        return getNestedProperty(DATA_IMPORT_BATCH_INFO, 'objectApiName');
    }

    /*******************************************************************************
    * @description Retrieves the DataImportBatch__c describe info.
    *
    * @param {string} dataImportBatchName: DataImportBatch__c object api name.
    */
    @wire(getObjectInfo, { objectApiName: '$dataImportBatchName' })
    wiredDataImportBatchInfo(response) {
        if (response.data) {
            console.log('DataImportBatchInfo: ', response.data);
            this.dataImportBatchInfo = response.data;

            this.dataImportBatchFieldInfos =
                this.buildFieldDescribesForWiredMethod(
                    this.dataImportBatchInfo.fields,
                    this.dataImportBatchInfo.apiName);
        }
    }

    /*******************************************************************************
    * @description Method converts field describe info into objects that the
    * getRecord method can accept into its 'fields' parameter.
    *
    * @param {list} fields: List of field describe info.
    * @param {string} objectApiName: An SObject api name.
    */
    buildFieldDescribesForWiredMethod(fields, objectApiName) {
        return Object.keys(fields).map((fieldApiName) => {
            return {
                fieldApiName: fieldApiName,
                objectApiName: objectApiName
            }
        });
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$dataImportBatchFieldInfos' })
    wiredDataImportBatchRecord(response) {
        if (response.data) {
            getAllFormTemplates()
                .then(templates => {
                    this.templates = templates;
                    this.builderTemplateComboboxOptions(this.templates);

                    this.dataImportBatchRecord = response.data;
                    let templateId = this
                        .dataImportBatchRecord
                        .fields[DATA_IMPORT_BATCH_FORM_TEMPLATE_INFO.fieldApiName]
                        .value;

                    this.handleTemplateChange({ detail: { value: templateId } });
                    this.step = 1;

                    this.isLoading = false;
                })
                .catch(error => {
                    handleError(error);
                });
        }
    }

    @wire(getRecordCreateDefaults, { objectApiName: '$dataImportBatchName' })
    dataImportBatchCreateDefaults;

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

    async connectedCallback() {
        console.log('>>>>>>>>>>>>>>>>>>>>>>>>>connectedCallback');
        console.log('>>>>>>>>>>>>>>>>>>>>>>>>>');
        console.log('>>>>>>>>>>>>>>>>>>>>>>>>>');
        if (!this.recordId) {
            this.templates = await getAllFormTemplates();
            this.templates = this.templates.sort();
            this.builderTemplateComboboxOptions(this.templates);
            this.isLoading = false;
        }
    }

    builderTemplateComboboxOptions(templates) {
        console.log('***************************--- builderTemplateComboboxOptions');
        if (templates && templates.length > 0) {
            this.templateOptions = this.templates.map(template => {
                this.templatesById[template[ID]] = template;
                return { label: template[NAME], value: template[ID] }
            });
        }
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
        this.selectedTemplateId = event.detail.value;

        if (this.recordId && this.dataImportBatchRecord && this.dataImportBatchRecord.fields) {
            this.setValuesForSelectedBatchHeaderFields(this.dataImportBatchRecord.fields);
        }
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the save action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleSave() {
        console.log('************--- handleSave');

        const dataImportBatchObjectInfo = this.dataImportBatchCreateDefaults.data.objectInfos[
            this.dataImportBatchName
        ];
        console.log('this.dataImportBatchCreateDefaults: ', this.dataImportBatchCreateDefaults);
        console.log('dataImportBatchObjectInfo: ', dataImportBatchObjectInfo);
        const recordDefaults = this.dataImportBatchCreateDefaults.data.record;
        console.log('recordDefaults: ', recordDefaults);
        let recordObject = generateRecordInputForCreate(recordDefaults, dataImportBatchObjectInfo);
        console.log('recordObject: ', recordObject);
        recordObject = this.setFieldValues(recordObject);
        this.handleRecordCreate(recordObject);
        /*const payload = { values: this.values, name: this.name };
        const detail = { action: SAVE, payload: payload };
        if (this.dedicatedListenerEventName) {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
        } else {
            this.dispatchEvent(new CustomEvent(SVGFEFuncAElement, { detail: payload }));
        }*/
    }

    setFieldValues(recordObject) {
        console.log('************--- collectFieldValues');
        console.log('recordObject: ', recordObject);
        console.log('Template Id: ', this.selectedTemplateId);
        let utilInputs = this.template.querySelectorAll('c-util-input');
        for (let i = 0; i < utilInputs.length; i++) {
            let formElement = utilInputs[i].reportValue();
            console.log(formElement.fieldApiName, formElement.value, formElement.objectApiName);
            if (recordObject.apiName === formElement.objectApiName) {
                recordObject.fields[formElement.fieldApiName] = formElement.value;
            }
        }

        console.log('setting gift entry fields...');
        recordObject.fields[DATA_IMPORT_BATCH_FORM_TEMPLATE_INFO.fieldApiName] = this.selectedTemplateId;
        recordObject.fields[DATA_IMPORT_BATCH_VERSION_INFO.fieldApiName] = 2.0;
        recordObject.fields[DATA_IMPORT_BATH_GIFT_INFO.fieldApiName] = true;

        console.log('recordObject: ', recordObject);
        return recordObject;
    }

    handleRecordCreate(recordObject) {
        console.log('************--- handleRecordCreate');
        createRecord(recordObject)
            .then(record => {
                console.log('Created Record: ', record);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record created',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
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