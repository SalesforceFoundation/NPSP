/* eslint-disable array-callback-return */
import { LightningElement, api, track, wire } from 'lwc';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {
    createRecord,
    updateRecord,
    getRecord,
    getRecordCreateDefaults,
    generateRecordInputForCreate, generateRecordInputForUpdate
} from 'lightning/uiRecordApi';
import { fireEvent } from 'c/pubsubNoPageRef';
import {
    handleError,
    addKeyToCollectionItems,
    isTrueFalsePicklist,
    trueFalsePicklistOptions
} from 'c/utilTemplateBuilder';
import {
    getNamespace,
    getNestedProperty,
    isNotEmpty,
    isNull,
    stripNamespace,
} from 'c/utilCommon';
import GeLabelService from 'c/geLabelService';
import psPaymentGateway from '@salesforce/label/c.psPaymentGateway';

import getAllFormTemplates from '@salesforce/apex/GE_GiftEntryController.getAllFormTemplates';
import getDonationMatchingValues from '@salesforce/apex/GE_GiftEntryController.getDonationMatchingValues';
import getGatewayAssignmentSettingsWithDefaultGatewayName from '@salesforce/apex/GE_GiftEntryController.getGatewayAssignmentSettingsWithDefaultGatewayName';

import DATA_IMPORT_BATCH_INFO from '@salesforce/schema/DataImportBatch__c';
import DATA_IMPORT_BATCH_ID_INFO from '@salesforce/schema/DataImportBatch__c.Id';
import DATA_IMPORT_BATCH_FORM_TEMPLATE_INFO from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import DATA_IMPORT_BATCH_VERSION_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Gift_Entry_Version__c';
import DATA_IMPORT_BATCH_GIFT_INFO from '@salesforce/schema/DataImportBatch__c.GiftBatch__c';
import DATA_IMPORT_BATCH_DEFAULTS_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Defaults__c';
import DATA_IMPORT_MATCHING_BEHAVIOR_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Matching_Behavior__c';
import DATA_IMPORT_BATCH_TABLE_COLUMNS_FIELD from '@salesforce/schema/DataImportBatch__c.Batch_Table_Columns__c';
import DATA_IMPORT_BATCH_DONATION_MATCHING_RULE from '@salesforce/schema/DataImportBatch__c.Donation_Matching_Rule__c';
import DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS from '@salesforce/schema/DataImportBatch__c.Allow_Recurring_Donations__c';
import Settings from 'c/geSettings';

const NAME = 'name';
const ID = 'id';
const MAX_STEPS = 2;
const CANCEL = 'cancel';
const SEMI_COLON_SEPARATOR = ';';
const PACKAGE_NAMESPACE_PREFIX = 'npsp';

export default class geBatchWizard extends NavigationMixin(LightningElement) {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api recordId;
    @api dedicatedListenerEventName;

    @track step = 0;
    @track templates;
    @track selectedBatchHeaderFields = [];
    @track formSections = [];
    @track selectedTemplateId;
    @track isLoading = true;
    @track donationMatchingBehaviors;
    @track hasInvalidBatchFields = false;
    @track missingBatchHeaderFieldLabels = [];
    @track missingRequiredFieldsMessage;

    dataImportBatchFieldInfos;
    dataImportBatchInfo;
    dataImportBatchRecord;
    templatesById = {};
    templateOptions;
    isLoaded = false;
    gatewayName;
    gatewaySettings = {};

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

    _allowFirstInstallment = false;
    _allowFirstInstallmentDisabled;
    _allowRecurringDonations = false;

    installmentCheckboxMetadata = Object.freeze({
        objectApiName : 'AllowFirstInstallment__o',
        fieldApiName : 'AllowFirstInstallment__f'
    });

    get allowRecurringDonations() {
        return this
            ?.dataImportBatchRecord
            ?.fields[DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS.fieldApiName]
            ?.value;
    }

    get allowRecurringDonationsField() {
        return this.dataImportBatchInfo
            .fields[DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS.fieldApiName];
    }

