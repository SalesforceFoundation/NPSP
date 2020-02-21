import { LightningElement, api, track, wire } from 'lwc';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import GeLabelService from 'c/geLabelService';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import {
    DONATION_DONOR_FIELDS,
    DONATION_DONOR,
    handleError,
    getRecordFieldNames,
    setRecordValuesOnTemplate,
    checkPermissionErrors
} from 'c/utilTemplateBuilder';
import { registerListener } from 'c/pubsubNoPageRef';
import { getQueryParameters, isEmpty, isNotEmpty, format, isUndefined, checkNestedProperty, arraysMatch, getValueFromDotNotationString } from 'c/utilCommon';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import { getRecord } from 'lightning/uiRecordApi';
import FORM_TEMPLATE_FIELD from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import NPSP_DATA_IMPORT_BATCH_FIELD from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';

import getOpenDonations from '@salesforce/apex/GE_FormRendererService.getOpenDonations';
import DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.Account1Imported__c';
import DATA_IMPORT_CONTACT1_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import DATA_IMPORT_DONATION_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.DonationImported__c';
import DATA_IMPORT_PAYMENT_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.PaymentImported__c';
import DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD from '@salesforce/schema/DataImport__c.DonationImportStatus__c';
import DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD from '@salesforce/schema/DataImport__c.PaymentImportStatus__c';
import PAYMENT_OPPORTUNITY_NAME_FIELD from '@salesforce/schema/npe01__OppPayment__c.npe01__Opportunity__r.Name';

import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';

// Labels are used in BDI_MatchDonations class
import userSelectedMatch from '@salesforce/label/c.bdiMatchedByUser';
import userSelectedNewOpp from '@salesforce/label/c.bdiMatchedByUserNewOpp';
import applyNewPayment from '@salesforce/label/c.bdiMatchedApplyNewPayment';

const mode = {
    CREATE: 'create',
    UPDATE: 'update'
};
const GIFT_ENTRY_TAB_NAME = 'GE_Gift_Entry';

export default class GeFormRenderer extends NavigationMixin(LightningElement) {
    @api donorRecordId;
    @api donorApiName;
    @api donorRecord;

    fieldNames = [ ACCOUNT_NAME_FIELD, CONTACT_NAME_FIELD ];
    @api sections = [];
    @api showSpinner = false;
    @api batchId;
    @api submissions = [];
    @api hasPageLevelError = false;
    @api pageLevelErrorMessageList = [];

    @track isPermissionError = false;
    @track permissionErrorTitle;
    @track permissionErrorMessage;
    @track formTemplate;
    @track fieldMappings;
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';
    @track formTemplateId;

    erroredFields = [];
    CUSTOM_LABELS = { ...GeLabelService.CUSTOM_LABELS, messageLoading };

    @track _dataRow; // Row being updated when in update mode
    @track widgetData = {}; // data that must be passed down to the allocations widget.
    @track isAccessible = true;
    @track opportunities;
    @track selectedDonation;
    @track blankDataImportRecord;
    @track selectedDonorId;
    @track selectedDonorType;
    @track hasPreviouslySelectedDonation = false;

    get hasPendingDonations() {
        return this.opportunities && this.opportunities.length > 0 ? true : false;
    }

    get title() {
        return checkNestedProperty(this.donorRecord, 'fields', 'Name', 'value') ?
            GeLabelService.format(
                this.CUSTOM_LABELS.geHeaderMatchingGiftBy,
                [this.donorRecord.fields.Name.value]) :
            this.CUSTOM_LABELS.commonNewGift;
    }

    get isSingleGiftEntry() {
        return this.batchId ? false : true;
    }

    get cancelButtonText() {
        return this.isSingleGiftEntry ?
            this.CUSTOM_LABELS.commonCancel :
            this.CUSTOM_LABELS.geButtonCancelAndClear;
    }

