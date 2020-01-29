import { LightningElement, api, track, wire } from 'lwc';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import geSave from '@salesforce/label/c.labelGeSave';
import geCancel from '@salesforce/label/c.labelGeCancel';
import geUpdate from '@salesforce/label/c.commonUpdate';
import geLabelService from 'c/geLabelService';
import { CONTACT1, ACCOUNT1,
         DONATION_DONOR_FIELDS, DONATION_DONOR,
         showToast,
         handleError,
         getRecordFieldNames,
         setRecordValuesOnTemplate,
         getPageAccess } from 'c/utilTemplateBuilder';
import { getQueryParameters, isEmpty, isNotEmpty, format } from 'c/utilCommon';
import { getRecord } from 'lightning/uiRecordApi';
import FORM_TEMPLATE_FIELD from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import TEMPLATE_JSON_FIELD from '@salesforce/schema/Form_Template__c.Template_JSON__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import NPSP_DATA_IMPORT_BATCH_FIELD from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';

import getOpenDonations from '@salesforce/apex/GE_FormRendererService.getOpenDonations';
import DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.Account1Imported__c';
import DATA_IMPORT_CONTACT1_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import DATA_IMPORT_DONATION_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.DonationImported__c';
import DATA_IMPORT_PAYMENT_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.PaymentImported__c';
import DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD from '@salesforce/schema/DataImport__c.DonationImportStatus__c';
import DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD from '@salesforce/schema/DataImport__c.PaymentImportStatus__c';

// Labels are used in BDI_MatchDonations class
import userSelectedMatch from '@salesforce/label/c.bdiMatchedByUser';
import userSelectedNewOpp from '@salesforce/label/c.bdiMatchedByUserNewOpp';
import applyNewPayment from '@salesforce/label/c.bdiMatchedApplyNewPayment';

const mode = {
    CREATE: 'create',
    UPDATE: 'update'
}

export default class GeFormRenderer extends NavigationMixin(LightningElement) {
    CUSTOM_LABELS = geLabelService.CUSTOM_LABELS;
    @api donorRecordId;
    @api donorApiName;
    @api donorRecord;

    fieldNames = [];
    @track formTemplate;
    @track fieldMappings;
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
    @track isAccessible = true;
    @track opportunities;
    @track selectedDonation;
    @track blankDataImportRecord;

    get hasPendingDonations() {
        return this.opportunities && this.opportunities.length > 0 ? true : false;
    }

