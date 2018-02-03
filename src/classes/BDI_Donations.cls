/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Helper class for the Batch Data Importer, dealing with Donations, ie, Opps and Payments
*
*/
public class BDI_Donations {

    /*******************************************************************************************************
    * @description constructor for the BDI Donations helper
    * @param bdi The Batch Data Import Service the helper should use
    * @return void
    */ 
    public BDI_Donations(BDI_DataImportService bdi) {
        this.bdi = bdi;
    }

    /*******************************************************************************************************
    * @description The Batch Data Import Service the helper should use
    */ 
    private BDI_DataImportService bdi { get; set; }
    
    /*******************************************************************************************************
    * @description map to track the Opportunity created/matched for each DI record
    */ 
    private map<Id, Opportunity> mapDIIdToOpp = new map<Id, Opportunity>();

    /*******************************************************************************************************
    * @description map to track the Payment created/matched for each DI record
    */ 
    private map<Id, npe01__OppPayment__c> mapDIIdToPmt = new map<Id, npe01__OppPayment__c>();
    
    /*******************************************************************************************************
    * @description provides a valid Close Won Opportunity Stage
    */
    private static string defaultClosedWonStage {
        get {   
            if (defaultClosedWonStage == null){
                List<OpportunityStage> listStg = [select masterlabel from opportunitystage where isActive = true and iswon = true];
                if (listStg.size() > 0) {
                    defaultClosedWonStage = listStg[0].masterlabel;
                } else {
                    defaultClosedWonStage = '';
                }
            }
            return defaultClosedWonStage;
        }
        set;
    }

    /*******************************************************************************************************
    * @description our exception class
    */
    private class BDIException extends Exception {}

    /*******************************************************************************************************
    * @description the class object that supports the BDI_IMatchDonations interface
    */
    private BDI_IMatchDonations iMatchDonations {
        get {
            if (iMatchDonations == null) {
                iMatchDonations = (BDI_IMatchDonations)BDI_DataImportService.instantiateClassForInterface('BDI_IMatchDonations',
                    bdi.diSettings.Donation_Matching_Implementing_Class__c);
                if (iMatchDonations == null) {
                    iMatchDonations = new BDI_MatchDonations();
                }
            }
            return iMatchDonations;
        }
        set;
    }
    
    /*******************************************************************************************************
    * @description the map of DI Donation Fields to Opportunity Fields
    */
    public static map<String, String> mapDIFieldToOppField {
        get {
            if (mapDIFieldToOppField == null) {
                mapDIFieldToOppField = BDI_DataImportService.mapFieldsForDIObject('Opportunity', 'Opportunity', 
                    BDI_DataImportService.listStrDataImportFields);
            }
            return mapDIFieldToOppField;
        }
        set;
    }
    
