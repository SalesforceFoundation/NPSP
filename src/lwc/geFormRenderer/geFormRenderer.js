import { LightningElement, api, track, wire } from 'lwc';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import geSave from '@salesforce/label/c.labelGeSave';
import geCancel from '@salesforce/label/c.labelGeCancel';
import { showToast, handleError } from 'c/utilTemplateBuilder';
import { getRecord } from 'lightning/uiRecordApi';
import FORM_TEMPLATE_FIELD from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import TEMPLATE_JSON_FIELD from '@salesforce/schema/Form_Template__c.Template_JSON__c';

export default class GeFormRenderer extends NavigationMixin(LightningElement) {
    @api sections = [];
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';
    @api showSpinner = false;
    @api batchId;
    @api submissions = [];
    @api hasPageLevelError = false;
    label = { messageLoading, geSave, geCancel };
    @track formTemplateId;
    erroredFields = [];
    @api pageLevelErrorMessageList = [];

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
        console.log('Form Cancel button clicked');
    }

    handleSave(event) {
        event.target.disabled = true;
        const enableSaveButton = function() {
            this.disabled = false;
        }.bind(event.target);

        this.clearErrors();

        // TODO: Pass the actual Data Import record, and navigate to the new Opportunity
        // const OpportunityId = GeFormService.createOpportunityFromDataImport(dataImport);
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');

        if(!this.isFormValid(sectionsList)){
            return;
        }

        // show the spinner
        this.toggleSpinner();

        // callback used to toggle spinner after save
        const toggleSpinner = () => this.toggleSpinner();

        if (this.batchId) {
            const submission = {
                sectionsList: sectionsList
            };
            this.submissions.push(submission);
            this.dispatchEvent(new CustomEvent('submit', {
                detail: {
                    success: function () {
                        enableSaveButton();
                        toggleSpinner();
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
}