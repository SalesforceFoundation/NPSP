import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import geSave from '@salesforce/label/c.labelGeSave';
import geCancel from '@salesforce/label/c.labelGeCancel';
import { showToast, getQueryParameters } from 'c/utilTemplateBuilder';

export default class GeFormRenderer extends NavigationMixin(LightningElement) {
    @api recordId = '';
    @track apiName = '';
    @track sections = [];
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';
    @api showSpinner = false;
    label = { messageLoading, geSave, geCancel };

    @wire(getRecord, { recordId: '$recordId', optionalFields: ['Account.Name', 'Contact.Name']})
    wiredGetRecordMethod({ error, data }) {
        if (data) {
            this.apiName = data.apiName;
            this.handleGetTemplate();
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }

    connectedCallback() {
        // check if there is a record id in the url
        this.recordId = getQueryParameters().c__recordId;

        /*GeFormService.getFormTemplate(this.recordId).then(response => {
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
        });*/
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
                this.sections = formTemplate.layout.sections;
            }
        }
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