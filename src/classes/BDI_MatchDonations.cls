/*
    Copyright (c) 2017, Salesforce.org
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
* @description Provides a default implementation of the BDI_IMatchDonations interface, which supports matching
* imported Donations with their appropriate Opportunity and Payment.
*
*/
public with sharing class BDI_MatchDonations implements BDI_IMatchDonations {
    
    /*******************************************************************************************************
    * @description the bdi we are invoked from
    */ 
    private BDI_DataImportService bdi { get; set; }

    /*******************************************************************************************************
    * @description the map of DI Donation Fields to Opportunity Fields
    */
    private static map<String, String> mapDIFieldToOppField {
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
    private static map<string, string> mapDIFieldToPmtField { 
        get {
            if (mapDIFieldToPmtField == null) {
                mapDIFieldToPmtField = BDI_DataImportService.mapFieldsForDIObject('Payment', 'npe01__OppPayment__c', 
                    BDI_DataImportService.listStrDataImportFields);
                // special case Donation fields we defaultly map to Opp fields, but we will use with Payments too!
                // note that these two work for matching rules.  
                mapDIFieldToPmtField.put(UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c').toLowercase(), 'npe01__Payment_Amount__c');
                mapDIFieldToPmtField.put(UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c').toLowercase(), 'npe01__Scheduled_Date__c');
            }
            return mapDIFieldToPmtField;
        }
        set;
    }

    /*******************************************************************************************************
    * @description For each of the provided Data Import records, find their existing Opportunity and Payment to
    * update, storing the lookup and status back in the BDI record.
    *
    * @param bdi The BDI instance currently running
    * @param dataImports The list of Data Import records with donations
    * @param opportunitiesById Map to fill in of DI Id's to matched Opportunities
    * @param paymentsById Map to fill in of DI Id's to matched Payments
    * @return void
    */
    public void match(BDI_DataImportService bdi, List<DataImport__c> dataImports,
        Map<Id, Opportunity> opportunitiesById, Map<Id, npe01__OppPayment__c> paymentsById) {

        this.bdi = bdi;

        // query for potential Opportunities & Payments based off our matching criteria
        List<Opportunity> potentialDonationMatches = getPotentialDonationMatches(dataImports);
        if (potentialDonationMatches == null) {
            return;
        }

        // put each contact's and account's opps in their own list
        Map<Id, List<Opportunity>> opportunitiesByContactsAndAccountsId = createMapConAccIdToOpps(potentialDonationMatches);

        // now look for the matching Opp for each donation
        for (DataImport__c di : dataImports) {
            // User told us in BGE interface to not match this record and only create new Opportunity
            // OR User told us in BGE interface to apply a new payment to a given Opportunity
            if (di.DonationImportStatus__c != Label.bdiMatchedByUserNewOpp
                    && di.DonationImportStatus__c != Label.bdiMatchedApplyNewPayment) {
                ID id;
                if (di.Donation_Donor__c == 'Account1') {
                    id = bdi.AccountFromDi(di, 1).Id;
                } else { // can assume Contact1
                    id = bdi.ContactFromDi(di, 1).Id;
                }
                List<Opportunity> contactAndAccountOpportunities = opportunitiesByContactsAndAccountsId.get(id);
                List<Integer> indexesOfDonationMatches = new List<Integer>();
                Map<ID, npe01__OppPayment__c> paymentsByOpportunityId = new Map<ID, npe01__OppPayment__c>();
                List<ID> paymentIdMatches = new List<ID>();

                Boolean isMatchedByOppId = false;
                Boolean isMatchedByPmtId = false;
                Integer bestOpportunityIndex = null;

                if (contactAndAccountOpportunities != null) {
                    Integer opportunityDateVariance = null;

                    // go thru each opp for this contact or account
                    for (Integer i = 0; i < contactAndAccountOpportunities.size(); i++) {
                        Opportunity opp = contactAndAccountOpportunities[i];
                        MatchInfo matchInfo = new MatchInfo(MATCHTYPE.NO_MATCH, 0);

                        // if 1 or more payments, use Payment matching rules
                        if (opp.npe01__Number_of_Payments__c >= 1) {
                            npe01__OppPayment__c pmtBest = null;
                            Integer dtVariancePmt = null;

                            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                                matchInfo = getMatchInfoByPmtRules(di, pmt);

                                if (matchInfo.matchType == MATCHTYPE.ID_MATCH) {
                                    pmtBest = pmt;
                                    isMatchedByPmtId = true;
                                    // clear possible other matches
                                    paymentIdMatches.clear();
                                    break;
                                } else if (matchInfo.matchType == MATCHTYPE.FIELD_MATCH) {
                                    paymentIdMatches.add(pmt.Id);
                                    // we start with the first field match as possible best, and then look for closer matches
                                    if (pmtBest == null || matchInfo.dateVariance < dtVariancePmt) {
                                        pmtBest = pmt;
                                        dtVariancePmt = matchInfo.dateVariance;
                                    }
                                }
                            } // end looping thru payments

                            // save our best match
                            if (pmtBest != null) {
                                paymentsByOpportunityId.put(opp.Id, pmtBest);

                                // treat a field match as Id match if the Opp was specified
                                if (opp.Id == di.DonationImported__c) {
                                    matchInfo.matchType = MATCHTYPE.ID_MATCH;
                                }

                                if (matchInfo.matchType != MATCHTYPE.ID_MATCH) {
                                    matchInfo.matchType = MATCHTYPE.FIELD_MATCH;
                                }
                            }
                        } // end matching an opp with >= 1 payment

                        // if no payments, or we failed to match with a single payment, use Opp matching rules
                        if (opp.npe01__Number_of_Payments__c <= 1 && matchInfo.matchType == MATCHTYPE.NO_MATCH) {
                            matchInfo = getMatchInfoByOppRules(di, opp);
                        }

                        if (matchInfo.matchType == MATCHTYPE.ID_MATCH) {
                            // if we matched by Id, then we don't even care about other matches by field.
                            indexesOfDonationMatches.clear();
                            indexesOfDonationMatches.add(i);
                            bestOpportunityIndex = i;
                            isMatchedByOppId = true;
                            paymentIdMatches.clear();
                            break;
                        } else if (matchInfo.matchType == MATCHTYPE.FIELD_MATCH) {
                            indexesOfDonationMatches.add(i);
                            // we start with the first field match as possible best, and then look for closer matches
                            if (bestOpportunityIndex == null || matchInfo.dateVariance < opportunityDateVariance) {
                                bestOpportunityIndex = i;
                                opportunityDateVariance = matchInfo.dateVariance;
                            }
                        }
                    } // end looping thru opps
                }

                // if we have 1 or more matches, record the best one
                if (indexesOfDonationMatches.size() > 0) {
                    Opportunity opp = contactAndAccountOpportunities[bestOpportunityIndex];
                    di.DonationImported__c = opp.Id;
                    // put the existing opp in our map for caller's use
                    opportunitiesById.put(di.Id, opp);

                    // if unique, remove this opp from the list to avoid matching it again.
                    if (indexesOfDonationMatches.size() == 1) {
                        // User told us in BGE interface to not match this record and use specified record
                        if (di.DonationImportStatus__c != Label.bdiMatchedByUser &&
                                di.DonationImportStatus__c != Label.bdiMatchedApplyNewPayment) {
                            di.DonationImportStatus__c = (isMatchedByOppId ? Label.bdiMatchedId : Label.bdiMatched);
                        }
                        contactAndAccountOpportunities.remove(bestOpportunityIndex);
                    } else {
                        // we have multiple matches, we want to record them all, and fixup our status
                        di.DonationImportStatus__c = Label.bdiMatchedBest;
                        for (Integer i = 0; i < indexesOfDonationMatches.size(); i++) {
                            Opportunity oppT = contactAndAccountOpportunities[indexesOfDonationMatches[i]];
                            if (di.Donation_Possible_Matches__c == null) {
                                di.Donation_Possible_Matches__c = oppT.Id;
                            } else {
                                di.Donation_Possible_Matches__c += ',' + oppT.Id;
                            }
                            // only take the first 10 matches to not blow our 255 char limit.
                            if (i == 9) {
                                break;
                            }
                        }
                    }

                    // also record the payment
                    npe01__OppPayment__c pmt = paymentsByOpportunityId.get(opp.Id);

                    // if we didn't match a payment for the Opp, but it has only one payment, let's use it!
                    if (pmt == null && opp.npe01__Number_of_Payments__c == 1) {
                        // This can happen if our only payment is paid.
                        if (!opp.npe01__OppPayment__r.isEmpty()) {
                            pmt = opp.npe01__OppPayment__r[0];
                        }
                    }

                    if (pmt != null) {
                        di.PaymentImported__c = pmt.Id;
                        // User told us in BGE interface to not match this record and use specified record
                        if (di.PaymentImportStatus__c != label.bdiMatchedByUser) {
                            di.PaymentImportStatus__c = (isMatchedByPmtId ? label.bdiMatchedId :
                                    (paymentIdMatches.size() > 1 ? label.bdiMatchedBest : label.bdiMatched));
                        }
                        // put the existing pmt in our map for caller's use
                        paymentsById.put(di.Id, pmt);

                        // also record payment matches if any
                        if (paymentIdMatches.size() > 1) {
                            for (integer i = 0; i < paymentIdMatches.size(); i++) {
                                ID idPmt = paymentIdMatches[i];
                                if (di.Payment_Possible_Matches__c == null) {
                                    di.Payment_Possible_Matches__c = idPmt;
                                } else {
                                    di.Payment_Possible_Matches__c += ',' + idPmt;
                                }
                                // only take the first 10 matches to not blow our 255 char limit.
                                if (i == 9)
                                    break;
                            }
                        }
                    }
                } else {
                    di.DonationImportStatus__c = label.bdiMatchedNone;
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description describes the type of match returned from our matching routines.
    */
    private enum MATCHTYPE {ID_MATCH, FIELD_MATCH, NO_MATCH}

    /*******************************************************************************************************
    * @description describes the type of match returned from our matching routines
    */
    private class MatchInfo {
        MATCHTYPE matchtype;
        integer dateVariance;

        MatchInfo(MATCHTYPE matchtype, integer dateVariance) {
            this.matchtype = matchtype;
            this.dateVariance = dateVariance;
        }
    }

    /*******************************************************************************************************
    * @description checks whether the specified opp is a match for this DI record
    * @param di The data import record we are trying to find an opp for
    * @param opp The opp to evaluate
    * @return MatchInfo
    */
    private MatchInfo getMatchInfoByOppRules(DataImport__c di, Opportunity opp) {
        // always match to an Opp we were given the Id to!
        if (di.DonationImported__c == opp.Id) {
            return new MatchInfo(MATCHTYPE.ID_MATCH, 0);
        }

        if (di.DonationImported__c == null) {
            // try match against all specified fields
            Boolean isAllMatch = true;
            Integer dtVariance = 0;

            for (String dataImportField : listMatchFields) {
                Object dataImportFieldValue = di.get(dataImportField);
                String opportunityField = mapDIFieldToOppField.get(dataImportField);
                String donationDate = UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c').toLowercase();

                // special case date matching
                if (dataImportField == donationDate && opportunityField != null) {
                    Date dtOpp = Date.valueOf(opp.get(opportunityField));
                    if (dtOpp != null && dataImportFieldValue != null) {
                        Integer dtVarianceT = math.abs(Date.valueOf(dataImportFieldValue).daysBetween(dtOpp));
                        if (dtVarianceT <= Integer.valueOf(bdi.diSettings.Donation_Date_Range__c)) {
                            dtVariance = dtVarianceT;
                            continue;
                        }
                    }
                }

                // handle mapping a specified record type name to the Id we must compare with
                if (dataImportField == UTIL_Namespace.StrTokenNSPrefix('Donation_Record_Type_Name__c').toLowercase()) {
                    dataImportFieldValue = UTIL_RecordTypes.getRecordTypeId(Opportunity.sObjectType,
                                                                            String.valueOf(dataImportFieldValue));
                }

                // only test opp fields (failing match if payment fields specified)
                if (opportunityField == null || dataImportFieldValue != opp.get(opportunityField)) {
                    isAllMatch = false;
                    break;
                }
            }
            if (isAllMatch) {
                return new MatchInfo(MATCHTYPE.FIELD_MATCH, dtVariance);
            }
        }
        
        return new MatchInfo(MATCHTYPE.NO_MATCH, 0);
    }
    
    /*******************************************************************************************************
    * @description checks whether the specified opp has a Payment match for this DI record
    * @param di The data import record we are trying to find an Opp & Payment for
    * @param pmt The payment to evaluate
    * @return MatchInfo
    */
    private MatchInfo getMatchInfoByPmtRules(DataImport__c di, npe01__OppPayment__c pmt) {

        // always match to an Payment we were given the Id to!
        if (di.PaymentImported__c == pmt.Id) {
            return new MatchInfo(MATCHTYPE.ID_MATCH, 0);
        }

        if (di.PaymentImported__c == null) {
            // try match against all specified fields
            Boolean isAllMatch = true;
            Integer dtVariance = 0;

            for (String dataImportField : listMatchFields) {
                Object dataImportFieldValue = di.get(dataImportField);
                String paymentField = mapDIFieldToPmtField.get(dataImportField);
                String donationDate = UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c').toLowercase();

                // special case date matching
                if (dataImportField == donationDate && paymentField != null) {
                    Date dtPmt = Date.valueOf(pmt.get(paymentField));
                    if (dtPmt != null && dataImportFieldValue != null) {
                        Integer dtVarianceT = math.abs(Date.valueOf(dataImportFieldValue).daysBetween(dtPmt));
                        if (dtVarianceT <= Integer.valueOf(bdi.diSettings.Donation_Date_Range__c)) {
                            dtVariance = dtVarianceT;
                            continue;
                        }
                    }
                }

                // only test pmt fields (failing match if Opp fields specified)
                if (paymentField == null || dataImportFieldValue != pmt.get(paymentField)) {
                    isAllMatch = false;
                    break;
                }
            }
            if (isAllMatch) {
                return new MatchInfo(MATCHTYPE.FIELD_MATCH, dtVariance);
            }
        }

        return new MatchInfo(MATCHTYPE.NO_MATCH, 0);
    }

    /*******************************************************************************************************
    * @description the list of BDI Donation fields to use in donation matching
    */
    private list<String> listMatchFields {
        get {
            if (listMatchFields == null) {
                string strRules = bdi.diSettings.Donation_Matching_Rule__c;
                if (strRules != null) {
                    listMatchFields = strRules.toLowercase().replace(' ', '').split(';');
                } else {
                    listMatchFields = new list<String> {
                        UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c').toLowercase(),
                        UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c').toLowercase()
                    };
                }
            }
            return listMatchFields;
        }
        set;
    }

    /*******************************************************************************************************
    * @description queries for all potential Donation Opportunities & Payments based off matching criteria
    * @param listDI The DataImport records we are trying to match
    * @return list<Opportunity> The list of potential matching Opps.  null if none.
    */
    private list<Opportunity> getPotentialDonationMatches(list<DataImport__c> listDI) {
        
        // collect all the contacts and accounts who have donations to import
        set<Id> setConId = new set<Id>();
        set<Id> setAccId = new set<Id>();
        set<Id> setOppId = new set<Id>();
        
        for (DataImport__c di : listDI) {
            // handle already been given the match!
            if (di.DonationImported__c != null) {
                setOppId.add(di.DonationImported__c);
            } else if (di.Donation_Donor__c == 'Contact1') {
                Contact con = bdi.ContactFromDi(di, 1);
                setConId.add(con.Id);                                
            } else if (di.Donation_Donor__c == 'Account1') {
                Account acc = bdi.AccountFromDi(di, 1);
                setAccId.add(acc.Id);
            }
        }
        
        // bail out if no donations to import!
        if (setOppId.size() == 0 && setAccId.size() == 0 && setConId.size() == 0) {
            return null;
        }
        
        // the set of Opportunity fields for our soql
        set<String> setOppFields = new set<String>();
        setOppFields.add('Id');
        setOppFields.add('Name');
        setOppFields.add('Amount');
        setOppFields.add('AccountId');
        setOppFields.add(UTIL_Namespace.StrTokenNSPrefix('Primary_Contact__c'));
        setOppFields.add('CloseDate');
        setOppFields.add('npe01__Number_of_Payments__c');
        setOppFields.add('Account.npe01__SYSTEMIsIndividual__c');

        // need to include any Opp fields we may update, so we can compare against them
        setOppFields.addAll(mapDIFieldToOppField.values());
        
        // the set of Payment fields for our soql
        set<String> setPmtFields = new set<String>();
        setPmtFields.add('Id');
        setPmtFields.add('Name');
        setPmtFields.add('npe01__Paid__c');
        setPmtFields.add('npe01__Opportunity__c');
        setPmtFields.add('npe01__Payment_Amount__c');
        setPmtFields.add('npe01__Payment_Date__c');
        setPmtFields.add('npe01__Scheduled_Date__c');
        setPmtFields.add('npe01__Written_Off__c');

        // need to include any Pmt fields we may update, so we can compare against them
        setPmtFields.addAll(mapDIFieldToPmtField.values());

        // now query for all Open Opportunities from these Contacts or Accounts
        integer cFilter = 0;
        string strSoql = 'select ' + string.join(new list<String>(setOppFields), ',');
        
        // add Payment subquery
        strSoql += ', (select ' + string.join(new list<String>(setPmtFields), ',');
        strSoql += ' from npe01__OppPayment__r where npe01__Paid__c = false )';
        
        strSoql += ' from Opportunity';
        strSoql += ' where IsClosed = false and (';
        if (setOppId.size() > 0) {
            strSoql += ' Id in :setOppId ';
            cFilter++;
        }
        if (setAccId.size() > 0) {
            if (cFilter > 0) {
                strSoql += ' or ';
            }
            strSoql += ' AccountId in :setAccId ';
            cFilter++;
        }
        if (setConId.size() > 0) {
            if (cFilter > 0) {
                strSoql += ' or ';
            }
            strSoql += ' ' + UTIL_Namespace.StrTokenNSPrefix('Primary_Contact__c') + ' in :setConId ';
            cFilter++;
        }
        strSoql += ') ';
        BDI_PerfLogger.PerfLog pl = BDI_DataImportService.perfLogger.newPerfLog('SOQL existing Opps', BDI_PerfLogger.QUERY);
        list<Opportunity> listOpp = database.query(strSoql);
        pl.stop();
        return listOpp;           
    }
    
    /*******************************************************************************************************
    * @description creates a map from a Contact Id or Account Id, to a list of Opportunities
    * @param listOpp The opps to put on the map
    * @return map<Id, list<Opportunity>> The returned map
    */
    private map<Id, list<Opportunity>> createMapConAccIdToOpps(list<Opportunity> listOpp) {
        map<Id, list<Opportunity>> mapConAccIdToOpps = new map<Id, list<Opportunity>>();
        for (Opportunity opp : listOpp) {
            ID id;
            if (opp.Account.npe01__SYSTEMIsIndividual__c && opp.Primary_Contact__c != null) {
                id = opp.Primary_Contact__c;
            } else {
                id = opp.AccountId;
            }
            list<Opportunity> listCAOpps = mapConAccIdToOpps.get(id);
            if (listCAOpps == null) {
                listCAOpps = new list<Opportunity>();
                mapConAccIdToOpps.put(id, listCAOpps);
            }
            listCAOpps.add(opp);
        }
        return mapConAccIdToOpps;
    }

} // BDI_MatchDonations