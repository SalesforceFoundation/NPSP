import {LightningElement, api} from 'lwc';
import {setAccountId as setServiceAccountId} from 'c/geFormService';

export default class GeFormApp extends LightningElement {
    @api batchId;
    @api accountId;
    @api isBatchMode = false; // once we are loading from a batch, just batchId should be
    // sufficient

    //method used for testing until form is ready to be loaded with a Batch id
    handleBatchId(event) {
        this.batchId = event.target.value;
        this.isBatchMode = this.batchId ? true : false;

        const form = this.template.querySelector('c-ge-form-renderer');
        form.isBatchMode = this.isBatchMode;

        const table = this.template.querySelector('c-ge-form-table');
        table.setBatchId(event.target.value);
        table.loadBatch();
    }

    //method used for testing until form has Account/Contact Lookups or is ready to be loaded
    // with an Account Id
    handleAccountId(event) {
        this.accountId = event.target.value;
        const table = this.template.querySelector('c-ge-form-table');
        table.setAccountId(event.target.value);
        setServiceAccountId(event.target.value);
    }

    connectedCallback() {
        //The form will load in batch mode once we are passing a batch id into the app on
        // load, since the form responds to this property
        this.isBatchMode = this.batchId ? true : false;
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