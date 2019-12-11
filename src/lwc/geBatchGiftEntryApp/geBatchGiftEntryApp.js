import {LightningElement, api} from 'lwc';
import {setAccountId as setServiceAccountId} from 'c/geFormService';
import GeFormService from 'c/geFormService';
import ACCOUNT_1_IMPORTED_FIELD from
        '@salesforce/schema/DataImport__c.Account1Imported__c';
import DONATION_DONOR_FIELD from '@salesforce/schema/DataImport__c.Donation_Donor__c';
import NPSP_DATA_IMPORT_BATCH_FIELD
    from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';

export default class GeBatchGiftEntryApp extends LightningElement {
    @api recordId;

    // @api accountId;
    @api accountId = '0011k00000W4UMyAAN';

    //method used for testing until form has Account/Contact Lookups or is ready to be loaded
    // with an Account Id
    handleAccountId(event) {
        this.accountId = event.target.value;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.setAccountId(event.target.value);
        setServiceAccountId(event.target.value);
    }

    connectedCallback() {
        //Remove after dev::
        window.setTimeout(() => {
            const table = this.template.querySelector('c-ge-batch-gift-entry-table');
            table.setAccountId(this.accountId);
            setServiceAccountId(this.accountId);
        }, 2000);
        //END Remove after dev::
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
                    const processedDataRow = dataImportModel.dataImportRows[0].record;
                    processedDataRow.Id = dataImportModel.dataImportRows[0].record.Id;
                    processedDataRow.donorName = dataImportModel.dataImportRows[0].donorName;
                    processedDataRow.donorLink = dataImportModel.dataImportRows[0].donorLink;
                    processedDataRow.matchedRecordLabel = dataImportModel.dataImportRows[0].matchedRecordLabel;
                    processedDataRow.matchedRecordUrl = dataImportModel.dataImportRows[0].matchedRecordUrl;
                    processedDataRow.errors = dataImportModel.dataImportRows[0].errors;
                    table.upsertData(processedDataRow, 'Id');
                    event.detail.success(); //Re-enable the Save button
                }
            )
            .catch(error => {
                console.error(JSON.stringify(error));
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