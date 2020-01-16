import { LightningElement, api, track, wire } from 'lwc';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import geSave from '@salesforce/label/c.labelGeSave';
import geCancel from '@salesforce/label/c.labelGeCancel';
import geDonationTypeErrorLabel from '@salesforce/label/c.geErrorDonorTypeValidation';
import geUpdate from '@salesforce/label/c.labelGeUpdate';
import { showToast, handleError } from 'c/utilTemplateBuilder';
import { getRecord } from 'lightning/uiRecordApi';
import { format, isEmpty } from 'c/utilCommon';
import FORM_TEMPLATE_FIELD from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import TEMPLATE_JSON_FIELD from '@salesforce/schema/Form_Template__c.Template_JSON__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import NPSP_DATA_IMPORT_BATCH_FIELD from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';
// Import required schema for donation type validation
import ACCOUNT1_NAME_FIELD_INFO from '@salesforce/schema/DataImport__c.Account1_Name__c';
import ACCOUNT1_IMPORTED_FIELD_INFO from '@salesforce/schema/DataImport__c.Account1Imported__c';
import CONTACT1_IMPORTED_FIELD_INFO from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import CONTACT1_LASTNAME_FIELD_INFO from '@salesforce/schema/DataImport__c.Contact1_Lastname__c';
import DONATION_DONOR_FIELD_INFO from '@salesforce/schema/DataImport__c.Donation_Donor__c';

const mode = {
    CREATE: 'create',
    UPDATE: 'update'
}

export default class GeFormRenderer extends NavigationMixin(LightningElement) {
    @api sections = [];
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';
    @api showSpinner = false;
    @api batchId;
    @api hasPageLevelError = false;
    label = { messageLoading, geSave, geCancel };
    @track formTemplateId;
    erroredFields = [];
    @api pageLevelErrorMessageList = [];
    @track _dataRow; // Row being updated when in update mode

    connectedCallback() {
        if (this.batchId) {
            // When the form is being used for Batch Gift Entry, the Form Template JSON
            // uses the @wire service below to retrieve the Template using the Template Id
            // stored on the Batch.
            return;
        }

        GeFormService.getFormTemplate().then(response => {
            // read the template header info
            if(response !== null && typeof response !== 'undefined') {
                const { formTemplate } = response;
                this.initializeForm(formTemplate);
            }
        });
    }

    initializeForm(formTemplate) {
        // read the template header info
        this.ready = true;
        this.name = formTemplate.name;
        this.description = formTemplate.description;
        this.version = formTemplate.layout.version;
        if (typeof formTemplate.layout !== 'undefined'
            && Array.isArray(formTemplate.layout.sections)) {
            this.sections = formTemplate.layout.sections;
            this.dispatchEvent(new CustomEvent('sectionsretrieved'));
        }
    }

    @wire(getRecord, {
        recordId: '$batchId',
        fields: FORM_TEMPLATE_FIELD
    })
    wiredBatch({data, error}) {
        if (data) {
            this.formTemplateId = data.fields[FORM_TEMPLATE_FIELD.fieldApiName].value;
        } else if (error) {
            handleError(error);
        }
    }

    @wire(getRecord, {
        recordId: '$formTemplateId',
        fields: TEMPLATE_JSON_FIELD
    })
    wiredTemplate({data, error}) {
        if (data) {
            this.loadTemplate(
                JSON.parse(data.fields[TEMPLATE_JSON_FIELD.fieldApiName].value));
        } else if (error) {
            handleError(error);
        }
    }

    async loadTemplate(formTemplate){
        // With the change to using a Lookup field to connect a Batch to a Template,
        // we can use getRecord to get the Template JSON.  But the GeFormService
        // component still needs to be initialized with the field mappings, and the
        // call to getFormTemplate() does that.
        // TODO: Maybe initialize GeFormService with the field mappings in its connected
        //       callback instead?
        await GeFormService.getFormTemplate();
        this.initializeForm(formTemplate);
    }

    handleCancel() {
        this.reset();
    }

