import {LightningElement, api} from 'lwc';

export default class GeFormApp extends LightningElement {
    @api batchId;
    @api isBatchMode = false;

    //method used for testing until form is ready to be loaded with a Batch id
    handleBatchId(event) {
        const table = this.template.querySelector('c-ge-form-table');
        table.loadBatch(event.target.value);

    }

    //method used for testing until form has Account/Contact Lookups or is ready to be loaded
    // with an Account Id
    handleAccountId(event) {
        this.accountId = event.target.value;
        const table = this.template.querySelector('c-ge-form-table');
        table.setAccountId(event.target.value);
    }

    connectedCallback() {
        this.isBatchMode = this.batchId !== undefined;
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