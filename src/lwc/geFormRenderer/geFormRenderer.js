import { LightningElement, api, track } from 'lwc';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import geSave from '@salesforce/label/c.labelGeSave';
import geCancel from '@salesforce/label/c.labelGeCancel';
import { showToast } from 'c/utilTemplateBuilder';

export default class GeFormRenderer extends NavigationMixin(LightningElement) {
    @track sections = [];
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';
    @api showSpinner = false;
    @api hasPageLevelError = false;
    @api pageLevelErrorMessage = '';
    label = { messageLoading, geSave, geCancel };
    erroredFields = [];

    connectedCallback() {
        GeFormService.getFormTemplate().then(response => {
            // read the template header info
            if(response !== null && typeof response !== 'undefined') {
                const { formTemplate } = response;
                this.ready = true;
                this.name = formTemplate.name;
                this.description = formTemplate.description;
                this.version = formTemplate.layout.version;
                if (typeof formTemplate.layout !== 'undefined'
                        && Array.isArray(formTemplate.layout.sections)) {
                    this.sections = formTemplate.layout.sections;
                }
            }

        });
    }

    handleCancel() {
        console.log('Form Cancel button clicked');
    }

    handleSave() {
        this.clearErrors();

        // TODO: Pass the actual Data Import record, and navigate to the new Opportunity
        // const OpportunityId = GeFormService.createOpportunityFromDataImport(dataImport);
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');

        if(!this.isFormValid(sectionsList)){
            return;
        }

        // show the spinner
        this.toggleSpinner();
        
        GeFormService.handleSave(sectionsList).then(opportunityId => {
            this.navigateToRecordPage(opportunityId);
        })
        .catch(error => {

            this.toggleSpinner();
            
            // Show on top if it is a page level
            this.hasPageLevelError = true;
            let exceptionWrapper = JSON.parse(error.body.message);
            const allDisplayedFields = this.getDisplayedFieldsMappedByAPIName(sectionsList);

            if (exceptionWrapper.exceptionType != null && exceptionWrapper.exceptionType != '') {

                // Check to see if there are any field level errors
                if (Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length == undefined || Object.entries(exceptionWrapper.DMLErrorFieldNameMapping).length === 0) {
                    
                    // If there are no specific fields the error has to go to, put it on the page level error message. 
                    this.setPageLevelError(Object.values(exceptionWrapper.DMLErrorMessageMapping).join(', '));
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

                        for (var i = 0; i < fieldList.length; i++) {
                            const fieldWithError = fieldList[i];

                            // Go to the field and set the error message using setCustomValidity 
                            if (fieldWithError in allDisplayedFields) {
                                var fieldInput = allDisplayedFields[fieldWithError];
                                this.erroredFields.push(fieldInput);

                                fieldInput.setCustomValidity(errorMessage);
                                
                            } else {

                                // Keep track of errored fields that are not displayed.  
                                hiddenFieldList.push(fieldWithError);
                            }
                        }

                        // If there are hidden fields, display the error message at the page level. 
                        // With the fields noted. 
                        if (hiddenFieldList.length > 0) {
                            var combinedFields = hiddenFieldList.join(', ');

                            this.addToPageLevelError(errorMessage + ' [' + combinedFields + ']');
                        }
                    }
                }
            } else {
                this.setPageLevelError(exceptionWrapper.errorMessage);
            }

            // focus either the page level or field level error messsage somehow
            window.scrollTo(0,0);
        }) ;
    }

    isFormValid(sectionsList){
        let invalidFields = [];
        sectionsList.forEach(section => {
            const fields = section.getInvalidFields();
            invalidFields.push(...fields);
        });

        if(invalidFields.length > 0){
            let fieldListAsString = invalidFields.join(', ');
            showToast(this, 'Invalid Form', 'The following fields are required: ' + fieldListAsString, 'error');
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
        this.pageLevelErrorMessage = '';

        // Clear the field level errors
        if (this.erroredFields.length > 0) {
            for (var field in this.erroredFields) {
                var fieldToReset = this.erroredFields[field];

                fieldToReset.setCustomValidity('');
            }
        }

        this.erroredFields = [];
    }

    setPageLevelError(errorMessage) {
        this.pageLevelErrorMessage = errorMessage;
    }

    addToPageLevelError(errorMessage) {
        this.pageLevelErrorMessage += '\n' + errorMessage;
    }
}