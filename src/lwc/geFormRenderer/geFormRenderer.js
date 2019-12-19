import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import geSave from '@salesforce/label/c.labelGeSave';
import geCancel from '@salesforce/label/c.labelGeCancel';
import { showToast, getQueryParameters, getRecordFieldNames, isEmpty, deepClone } from 'c/utilTemplateBuilder';

export default class GeFormRenderer extends NavigationMixin(LightningElement) {
    @api recordId = '';
    @api record;
    apiName = '';
    fieldNames = [];

    @track sections = [];
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';
    @api showSpinner = false;
    label = { messageLoading, geSave, geCancel };

    @wire(getRecord, { recordId: '$recordId', optionalFields: '$fieldNames'})
    wiredGetRecordMethod({ error, data }) {
        if (data) {
            this.apiName = data.apiName;
            this.record = data;
            this.handleGetTemplate();
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }

    connectedCallback() {
        // check if there is a record id in the url
        this.recordId = getQueryParameters().c__recordId;

        GeFormService.getFormTemplate(this.recordId, this.apiName).then(response => {
            // read the template header info
            if(response !== null && typeof response !== 'undefined') {
                const { formTemplate } = response;
                let fieldMappings = response.fieldMappingSetWrapper.fieldMappingByDevName;

                // get the target field names to be used by getRecord
                this.fieldNames = getRecordFieldNames(formTemplate, fieldMappings);
            }
        });
    }

    handleGetTemplate = async () => {
        let response = await GeFormService.getFormTemplate(this.recordId, this.apiName);

        if (response !== null && typeof response !== 'undefined') {
            const { formTemplate } = response;
            this.ready = true;
            this.name = formTemplate.name;
            this.description = formTemplate.description;
            this.version = formTemplate.layout.version;
            if (typeof formTemplate.layout !== 'undefined'
                && Array.isArray(formTemplate.layout.sections)) {

                // TODO - vm
                //this.sections = formTemplate.layout.sections;
                let sectionsWithValues = this.setRecordValuesOnTemplate(formTemplate.layout.sections);
                this.sections = sectionsWithValues;
            }
        }
    }

    // adds the record values to the template elements so they can be rendered
    setRecordValuesOnTemplate(templateSections) {
        if (isEmpty(this.record)) {
            return templateSections;
        }

        // we have a contact or account record
        let sections = deepClone(templateSections);

        sections.forEach(section => {
            const elements = section.elements;
            elements.forEach(element => {
                //alert(JSON.stringify(element));
                alert(element.label);
                if (element.label === 'Contact 1: First Name') {
                    element.recordValue = 'Bart';
                    //element.dataImportFieldMappingDevNames = ['Contact1_First_Name_3fac9de77'];
                } else {
                    element.recordValue = '';
                }
                
            });                 
        });

        return sections;
    }

    handleCancel() {
        console.log('Form Cancel button clicked');
    }

    handleSave() {
        console.log('Form Save button clicked');

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
        });
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
}