import { LightningElement, api, track, wire } from 'lwc';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
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
import {
    getQueryParameters,
    isEmpty,
    isNotEmpty,
    format,
    isUndefined,
    checkNestedProperty,
    arraysMatch,
    deepClone,
    getSubsetObject
} from 'c/utilCommon';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import FORM_TEMPLATE_FIELD from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import BATCH_DEFAULTS_FIELD from '@salesforce/schema/DataImportBatch__c.Batch_Defaults__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import NPSP_DATA_IMPORT_BATCH_FIELD from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';

import getOpenDonations from '@salesforce/apex/GE_FormRendererService.getOpenDonations';
import DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.Account1Imported__c';
import DATA_IMPORT_CONTACT1_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import DATA_IMPORT_DONATION_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.DonationImported__c';
import DATA_IMPORT_PAYMENT_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.PaymentImported__c';
import DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD from '@salesforce/schema/DataImport__c.DonationImportStatus__c';
import DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD from '@salesforce/schema/DataImport__c.PaymentImportStatus__c';
import DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DATE from '@salesforce/schema/DataImport__c.Donation_Date__c';
import DONATION_RECORD_TYPE_NAME from '@salesforce/schema/DataImport__c.Donation_Record_Type_Name__c';
import OPP_PAYMENT_AMOUNT
    from '@salesforce/schema/npe01__OppPayment__c.npe01__Payment_Amount__c';
