import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormRenderer extends LightningElement {
    @track sections = [];
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';

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
        console.log('Form Save button clicked');
        // TODO: Pass the actual Data Import record, and navigate to the new Opportunity
        // const OpportunityId = GeFormService.createOpportunityFromDataImport(dataImport);
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');
        
        const opportunityId = GeFormService.handleSave(sectionsList);
    }
}