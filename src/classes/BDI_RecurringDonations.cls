/*
    Copyright (c) 2020 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2020
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Helper class for the Batch Data Importer, dealing with Recurring Donations
*
*/

public class BDI_RecurringDonations {


    /*******************************************************************************************************
    * @description The Batch Data Import Service the helper should use
    */ 
    private BDI_DataImportService bdi { get; set; }

    /*******************************************************************************************************
    * @description map to track the Recurring Donation created/matched for each DI record
    */ 
    private Map<Id, npe03__Recurring_Donation__c> rdByDataImportId = new Map<Id, npe03__Recurring_Donation__c>();

    /*******************************************************************************************************
    * @description constructor for the BDI Recurring Donations helper
    * @param bdi The Batch Data Import Service the helper should use
    * @return void
    */ 
    public BDI_RecurringDonations(BDI_DataImportService bdi) {
        this.bdi = bdi;
    }


    private final String IMPORT_STATUS_FIELD = UTIL_Namespace.StrTokenNSPrefix('RecurringDonationImportStatus__c');
    private final String CONTACT_1 = 'Contact1';
    private final String ACCOUNT_1 = 'Account1';

    /*******************************************************************************************************
    * @description the map of DI Recurring Donation Fields to Recurring Donation Fields
    */
    public Map<String, String> dataImportFieldToRDField {
        get {
            if (dataImportFieldToRDField == null) {
                dataImportFieldToRDField = bdi.mapDataImportFields(
                    'Recurring_Donation', 'npe03__Recurring_Donation__c',
                    BDI_DataImportService.listStrDataImportFields);
            }
            return dataImportFieldToRDField;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Imports the appropriate Recurring Donations into NPSP
    * @return void
    */ 
    public void importRecurringDonations() {
        System.debug('inImportRecurringDonations with: ' + bdi.listDI) ;
        rdByDataImportId = new Map<Id, npe03__Recurring_Donation__c>();
        List<npe03__Recurring_Donation__c> rdsForInsert = new List<npe03__Recurring_Donation__c>();
        List<npe03__Recurring_Donation__c> rdsForUpdate = new List<npe03__Recurring_Donation__c>();

        List<DataImport__c> disForInsert = new List<DataImport__c>();
        List<DataImport__c> disForUpdate = new List<DataImport__c>();

        // get the list of DI records that have recurring donations to process
        List<DataImport__c> diWithValidRDInfo = validateRDToProcess();

        matchRecurringDonations(diWithValidRDInfo);

        for (DataImport__c dataImport : diWithValidRDInfo) {
            System.debug('Processing DI: ' + dataImport);

            try {
                npe03__Recurring_Donation__c rd = prepareRDForUpdateInsert(dataImport);
                System.debug('rd post-population: ' + rd);
                if (rd == null) {
                    continue;
                }

                if (rd.Id == null) {
                    rdsForInsert.add(rd);
                    disForInsert.add(dataImport);
                } else {
                    rdsForUpdate.add(rd);
                    disForUpdate.add(dataImport);
                }
            }catch (Exception ex) {
                bdi.LogBDIError(dataImport, ex.getMessage(), IMPORT_STATUS_FIELD);
            }
        }

        // Insert new Recurring Donations
        List<Database.SaveResult> results = UTIL_DMLService.insertRecords(rdsForInsert, false);
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];
            if (!result.isSuccess()) {
                System.debug('Insert Failure');
                bdi.LogBDIError(disForInsert[i], result.getErrors()[0].getMessage(), IMPORT_STATUS_FIELD);
            } else {
                disForInsert[i].RecurringDonationImported__c = rdsForInsert[i].Id;
                disForInsert[i].RecurringDonationImportStatus__c = System.Label.bdiCreated;

            }
        }
        
        // Update existing Recurring Donations
        results = UTIL_DMLService.updateRecords(rdsForUpdate, false);
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];
            if (!result.isSuccess()) {
                System.debug('Update Failure');
                System.debug('update error is: ' + result.getErrors());
                bdi.LogBDIError(disForUpdate[i], result.getErrors()[0].getMessage(), IMPORT_STATUS_FIELD);
            } else {
                disForUpdate[i].RecurringDonationImportStatus__c = System.Label.bdiUpdated;
            }
        }
        
    }

    /*******************************************************************************************************
    * @description Validate and determine which Data Import records have records to process.
    * @return List<DataImport__c> The list of BDI records that have donations to process
    */ 
    private List<DataImport__c> validateRDToProcess(){
        DataImport__c[] diWithRDForProcessing = new DataImport__c[]{};

        if (bdi.listDI == null) {
            return diWithRDForProcessing;
        }

        for (DataImport__c dataImport : bdi.listDI) {
            System.debug('beginning to validate di: ' + dataImport);
            // skip di that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            // If there are no RD fields on the DI populated then skip the record,
            if (!anyPopulatedRDFields(dataImport)) {
                continue;
            }

            //skip di that were created or update on a previous run since we don't 
            //want unnecessary updates.
            if (dataImport.RecurringDonationImportStatus__c == System.Label.bdiCreated || 
                dataImport.RecurringDonationImportStatus__c == System.Label.bdiUpdated) {
                continue;
            }

            //Throw errors if the selected donation donor is null
            //Also default the donation donor to Contact1 if none is provided.
            /*
            if (dataImport.Donation_Donor__c == CONTACT_1 || 
                (dataImport.Donation_Donor__c == null && dataImport.Recurring_Donation_Amount__c != null)) {
                dataImport.Donation_Donor__c = CONTACT_1;
                Contact con = bdi.ContactFromDi(dataImport, 1);
                if (con == null) {
                    bdi.LogBDIError(dataImport, System.Label.bdiErrorInvalidDonor, IMPORT_STATUS_FIELD);
                    continue;
                }
            } else if (dataImport.Donation_Donor__c == ACCOUNT_1) {
                Account acc = bdi.AccountFromDi(dataImport, 1);
                if (acc == null) {
                    bdi.LogBDIError(dataImport, System.Label.bdiErrorInvalidDonor, IMPORT_STATUS_FIELD);
                    continue;
                }
            } else if (dataImport.Donation_Donor__c != null) {
                bdi.LogBDIError(dataImport, System.Label.bdiErrorInvalidDonor, IMPORT_STATUS_FIELD);
                continue;
            }
            */
            System.debug('Adding DI to list for processing: ' + dataImport);
            diWithRDForProcessing.add(dataImport);
        }
        
        return diWithRDForProcessing;
    }

    /*******************************************************************************************************
    * @description Matches certain recurring donation fields against existing recurring donations.  This initial
    * version is just setting the import status to matched for records that have an Id populated in the recurring 
    * donation imported field.
    * @param disForMatching The data import records to match.
    */
    private void matchRecurringDonations(DataImport__c[] disForMatching) {
        System.debug('Matching Dis: ' + disForMatching);

        //Loop through the DIs and if there is a recurring donation id populated, then mark it as matched.
        //We don't need to actually query it to know it is matched since lookups already validate that it is a 
        //real id for a record that hasn't been deleted on insert of the DI.
        for (DataImport__c di : disForMatching) {
            if (di.RecurringDonationImported__c != null){
                System.debug('recurringDonationMatched');
                di.DonationImportStatus__c = System.label.bdiMatched;
                rdByDataImportId.put(di.Id,new npe03__Recurring_Donation__c(Id = di.RecurringDonationImported__c));
            }
            
        }
    }

    /*******************************************************************************************************
    * @description for the provided DataImport record, create or update the appropriate Recurring Donation (in memory)
    * with data from the DI record, and return it unsaved.
    *
    * @param dataImport The DataImport record to prepare the Recurring Donation for
    * @return npe03__Recurring_Donation__c A new or existing Recurring Donation. Null if there was an error.
    */
    private npe03__Recurring_Donation__c prepareRDForUpdateInsert(DataImport__c dataImport) {
        npe03__Recurring_Donation__c rd = rdByDataImportId.get(dataImport.Id);

        System.debug('rd received from map: ' + rdByDataImportId);
        String rdName = 'Temp';



        // if there is no rd matched, create one for it
        Boolean isNew = (rd == null);
        if (isNew) {
            rd = new npe03__Recurring_Donation__c();
            rdByDataImportId.put(dataImport.Id, rd);
            if (dataImport.Donation_Donor__c == ACCOUNT_1) {
                Account acc = bdi.AccountFromDi(dataImport, 1);
                rd.npe03__Organization__c = acc.Id;
            } else if (dataImport.Donation_Donor__c == CONTACT_1){ 
                // ADD ERROR HERE IF CONTACT IS NOT VALID
                Contact con = bdi.ContactFromDi(dataImport, 1);
                rd.npe03__Contact__c = con.Id;
            }
        }

        if (bdi.isDryRun) {
            return rd;
        }

        // Copy the data import fields to the Recurring Donation
        for (String dataImportField : dataImportFieldToRDField.keySet()) {
            System.debug('Mapping fields to RD: ' + dataImportField);

            BDI_DataImportService.copyDIFieldToDestinationRecord(dataImport, 
                    dataImportField, 
                    rd, 
                    dataImportFieldToRDField);
        }

        return rd;
    }

    private Boolean anyPopulatedRDFields(DataImport__c di){
        Boolean isPopulated = false;
        for (String diField : dataImportFieldToRDField.keySet()){
            
            if (di.get(diField) != null) {
                isPopulated = true;
                break;
            }
        }
        
        return isPopulated;
    }
}