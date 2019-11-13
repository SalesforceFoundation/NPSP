import {LightningElement, api} from 'lwc';

export default class GeFormApp extends LightningElement {
    @api batchId;
    @api isBatchMode = false;
    
    connectedCallback() {
        this.isBatchMode = this.batchId;
    }

    handleSubmit(event) {
        const latestSubmission =
            event.target.submissions[event.target.submissions.length - 1];
        const table = this.template.querySelector('c-ge-form-table');
        table.handleFormSubmission(latestSubmission);
    }

    handleSectionsRetrieved(event) {
        const formSections = event.target.sections;
        const table = this.template.querySelector('c-ge-form-table');
        table.handleSectionsRetrieved(formSections);
    }
}