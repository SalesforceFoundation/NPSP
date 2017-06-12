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
    * @param bdi The Batch Data Import object the helper should use
    * @return void
    */ 
    public BDI_Donations(BDI_DataImport_BATCH bdi) {
        this.bdi = bdi;
    }

    /*******************************************************************************************************
    * @description The Batch Data Import object the helper should use
    */ 
    BDI_DataImport_BATCH bdi { get; set; }
    
    /*******************************************************************************************************
    * @description map to track the Opportunity created/matched for each DI record
    */ 
    private map<Id, Opportunity> mapDIIdToOpp = new map<Id, Opportunity>();

    /*******************************************************************************************************
    * @description map to track the Payment created/matched for each DI record
    */ 
    private map<Id, npe01__OppPayment__c> mapDIIdPmt = new map<Id, npe01__OppPayment__c>();
    
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
    * @description Imports the appropriate Donations into NPSP, following matching rules and criteria
    * to potentially match existing Opportunities or Payments.
    * @return void
    */ 
    public void importDonations() {
    
        // get the fields we will auto-copy
        map<string, string> mapDIFieldToOppField = 
            BDI_DataImport_BATCH.mapFieldsForDIObject('Opportunity', 'Opportunity', BDI_DataImport_BATCH.listStrDataImportFields);
        list<Opportunity> listOppInsert = new list<Opportunity>();
        list<DataImport__c> listDIInsert = new list<DataImport__c>();
        
        for (DataImport__c di : bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
               continue;
            integer cPropSet = 0;
            Opportunity opp = new Opportunity();
            string strOppName;
            
            // ignore this row if we've already imported an opp 
            if (di.DonationImported__c != null)
                continue;

            if (di.Donation_Donor__c == 'Contact1' || (di.Donation_Donor__c == null && di.Donation_Amount__c != null)) {
                Contact con = bdi.ContactFromDi(di, 1);
                if (con == null) {
                    bdi.LogBDIError(di, label.bdiErrorInvalidDonor, 'DonationImportStatus__c');
                    continue;
                }                
                opp.npe01__Contact_Id_for_Role__c = con.Id;
                opp.Primary_Contact__c = con.Id;
                opp.Primary_Contact_Campaign_Member_Status__c = di.Campaign_Member_Status__c;
                opp.AccountId = con.AccountId;
                strOppName = con.Firstname + ' ' + con.Lastname;
            } else if (di.Donation_Donor__c == 'Account1') {
                Account acc = bdi.AccountFromDi(di, 1);
                if (acc == null) {
                    bdi.LogBDIError(di, label.bdiErrorInvalidDonor, 'DonationImportStatus__c');
                    continue;
                }
                opp.accountId = acc.Id;    
                strOppName = acc.Name;            
            } else if (di.Donation_Donor__c != null) {
                bdi.LogBDIError(di, label.bdiErrorInvalidDonor, 'DonationImportStatus__c');
                continue;
            }
                
            if (di.Donation_Record_Type_Name__c != null) {
                Id idRt = UTIL_RecordTypes.GetRecordTypeId(Opportunity.sObjectType, di.Donation_Record_Type_Name__c);
                if (idRt == null) {
                    bdi.LogBDIError(di, label.bdiErrorInvalidOppRTName, 'DonationImportStatus__c');
                    continue;
                }
                opp.RecordTypeId = idRt;
                strOppName += ' ' + di.Donation_Record_Type_Name__c;
            } else {
                strOppName += ' ' + label.bdiDonation;
            }
            
            if (di.Donation_Campaign_Name__c != null) {
                Id idCmp = bdi.mapStrNameToCampaignId.get(di.Donation_Campaign_Name__c);
                if (idCmp == null) {
                    bdi.LogBDIError(di, label.bdiErrorInvalidCampaignName, 'DonationImportStatus__c');
                    continue;
                }
                opp.CampaignId = idCmp;
            }
            
            if (di.Donation_Date__c == null) {
                di.Donation_Date__c = system.today();
                cPropSet--;
            }
            
            if (di.Donation_Name__c == null) {
                di.Donation_Name__c = strOppName + ' ' + di.Donation_Date__c.format();
                cPropSet--;
            } 
                
            if (di.Donation_Stage__c == null && defaultClosedWonStage != '') {
                di.Donation_Stage__c = defaultClosedWonStage;
                cPropSet--;
            }

            for (string strDIField : mapDIFieldToOppField.keySet()) {
                if (BDI_DataImport_BATCH.isCopiedDIField(di, strDIField, opp, mapDIFieldToOppField)) {
                    cPropSet++;
                }
            }
            // unfortunately, if there are checkbox fields that we copied, we can't tell the difference
            // between null or false, so looking at cPropSet isn't good enough!  let's also look for an account specified.
            if (cPropSet > 0 && opp.AccountId != null) {
                mapDIIdToOpp.put(di.Id, opp);
                listOppInsert.add(opp);
                listDIInsert.add(di);  
            } else {
                // clear out fields we autoset since we didn't actually create an opp.
                di.Donation_Date__c = null;
                di.Donation_Name__c = null;
                di.Donation_Stage__c = null;
            }
            if (Test.isRunningTest() && opp.Name != null && opp.Name.startsWith('FailTest'))
                opp.Name = null;
        }
        //insert mapDIIdToOpp.values();
        list<Database.SaveResult> listSR = database.insert(listOppInsert, false);
        for (integer i = 0; i < listSR.size(); i++) {
            Database.SaveResult sr = listSR[i];
            if (!sr.isSuccess()) {
                bdi.LogBDIError(listDIInsert[i], sr.getErrors()[0].getMessage(), 'DonationImportStatus__c');
            }
        }
        
        // update each DI with its new opp
        for (DataImport__c di: bdi.listDI) {
            if (di.DonationImported__c == null) {
                Opportunity opp = mapDIIdToOpp.get(di.Id);
                if (opp != null && opp.Id != null) {
                    di.DonationImported__c = opp.Id;
                    di.DonationImportStatus__c = label.bdiCreated;
                }
            }
        }  
        
        // now deal with any payment child records
        updatePayments();      
    }

    /*******************************************************************************************************
    * @description Updates any fields on payment objects created for the Data Import opportunities.
    * @return void
    */ 
    public void updatePayments() {

        // need to find payment records, to add any additional info.
        map<Id, npe01__OppPayment__c> mapOppIdToPayment = new map<Id, npe01__OppPayment__c>();
        for (npe01__OppPayment__c pmt : [select Id, npe01__Opportunity__c from npe01__OppPayment__c where npe01__Opportunity__c in :mapDIIdToOpp.values()]) {
            mapOppIdToPayment.put(pmt.npe01__Opportunity__c, pmt);
        }

        // get the payment fields we will auto-copy
        map<string, string> mapDIFieldToPmtField = 
            BDI_DataImport_BATCH.mapFieldsForDIObject('Payment', 'npe01__OppPayment__c', BDI_DataImport_BATCH.listStrDataImportFields);
        list<npe01__OppPayment__c> listPmtUpsert = new list<npe01__OppPayment__c>();
        list<DataImport__c> listDIUpsert = new list<DataImport__c>();

        // update payments
        for (DataImport__c di: bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
               continue;            
            if (di.DonationImported__c != null) {
                npe01__OppPayment__c pmt = mapOppIdToPayment.get(di.DonationImported__c);
                if (pmt != null) {
                    integer cPropSet = 0;
                    for (string strDIField : mapDIFieldToPmtField.keySet()) {
                        if (BDI_DataImport_BATCH.isCopiedDIField(di, strDIField, pmt, mapDIFieldToPmtField)) {
                            cPropSet++;
                        }
                    }                    
                    if (cPropSet > 0) {
                        mapDIIdPmt.put(di.Id, pmt);
                        listPmtUpsert.add(pmt);
                        listDIUpsert.add(di);
                    }
                }
            }
        }
        
        //upsert mapDIIdPmt.values();
        list<Database.UpsertResult> listUR = database.upsert(listPmtUpsert, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                bdi.LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), null);
            }
        }
        
    }    
}