    /*******************************************************************************************************
    * @description the map of DI Donation Fields to Payment Fields
    */
    public static map<string, string> mapDIFieldToPmtField { 
        get {
            if (mapDIFieldToPmtField == null) {
                mapDIFieldToPmtField = BDI_DataImportService.mapFieldsForDIObject('Payment', 'npe01__OppPayment__c', 
                    BDI_DataImportService.listStrDataImportFields);
            }
            return mapDIFieldToPmtField;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Imports the appropriate Donations into NPSP, following matching rules and criteria
    * to potentially match existing Opportunities or Payments.
    * @return void
    */ 
    public void importDonations() {
    
        // get our matching behavior to use
        string matchBehavior = bdi.diSettings.Donation_Matching_Behavior__c;

        // get the list of DI records that have donations to process
        list<DataImport__c> listDIDonations = validateDonationsToProcess(matchBehavior);
        
        // call the extension to match against existing donations
        if (matchBehavior != BDI_DataImport_API.DoNotMatch) {
            BDI_PerfLogger.PerfLog pl = BDI_DataImportService.perfLogger.newPerfLog('iMatchDonations.match');
            iMatchDonations.match(bdi, listDIDonations, mapDIIdToOpp, mapDIIdToPmt);
            pl.stop();
        }
        
        // now go thru the new & existing donations and update them
        list<Opportunity> listOppInsert = new list<Opportunity>();
        list<Opportunity> listOppUpdate = new list<Opportunity>();
        list<DataImport__c> listDIInsert = new list<DataImport__c>();
        list<DataImport__c> listDIUpdate = new list<DataImport__c>();
        
        for (DataImport__c di : listDIDonations) {
            // validate against our desired matching behavior (exact match, best match, new, etc.)
            if (!isValidMatchBehavior(di, matchBehavior)) {
                continue;
            }
            
            // update the new or existing Opp with the DI's field data
            Opportunity opp = prepareOppForUpdateInsert(di);
            
            // handle any error from the prepare
            if (opp == null) {
                continue;
            }
            
            if (opp.Id == null) {
                listOppInsert.add(opp);
                listDIInsert.add(di);
            } else {
                listOppUpdate.add(opp);
                listDIUpdate.add(di);
            }
            
            // for some error handling detection tests  
            if (Test.isRunningTest() && opp.Name != null && opp.Name.startsWith('FailTest'))
                opp.Name = null;
        }

        if (bdi.isDryRun) {
            setDryRunDonationStatuses(listDIDonations);
            return;
        }
        
        // insert our new Opps
        list<Database.SaveResult> listSR = UTIL_DMLService.insertRecords(listOppInsert, false);
        for (integer i = 0; i < listSR.size(); i++) {
            Database.SaveResult sr = listSR[i];
            if (!sr.isSuccess()) {
                bdi.LogBDIError(listDIInsert[i], sr.getErrors()[0].getMessage(), 'DonationImportStatus__c');
            } else {
                listDIInsert[i].DonationImported__c = listOppInsert[i].Id;
                listDIInsert[i].DonationImportStatus__c = label.bdiCreated;
            }
        }
        
        // update our matched Opps
        listSR = UTIL_DMLService.updateRecords(listOppUpdate, false);
        for (integer i = 0; i < listSR.size(); i++) {
            Database.SaveResult sr = listSR[i];
            if (!sr.isSuccess()) {
                bdi.LogBDIError(listDIUpdate[i], sr.getErrors()[0].getMessage(), 'DonationImportStatus__c');
            }
        }

        // mark any paid Payments we matched
        markPaidPayments(listDIDonations);

        // add any new payments to our map
        trackPayments(listDIDonations);
        
        // when we mark Payments paid, ensure they will close our Opp.
        npe01__Contacts_And_Orgs_Settings__c cs = UTIL_CustomSettingsFacade.getContactsSettings();
        if (cs.Payments_Auto_Close_Stage_Name__c == null) {
            cs.Payments_Auto_Close_Stage_Name__c = defaultClosedWonStage;
        }
        
        // update payments with any data from the DI record
        updatePayments(listDIDonations);      
    }

    /*******************************************************************************************************
    * @description validate bdi records for donations and return those to process
    * @param matchBehavior The match behavior to validate against
    * @return list<DataImport__c> The list of BDI records that have donations to process
    */ 
    private list<DataImport__c> validateDonationsToProcess(string matchBehavior) {
        list<DataImport__c> listDIDonations = new list<DataImport__c>();
        for (DataImport__c di : bdi.listDI) {
            
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed) {
               continue;
            }
            
            // skip di's that have an OppId or PaymentId, but we were told to do no matching.  in this case
            // they must have already been created for this di on a previous run, and we don't want to create another.
            if ((di.DonationImported__c != null || di.PaymentImported__c != null) && matchBehavior == BDI_DataImport_API.DoNotMatch) {
                continue;
            }
                
            if (di.Donation_Donor__c == 'Contact1' || (di.Donation_Donor__c == null && di.Donation_Amount__c != null)) {
                di.Donation_Donor__c = 'Contact1';
                Contact con = bdi.ContactFromDi(di, 1);
                if (con == null) {
                    bdi.LogBDIError(di, label.bdiErrorInvalidDonor, 'DonationImportStatus__c');
                    continue;
                }
            } else if (di.Donation_Donor__c == 'Account1') {
                Account acc = bdi.AccountFromDi(di, 1);
                if (acc == null) {
                    bdi.LogBDIError(di, label.bdiErrorInvalidDonor, 'DonationImportStatus__c');
                    continue;
                }
            } else if (di.Donation_Donor__c != null) {
                bdi.LogBDIError(di, label.bdiErrorInvalidDonor, 'DonationImportStatus__c');
                continue;
            } else {
                // this DI record does not have a donation!
                continue;
            }
            // add the donation to our list
            listDIDonations.add(di);
        }
        return listDIDonations;
    }
    
    /*******************************************************************************************************
    * @description validate whether the current donation record was appropriately matched to an exact,
    * best, or new donation record given the matchingBehavior.  Invalid matches will be marked as an
    * error in the DI record.
    *
    * @param di The DataImport record to validate
    * @param matchBehavior The match behavior to validate against
    * @return boolean True if valid, False if not
    */ 
    private boolean isValidMatchBehavior(DataImport__c di, string matchBehavior) {
        string strError;

        // always allow matching by Id, regardless of specified behavior
        if (di.DonationImportStatus__c == label.bdiMatchedId) {
            return true;
        }
        // always error if they provided Donation or Payment ID, but it wasn't valid
        if ((di.DonationImported__c != null || di.PaymentImported__c != null) && di.DonationImportStatus__c == label.bdiMatchedNone) {
            strError = label.bdiErrorDonationLookupMatch;
            // usually we clear the payment status, but if it's Id might have been at fault, let's put the message there too!
            if (di.PaymentImported__c != null) {
                di.PaymentImportStatus__c = label.bdiErrorDonationLookupMatch;
            }
        }
        else if (matchBehavior == BDI_DataImport_API.RequireNoMatch && di.DonationImported__c != null) {
            strError = label.bdiErrorDonationRequireNoMatch;
        }
        else if (matchBehavior == BDI_DataImport_API.RequireExactMatch && di.Payment_Possible_Matches__c != null) {
            strError = label.bdiErrorPaymentMultiMatch;
        }
        else if (matchBehavior == BDI_DataImport_API.RequireExactMatch && di.Donation_Possible_Matches__c != null) {
            strError = label.bdiErrorDonationMultiMatch;
        } 
        else if (matchBehavior == BDI_DataImport_API.RequireExactMatch && di.DonationImported__c == null) {
            strError = label.bdiErrorDonationNoMatch;
        } 
        else if (matchBehavior == BDI_DataImport_API.ExactMatchOrCreate && di.Donation_Possible_Matches__c != null) {
            strError = label.bdiErrorDonationMultiMatch;
        }
        else if (matchBehavior == BDI_DataImport_API.RequireBestMatch && di.DonationImported__c == null) {
            strError = label.bdiErrorDonationNoMatch;
        }
        else { 
            // valid behavior
            return true;
        }

        // clear the match so it won't be used (but only if we think the user didn't put it in themselves!)
        if (strError != label.bdiErrorDonationLookupMatch) {
    
            // move any match that we reject to possible matches
            if (di.Donation_Possible_Matches__c == null) {
                di.Donation_Possible_Matches__c = di.DonationImported__c;
            }
            if (di.Payment_Possible_Matches__c == null) {
                di.Payment_Possible_Matches__c = di.PaymentImported__c;
            }

            di.DonationImported__c = null;
            di.PaymentImported__c = null;
            di.PaymentImportStatus__c = strError;
        }

        // invalid behavior
        bdi.LogBDIError(di, strError, 'DonationImportStatus__c');        
        return false;
    }
    
    /*******************************************************************************************************
    * @description for the provided DataImport record, create or update the appropriate Opp (in memory)
    * with data from the DI record, and return it unsaved.
    *
    * @param di The DataImport record to prepare the Opportunity for
    * @return Opportunity A new or existing Opportunity. Null if there was an error.
    */ 
    private Opportunity prepareOppForUpdateInsert(DataImport__c di) {        
        Opportunity opp = mapDIIdToOpp.get(di.Id);
        string strOppName;

        // if there is no opp matched, create one for it
        boolean isNew = (opp == null);
        if (isNew) {
            opp = new Opportunity();
            mapDIIdToOpp.put(di.Id, opp);
            if (di.Donation_Donor__c == 'Account1') {
                Account acc = bdi.AccountFromDi(di, 1);
                opp.accountId = acc.Id;
                strOppName = acc.Name;
            } else { // we can assume it's for Contact1
                Contact con = bdi.ContactFromDi(di, 1);
                opp.npe01__Contact_Id_for_Role__c = con.Id;
                opp.Primary_Contact__c = con.Id;
                opp.Primary_Contact_Campaign_Member_Status__c = di.Campaign_Member_Status__c;
                opp.AccountId = con.AccountId;
                strOppName = con.Firstname + ' ' + con.Lastname;
            }
        }

        if (di.Donation_Record_Type_Name__c != null) {
            Id idRt = UTIL_RecordTypes.GetRecordTypeId(Opportunity.sObjectType, di.Donation_Record_Type_Name__c);
            if (idRt == null) {
                bdi.LogBDIError(di, label.bdiErrorInvalidOppRTName, 'DonationImportStatus__c');
                return null;
            }
            opp.RecordTypeId = idRt;
            strOppName += ' ' + di.Donation_Record_Type_Name__c;
        } else {
            strOppName += ' ' + label.bdiDonation;
        }

        // in Dry Run, we don't save campaigns, nor do we try to validate that all of the
        // updates to the object would succeed, so we should bail out now. (we didn't just bail
        // out at the beginning, so we would do the record type validation).
        if (bdi.isDryRun) {
            return opp;
        }

        if (di.Donation_Campaign_Name__c != null) {
            Id idCmp = bdi.mapStrNameToCampaignId.get(di.Donation_Campaign_Name__c);
            if (idCmp == null) {
                bdi.LogBDIError(di, label.bdiErrorInvalidCampaignName, 'DonationImportStatus__c');
                return null;
            }
            opp.CampaignId = idCmp;
        }

        if (di.Donation_Date__c == null) {
            if (isNew) {
                di.Donation_Date__c = system.today();
            } else {
                di.Donation_Date__c = opp.CloseDate;
            }
        }

        if (di.Donation_Name__c == null) {
            if (isNew) {
                di.Donation_Name__c = strOppName + ' ' + di.Donation_Date__c.format();
            } else {
                di.Donation_Name__c = opp.Name;
            }
        }

        if (di.Donation_Stage__c == null && defaultClosedWonStage != '' && di.PaymentImported__c == null) {
            di.Donation_Stage__c = defaultClosedWonStage;
        }

        // now copy over all the data to the Opp
        for (string strDIField : mapDIFieldToOppField.keySet()) {
            // skip recordtype which we special cased above
            if (strDIField == UTIL_Namespace.StrTokenNSPrefix('Donation_Record_Type_Name__c').toLowercase()) {
                continue;
            }
            // only honor Stage if we aren't updating its payment
            if (strDIField == UTIL_Namespace.StrTokenNSPrefix('Donation_Stage__c').toLowercase() && di.PaymentImported__c != null) {
                continue;
            }
            // only honor Amount if we aren't updating its payment
            if (strDIField == UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c').toLowercase() && di.PaymentImported__c != null) {
                continue;
            }
            BDI_DataImportService.isCopiedDIField(di, strDIField, opp, mapDIFieldToOppField);
        }

        // the Opp is ready!
        return opp;
    }

    /*******************************************************************************************************
    * @description Updates the Donation Status in the provided donations to the Dry Run appropriate Status.
    * @param listDIDonations The DI Records that have donations to import
    * @return void
    */
    private void setDryRunDonationStatuses(list<DataImport__c> listDIDonations) {

        for (DataImport__c di : listDIDonations) {

            // opps
            if (di.DonationImportStatus__c == BDI_DataImport_API.bdiFailed) {
                di.DonationImportStatus__c = bdi.statusDIFailed();
            } else if (di.DonationImportStatus__c == label.bdiMatched) {
                di.DonationImportStatus__c = bdi.statusMatchedExisting();
            } else if (di.DonationImportStatus__c == label.bdiMatchedBest) {
                di.DonationImportStatus__c = bdi.statusMatchedBest();
            } else if (di.DonationImportStatus__c == label.bdiMatchedId) {
                di.DonationImportStatus__c = bdi.statusMatchedById();
            } else if (di.DonationImportStatus__c == label.bdiMatchedNone) {
                di.DonationImportStatus__c = bdi.statusMatchedNone();
            }

            // payments
            if (di.PaymentImportStatus__c == BDI_DataImport_API.bdiFailed) {
                di.PaymentImportStatus__c = bdi.statusDIFailed();
            } else if (di.PaymentImportStatus__c == label.bdiMatched) {
                di.PaymentImportStatus__c = bdi.statusMatchedExisting();
            } else if (di.PaymentImportStatus__c == label.bdiMatchedBest) {
                di.PaymentImportStatus__c = bdi.statusMatchedBest();
            } else if (di.PaymentImportStatus__c == label.bdiMatchedId) {
                di.PaymentImportStatus__c = bdi.statusMatchedById();
            } else if (di.PaymentImportStatus__c == label.bdiMatchedNone) {
                di.PaymentImportStatus__c = bdi.statusMatchedNone();
            }
        }
    }

    /*******************************************************************************************************
    * @description marks Payments that we matched as Paid, and with correct date and amount
    * @param listDIDonations The DI Records that have donations to import
    * @return void
    */
    public void markPaidPayments(list<DataImport__c> listDIDonations) {

        // mark existing Payments paid.
        list<ID> listOppId = new list<ID>();
        for (DataImport__c di : listDIDonations) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            if (di.PaymentImported__c != null) {
                npe01__OppPayment__c pmt = mapDIIdToPmt.get(di.Id);
                pmt.npe01__Paid__c = true;
                pmt.npe01__Payment_Amount__c = di.Donation_Amount__c;
                if (pmt.npe01__Payment_Date__c == null) {
                    pmt.npe01__Payment_Date__c = di.Donation_Date__c;
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Updates our map of DI records to Payments to include the Payments just auto-created
    * when we created new Opps, or pmt's for matched Opps that we haven't yet tracked.
    * @param listDIDonations The DI Records that have donations to import
    * @return void
    */ 
    public void trackPayments(list<DataImport__c> listDIDonations) {
        
        // find the Opps for our missing payments and mark existing Payments paid.
        list<ID> listOppId = new list<ID>();        
        for (DataImport__c di : listDIDonations) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
               continue;
            if (di.DonationImported__c != null && di.PaymentImported__c == null) {
                listOppId.add(di.DonationImported__c);
            }
        }

        // query for the new payments
        if (listOppId.size() > 0) {
            map<Id, npe01__OppPayment__c> mapOppIdToPayment = new map<Id, npe01__OppPayment__c>();
            for (npe01__OppPayment__c pmt : database.query(strSoqlForPayments())) {
                mapOppIdToPayment.put(pmt.npe01__Opportunity__c, pmt);
            }

            // store the Payments into our shared map and update their DI record
            for (DataImport__c di : listDIDonations) {
                // skip di's that already have an error
                if (di.Status__c == BDI_DataImport_API.bdiFailed)
                    continue;
                if (di.DonationImported__c != null && di.PaymentImported__c == null) {
                    npe01__OppPayment__c pmt = mapOppIdToPayment.get(di.DonationImported__c);
                    if (pmt != null) {
                        di.PaymentImported__c = pmt.Id;
                        di.PaymentImportStatus__c = di.DonationImportStatus__c; // could be new or matched
                        mapDIIdToPmt.put(di.Id, pmt);
                    }
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description returns the soql to use for querying Payments
    * @return String the soql string
    */
    private String strSoqlForPayments() {
        // the set of Payment fields for our soql
        set<String> setPmtFields = new set<String>();
        setPmtFields.add('Id');
        setPmtFields.add('npe01__Opportunity__c');
        setPmtFields.add('npe01__Payment_Amount__c');
        setPmtFields.add('npe01__Payment_Date__c');
        setPmtFields.add('npe01__Scheduled_Date__c');
        setPmtFields.add('npe01__Paid__c');

        // need to include any Pmt fields we may update, so we can compare against them
        setPmtFields.addAll(mapDIFieldToPmtField.values());

        String strSoql = 'SELECT ' + string.join(new list<String>(setPmtFields), ',');
        strSoql += ' FROM npe01__OppPayment__c WHERE npe01__Opportunity__c in :listOppId';

        return strSoql;
    }

    /*******************************************************************************************************
    * @description Updates any fields on payment objects created for the Data Import opportunities.
    * @param listDIDonations The DI Records that have donations to import
    * @return void
    */
    public void updatePayments(list<DataImport__c> listDIDonations) {

        list<npe01__OppPayment__c> listPmtUpdate = new list<npe01__OppPayment__c>();
        list<DataImport__c> listDIUpdate = new list<DataImport__c>();
        
        // update payments
        for (DataImport__c di : listDIDonations) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
               continue;            
            if (di.PaymentImported__c != null) {
                npe01__OppPayment__c pmt = mapDIIdToPmt.get(di.Id);
                if (pmt != null) {
                    integer cPropSet = 0;
                    for (string strDIField : mapDIFieldToPmtField.keySet()) {
                        if (BDI_DataImportService.isCopiedDIField(di, strDIField, pmt, mapDIFieldToPmtField)) {
                            cPropSet++;
                        }
                    }
                    // if it's marked paid, we know we need to update it regardless of any copied fields
                    if (cPropSet > 0 || pmt.npe01__Paid__c) {
                        listPmtUpdate.add(pmt);
                        listDIUpdate.add(di);
                    }
                }
            }
        }
        list<Database.SaveResult> listSR = UTIL_DMLService.updateRecords(listPmtUpdate, false);
        for (integer i = 0; i < listSR.size(); i++) {
            Database.SaveResult sr = listSR[i];
            if (!sr.isSuccess()) {
                bdi.LogBDIError(listDIUpdate[i], sr.getErrors()[0].getMessage(), null);
            }
        }
    }
    
} // BDI_Donations