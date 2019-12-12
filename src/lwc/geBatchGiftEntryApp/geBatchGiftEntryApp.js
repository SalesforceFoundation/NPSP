import {LightningElement, api, track} from 'lwc';
import {setAccountId as setServiceAccountId} from 'c/geFormService';
import GeFormService from 'c/geFormService';
import ACCOUNT_1_IMPORTED_FIELD from
        '@salesforce/schema/DataImport__c.Account1Imported__c';
import DONATION_DONOR_FIELD from '@salesforce/schema/DataImport__c.Donation_Donor__c';
import NPSP_DATA_IMPORT_BATCH_FIELD
    from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';
import {handleError} from 'c/utilTemplateBuilder';

export default class GeBatchGiftEntryApp extends LightningElement {
    @api recordId;
    @track accountId;

    //method used for testing until form has Account/Contact Lookups or is ready to be loaded
    // with an Account Id
    handleAccountId(event) {
        this.accountId = event.target.value;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.setAccountId(event.target.value);
        setServiceAccountId(event.target.value);
    }

    handleSubmit(event) {
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        const dataRow = this.getTableDataRow(
            event.target.submissions[event.target.submissions.length - 1]
        );

        //simulate a lookup field being used to select an existing Account
        if (!dataRow[ACCOUNT_1_IMPORTED_FIELD.fieldApiName]) {
            dataRow[ACCOUNT_1_IMPORTED_FIELD.fieldApiName] = this.accountId;
        }
        if (!dataRow[DONATION_DONOR_FIELD.fieldApiName]) {
            dataRow[DONATION_DONOR_FIELD.fieldApiName] = 'Account1';
        }

        if (!dataRow[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName]) {
            dataRow[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName] = this.recordId;
        }

        GeFormService.saveAndDryRun(
            this.recordId, dataRow)
            .then(
                dataImportModel => {
                    Object.assign(dataImportModel.dataImportRows[0],
                        dataImportModel.dataImportRows[0].record);
                    table.upsertData(dataImportModel.dataImportRows[0], 'Id');
                    event.detail.success(); //Re-enable the Save button
                }
            )
            .catch(error => {
                handleError(error);
            });
    }

    getTableDataRow(formSubmission) {
        let dataImportRecord =
            GeFormService.getDataImportRecord(formSubmission.sectionsList);
        dataImportRecord.submissionId = formSubmission.submissionId;
        return dataImportRecord;
    }

    handleSectionsRetrieved(event) {
        const formSections = event.target.sections;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.handleSectionsRetrieved(formSections);
    }
}