    get saveButtonText() {
        return this.isSingleGiftEntry ?
            this.CUSTOM_LABELS.commonSave :
            this.CUSTOM_LABELS.geButtonSaveNewGift;
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
        registerListener('widgetData', this.handleWidgetData, this);

        if (this.batchId) {
            // When the form is being used for Batch Gift Entry, the Form Template JSON
            // uses the @wire service below to retrieve the Template using the Template Id
            // stored on the Batch.
            return;
        }

        GeFormService.getFormTemplate().then(response => {
            // check if there is a record id in the url
            this.selectedDonorId = this.donorRecordId = getQueryParameters().c__donorRecordId;
            this.selectedDonorType = this.donorApiName = getQueryParameters().c__apiName;
            // read the template header info
            if (response !== null && typeof response !== 'undefined') {
                this.formTemplate = response.formTemplate;
                this.fieldMappings = response.fieldMappingSetWrapper.fieldMappingByDevName;

                let errorObject = checkPermissionErrors(this.formTemplate);
                if (errorObject) {
                    this.setPermissionsError(errorObject);

                    return;
                }

                // get the target field names to be used by getRecord
                let fieldNamesFromTemplate =
                    getRecordFieldNames(this.formTemplate, this.fieldMappings, this.donorApiName);
                this.fieldNames = [ ...this.fieldNames, ...fieldNamesFromTemplate ];
                if (isEmpty(this.donorRecordId)) {
                    // if we don't have a donor record, it's ok to initialize the form now
                    // otherwise the form will be initialized after wiredGetRecordMethod completes
                    this.initializeForm(this.formTemplate);
                }
            }
        });
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
                let sectionsWithValues = setRecordValuesOnTemplate(formTemplate.layout.sections,
                    fieldMappings, this.donorRecord);
                this.sections = sectionsWithValues;
            } else {
                this.sections = formTemplate.layout.sections;
            }