    get canAllowRecurringDonations() {
        return Settings.canMakeGiftsRecurring();
    }

    handleAllowRecurringDonationsOnChange(event) {
        const isChecked = event.detail.value
        this._allowRecurringDonations = isChecked;
        if (!isChecked) {
            this._allowFirstInstallment = false;
            this._allowFirstInstallmentDisabled = true;
        } else {
            this._allowFirstInstallmentDisabled = false;
        }

    }

    get allowFirstInstallment () {
        if (this.isEditMode && this._allowRecurringDonations) {
            let batchLevelDefaults =
                JSON.parse(this.dataImportBatchRecord.fields[DATA_IMPORT_BATCH_DEFAULTS_INFO.fieldApiName].value);
            return batchLevelDefaults['AllowFirstInstallment__f'] ? 
                batchLevelDefaults['AllowFirstInstallment__f'].value : 
                false;
        }

        return this._allowFirstInstallment;
    }

    handleAllowFirstInstallmentOnChange(event) {
        this._allowFirstInstallment = event.detail.value;
    }

    get allowFirstInstallmentDisabled() {
        return this._allowFirstInstallmentDisabled;
    }

    get showBackButton() {
        if (this.step === 1 && this.isEditMode) {
            return false;
        }
        return this.step > 0;
    }

    get showSaveButton() {
        return this.step === 2;
    }

    get isNextButtonDisabled() {
        if (this.step === 0) {
            return !this.selectedTemplateId;
        } else if (this.step === 1) {
            return false;
        }
        return false;
    }

    get header() {
        return this.headers[this.step];
    }

    get cssClassStep0() {
        return this.header === this.headers[0] ?
            'slds-p-horizontal_x-large slds-p-vertical_large slds-size_1-of-1 step-0' :
            'slds-hide';
    }

    get cssClassStep1() {
        return this.header === this.headers[1] ?
            'slds-p-horizontal_x-large slds-p-vertical_large slds-size_1-of-1' :
            'slds-hide';
    }

    get cssClassStep2() {
        return this.header === this.headers[2] ?
            'slds-p-horizontal_large slds-p-bottom_x-large slds-size_1-of-1' :
            'slds-hide';
    }

    get selectedTemplate() {
        if (this.selectedTemplateId && this.templatesById) {
            return this.templatesById[this.selectedTemplateId];
        }
        return undefined;
    }

