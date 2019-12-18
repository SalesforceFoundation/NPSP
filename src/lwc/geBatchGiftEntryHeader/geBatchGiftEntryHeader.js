import {LightningElement, api, wire} from 'lwc';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import {NavigationMixin} from 'lightning/navigation';

import NAME_FIELD from '@salesforce/schema/DataImportBatch__c.Name';
import BATCH_DRY_RUN_LABEL from '@salesforce/label/c.bgeBatchDryRun';
import PROCESS_BATCH_LABEL from '@salesforce/label/c.bgeProcessBatch';
import EDIT_BUTTON_LABEL from '@salesforce/label/c.stgBtnEdit';
import TAB_HEADER_LABEL from '@salesforce/label/c.bgeTabHeader';

import alignClassNSWithEnvironment
    from '@salesforce/apex/UTIL_Namespace.alignClassNSWithEnvironment';
import {handleError} from 'c/utilTemplateBuilder';

export default class GeBatchGiftEntryHeader extends NavigationMixin(LightningElement) {

    batchDryRunLabel = BATCH_DRY_RUN_LABEL;
    processBatchLabel = PROCESS_BATCH_LABEL;
    editButtonLabel = EDIT_BUTTON_LABEL;
    tabHeaderLabel = TAB_HEADER_LABEL;
    bdiDataImportPageName;

    @api batchId;

    @wire(getRecord, {
        recordId: '$batchId',
        fields: NAME_FIELD
    })
    batch;

    get batchName() {
        return getFieldValue(this.batch.data, NAME_FIELD);
    }

    connectedCallback() {
        alignClassNSWithEnvironment({name:'BDI_DataImport'})
            .then(bdiDataImportPageName => {
                this.bdiDataImportPageName = bdiDataImportPageName;
            })
            .catch(error => handleError(error));
    }

    handleClick(event) {
        switch (event.target.label) {
            case BATCH_DRY_RUN_LABEL:
                this.dispatchEvent(new CustomEvent('batchdryrun'));
                break;
            case PROCESS_BATCH_LABEL:
                this.navigateToDataImportProcessingPage();
                break;
            case EDIT_BUTTON_LABEL:
                //TODO:load batch into new hge batch creation/editing wizard when ready
                this.navigateToBatchEditPage();
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
}