            if (this.batchId) {
                this.dispatchEvent(new CustomEvent('sectionsretrieved'));
            }
        }
    }

    setPermissionsError(errorObject) {
        if (errorObject) {
            this.isPermissionError = true;
            this.permissionErrorTitle = errorObject.errorTitle;
            this.permissionErrorMessage = errorObject.errorMessage;
        }
    }

    @wire(getRecord, {
        recordId: '$batchId',
        fields: FORM_TEMPLATE_FIELD
    })
    wiredBatch({data, error}) {
        if (data) {
            this.formTemplateId = data.fields[FORM_TEMPLATE_FIELD.fieldApiName].value;
            GeFormService.getFormTemplateById(this.formTemplateId)
                .then(template => {
                    let errorObject = checkPermissionErrors(template);
                    if (errorObject) {
                        this.dispatchEvent(new CustomEvent('permissionerror'));
                        this.setPermissionsError(errorObject)
                    }
                    this.initializeForm(template);
                })
                .catch(err => {
                    handleError(err);
                });
        } else if (error) {
            handleError(error);
        }
    }

    handleCancel() {
        this.reset();

        // if not in batch mode, go back to point of origin
        if (isEmpty(this.batchId)) {
            if (isNotEmpty(this.donorRecordId)) {
                // go back to the donor record page
                this.navigateToRecordPage(this.donorRecordId);
            } else {
                // go back to the gift entry landing page;
                this.navigateToLandingPage();
            }
        }
    }

    handleSaveSingleGiftEntry(sectionsList,enableSave,toggle) {

        // handle error on callback from promise
        const handleCatchError = (err) => this.handleCatchOnSave(err);

        GeFormService.handleSave(sectionsList, this.donorRecord, this.blankDataImportRecord).then(opportunityId => {
            this.navigateToRecordPage(opportunityId);
        }).catch(error => {
            enableSave();
            toggle();
            handleCatchError(error);
        });

    }

    handleSaveBatchGiftEntry(sectionsList,enableSave,toggle) {

        // reset function for callback
        const reset = () => this.reset();
        // handle error on callback from promise
        const handleCatchError = (err) => this.handleCatchOnSave(err);

        // di data for save
        let { diRecord, widgetValues } = this.getData(sectionsList);
        // Apply selected donation fields to data import record
        if (this.blankDataImportRecord) {
            diRecord = { ...diRecord, ...this.blankDataImportRecord };
        }

        this.dispatchEvent(new CustomEvent('submit', {
            detail: {
                data: { diRecord, widgetValues },
                success: () => {
                    enableSave();
                    toggle();
                    reset();
                },
                error: (error) => {
                    enableSave();
                    toggle();
                    handleCatchError(error);
                }
            }
        }));

    }

    @api
    handleCatchOnSave( error ) {

        // var inits
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');
        const exceptionWrapper = JSON.parse(error.body.message);
        const allDisplayedFields = this.getDisplayedFieldsMappedByAPIName(sectionsList);
        this.hasPageLevelError = true;

        if (isNotEmpty(exceptionWrapper.exceptionType)) {

            // Check to see if there are any field level errors
            if (Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === undefined ||
                Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === 0) {

                // validation rules on Target Objects shows up here
                // unfortunately currently it doesnt bring field info yet
                if ( isNotEmpty(exceptionWrapper.errorMessage) &&
                        isNotEmpty(JSON.parse(exceptionWrapper.errorMessage).errorMessage) ) {
                    this.pageLevelErrorMessageList = [{
                        index: 0,
                        errorMessage: JSON.parse(exceptionWrapper.errorMessage).errorMessage
                    }];
                }

                // If there are no specific fields the error has to go to,
                // put it on the page level error message.
                for (const dmlIndex in exceptionWrapper.DMLErrorMessageMapping) {
                    this.pageLevelErrorMessageList = [...this.pageLevelErrorMessageList,
                        {index: dmlIndex+1, errorMessage: exceptionWrapper.DMLErrorMessageMapping[dmlIndex]}];
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
                        this.pageLevelErrorMessageList = [...this.pageLevelErrorMessageList,
                                                            { index: key, errorMessage: errorMessage + ' [' + combinedFields + ']' }];
                    }
                }
            }
        } else {
            this.pageLevelErrorMessageList = [...this.pageLevelErrorMessageList,
                                                { index: 0, errorMessage: exceptionWrapper.errorMessage }];
        }

        // focus either the page level or field level error messsage somehow
        window.scrollTo(0, 0);
    }

    handleSave(event) {

        // clean errors present on form
        this.clearErrors();
        // get sections on form
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');

        // apply custom and standard field validation
        if (!this.isFormValid(sectionsList)) {
            return;
        }

        // show the spinner
        this.toggleSpinner();
        // callback used to toggle spinner after Save promise
        const toggleSpinner = () => this.toggleSpinner();
        // disable the Save button and set callback to use after Save promise
        event.target.disabled = true;
        const enableSaveButton = function () {
            this.disabled = false;
        }.bind(event.target);

        // handle save depending mode
        if (this.batchId) {
            this.handleSaveBatchGiftEntry(sectionsList,enableSaveButton,toggleSpinner);
        } else {
            this.handleSaveSingleGiftEntry(sectionsList,enableSaveButton,toggleSpinner);
        }

    }

    isFormValid(sectionsList) {

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
            this.pageLevelErrorMessageList = [ {
                index: 0,
                errorMessage: `The following fields are required: ${fieldListAsString}`
            } ];
        }

        return invalidFields.length === 0;
    }

    /**
     * validates donation donor type on sectionsList
     * @param sectionsList, list of sections
     * @returns {boolean|*} - true if form invalid, false otherwise
     */
    isDonorTypeInvalid(sectionsList) {

        const DONATION_VALUES = [
            DONATION_DONOR_FIELDS.donationDonorField,
            DONATION_DONOR_FIELDS.account1ImportedField, DONATION_DONOR_FIELDS.account1NameField,
            DONATION_DONOR_FIELDS.contact1ImportedField, DONATION_DONOR_FIELDS.contact1LastNameField
        ];
        // get label and value using apiName as key from fields for each section
        let miniFieldWrapper = {};
        sectionsList.forEach(section => {
            miniFieldWrapper = { ...miniFieldWrapper, ...(section.getFieldValueAndLabel(DONATION_VALUES))};
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
    getDonorTypeValidationError(fieldWrapper, sectionsList) {

        // get data import record helper
        const di_record = this.getDataImportHelper(fieldWrapper);

        // donation donor validation depending on selection and field presence
        let isError = (di_record.donationDonorValue === DONATION_DONOR.isAccount1) ?
            di_record.isAccount1ImportedEmpty && di_record.isAccount1NameEmpty :
            di_record.donationDonorValue === DONATION_DONOR.isContact1 &&
            di_record.isContact1ImportedEmpty && di_record.isContact1LastNameEmpty;

        // process error notification when error
        if (isError) {
            // highlight validation fields
            this.highlightValidationErrorFields(di_record, sectionsList, ' ');
            // set page error
            this.hasPageLevelError = true;
            this.pageLevelErrorMessageList = [ {
                index: 0,
                errorMessage: this.getDonationDonorErrorLabel(di_record, fieldWrapper)
            } ];
        }

        return isError;
    }

    /**
     * Set donation donor error message using custom label depending on field presence
     * @param diRecord, Object - helper obj
     * @param fieldWrapper, Array of fields with Values and Labels
     * @returns {String}, formatted error message for donation donor validation
     */
    getDonationDonorErrorLabel(diRecord, fieldWrapper) {

        // init array replacement for custom label
        let validationErrorLabelReplacements = [diRecord.donationDonorValue, diRecord.donationDonorLabel];

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
            case 2:
                label = this.CUSTOM_LABELS.geErrorDonorTypeInvalid;
                break;
            case 3:
                label = this.CUSTOM_LABELS.geErrorDonorTypeValidationSingle;
                break;
            case 4:
                label = this.CUSTOM_LABELS.geErrorDonorTypeValidation;
                break;
            default:
                label = this.CUSTOM_LABELS.geErrorDonorTypeInvalid;
        }

        // set message using replacement array
        return format(label, validationErrorLabelReplacements);
    }

    /**
     * highlight geForm fields on lSections using sError as message
     * @param diRecord, Object - helper obj
     * @param lSections, Array of geFormSection
     * @param sError, String to set on setCustomValidity
     */
    highlightValidationErrorFields(diRecord, lSections, sError) {

        // prepare array to highlight fields that require attention depending on Donation_Donor
        const highlightFields = [DONATION_DONOR_FIELDS.donationDonorField,
            diRecord.donationDonorValue === DONATION_DONOR.isAccount1 ? DONATION_DONOR_FIELDS.account1ImportedField :
                DONATION_DONOR_FIELDS.contact1ImportedField,
            diRecord.donationDonorValue === DONATION_DONOR.isAccount1 ? DONATION_DONOR_FIELDS.account1NameField :
                DONATION_DONOR_FIELDS.contact1LastNameField
        ];
        lSections.forEach(section => {
            section.setCustomValidityOnFields(highlightFields, sError);
        });

    }

    /**
     * helper object to minimize length of if statements and improve code legibility
     * @param fieldWrapper, Array of fields with Values and Labels
     * @returns Object, helper object to minimize length of if statements and improve code legibility
     */
    getDataImportHelper(fieldWrapper) {

        const dataImportRecord = {
            // donation donor
            donationDonorValue: fieldWrapper[DONATION_DONOR_FIELDS.donationDonorField].value,
            donationDonorLabel: fieldWrapper[DONATION_DONOR_FIELDS.donationDonorField].label,
            // empty val checks
            isAccount1ImportedEmpty: isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1ImportedField]) ||
                isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1ImportedField].value),
            isContact1ImportedEmpty: isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1ImportedField]) ||
                isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1ImportedField].value),
            isContact1LastNameEmpty: isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1LastNameField]) ||
                isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.contact1LastNameField].value),
            isAccount1NameEmpty: isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1NameField]) ||
                isEmpty(fieldWrapper[DONATION_DONOR_FIELDS.account1NameField].value),
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
        this.widgetData = {};
    }

    get mode() {
        return this._dataRow ? mode.UPDATE : mode.CREATE;
    }

    @api
    get saveActionLabel() {
        if (this.isSingleGiftEntry) {
            return this.CUSTOM_LABELS.commonSave;
        }

        switch (this.mode) {
            case mode.UPDATE:
                return this.CUSTOM_LABELS.commonUpdate;
            default:
                return this.CUSTOM_LABELS.geButtonSaveNewGift;
        }
    }

    @api
    get isUpdateActionDisabled() {
        return this._dataRow && this._dataRow[STATUS_FIELD.fieldApiName] === 'Imported';
    }

    /**
     * Track widget data so that our widgets can react to the overall state of the form
     * @param payload   An object to store in widgetData
     */
    handleWidgetData(payload) {
        this.widgetData = {...this.widgetData, ...payload};
    }

    getData(sections) {
        let { diRecord, widgetValues } =
            GeFormService.getDataImportRecord(sections);

        if (!diRecord[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName]) {
            diRecord[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName] = this.batchId;
        }

        if (this._dataRow) {
            diRecord.Id = this._dataRow.Id;
        }

        return {diRecord, widgetValues};
    }

    /*******************************************************************************
     * @description Navigates to Gift Entry landing page.
     */
    navigateToLandingPage() {
        const giftEntryTabName = TemplateBuilderService.alignSchemaNSWithEnvironment(GIFT_ENTRY_TAB_NAME);
        let url = `/lightning/n/${giftEntryTabName}`;

        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            },
            true
        );
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

    @wire(getOpenDonations, { donorId: '$selectedDonorId', donorType: '$selectedDonorType' })
    wiredOpenDonations({ error, data }) {
        if (data) {
            if (isNotEmpty(data)) {
                let donorOpportunities = JSON.parse(data);

                if (arraysMatch(this.opportunities, donorOpportunities) === false) {
                    this.opportunities = donorOpportunities;

                    if (this.hasPreviouslySelectedDonation) {
                        const reviewDonationsComponent = this.template.querySelector('c-ge-review-donations');
                        reviewDonationsComponent.resetDonationType();
                        this.selectedDonation = undefined;
                        this.resetDonationAndPaymentImportedFields();
                    }
                }
            } else {
                this.opportunities = [];
            }
        }

        if (error) {
            handleError(error);
        }
    }

    handleChangePicklist(event) {
        const account = DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD.fieldApiName;
        const contact = DATA_IMPORT_CONTACT1_IMPORTED_FIELD.fieldApiName;
        const donorTypeFieldApiName = DONATION_DONOR_FIELDS.donationDonorField;
        const picklistFieldApiName = event.detail.fieldApiName;
        const picklistValue = event.detail.value;

        if (picklistFieldApiName === donorTypeFieldApiName) {
            const sectionsList = this.template.querySelectorAll('c-ge-form-section');
            const sectionData = this.getData(sectionsList);
            const diRecord = sectionData.diRecord;
            const picklistDonorType = picklistValue === 'Account1' ? 'Account' : 'Contact';
            const recordId = picklistDonorType === 'Account' ? diRecord[account] : diRecord[contact];

            this.setReviewDonationsDonorProperties(recordId, picklistDonorType);
        }
    }

    // TODO: Need to handle displaying of review donations onload when coming from an Account/Contact page
    handleChangeLookup(event) {
        const recordId = event.detail.recordId;
        const lookupFieldApiName = event.detail.fieldApiName;
        const account = DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD.fieldApiName;
        const contact = DATA_IMPORT_CONTACT1_IMPORTED_FIELD.fieldApiName;
        const lookupDonorType = lookupFieldApiName === account ? 'Account' : 'Contact';

        if (lookupFieldApiName === account || lookupFieldApiName === contact) {
            let donorType = this.getCurrentlySelectedDonorType();

            if (donorType && donorType === lookupDonorType) {
                this.setReviewDonationsDonorProperties(recordId, donorType);
            }
        }
    }

    getCurrentlySelectedDonorType() {
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');
        let donorType;

        if (!this.selectedDonorType) {
            const sectionData = this.getData(sectionsList);
            const diRecord = sectionData.diRecord;
            donorType = diRecord[DONATION_DONOR_FIELDS.donationDonorField];

            if (isUndefined(donorType)) {
                // Highlight donor type field if none is selected
                this.isDonorTypeInvalid(sectionsList);
            } else {
                donorType = donorType === 'Account1' ? 'Account' : 'Contact';
            }
        } else {
            donorType = this.selectedDonorType;
        }

        return donorType;
    }

    setReviewDonationsDonorProperties(recordId, donorType) {
        if (recordId) {
            this.selectedDonorId = recordId;
            this.selectedDonorType = donorType;
        } else {
            this.selectedDonation = undefined;
            this.opportunities = undefined;
            this.selectedDonorId = undefined;
            this.selectedDonorType = undefined;

            if (isUndefined(this.opportunities) && this.hasPreviouslySelectedDonation) {
                // Reset populated donation/payment imported fields
                this.resetDonationAndPaymentImportedFields();
            }
        }
    }

    handleChangeSelectedDonation(event) {
        this.hasPreviouslySelectedDonation = true;
        this.selectedDonation = event.detail.selectedDonation;
        const donationType = event.detail.donationType;

        let blankDataImportRecord = {};

        const donationImported = DATA_IMPORT_DONATION_IMPORTED_FIELD.fieldApiName;
        const donationImportStatus = DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD.fieldApiName;
        const paymentImported = DATA_IMPORT_PAYMENT_IMPORTED_FIELD.fieldApiName;
        const paymentImportStatus = DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD.fieldApiName;

        if (this.selectedDonation) {
            if (donationType === 'opportunity') {
                blankDataImportRecord[donationImported] = this.selectedDonation.Id;

                if (this.selectedDonation.applyPayment) {
                    blankDataImportRecord[donationImportStatus] = applyNewPayment;
                } else {
                    blankDataImportRecord[donationImportStatus] = userSelectedMatch;
                }
                blankDataImportRecord[paymentImported] = undefined;
                blankDataImportRecord[paymentImportStatus] = undefined;
            } else if (donationType === 'payment') {
                blankDataImportRecord[paymentImported] = this.selectedDonation.Id;
                blankDataImportRecord[paymentImportStatus] = userSelectedMatch;
                blankDataImportRecord[donationImported] = this.selectedDonation.npe01__Opportunity__c;
                blankDataImportRecord[donationImportStatus] = userSelectedMatch;
            }

        } else {
            blankDataImportRecord[donationImportStatus] = userSelectedNewOpp;
        }

        this.blankDataImportRecord = blankDataImportRecord;

        this.applyFieldValuesFromSelectedDonation(blankDataImportRecord, donationType);
    }

    applyFieldValuesFromSelectedDonation(blankDataImportRecord, donationType) {
        const donationImported = DATA_IMPORT_DONATION_IMPORTED_FIELD.fieldApiName;
        const paymentImported = DATA_IMPORT_PAYMENT_IMPORTED_FIELD.fieldApiName;

        Object.keys(blankDataImportRecord).forEach(fieldApiName => {
            const value = blankDataImportRecord[fieldApiName];
            const isDonorLookupAndHasValue =
                value && (fieldApiName === donationImported || fieldApiName === paymentImported);
            let displayValue;

            if (isDonorLookupAndHasValue) {
                if (fieldApiName === donationImported) {
                    if (donationType === 'payment') {
                        displayValue = getValueFromDotNotationString(
                            this.selectedDonation,
                            PAYMENT_OPPORTUNITY_NAME_FIELD.fieldApiName);
                        return;
                    }
                }
                displayValue = this.selectedDonation.Name;
            }

            this.setFormFieldValue(fieldApiName, value, displayValue);
        });
    }

    setFormFieldValue(fieldApiName, value, displayValue) {
        const sections = this.template.querySelectorAll('c-ge-form-section');
        let allFormFields = this.getDisplayedFieldsMappedByAPIName(sections);

        if (allFormFields[fieldApiName]) {
            allFormFields[fieldApiName].load({ value, displayValue });
        }
    }

    resetDonationAndPaymentImportedFields() {
        const donationImported = DATA_IMPORT_DONATION_IMPORTED_FIELD.fieldApiName;
        const paymentImported = DATA_IMPORT_PAYMENT_IMPORTED_FIELD.fieldApiName;
        this.setFormFieldValue(donationImported, undefined, undefined);
        this.setFormFieldValue(paymentImported, undefined, undefined);
    }
}