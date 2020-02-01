import {LightningElement, api, track, wire} from 'lwc';
import GeFormService from 'c/geFormService';
import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import getFormRenderWrapper
    from '@salesforce/apex/GE_FormServiceController.getFormRenderWrapper';

export default class GeGiftEntryFormApp extends LightningElement {
    @api recordId;
    @api sObjectName;
    defaultTemplate = null;
    fieldMappingsByDevName;
    objectMappingsByDevName;
    isReady = false;

    @track isPermissionError;
    @track errorTitle;
    @track errorMessage;

    /**
     * Initialize the app by retrieving the default form render wrapper, which contains
     * the default form template and the field mappings from Advanced Mapping.
     */
    @wire(getFormRenderWrapper, {templateId: null})
    initializeDefaultTemplateAndMappings({data, error}){
        if (data) {
            this.defaultTemplate = data.formTemplate;

            this.fieldMappingsByDevName =
                data.fieldMappingSetWrapper.fieldMappingByDevName;
            this.objectMappingsByDevName =
                data.fieldMappingSetWrapper.objectMappingByDevName;

            GeFormService.setMappings(data.fieldMappingSetWrapper);

            this.isReady = true;
        } else if(error) {
            handleError(error);
        }
    }

    handleSubmit(event) {
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');

        GeFormService.saveAndDryRun(
            this.recordId, event.detail.data)
            .then(
                dataImportModel => {
                    Object.assign(dataImportModel.dataImportRows[0],
                        dataImportModel.dataImportRows[0].record);
                    table.upsertData(dataImportModel.dataImportRows[0], 'Id');
                    table.setTotalCount(dataImportModel.totalCountOfRows);
                    table.setTotalAmount(dataImportModel.totalAmountOfRows);
                    event.detail.success(); //Re-enable the Save button
                }
            )
            .catch(error => {
                event.detail.error(error);
            });
    }

    handleSectionsRetrieved(event) {
        const formSections = event.target.sections;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.handleSectionsRetrieved(formSections);
    }

    handleBatchDryRun() {
        //toggle the spinner on the form
        const form = this.template.querySelector('c-ge-form-renderer');
        const toggleSpinner = function () {
            form.showSpinner = !form.showSpinner
        };
        form.showSpinner = true;

        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.runBatchDryRun(toggleSpinner);
    }

    handleLoadData(event) {
        const form = this.template.querySelector('c-ge-form-renderer');
        form.load(event.detail);
    }

    handlePermissionErrors() {
        this.isPermissionError = true;
    }
    handleEditBatch() {
        this.dispatchEvent(new CustomEvent('editbatch'));
    }

    get isBatchMode() {
        return this.sObjectName &&
            this.sObjectName === DATA_IMPORT_BATCH_OBJECT.objectApiName;
    }

    handleReviewDonationsModal(event) {
        this.dispatchEvent(new CustomEvent('togglereviewdonationsmodal', { detail: event.detail }));
    }

}