    @wire(getRecord, { recordId: '$donorRecordId', optionalFields: '$fieldNames' })
    wiredGetRecordMethod({ error, data }) {
        if (data) {
            this.donorRecord = data;
            this.initializeForm(this.formTemplate, this.fieldMappings);
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }

   connectedCallback() {
        this.checkPageAccess();
        if (this.isAccessible) {
            if (this.batchId) {
                // When the form is being used for Batch Gift Entry, the Form Template JSON
                // uses the @wire service below to retrieve the Template using the Template Id
                // stored on the Batch.
                return;
            }

            GeFormService.getFormTemplate().then(response => {
                // check if there is a record id in the url
                this.donorRecordId = getQueryParameters().c__donorRecordId;
                this.donorApiName = getQueryParameters().c__apiName;

                // read the template header info
                if (response !== null && typeof response !== 'undefined') {
                    this.formTemplate = response.formTemplate;
                    this.fieldMappings = response.fieldMappingSetWrapper.fieldMappingByDevName;

                    // get the target field names to be used by getRecord
                    this.fieldNames = getRecordFieldNames(this.formTemplate, this.fieldMappings, this.donorApiName);

                    if (isEmpty(this.donorRecordId)) {
                        // if we don't have a donor record, it's ok to initialize the form now
                        // otherwise the form will be initialized after wiredGetRecordMethod completes
                        this.initializeForm(this.formTemplate);
                    }
                }
            });
        }
    }

    initializeForm(formTemplate, fieldMappings) {
        // read the template header info
        this.ready = true;
        this.name = formTemplate.name;
        this.description = formTemplate.description;
        this.version = formTemplate.layout.version;
        if (typeof formTemplate.layout !== 'undefined'
            && Array.isArray(formTemplate.layout.sections)) {

            // add record data to the template fields
            if (isNotEmpty(fieldMappings) && isNotEmpty(this.donorRecord)) {
                let sectionsWithValues = setRecordValuesOnTemplate(formTemplate.layout.sections, fieldMappings, this.donorRecord);
                this.sections = sectionsWithValues;
            } else {
                this.sections = formTemplate.layout.sections;
            }

            if (this.batchId) {
                this.dispatchEvent(new CustomEvent('sectionsretrieved'));
            }
        }
    }

    @wire(getRecord, {
        recordId: '$batchId',
        fields: FORM_TEMPLATE_FIELD
    })
    wiredBatch({ data, error }) {
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
    wiredTemplate({ data, error }) {
        if (data) {
            this.loadTemplate(
                JSON.parse(data.fields[TEMPLATE_JSON_FIELD.fieldApiName].value));
        } else if (error) {
            handleError(error);
        }
    }

    async loadTemplate(formTemplate) {
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

        // go back to the donor record page
        if (isNotEmpty(this.donorRecordId)) {
            this.navigateToRecordPage(this.donorRecordId);
        }
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
        const enableSaveButton = function () {
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
                    error: function () {
                        enableSaveButton();
                        toggleSpinner();
                    }
                }
            }));
        } else {
            GeFormService.handleSave(sectionsList, this.donorRecord, this.blankDataImportRecord)
                .then(opportunityId => {
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
                        if (Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === undefined ||
                            Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === 0) {

                            // If there are no specific fields the error has to go to,
                            // put it on the page level error message.
                            for (const dmlIndex in exceptionWrapper.DMLErrorMessageMapping) {
                                this.pageLevelErrorMessageList = [...this.pageLevelErrorMessageList,
                                    {index: dmlIndex, errorMessage: exceptionWrapper.DMLErrorMessageMapping[dmlIndex]}];
                            }
                        } else {
                            // If there is a specific field that each error is supposed to go to,
                            // show it on the field on the page.
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

                                    this.pageLevelErrorMessageList = [...this.pageLevelErrorMessageList, { index: key, errorMessage: errorMessage + ' [' + combinedFields + ']' }];
                                }
                            }
                        }
                    } else {
                        pageLevelErrorMessageList = [...pageLevelErrorMessageList, { index: 0, errorMessage: exceptionWrapper.errorMessage }];
                    }

                    // focus either the page level or field level error messsage somehow
                    window.scrollTo(0, 0);
                });
        }
    }

    isFormValid(sectionsList){

        // custom donor type validation
        if (this.isDonorTypeInvalid(sectionsList)) {
            return false;
        }

        // field validations
        let invalidFields = [];
        sectionsList.forEach(section => {
            const fields = section.getInvalidFields();
            invalidFields.push(...fields);
        });

        if (invalidFields.length > 0) {
            let fieldListAsString = invalidFields.join(', ');
            this.hasPageLevelError = true;
            this.pageLevelErrorMessageList = [ {index: 0, errorMessage: `The following fields are required: ${fieldListAsString}`} ];
        }

        return invalidFields.length === 0;
    }

    /**
     * validates donation donor type on sectionsList
     * @param sectionsList, list of sections
     * @returns {boolean|*} - true if form invalid, false otherwise
     */
    isDonorTypeInvalid( sectionsList ){

        const DONATION_VALUES = [
            DONATION_DONOR_FIELDS.donationDonorField,
            DONATION_DONOR_FIELDS.account1ImportedField, DONATION_DONOR_FIELDS.account1NameField,
            DONATION_DONOR_FIELDS.contact1ImportedField, DONATION_DONOR_FIELDS.contact1LastNameField
        ];
        // get label and value using apiName as key from fields for each section
        let miniFieldWrapper = {};
        sectionsList.forEach( section => {
            miniFieldWrapper = { ...miniFieldWrapper, ...(section.getFieldValueAndLabel(DONATION_VALUES)) };
        });

        // if no donation donor selection, nothing to validate here yet
        if ( isEmpty(miniFieldWrapper[DONATION_DONOR_FIELDS.donationDonorField].value) ) {
            return false;
        }

        // returns true when error message was generated
        return this.getDonorTypeValidationError( miniFieldWrapper, sectionsList );
    }

    /**
     * helper class for isDonorTypeInvalid, contains majority of logic
     * @param fieldWrapper - Array, field ui-label and value using field-api-name as key
     * @param sectionsList - Array, all sections
     * @returns {boolean} - true if error message was generated, false if otherwise
     */
    getDonorTypeValidationError( fieldWrapper, sectionsList ){

        // get data import record helper
        const di_record = this.getDataImportHelper( fieldWrapper );

        // donation donor validation depending on selection and field presence
        let isError = (di_record.donationDonorValue===DONATION_DONOR.isAccount1) ?
                        di_record.isAccount1ImportedEmpty && di_record.isAccount1NameEmpty :
                            di_record.donationDonorValue===DONATION_DONOR.isContact1 &&
                                di_record.isContact1ImportedEmpty && di_record.isContact1LastNameEmpty;

        // process error notification when error
        if (isError) {
            // highlight validation fields
            this.highlightValidationErrorFields( di_record, sectionsList, ' ' );
            // set page error
            this.hasPageLevelError = true;
            this.pageLevelErrorMessageList = [ {index: 0, errorMessage: this.getDonationDonorErrorLabel( di_record, fieldWrapper )} ];
        }

        return isError;
    }

    /**
     * Set donation donor error message using custom label depending on field presence
     * @param diRecord, Object - helper obj
     * @param fieldWrapper, Array of fields with Values and Labels
     * @returns {String}, formatted error message for donation donor validation
     */
    getDonationDonorErrorLabel( diRecord, fieldWrapper ){

        // init array replacement for custom label
        let validationErrorLabelReplacements = [ diRecord.donationDonorValue, diRecord.donationDonorLabel ];

        if (diRecord.donationDonorValue === DONATION_DONOR.isAccount1) {
            if (diRecord.isAccount1ImportedPresent)
                validationErrorLabelReplacements.push(fieldWrapper[DONATION_DONOR_FIELDS.account1ImportedField].label);
            if (diRecord.isAccount1NamePresent)
                validationErrorLabelReplacements.push(fieldWrapper[DONATION_DONOR_FIELDS.account1NameField].label);
        } else {
            if (diRecord.isContact1ImportedPresent)
                validationErrorLabelReplacements.push(fieldWrapper[DONATION_DONOR_FIELDS.contact1ImportedField].label);
            if (diRecord.isContact1LastNamePresent)
                validationErrorLabelReplacements.push(fieldWrapper[DONATION_DONOR_FIELDS.contact1LastNameField].label);
        }

        // set label depending fields present on template
        let label;
        switch (validationErrorLabelReplacements.length) {
            case 2: label = geLabelService.CUSTOM_LABELS.geErrorDonorTypeInvalid; break;
            case 3: label = geLabelService.CUSTOM_LABELS.geErrorDonorTypeValidationSingle; break;
            case 4: label = geLabelService.CUSTOM_LABELS.geErrorDonorTypeValidation; break;
            default: label = geLabelService.CUSTOM_LABELS.geErrorDonorTypeInvalid;
        }

        // set message using replacement array
        return  format( label, validationErrorLabelReplacements);
    }

    /**
     * highlight geForm fields on lSections using sError as message
     * @param diRecord, Object - helper obj
     * @param lSections, Array of geFormSection
     * @param sError, String to set on setCustomValidity
     */
    highlightValidationErrorFields( diRecord, lSections, sError ) {

        // prepare array to highlight fields that require attention depending on Donation_Donor
        const highlightFields = [ DONATION_DONOR_FIELDS.donationDonorField,
            diRecord.donationDonorValue === DONATION_DONOR.isAccount1 ? DONATION_DONOR_FIELDS.account1ImportedField : DONATION_DONOR_FIELDS.contact1ImportedField,
            diRecord.donationDonorValue === DONATION_DONOR.isAccount1 ? DONATION_DONOR_FIELDS.account1NameField : DONATION_DONOR_FIELDS.contact1LastNameField
        ];
        lSections.forEach(section => {
            section.setCustomValidityOnFields( highlightFields, sError );
        });

    }

    /**
     * helper object to minimize length of if statements and improve code legibility
     * @param fieldWrapper, Array of fields with Values and Labels
     * @returns Object, helper object to minimize length of if statements and improve code legibility
     */
    getDataImportHelper( fieldWrapper ) {

        const dataImportRecord = {
            // donation donor
            donationDonorValue: fieldWrapper[DONATION_DONOR_FIELDS.donationDonorField].value,
            donationDonorLabel: fieldWrapper[DONATION_DONOR_FIELDS.donationDonorField].label,
            // empty val checks
            isAccount1ImportedEmpty: isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1ImportedField]) || isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1ImportedField].value),
            isContact1ImportedEmpty: isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1ImportedField]) || isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1ImportedField].value),
            isContact1LastNameEmpty: isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1LastNameField]) || isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1LastNameField].value),
            isAccount1NameEmpty: isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1NameField]) || isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1NameField].value),
            // field presence
            isAccount1ImportedPresent: isNotEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1ImportedField]),
            isAccount1NamePresent: isNotEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1NameField]),
            isContact1ImportedPresent: isNotEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1ImportedField]),
            isContact1LastNamePresent: isNotEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1LastNameField])
        };
        return dataImportRecord;
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
        this.hasPageLevelError = false;
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

    /************************************************************************************
     * @description This function retrieves page access based on the Advanced Mapping and
     * Gift Entry feature gate.
     */
    checkPageAccess = async () => {
        this.isAccessible = await getPageAccess();
    }

    /*******************************************************************************
    * @description Pass through method that receives an event from geReviewDonations
    * to notify the parent component to construct a modal for reviewing donations.
    *
    * @param {object} event: Event object containing a payload for the modal.
    */
    toggleModal(event) {
        this.dispatchEvent(new CustomEvent('togglemodal', { detail: event.detail }));
    }

    // TODO: Need to handle displaying of review donations onload when coming from an Account/Contact page
    handleChangeLookup(event) {
        const detail = event.detail;
        const account = DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD.fieldApiName;
        const contact = DATA_IMPORT_CONTACT1_IMPORTED_FIELD.fieldApiName;

        if (detail.recordId && (detail.fieldApiName === account || detail.fieldApiName === contact)) {
            console.log('IS A DONOR LOOKUP FIELD CHANGE');
            const donationType = detail.fieldApiName === account ? 'account' : 'contact';
            getOpenDonations({ donorId: detail.recordId, donorType: donationType})
                .then(response => {
                    if (isNotEmpty(response)) {
                        this.opportunities = JSON.parse(response);
                    } else {
                        this.opportunities = undefined;
                    }
                })
                .catch(error => {
                    handleError(error);
                });
        } else {
            this.selectedDonation = undefined;
            this.opportunities = undefined;
        }
    }

    handleChangeSelectedDonation(event) {
        const selectedDonation = event.detail.selectedDonation;
        const donationType = event.detail.donationType;

        let blankDataImportRecord = {};

        const donationImported = DATA_IMPORT_DONATION_IMPORTED_FIELD.fieldApiName;
        const donationImportStatus = DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD.fieldApiName;
        const paymentImported = DATA_IMPORT_PAYMENT_IMPORTED_FIELD.fieldApiName;
        const paymentImportStatus = DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD.fieldApiName;

        if (selectedDonation) {
            if (donationType === 'opportunity') {
                blankDataImportRecord[donationImported] = selectedDonation.Id;

                if (selectedDonation.applyPayment) {
                    blankDataImportRecord[donationImportStatus] = applyNewPayment;
                } else {
                    blankDataImportRecord[donationImportStatus] = userSelectedMatch;
                }
            } else if (donationType === 'payment') {
                blankDataImportRecord[paymentImported] = selectedDonation.Id;
                blankDataImportRecord[paymentImportStatus] = userSelectedMatch;
                blankDataImportRecord[donationImported] = selectedDonation.npe01__Opportunity__c;
                blankDataImportRecord[donationImportStatus] = userSelectedMatch;
            }

        } else {
            blankDataImportRecord[donationImportStatus] = userSelectedNewOpp;
        }
        blankDataImportRecord = {
            ...blankDataImportRecord,
            npsp__Expected_Count_of_Gifts__c: 0,
            npsp__Expected_Total_Batch_Amount__c: 0,
            npsp__RequireTotalMatch__c: false,
        }
        this.blankDataImportRecord = blankDataImportRecord;
        console.log('Prepopulated Data Import: ', blankDataImportRecord);
    }
}