    handleSave(event) {

        this.clearErrors();

        const sectionsList = this.template.querySelectorAll('c-ge-form-section');

        // apply custom and standard field validation
        if (!this.isFormValid(sectionsList)) {
            return;
        }

        // disable the Save button
        event.target.disabled = true;
        const enableSaveButton = function() {
            this.disabled = false;
        }.bind(event.target);

        // show the spinner
        this.toggleSpinner();

        // callback used to toggle spinner after save
        const toggleSpinner = () => this.toggleSpinner();

        const reset = () => this.reset();

        if (this.batchId) {
            const data = this.getData(sectionsList);

            this.dispatchEvent(new CustomEvent('submit', {
                detail: {
                    data: data,
                    success: function () {
                        enableSaveButton();
                        toggleSpinner();
                        reset();
                    },
                    error: function() {
                        enableSaveButton();
                        toggleSpinner();
                    }
                }
            }));
        } else {
            GeFormService.handleSave(sectionsList).then(opportunityId => {
                this.navigateToRecordPage(opportunityId);
            })
                .catch(error => {

                    this.toggleSpinner();

                    // Show on top if it is a page level
                    this.hasPageLevelError = true;
                    const exceptionWrapper = JSON.parse(error.body.message);
                    const allDisplayedFields = this.getDisplayedFieldsMappedByAPIName(sectionsList);

                    if (exceptionWrapper.exceptionType !== null && exceptionWrapper.exceptionType !== '') {

                        // Check to see if there are any field level errors
                        if (Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === undefined || Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === 0) {

                            // If there are no specific fields the error has to go to, put it on the page level error message.
                            for (const dmlIndex in exceptionWrapper.DMLErrorMessageMapping) {
                                this.pageLevelErrorMessageList = [...this.pageLevelErrorMessageList, {index: dmlIndex, errorMessage: exceptionWrapper.DMLErrorMessageMapping[dmlIndex]}];
                            }
                        } else {
                            // If there is a specific field that each error is supposed to go to, show it on the field on the page.
                            // If it is not on the page to show, display it on the page level.
                            for (const key in exceptionWrapper.DMLErrorFieldNameMapping) {

                                // List of fields with this error
                                let fieldList = exceptionWrapper.DMLErrorFieldNameMapping[key];

                                // Error message for the field.
                                let errorMessage = exceptionWrapper.DMLErrorMessageMapping[key];

                                // Errored fields that are not displayed
                                let hiddenFieldList = [];

                                fieldList.forEach(fieldWithError => {
                                    // Go to the field and set the error message using setCustomValidity
                                    if (fieldWithError in allDisplayedFields) {
                                        let fieldInput = allDisplayedFields[fieldWithError];
                                        this.erroredFields.push(fieldInput);

                                        fieldInput.setCustomValidity(errorMessage);
                                    } else {

                                        // Keep track of errored fields that are not displayed.
                                        hiddenFieldList.push(fieldWithError);
                                    }
                                });

                                // If there are hidden fields, display the error message at the page level.
                                // With the fields noted.
                                if (hiddenFieldList.length > 0) {
                                    let combinedFields = hiddenFieldList.join(', ');

                                    this.pageLevelErrorMessageList = [...this.pageLevelErrorMessageList, {index: key, errorMessage: errorMessage + ' [' + combinedFields + ']'}];
                                }
                            }
                        }
                    } else {
                        pageLevelErrorMessageList = [...pageLevelErrorMessageList, {index: 0, errorMessage: exceptionWrapper.errorMessage}];
                    }

                    // focus either the page level or field level error messsage somehow
                    window.scrollTo(0,0);
                }) ;
        }
    }

    isFormValid(sectionsList){

        // custom donor type validation
        if (this.donorTypeInvalid(sectionsList)) {
            return false;
        }

        // field validations
        let invalidFields = [];
        sectionsList.forEach(section => {
            const fields = section.getInvalidFields();
            invalidFields.push(...fields);
        });

        if(invalidFields.length > 0){
            let fieldListAsString = invalidFields.join(', ');
            showToast('Invalid Form', 'The following fields are required: ' + fieldListAsString, 'error');
        }

        return invalidFields.length === 0;
    }

