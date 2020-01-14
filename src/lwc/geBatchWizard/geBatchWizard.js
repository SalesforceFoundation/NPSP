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
import DATA_IMPORT_BATCH_FORM_TEMPLATE_INFO from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import DATA_IMPORT_BATCH_VERSION_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Gift_Entry_Version__c';
import DATA_IMPORT_BATCH_GIFT_INFO from '@salesforce/schema/DataImportBatch__c.GiftBatch__c';
import DATA_IMPORT_BATCH_DEFAULTS_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Defaults__c';

const NAME = 'name';
const ID = 'id';
const MAX_STEPS = 2;
const CANCEL = 'cancel';

export default class geBatchWizard extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api recordId;
    @api dedicatedListenerEventName;

    @track step = 0;
    @track templates;
    @track formSections = [];
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

    /*get formSections() {
        return getNestedProperty(this.selectedTemplate, 'layout', 'sections');
    }*/

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
                    this.setFormFieldsBatchLevelDefaults();

                    this.step = 1;

                    this.isLoading = false;
                })
                .catch(error => {
                    handleError(error);
                });
        }
    }

    setFormFieldsBatchLevelDefaults() {
        let batchLevelDefaults =
            JSON.parse(this.dataImportBatchRecord.fields[DATA_IMPORT_BATCH_DEFAULTS_INFO.fieldApiName].value);

        this.formSections.forEach(section => {
            if (section.elements) {
                section.elements.forEach(element => {
                    if (batchLevelDefaults[element.fieldApiName]) {
                        element.value = batchLevelDefaults[element.fieldApiName].value;
                    }
                });
            }
        });
    }

    @wire(getRecordCreateDefaults, { objectApiName: '$dataImportBatchName' })
    dataImportBatchCreateDefaults;

    setValuesForSelectedBatchHeaderFields(allFields) {
        console.log('**********************--- setValuesForSelectedBatchHeaderFields');
        this.selectedBatchHeaderFields.map(batchHeaderField => {
            let queriedField = allFields[batchHeaderField.apiName];
            if (queriedField) {
                batchHeaderField.value = queriedField.value;
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
        this.formSections = this.selectedTemplate.layout.sections;

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
        const recordDefaults = this.dataImportBatchCreateDefaults.data.record;
        let recordObject = generateRecordInputForCreate(recordDefaults, dataImportBatchObjectInfo);
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

    setFieldValues(dataImportBatch) {
        console.log('************--- collectFieldValues');

        let utilInputs = this.template.querySelectorAll('c-util-input');
        let batchDefaults = {};
        for (let i = 0; i < utilInputs.length; i++) {
            let formElement = utilInputs[i].reportValue();

            if (dataImportBatch.apiName === formElement.objectApiName) {
                dataImportBatch.fields[formElement.fieldApiName] = formElement.value;
            } else {
                batchDefaults[formElement.fieldApiName] = {
                    objectApiName: formElement.objectApiName,
                    fieldApiName: formElement.fieldApiName,
                    value: formElement.value
                };
            }
        }

        dataImportBatch.fields[DATA_IMPORT_BATCH_DEFAULTS_INFO.fieldApiName] =
            JSON.stringify(batchDefaults);
        dataImportBatch.fields[DATA_IMPORT_BATCH_FORM_TEMPLATE_INFO.fieldApiName] = this.selectedTemplateId;
        dataImportBatch.fields[DATA_IMPORT_BATCH_VERSION_INFO.fieldApiName] = 2.0;
        dataImportBatch.fields[DATA_IMPORT_BATCH_GIFT_INFO.fieldApiName] = true;

        console.log('dataImportBatch: ', dataImportBatch);
        return dataImportBatch;
    }

    handleRecordCreate(recordObject) {
        console.log('************--- handleRecordCreate');
        createRecord(recordObject)
            .then(record => {
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