    get isEditMode() {
        return isNotEmpty(this.recordId);
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

    @wire(getRecordCreateDefaults, { objectApiName: '$dataImportBatchName' })
    dataImportBatchCreateDefaults;

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
        this._allowRecurringDonations =
            this.dataImportBatchRecord
            ?.fields[DATA_IMPORT_BATCH_ALLOW_RECURRING_DONATIONS.fieldApiName]
            ?.value;

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

    appendTrueFalsePicklistToElement() {
        this.formSections.forEach(section => {
            if (section.elements) {
                section.elements.forEach(element => {
                    const fieldMapping = GeFormService.getFieldMappingWrapper(element.dataImportFieldMappingDevNames[0]);

                    if (isNotEmpty(fieldMapping)) {
                        if (isTrueFalsePicklist(fieldMapping)) {
                            element.picklistOptionsOverride = trueFalsePicklistOptions();
                        }
                    }

                    Object.defineProperty(element, 'showDefaultValueInput', {
                        get: function() { return this.dataType !== 'BOOLEAN' || !!this.picklistOptionsOverride; }
                    });
                });
            }
        });
    }

    setValuesForSelectedBatchHeaderFields(allFields) {
        this.selectedBatchHeaderFields.map(batchHeaderField => {
            let queriedField = allFields[batchHeaderField.apiName];
            if (queriedField) {
                batchHeaderField.value = queriedField.value;
            }
        });
    }

    async connectedCallback() {
        try {
            this.donationMatchingBehaviors = await getDonationMatchingValues();

            if (!GeFormService.fieldMappings) {
                await GeFormService.getFieldMappings();
            }

            if (Settings.isElevateCustomer()) {
                this.gatewaySettings = JSON.parse(await getGatewayAssignmentSettingsWithDefaultGatewayName());
            }

            if (!this.recordId) {
                this.templates = await getAllFormTemplates();
                this.templates = this.templates.sort();
                this.builderTemplateComboboxOptions(this.templates);
                this.isLoading = false;
            }
            if (!this.isEditMode) {
                this._allowFirstInstallmentDisabled = true;
            }
        } catch (error) {
            handleError(error);
        }
    }

    builderTemplateComboboxOptions(templates) {
        if (templates && templates.length > 0) {
            this.templateOptions = this.templates.map(template => {
                this.templatesById[template[ID]] = template;
                return { label: template[NAME], value: template[ID] }
            });
        }
    }

    handleNext() {
        if (this.step === 1) {
            this.validateBatchHeaderFields();

            if (this.hasInvalidBatchFields) {
                return;
            }
        }

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
        this.selectedTemplateId = event.detail.value;
        this.gatewayName = this.selectedTemplate.elevateSettings?.gatewayName;
        this.selectedBatchHeaderFields = [];

        this.selectedBatchHeaderFields = addKeyToCollectionItems(this.selectedTemplate.batchHeaderFields);
        this.formSections = this.selectedTemplate.layout.sections;
        this.appendTrueFalsePicklistToElement();

        if (this.recordId && this.dataImportBatchRecord && this.dataImportBatchRecord.fields) {
            this.setValuesForSelectedBatchHeaderFields(this.dataImportBatchRecord.fields);
        }

        this.resetValidations();
    }

    /*******************************************************************************
    * @description Method collects all batch header fields and checks for their
    * validity.
    */
    validateBatchHeaderFields() {
        this.resetValidations();

        let inputComponents = this.template.querySelectorAll('c-util-input[data-id="batchHeaderField"]');
        for (let i = 0; i < inputComponents.length; i++) {
            if (!inputComponents[i].isValid()) {
                this.hasInvalidBatchFields = true;
                this.missingBatchHeaderFieldLabels =
                    [...this.missingBatchHeaderFieldLabels, inputComponents[i].uiLabel];
            }
        }

        if (this.hasInvalidBatchFields &&
            (this.missingBatchHeaderFieldLabels && this.missingBatchHeaderFieldLabels.length > 0)) {

            this.missingRequiredFieldsMessage = GeLabelService.format(
                this.CUSTOM_LABELS.commonMissingRequiredFields,
                [this.missingBatchHeaderFieldLabels.join(', ')]);
        }
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the save action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleSave() {
        this.isLoading = true;
        if (this.recordId) {
            this.handleRecordUpdate(this.buildUpdateRecord());
        } else {
            this.handleRecordCreate(this.buildCreateRecord());
        }
    }

    /**
     * @description Builds a new data import batch record to be saved
     * @returns {DataImportBatch record}
     */
    buildCreateRecord() {
        const dataImportBatchObjectInfo = this.dataImportBatchCreateDefaults.
            data.objectInfos[this.dataImportBatchName];
        const createRecord = generateRecordInputForCreate(
            this.dataImportBatchCreateDefaults.data.record,
            dataImportBatchObjectInfo);
        return this.setFieldValues(createRecord);
    }

    /**
     * @description Builds a data import batch record to be updated
     * @returns {DataImportBatch record}
     */
    buildUpdateRecord() {
        const dataImportBatchObjectInfo = this.dataImportBatchCreateDefaults.
            data.objectInfos[this.dataImportBatchName];
        let updateRecord = generateRecordInputForUpdate(
            this.dataImportBatchRecord, dataImportBatchObjectInfo);
        updateRecord.apiName = this.dataImportBatchRecord.apiName;
        return this.setFieldValues(updateRecord);
    }

    setFieldValues(dataImportBatch) {
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
        // Set matching behavior
        dataImportBatch.fields[DATA_IMPORT_MATCHING_BEHAVIOR_INFO.fieldApiName] =
            this.donationMatchingBehaviors.ExactMatchOrCreate;
        // Set batch table column headers
        const hasAccessTobatchTableColumnsField =
            this.dataImportBatchInfo.fields[DATA_IMPORT_BATCH_TABLE_COLUMNS_FIELD.fieldApiName];
        if (hasAccessTobatchTableColumnsField) {
            dataImportBatch.fields[DATA_IMPORT_BATCH_TABLE_COLUMNS_FIELD.fieldApiName] =
                JSON.stringify(this.selectedTemplate.defaultBatchTableColumns);
        }

        if (this.recordId) {
            dataImportBatch.fields[DATA_IMPORT_BATCH_ID_INFO.fieldApiName] = this.recordId;
        }

        dataImportBatch = this.stripNamespaceFromDonationMatchingRuleFields(dataImportBatch);

        return dataImportBatch;
    }

    /***************************************************************************
     * @description Strips namespace prefix from the Data Import Batch donation matching
     * rule fields if in a namespaced context
     * @param dataImportBatch
     * @returns {object}
     */
    stripNamespaceFromDonationMatchingRuleFields (dataImportBatch) {
        const donationMatchingRule = dataImportBatch.fields[
          DATA_IMPORT_BATCH_DONATION_MATCHING_RULE.fieldApiName];
        const namespace = getNamespace(DATA_IMPORT_BATCH_INFO.objectApiName);
        
        if (isNull(namespace)) {
            let strippedFields = '';
            const matchingRuleFields = donationMatchingRule.split(
              SEMI_COLON_SEPARATOR);
            matchingRuleFields.forEach(field => {
                strippedFields += stripNamespace(field,
                  PACKAGE_NAMESPACE_PREFIX+'__') +
                  SEMI_COLON_SEPARATOR;
            });
            dataImportBatch.fields[
              DATA_IMPORT_BATCH_DONATION_MATCHING_RULE.fieldApiName] =
              strippedFields.slice(0, -1);
        }
        return dataImportBatch;
    }

    handleRecordCreate(recordObject) {
        createRecord(recordObject)
            .then(record => {
                this.navigateToRecordViewPage(record.id);
            })
            .catch(error => {
                handleError(error);
            });
    }

    handleRecordUpdate(recordObject) {
        updateRecord({ fields: recordObject.fields })
            .then(() => {
                this.navigateToRecordViewPage(this.recordId);
            })
            .catch(error => {
                handleError(error);
            })
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the cancel action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleCancel() {
        if (this.dedicatedListenerEventName) {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, { action: CANCEL });
        } else {
            this.dispatchEvent(new CustomEvent(CANCEL, { detail: {} }));
        }
    }

    /*******************************************************************************
    * @description Navigates to a record detail page by record id.
    *
    * @param {string} formTemplateRecordId: Form_Template__c record id.
    */
    navigateToRecordViewPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    resetValidations() {
        this.hasInvalidBatchFields = false;
        this.missingBatchHeaderFieldLabels = [];
    }

    get gatewayNameMessage() {
        if (this.gatewaySettings?.gatewayAssignmentEnabled && this.selectedTemplateId) {
            let gatewayName = this.gatewayName ? this.gatewayName : this.gatewaySettings?.defaultGatewayName;
            return psPaymentGateway + ' ' + gatewayName;
        }
        return '';
    }

    /*******************************************************************************
     * Start getters for data-qa-locator attributes
     */

    get qaLocatorSelectTemplate() {
        return `combobox Wizard ${this.CUSTOM_LABELS.commonTemplate}`;
    }

    get qaLocatorSave() {
        return `button Wizard ${this.CUSTOM_LABELS.commonSave}`;
    }

    get qaLocatorNext() {
        return `button Wizard ${this.CUSTOM_LABELS.commonNext}`;
    }

    get qaLocatorCancel() {
        return `button Wizard ${this.CUSTOM_LABELS.commonCancel}`;
    }

    get qaLocatorBack() {
        return `button Wizard ${this.CUSTOM_LABELS.commonBack}`;
    }

    /*******************************************************************************
     * End getters for data-qa-locator-attributes
     */
}