    donorTypeInvalid( sectionsList ){

        // aux vars
        let fieldDataWrapper = {};
        // get DeveloperName and value from fields for each section
        sectionsList.forEach(section => {
            fieldDataWrapper = { ...fieldDataWrapper, ...(section.getValidationHelper)};
        });

        // if no donation donor selection, nothing to validate here yet
        if ( isEmpty(fieldDataWrapper[DONATION_DONOR_FIELD_INFO.fieldApiName].value) ) {
            return false;
        }

        // relevant Donation_Donor picklist values for validation
        const DONATION_DONOR = {
            isAccount1: 'Account1',
            isContact1: 'Contact1'
        };

        // relevant donation type fields for validation
        const DONATION_TYPE_FIELDS = {
            account1ImportedField:  ACCOUNT1_IMPORTED_FIELD_INFO.fieldApiName,
            account1NameField:      ACCOUNT1_NAME_FIELD_INFO.fieldApiName,
            contact1ImportedField:  CONTACT1_IMPORTED_FIELD_INFO.fieldApiName,
            contact1LastNameField:  CONTACT1_LASTNAME_FIELD_INFO.fieldApiName,
            donationDonorField:     DONATION_DONOR_FIELD_INFO.fieldApiName,
        };

        // aux vars
        let diRecord = {};
        let diRecordLabels = {};

        // get field mapping wrapper to retrieve api definitions
        for (let key in fieldDataWrapper) {
            if (fieldDataWrapper.hasOwnProperty(key)) {

                let dataWrapper = fieldDataWrapper[key];
                diRecord[ dataWrapper.sourceFieldAPIName ] = dataWrapper.value;
                diRecordLabels[ dataWrapper.sourceFieldAPIName ] = dataWrapper.label;

            }
        }

        // donation type validation ready to start
        if (diRecord[DONATION_TYPE_FIELDS.donationDonorField] === DONATION_DONOR.isAccount1 &&
                isEmpty( diRecord[DONATION_TYPE_FIELDS.account1ImportedField] ) &&
                    isEmpty( diRecord[DONATION_TYPE_FIELDS.account1NameField] ) &&
                        this.getDonorTypeValidationError(   DONATION_DONOR.isAccount1,
                                                            diRecordLabels[DONATION_TYPE_FIELDS.donationDonorField],
                                                            diRecordLabels[DONATION_TYPE_FIELDS.account1ImportedField],
                                                            diRecordLabels[DONATION_TYPE_FIELDS.account1NameField])) {

            return true;

        } else if (diRecord[DONATION_TYPE_FIELDS.donationDonorField] === DONATION_DONOR.isContact1 &&
                    isEmpty( diRecord[DONATION_TYPE_FIELDS.contact1ImportedField] ) &&
                        isEmpty( diRecord[DONATION_TYPE_FIELDS.contact1LastNameField] ) &&
                            this.getDonorTypeValidationError(   DONATION_DONOR.isContact1,
                                                                diRecordLabels[DONATION_TYPE_FIELDS.donationDonorField],
                                                                diRecordLabels[DONATION_TYPE_FIELDS.contact1ImportedField],
                                                                diRecordLabels[DONATION_TYPE_FIELDS.contact1LastNameField])) {

            return true;

        }

        return false;

    }

    getDonorTypeValidationError( donorValue, donorLabel, requiredLabel, requiredLabelAux ){

        // set message using label
        let message = format( geDonationTypeErrorLabel, [donorValue, donorLabel, requiredLabel, requiredLabelAux] );
        // set page error
        this.hasPageLevelError = true;
        this.pageLevelErrorMessageList = [...this.pageLevelErrorMessageList, {index: 0, errorMessage: message}];
        // TODO: mark fields with errors using this.erroredFields

        return true;

    }

    navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    // change showSpinner to the opposite of its current value
    toggleSpinner() {
        this.showSpinner = !this.showSpinner;
    }

    getDisplayedFieldsMappedByAPIName(sectionsList) {
        let allFields = {};
        sectionsList.forEach(section => {
            const fields = section.getAllFieldsByAPIName();

            allFields = Object.assign(allFields, fields);
        });

        return allFields;
    }

    clearErrors() {

        // Clear the page level error
        this.pageLevelErrorMessageList = [];

        // Clear the field level errors
        if (this.erroredFields.length > 0) {
            this.erroredFields.forEach(fieldToReset => {
                fieldToReset.setCustomValidity('');
            });
        }

        this.erroredFields = [];
    }

    @api
    load(dataRow) {
        this._dataRow = dataRow;
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');

        sectionsList.forEach(section => {
            section.load(dataRow);
        });
    }

    @api
    reset() {
        this._dataRow = undefined;
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');

        sectionsList.forEach(section => {
            section.reset();
        });
    }

    get mode() {
        return this._dataRow ? mode.UPDATE : mode.CREATE;
    }

    @api
    get saveActionLabel() {
        switch (this.mode) {
            case mode.UPDATE:
                return geUpdate;
                break;
            default:
                return geSave;
        }
    }

    @api
    get isUpdateActionDisabled() {
        return this._dataRow && this._dataRow[STATUS_FIELD.fieldApiName] === 'Imported';
    }

    getData(sections) {
        let dataImportRecord =
            GeFormService.getDataImportRecord(sections);

        if (!dataImportRecord[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName]) {
            dataImportRecord[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName] = this.batchId;
        }

        if (this._dataRow) {
            dataImportRecord.Id = this._dataRow.Id;
        }

        return dataImportRecord;
    }

}