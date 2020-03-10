import {LightningElement, api, wire} from 'lwc';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import {NavigationMixin} from 'lightning/navigation';

import NAME_FIELD from '@salesforce/schema/DataImportBatch__c.Name';
import BATCH_DRY_RUN_LABEL from '@salesforce/label/c.bgeBatchDryRun';
import PROCESS_BATCH_LABEL from '@salesforce/label/c.bgeProcessBatch';
import EDIT_BATCH_INFO_LABEL from '@salesforce/label/c.geEditBatchInfo';
import TAB_HEADER_LABEL from '@salesforce/label/c.bgeTabHeader';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import {handleError} from 'c/utilTemplateBuilder';

const DEFAULT_FIELD_MAPPING_SET = 'Migrated_Custom_Field_Mapping_Set';

export default class GeBatchGiftEntryHeader extends NavigationMixin(LightningElement) {

    batchDryRunLabel = BATCH_DRY_RUN_LABEL;
    processBatchLabel = PROCESS_BATCH_LABEL;
    editButtonLabel = EDIT_BATCH_INFO_LABEL;
    tabHeaderLabel = TAB_HEADER_LABEL;
    bdiDataImportPageName;

    @api batchId;
    @api isPermissionError;

    @wire(getRecord, {
        recordId: '$batchId',
        fields: NAME_FIELD
    })
    batch;

    get batchName() {
        return getFieldValue(this.batch.data, NAME_FIELD);
    }

    async connectedCallback() {
        try {
            await TemplateBuilderService.init(DEFAULT_FIELD_MAPPING_SET);
            this.bdiDataImportPageName =
                TemplateBuilderService.alignSchemaNSWithEnvironment('BDI_DataImport');
        } catch (error) {
            handleError(error);
        }
    }

    handleClick(event) {
        switch (event.target.label) {
            case BATCH_DRY_RUN_LABEL:
                this.dispatchEvent(new CustomEvent('batchdryrun'));
                break;
            case PROCESS_BATCH_LABEL:
                this.navigateToDataImportProcessingPage();
                break;
            case EDIT_BATCH_INFO_LABEL:
                this.editBatch();
                break;
        }
    }

    navigateToDataImportProcessingPage() {
        let url = '/apex/' + this.bdiDataImportPageName +
            '?batchId=' + this.batchId + '&retURL=' + this.batchId;

        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            },
            true
        );
    }

    navigateToBatchEditPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.batchId,
                actionName: 'edit'
            }
        });
    }

    editBatch() {
        this.dispatchEvent(new CustomEvent(
            'edit', {detail: this.batchId}
        ));
    }
}