import SCHEDULED_DATE from '@salesforce/schema/npe01__OppPayment__c.npe01__Scheduled_Date__c';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import OPP_PAYMENT_OBJECT from '@salesforce/schema/npe01__OppPayment__c';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import PARENT_OPPORTUNITY_FIELD
    from '@salesforce/schema/npe01__OppPayment__c.npe01__Opportunity__c';

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
    _batchDefaults;

    erroredFields = [];
    CUSTOM_LABELS = { ...GeLabelService.CUSTOM_LABELS, messageLoading };

    @track dataImport; // Row being updated when in update mode
    @track widgetData = {}; // data that must be passed down to the allocations widget.
    @track isAccessible = true;

    @track selectedDonorId;
    @track selectedDonorType;
    @track opportunities;
    @track selectedDonation;
    @track selectedDonationDataImportFieldValues = {};
    @track hasPreviouslySelectedDonation = false;

    donationDonorEnum = {
        account1: 'Account1',
        contact1: 'Contact1'
    }

    _donationDonor;
    _account1Imported;
    _contact1Imported;

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

    @wire(getRecord, {recordId: '$donorRecordId', optionalFields: '$fieldNames'})
    wiredGetRecordMethod({error, data}) {
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
            this.donorApiName = getQueryParameters().c__apiName;
            this.selectedDonorType =
                this.donorApiName === 'Account' ? this.donationDonorEnum.account1 :
                    this.donorApiName === 'Contact' ? this.donationDonorEnum.contact1 : null;

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
                this.sections = setRecordValuesOnTemplate(formTemplate.layout.sections,
                    fieldMappings, this.donorRecord);
            } else {
                this.sections = formTemplate.layout.sections;
            }

            if (this.batchId) {
                this.sections = this.setBatchDefaults(formTemplate.layout.sections);
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
        fields: [FORM_TEMPLATE_FIELD, BATCH_DEFAULTS_FIELD]
    })
    wiredBatch({data, error}) {
        if (data) {
            this.formTemplateId = data.fields[FORM_TEMPLATE_FIELD.fieldApiName].value;
            this._batchDefaults = data.fields[BATCH_DEFAULTS_FIELD.fieldApiName].value;
            GeFormService.getFormTemplateById(this.formTemplateId)
                .then(formTemplate => {
                    this.formTemplate = formTemplate;

                    let errorObject = checkPermissionErrors(formTemplate);
                    if (errorObject) {
                        this.dispatchEvent(new CustomEvent('permissionerror'));
                        this.setPermissionsError(errorObject)
                    }
                    this.initializeForm(formTemplate, GeFormService.fieldMappings);
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

        GeFormService.handleSave(
            sectionsList,
            this.donorRecord,
            this.selectedDonationDataImportFieldValues)
            .then(opportunityId => {
                this.navigateToRecordPage(opportunityId);
            })
            .catch(error => {
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
        // Apply any selected donation fields that are not on the form
        // to the data import record
        for (const [key, value] of Object.entries(
            this.selectedDonationDataImportFieldValues)) {
            if (!diRecord.hasOwnProperty(key)) {
                diRecord[key] = value === null ? null : value.value || value;
            }
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
    load(dataImport, applySelectedDonationFieldValues = true) {
        if (dataImport.Id) {
            // Set this.dataImport when the record Id is present so
            // the form knows it is in update mode
            this.dataImport = dataImport;
        }

        // If the dataImport being loaded has Donation Donor, Contact1Imported,
        // or Account1Imported set, set the Renderer's stored property values
        this.setStoredDonationDonorProperties(dataImport);

        // If there is a currently selected Donation and the caller wants those values
        // applied to the dataImport record, add them (used during save operation)
        if (this.selectedDonation && applySelectedDonationFieldValues) {
            dataImport = {...dataImport, ...this.selectedDonationDataImportFieldValues};
        }

        if (this.selectedDonation && this.selectedDonation.Id &&
            this.selectedDonation.Id.startsWith(this.oppPaymentKeyPrefix)) {
            // If the selected donation is a Payment, set Donation Amount
            // and Donation Date to the values from the selected Payment.
            dataImport[DONATION_AMOUNT.fieldApiName] =
                this.selectedDonation[OPP_PAYMENT_AMOUNT.fieldApiName];
            dataImport[DONATION_DATE.fieldApiName] =
                this.selectedDonation[SCHEDULED_DATE.fieldApiName];
        }

        this.preprocessRecordTypeNameField(dataImport);

        const sectionsList = this.template.querySelectorAll('c-ge-form-section');
        sectionsList.forEach(section => {
            section.load(
                getSubsetObject(
                    dataImport,
                    section.sourceFields));
        });
    }

    /**
     * @description DataImport__c.Donation_Record_Type_Name__c field is mapped from one
     *              data type to another (Text to Lookup).  This method:
     *              1. ensures that when the dataImport object is loaded this field always
     *              holds the RecordType Id value (not the RecordType Name), and
     *              2. passes the RecordType Id to the setRecordTypeOnFields method so that
     *              the recordTypeId property is set on sibling fields.
     * @param dataImport The object being loaded into the form renderer.
     * @returns {boolean} Returns false if called with a non-null falsy parameter value.
     */
    preprocessRecordTypeNameField(dataImport) {
        const recordTypeNameValue = dataImport[DONATION_RECORD_TYPE_NAME.fieldApiName];
        if (!recordTypeNameValue && recordTypeNameValue !== null) {
            return false;
        }

        if (this.opportunityRecordTypeNames.includes(recordTypeNameValue)) {
            // If value is the RecordType Name, change it to the RecordType Id since child
            // fields are expecting the Id and not the Name.
            dataImport[DONATION_RECORD_TYPE_NAME.fieldApiName] = this.getRecordTypeIdByName(
                this.opportunityObjectInfo.data.recordTypeInfos,
                recordTypeNameValue
            );
        } else if (recordTypeNameValue.value) {
            dataImport[DONATION_RECORD_TYPE_NAME.fieldApiName] = recordTypeNameValue.value;
        }

        // Set the recordTypeId property on sibling fields that need it
        this.setRecordTypeIdOnSiblingFieldsForSourceField(
            DONATION_RECORD_TYPE_NAME.fieldApiName,
            dataImport[DONATION_RECORD_TYPE_NAME.fieldApiName]
        );
    }

    setRecordTypeIdOnSiblingFieldsForSourceField(sourceFieldApiName, recordTypeId) {
        const objectMappingDevNames =
            this.getObjectMappingsForSourceField(sourceFieldApiName);

        for (const objectMappingDevName of objectMappingDevNames) {
            this.setRecordTypeOnFields(objectMappingDevName, recordTypeId);
        }
    }

    setStoredDonationDonorProperties(dataImport) {
    if (dataImport[DONATION_DONOR_FIELDS.donationDonorField]) {
            this.handleDonationDonorChange(
                dataImport[DONATION_DONOR_FIELDS.donationDonorField]
            );
        }
        if (dataImport[DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD.fieldApiName]) {
            this.handleDonorAccountChange(
                dataImport[DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD.fieldApiName]
            );
        }
        if (dataImport[DATA_IMPORT_CONTACT1_IMPORTED_FIELD.fieldApiName]) {
            this.handleDonorContactChange(
                dataImport[DATA_IMPORT_CONTACT1_IMPORTED_FIELD.fieldApiName]
            );
        }
    }

    @api
    reset(objectMappingDeveloperName = null) {
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');

        let fieldMappingDevNames = null;
        if (objectMappingDeveloperName === null) {
            this.dataImport = null;
            this.setReviewDonationsDonorProperties(null);
            this.resetStoredDonationDonorProperties();
        } else {
            fieldMappingDevNames =
                Object.values(GeFormService.fieldMappings).filter(
                    ({Target_Object_Mapping_Dev_Name, DeveloperName}) =>
                        Target_Object_Mapping_Dev_Name === objectMappingDeveloperName)
                    .map(({DeveloperName}) => DeveloperName);
        }

        sectionsList.forEach(section => {
            section.reset(fieldMappingDevNames);
        });
        this.widgetData = {};
    }

    resetStoredDonationDonorProperties() {
        this._donationDonor = null;
        this._account1Imported = null;
        this._contact1Imported = null;
    }

    get mode() {
        return this.dataImport ? mode.UPDATE : mode.CREATE;
    }

    @api
    get saveActionLabel() {
        return this.isSingleGiftEntry ?
            this.CUSTOM_LABELS.commonSave :
            this.mode === mode.UPDATE ?
                this.CUSTOM_LABELS.commonUpdate :
                this.CUSTOM_LABELS.geButtonSaveNewGift;
    }

    @api
    get isUpdateActionDisabled() {
        return this.dataImport && this.dataImport[STATUS_FIELD.fieldApiName] === 'Imported';
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

        if (this.dataImport) {
            diRecord.Id = this.dataImport.Id;
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

    getSiblingFieldsForSourceField(sourceFieldApiName) {
        const objectMapping = Object.values(GeFormService.objectMappings)
            .find(({Imported_Record_Field_Name}) =>
                Imported_Record_Field_Name === sourceFieldApiName);
        return this.getSiblingFields(objectMapping.DeveloperName);
    }

    getSiblingFields(objectMappingDeveloperName) {
        // For a given field, get the full list of fields related to its object mapping

        // 1. Get this field's object mapping
        // 2. Get the other field mappings that have the same Target_Object_Mapping_Dev_Name
        // 3. Return the list of fields from those mappings

        const objectMapping =
            GeFormService.getObjectMappingWrapper(objectMappingDeveloperName);

        const relevantFieldMappings =
            Object.values(GeFormService.fieldMappings)
                .filter(({Target_Object_Mapping_Dev_Name}) =>
                    Target_Object_Mapping_Dev_Name === objectMapping.DeveloperName);

        // Return the sibling fields used by Advanced Mapping
        return relevantFieldMappings.map(
            ({Target_Field_API_Name}) =>
                `${objectMapping.Object_API_Name}.${Target_Field_API_Name}`);
    }

    handleLookupRecordSelect(event) {
        const recordId = event.detail.value; // Reset the field if null
        const fieldApiName = event.detail.fieldApiName;

        if(!fieldApiName ||
            fieldApiName !== 'RecordTypeId') {
            if (!GeFormService.importedRecordFieldNames.includes(fieldApiName)) {
                return false;
            }
        }

        if (fieldApiName === 'RecordTypeId') {
            this.setRecordTypeOnFields(event.detail.objectMappingDevName, recordId);
        } else if (event.detail.hasOwnProperty('value') && recordId !== null) {
            this.loadSelectedRecordFieldValues(fieldApiName, recordId);
        } else {
            // Reset all fields related to this lookup field's object mapping
            this.reset(this.getObjectMapping(fieldApiName).DeveloperName);
        }

        const account1Imported = DATA_IMPORT_ACCOUNT1_IMPORTED_FIELD.fieldApiName;
        const contact1Imported = DATA_IMPORT_CONTACT1_IMPORTED_FIELD.fieldApiName;

        if (fieldApiName === account1Imported) {
            this.handleDonorAccountChange(recordId);
        } else if (fieldApiName === contact1Imported) {
            this.handleDonorContactChange(recordId);
        }
    }

    setReviewDonationsDonorProperties(recordId) {
        if (recordId && this._donationDonor) {
            if ((this._donationDonor === this.donationDonorEnum.account1 &&
                recordId.startsWith(this.accountKeyPrefix)) ||
                (this._donationDonor === this.donationDonorEnum.contact1 &&
                    recordId.startsWith(this.contactKeyPrefix))) {
                this.selectedDonorId = recordId;
                this.selectedDonorType = this._donationDonor;
                return;
            }
        }

        // If _donationDonor and recordId don't align or aren't set,
        // reset all selected donation properties and form fields
        this.selectedDonorType = undefined;
        this.selectedDonorId = undefined;
        this.selectedDonation = undefined;
        this.opportunities = undefined;
        if (!!this.selectedDonation) {
            this.resetDonationAndPaymentImportedFields();
        }
    }

    handleChangeSelectedDonation(event) {
        this.hasPreviouslySelectedDonation = true;
        this.selectedDonation = event.detail.selectedDonation;

        const donationImportStatus = DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD.fieldApiName;
        const donationImported = DATA_IMPORT_DONATION_IMPORTED_FIELD.fieldApiName;
        const paymentImported = DATA_IMPORT_PAYMENT_IMPORTED_FIELD.fieldApiName;
        const paymentImportStatus = DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD.fieldApiName;

        if (!this.selectedDonation.hasOwnProperty('Id')) {
            this.resetDonationAndPaymentImportedFields();
            if (this.selectedDonation.new === true) {
                this.selectedDonationDataImportFieldValues[donationImportStatus] =
                    userSelectedNewOpp;
            }
        } else {
            if (this.selectedDonation.Id.startsWith(this.oppPaymentKeyPrefix)) {
                this.selectedDonationDataImportFieldValues[paymentImported] =
                    {
                        value: this.selectedDonation.Id,
                        displayValue: this.selectedDonation.Name
                    };
                this.selectedDonationDataImportFieldValues[paymentImportStatus] =
                    userSelectedMatch;
                this.selectedDonationDataImportFieldValues[donationImported] =
                    {
                        value: this.selectedDonation.npe01__Opportunity__c,
                        displayValue: this.selectedDonation.npe01__Opportunity__r.Name
                    };
                this.selectedDonationDataImportFieldValues[donationImportStatus] =
                    userSelectedMatch;
            } else if (this.selectedDonation.Id.startsWith(this.opportunityKeyPrefix)) {
                this.selectedDonationDataImportFieldValues[donationImported] =
                    {
                        value: this.selectedDonation.Id,
                        displayValue: this.selectedDonation.Name
                    };

                if (this.selectedDonation.applyPayment) {
                    this.selectedDonationDataImportFieldValues[donationImportStatus] =
                        applyNewPayment;
                } else {
                    this.selectedDonationDataImportFieldValues[donationImportStatus] =
                        userSelectedMatch;
                }

                this.selectedDonationDataImportFieldValues[paymentImported] = null;
                this.selectedDonationDataImportFieldValues[paymentImportStatus] = null;
            }
        }

        // Load the "imported" and "imported status" fields in case they are on the form
        this.load(this.selectedDonationDataImportFieldValues);

        if (this.selectedDonation.Id) {
            // Load the sibling field values (parented by the same object mapping)
            // for the donation and payment "imported" fields
            this.loadSelectedRecordFieldValues(
                this.selectedDonation.Id.startsWith(this.oppPaymentKeyPrefix) ?
                    paymentImported :
                    donationImported,
                this.selectedDonation.Id
            );

            if (this.selectedDonation.Id.startsWith(this.opportunityKeyPrefix)) {
                // If the selected donation is an Opportunity, reset form fields that have
                // field mappings parented by PaymentImported__c
                this.reset(
                    GeFormService.getObjectMappingWrapperByImportedFieldName(
                        DATA_IMPORT_PAYMENT_IMPORTED_FIELD.fieldApiName
                    ).DeveloperName);
            }
        }
    }

    resetDonationAndPaymentImportedFields() {
        // Reset the stored values for selected donation
        this.selectedDonationDataImportFieldValues
            [DATA_IMPORT_DONATION_IMPORTED_FIELD.fieldApiName] = null;
        this.selectedDonationDataImportFieldValues
            [DATA_IMPORT_DONATION_IMPORT_STATUS_FIELD.fieldApiName] = null;
        this.selectedDonationDataImportFieldValues
            [DATA_IMPORT_PAYMENT_IMPORTED_FIELD.fieldApiName] = null;
        this.selectedDonationDataImportFieldValues
            [DATA_IMPORT_PAYMENT_IMPORT_STATUS_FIELD.fieldApiName] = null;

        // Reset the "imported" and "imported status" donation fields if they are on the
        // form by loading the stored (now null) values for those fields
        this.load(
            this.selectedDonationDataImportFieldValues, false);

        // Reset form fields that have field mappings parented by DonationImported__c
        this.reset(
            GeFormService.getObjectMappingWrapperByImportedFieldName(
                DATA_IMPORT_DONATION_IMPORTED_FIELD.fieldApiName
            ).DeveloperName);

        // Reset form fields that have field mappings parented by PaymentImported__c
        this.reset(
            GeFormService.getObjectMappingWrapperByImportedFieldName(
                DATA_IMPORT_PAYMENT_IMPORTED_FIELD.fieldApiName
            ).DeveloperName);
    }

    /**
     * @description Function that sets batch defaults on the BGE Form
     * @param templateSections
     * @returns {sections}
     */
    setBatchDefaults(templateSections) {
        let sections = deepClone(templateSections);
        if (isNotEmpty(this._batchDefaults)) {
            let batchDefaultsObject;
            try {
                batchDefaultsObject = JSON.parse(this._batchDefaults);
                sections.forEach(section => {
                    const elements = section.elements;
                    elements.forEach(element => {
                        for (let key in batchDefaultsObject) {
                            if (batchDefaultsObject.hasOwnProperty(key)) {
                                const batchDefault = batchDefaultsObject[key];
                                if (batchDefault.objectApiName === element.objectApiName &&
                                    batchDefault.fieldApiName === element.fieldApiName) {
                                    if (!isUndefined(batchDefault.value)) {
                                        element.defaultValue = batchDefault.value;
                                    }
                                }
                            }
                        }
                    });
                });
            } catch (err) {
                handleError(err);
            }
        }
        return sections;
    }

    /**
     * @description Retrieves a records mapped target field values and
     *              loads them into the appropriate source fields in use
     *              on the Gift Entry form.
     * @param lookupFieldApiName Api name of the lookup field.
     * @param selectedRecordId Id of the selected record.
     */
    loadSelectedRecordFieldValues(lookupFieldApiName, selectedRecordId) {
        let selectedRecordFields =
            this.getSiblingFieldsForSourceField(lookupFieldApiName);

        if (selectedRecordId &&
            selectedRecordId.startsWith(this.oppPaymentKeyPrefix) &&
            this.selectedDonation.Id === selectedRecordId) {
            // This is the selected payment, so add in the parent opp field so
            // it can be used to populate the parent Opportunities' fields.
            selectedRecordFields.push(
                this.getQualifiedFieldName(OPP_PAYMENT_OBJECT, PARENT_OPPORTUNITY_FIELD));
        }

        this.storeSelectedRecordIdByObjectMappingName(
            this.getObjectMapping(lookupFieldApiName).DeveloperName,
            selectedRecordId
        );

        this.queueSelectedRecordForRetrieval(selectedRecordId, selectedRecordFields);
    }

    getQualifiedFieldName(objectInfo, fieldInfo) {
        return `${objectInfo.objectApiName}.${fieldInfo.fieldApiName}`;
    }

    get oppPaymentKeyPrefix() {
        return this.oppPaymentObjectInfo.data.keyPrefix;
    }

    get opportunityKeyPrefix() {
        return this.opportunityObjectInfo.data.keyPrefix;
    }

    get accountKeyPrefix() {
        return this.accountObjectInfo.data.keyPrefix;
    }

    get contactKeyPrefix() {
        return this.contactObjectInfo.data.keyPrefix;
    }

    getObjectMapping(fieldApiName) {
        return Object.values(GeFormService.objectMappings)
            .find(({Imported_Record_Field_Name}) =>
                Imported_Record_Field_Name == fieldApiName);
    }

    // Properties used to manage retrieval of fields for selected records
    selectedRecordIdByObjectMappingDevName = {};
    selectedRecordId;
    selectedRecordFields;
    getSelectedRecordStatus = 'ready';
    selectedRecordsQueue = [];

    @wire(getRecord, {recordId: '$selectedRecordId', optionalFields: '$selectedRecordFields'})
    getSelectedRecord({error, data}) {
        if (error) {
            handleError(error);
        } else if (data) {
            const dataImport = this.mapRecordValuesToDataImportFields(data);
            this.load(dataImport, false);

            // If the record being loaded is an object-mapped lookup, then set the
            // recordTypeId on its sibling fields
            if (data.recordTypeId &&
                Object.values(this.selectedRecordIdByObjectMappingDevName)
                    .includes(data.id)) {
                for (const [key, value] of
                    Object.entries(this.selectedRecordIdByObjectMappingDevName)) {
                    if (value === data.id) {
                        this.setRecordTypeOnFields(key, data.recordTypeId);
                    }
                }
            }

            if (this.oppPaymentObjectInfo.data.keyPrefix === data.id.substring(0, 3) &&
                data.id === this.selectedDonation.Id) {
                const oppId = this.parentOpportunityId(data);
                this.loadSelectedRecordFieldValues(DATA_IMPORT_DONATION_IMPORTED_FIELD.fieldApiName, oppId);
            }
        }

        // Get the next record if there is one in the queue
        if (this.selectedRecordsQueue.length > 0) {
            const nextSelectedRecord = this.selectedRecordsQueue.pop();
            this.selectedRecordId = nextSelectedRecord.selectedRecordId;
            this.selectedRecordFields = nextSelectedRecord.selectedRecordFields;
        } else {
            // If there are no records in the queue, set status back to 'ready'
            this.getSelectedRecordStatus = 'ready';
        }
    }

    parentOpportunityId(oppPaymentRecord) {
        return getFieldValue(oppPaymentRecord, PARENT_OPPORTUNITY_FIELD);
    }

    @wire(getObjectInfo, {objectApiName: OPP_PAYMENT_OBJECT.objectApiName})
    oppPaymentObjectInfo;

    @wire(getObjectInfo, {objectApiName: OPPORTUNITY_OBJECT.objectApiName})
    opportunityObjectInfo;

    @wire(getObjectInfo, {objectApiName: ACCOUNT_OBJECT.objectApiName})
    accountObjectInfo;

    @wire(getObjectInfo, {objectApiName: CONTACT_OBJECT.objectApiName})
    contactObjectInfo;

    mapRecordValuesToDataImportFields(record) {
        //reverse map to create an object with relevant source field api names to values
        let dataImport = {};

        let objectMappingDevNames = [];
        for (let [key, value] of Object.entries(
            this.selectedRecordIdByObjectMappingDevName)) {
            if (value === record.id) {
                objectMappingDevNames.push(key);
            }
        }

        for (const objectMappingName of objectMappingDevNames) {
            //relevant field mappings
            for (const fieldMapping of Object.values(GeFormService.fieldMappings)
                .filter(({Target_Object_Mapping_Dev_Name}) =>
                    Target_Object_Mapping_Dev_Name === objectMappingName)) {

                const value = record.fields[fieldMapping.Target_Field_API_Name];
                dataImport[fieldMapping.Source_Field_API_Name] = value;
            }
        }

        return dataImport;
    }

    storeSelectedRecordIdByObjectMappingName(objectMappingName, recordId) {
        this.selectedRecordIdByObjectMappingDevName[objectMappingName] = recordId;
    }

    handleChangeDonationDonor(event) {
        this.handleDonationDonorChange(event.detail.value);
    }

    get donorId() {
        switch (this._donationDonor) {
            case this.donationDonorEnum.account1:
                return this._account1Imported;
            case this.donationDonorEnum.contact1:
                return this._contact1Imported;
            default:
                return null;
        }
    }

    handleDonorAccountChange(selectedRecordId) {
        this._account1Imported = selectedRecordId;
        if (this._donationDonor === this.donationDonorEnum.account1) {
            this.setReviewDonationsDonorProperties(this._account1Imported);
        } else if (this._donationDonor === null) {
            // TODO: Maybe auto-set to 'Account1'?
        }
    }

    handleDonorContactChange(selectedRecordId) {
        this._contact1Imported = selectedRecordId;
        if (this._donationDonor === this.donationDonorEnum.contact1) {
            this.setReviewDonationsDonorProperties(this._contact1Imported);
        } else if (this._donationDonor === null) {
            // TODO: Maybe auto-set to 'Contact1'?
        }
    }

    handleDonationDonorChange(donationDonorValue) {
        this._donationDonor = donationDonorValue;
        if (!!this.selectedDonation) {
            this.resetDonationAndPaymentImportedFields();
        }
        this.setReviewDonationsDonorProperties(this.donorId);
    }

    setRecordTypeOnFields(objectMappingDevName, recordTypeId) {
        this.template.querySelectorAll('c-ge-form-section')
            .forEach(section => {
                section.setRecordTypeOnFields(objectMappingDevName, recordTypeId);
            });
    }

    getRecordTypeIdByName(recordTypeInfos, d) {
        return Object.values(recordTypeInfos)
            .find(recordTypeInfo => recordTypeInfo.name === d).recordTypeId;
    }

    getObjectMappingsForSourceField(fieldApiName) {
        return Object.values(GeFormService.fieldMappings)
            .filter(({Source_Field_API_Name}) => Source_Field_API_Name === fieldApiName)
            .map(({Target_Object_Mapping_Dev_Name}) => Target_Object_Mapping_Dev_Name);
    }

    get opportunityRecordTypeNames() {
        return Object.values(this.opportunityObjectInfo.data.recordTypeInfos)
            .map(({name}) => name);
    }

    /**
     * @description Queues selected record Ids (and fields) when getRecord is
     *              in the progress of retrieving another record's related fields.
     *              Prevents one lookup from overwriting the reactive selectedRecordId
     *              and selectedRecordFields properties before getRecord has returned
     *              with data.
     * @param selectedRecordId Id of record to be retrieved.
     * @param selectedRecordFields Fields list to be retrieved.
     */
    queueSelectedRecordForRetrieval(selectedRecordId, selectedRecordFields) {
        if (this.getSelectedRecordStatus == 'ready') {
            this.getSelectedRecordStatus = 'pending';
            this.selectedRecordId = selectedRecordId;
            this.selectedRecordFields = selectedRecordFields;
        } else {
            this.selectedRecordsQueue.push({selectedRecordId, selectedRecordFields});
        }
    }

}