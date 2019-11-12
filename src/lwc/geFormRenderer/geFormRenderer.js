import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';
import { NavigationMixin } from 'lightning/navigation';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import geSave from '@salesforce/label/c.labelGeSave';
import geCancel from '@salesforce/label/c.labelGeCancel';

export default class GeFormRenderer extends NavigationMixin(LightningElement) {
    @api sections = [];
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';
    @api showSpinner = false;
    @api isBatchMode = false;
    @api submissions = [];
    label = { messageLoading, geSave, geCancel };

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
                    this.dispatchEvent(new CustomEvent('sectionsretrieved'));
                }
            }

        });
    }

    handleCancel() {
        console.log('Form Cancel button clicked');
    }

    handleSave() {
        console.log('Form Save button clicked');

        // show the spinner
        this.toggleSpinner();

        // TODO: Pass the actual Data Import record, and navigate to the new Opportunity
        // const OpportunityId = GeFormService.createOpportunityFromDataImport(dataImport);
        const sectionsList = this.template.querySelectorAll('c-ge-form-section');

        if (this.isBatchMode) {
            console.log('this.submissions.length: ', this.submissions.length);
            const submission = {
                sectionsList: sectionsList,
                submissionId: this.submissions.length
            };
            // this.submissions = [...this.submissions, sectionsList];
            // sectionsList.submissionId = this.submissions.length;//First one should be zero
            // console.log('sectionsList: ', sectionsList);
            // console.log(JSON.parse(JSON.stringify(sectionsList)));
            this.submissions.push(submission);
            console.log('this.submissions: ', this.submissions);
            this.dispatchEvent(new CustomEvent('submit'));
            this.toggleSpinner();
        } else {
            GeFormService.handleSave(sectionsList).then(opportunityId => {
                this.navigateToRecordPage(opportunityId);
            });
        }
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