/*
    Copyright (c) 2009, Salesforce.org
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
* @author Nick Bailey 
* @date 2011 (2.1)
* @group Payments
* @description Controls the creation of payment objects from Opportunity trigger
*/
public class PMT_PaymentCreator {

    /* @description Retrieve info about specific fields that may or may not exist on the objects */
    private static final SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
    private static final SObjectField PaymentCurrencyField = Schema.sObjectType.npe01__OppPayment__c.fields.getMap().get('CurrencyIsoCode');
    private static final SObjectField OppRecordTypeId = Schema.sObjectType.Opportunity.fields.getMap().get('RecordTypeId');


    /*******************************************************************************************************
    * @description map of Opportunity to Payment field mappings, validated to only contain mappings that
    * are of compatible types.
    */ 
    public static map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappings {
        get {
            if (paymentMappings == null) {
                //load custom field mapping settings - if they exist        
                map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappingsAll = UTIL_ListCustomSettingsFacade.getMapPaymentFieldMappingSettings().clone();
                paymentMappings = UTIL_ListCustomSettingsFacade.getMapPaymentFieldMappingSettings().clone();
            
                for (string s : paymentMappingsAll.keySet()){
                    npe01__Payment_Field_Mapping_Settings__c pfms = paymentMappingsAll.get(s); 
                
                    SobjectField opportunityField;
                    SobjectField paymentField;
                    boolean isValid = true; 
                                
                    //check Opp fields
                    opportunityField = Schema.sObjectType.Opportunity.fields.getMap().get(pfms.npe01__Opportunity_Field__c);
                              
                    //check Payment fields            
                    paymentField = Schema.sObjectType.npe01__OppPayment__c.fields.getMap().get(pfms.npe01__Payment_Field__c);
                        
                    if (paymentField != null && opportunityField != null) {
                        Schema.DisplayType payF = paymentField.getDescribe().getType();
                        Schema.DisplayType oppF = opportunityField.getDescribe().getType();
                        isValid = UTIL_Describe.canDisplaytypesCopy(oppF, payF);
                    } else {
                        isValid = false;
                    }
    
                    if (isValid == false) paymentMappings.keyset().remove(s);                         
                }
                
            }
            return paymentMappings;
        }
        set;
    }
    
    /*******************************************************************************************************
    * @description set of Opportunity Recordtype Id's to not create Payments for.
    */ 
    public static set<id> setOppRecordTypeIdNoPayment {
        get {
            if (setOppRecordTypeIdNoPayment == null) {
                string strProp = UTIL_CustomSettingsFacade.getContactsSettings().Opp_RecTypes_Excluded_for_Payments__c;
                if (strProp != null) {
                    setOppRecordTypeIdNoPayment = new Set<Id>((List<Id>)strProp.split(';'));
                } else {
                    setOppRecordTypeIdNoPayment = new set<Id>();
                }
            }
            return setOppRecordTypeIdNoPayment;
        }
        set;
    }

    /*******************************************************************************************************
    * @description set of Opportunity Type values to not create Payments for.
    */ 
    public static set<string> setOppTypeNoPayment {
        get {
            if (setOppTypeNoPayment == null) {
                string strProp = UTIL_CustomSettingsFacade.getContactsSettings().Opp_Types_Excluded_for_Payments__c;
                if (strProp != null) {
                    setOppTypeNoPayment = new set<string>(strProp.split(';'));    
                } else {
                    setOppTypeNoPayment = new set<string>();
                }
            }
            return setOppTypeNoPayment;
        }
        set;
    }

    /*******************************************************************************************************
    * @description specifies whether Payments should be excluded for the Opportunity
    * @param opp the Opportunity to test.
    * @return boolean true if Payments excluded for the Opportunity
    */ 
    private static boolean isNoPaymentForOpp(Opportunity opp) {
        if (opp.npe01__Do_Not_Automatically_Create_Payment__c)
            return true;
        if (setOppTypeNoPayment.contains(opp.Type))
            return true;
        if (setOppRecordTypeIdNoPayment.contains((id)opp.get('RecordTypeId')))
            return true;
        return false;
    }    
                
    /*******************************************************************************************************
    * @description Constructor that gets called by the PMT_Payment_TDTM trigger handler.
    * @param newOppsMap the map of Opps from trigger new. 
    * @param oldOppsMap the map of Opps from trigger old. 
    * @param ta which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param dmlWrapper to hold any payments that need to be inserted, updated, or deleted.  
    ********************************************************************************************************/
    public PMT_PaymentCreator(Map<id, Opportunity> newOppsMap, Map<id, Opportunity> oldOppsMap, TDTM_Runnable.Action ta, 
        TDTM_Runnable.DMLWrapper dmlWrapper) {
        
        npe01__Contacts_And_Orgs_Settings__c ContactSettings = UTIL_CustomSettingsFacade.getContactsSettings();

        Boolean isACMEnabled = UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled();

        // If ACM is enabled in an organization, changes to the Payment object will not roll-up to (and cause triggers
        // to execute) on the Opportunity. The trigger on the Payment Object is used to detect a new/updated payment
        // and to handle auto-closing the Opportunity if necessary. However, if the Opportunity.Amount is updated to
        // match the total of the payments, the Opportunity must still be closed. The issue is that when ACM is enabled
        // the npe01__Payments_Made__c rollup field on the Opportunity does not work. In this case, we have to force
        // a requery of the Opportunities (with a sub-query on Payments) to allow the actual Payment Amount to be
        // queried.

        if (ContactSettings != null && ContactSettings.npe01__Payments_Enabled__c == true){
            list<Opportunity> newOpps = newOppsMap.values();
            Map<Id, Opportunity> newOppsMapRequeried = new Map<Id, Opportunity>();
            list<npe01__OppPayment__c> paymentsToInsert = new list<npe01__OppPayment__c>();
            list<npe01__OppPayment__c> paymentsToUpdate = new list<npe01__OppPayment__c>();
            list<Opportunity> updatedOpps = new list<Opportunity>();

            // SOQL for Updated Opps and Related Payments.
            // AfterUpdate => Queries for known fields and field in custom Payment Field Mappings.
            // BeforeUpdate AND IsACMEnabled => Used to handle summing total payments when ACM is enabled in the org.
            if (ta == TDTM_Runnable.Action.AfterUpdate || (isACMEnabled && ta == TDTM_Runnable.Action.BeforeUpdate)) {
                String query = buildOppsQuery() + 'WHERE Id IN :newOpps';
                updatedOpps = database.query(query);
                if (isACMEnabled && ta == TDTM_Runnable.Action.BeforeUpdate) {
                    newOppsMapRequeried = new Map<Id, Opportunity>((List<Opportunity>)(updatedOpps));
                }
            }

            if (TDTM_Runnable.Action.BeforeUpdate == ta) {
                if (!String.isEmpty(ContactSettings.Payments_Auto_Close_Stage_Name__c)) {
                    String closedStageName = ContactSettings.Payments_Auto_Close_Stage_Name__c;
                    for (Opportunity opp : newOpps) {

                        Decimal totalPaymentAmount = (isACMEnabled
                                ? PMT_PaymentCreator.getPaymentsMade(newOppsMapRequeried.get(opp.Id)) : opp.npe01__Payments_Made__c);
                        closeOpportunityIfAllPaymentsReceived(
                            oldOppsMap.get(opp.Id),
                            opp,
                            closedStageName,
                            totalPaymentAmount
                        );
                    }
                }
            }

            //IF Trigger is Insert, Create a new Payment
            if( ta == TDTM_Runnable.Action.AfterInsert){
                for (Opportunity thisOpp : newOpps){
                    
                    if (isNoPaymentForOpp(thisOpp)) {
                        continue;
                    }

                    // if opp is closed won with no payments scheduled or made, add an automatic payment
                        if ( /*(thisOpp.IsClosed && thisOpp.IsWon) && */
                                        thisOpp.amount > 0 && thisOpp.npe01__payments_made__c == 0 && thisOpp.npe01__Number_of_Payments__c == 0) {

                            npe01__oppPayment__c op = new npe01__oppPayment__c(
                                npe01__opportunity__c = thisOpp.id
                            );

                            //in multicurrency SFDC set the payment currency field to equal to the opp currency
                            if(paymentCurrencyField != null && oppCurrencyField != null) {
                                op.put(paymentCurrencyField, thisOpp.get(oppCurrencyField));
                            }

                            op.npe01__payment_amount__c = thisOpp.amount;

                            if (paymentMappings.size() > 0){
                                for (string s : paymentMappings.keyset()){
                                        npe01__Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
                                        string oppField = pfms.npe01__Opportunity_Field__c;
                                        if (thisOpp.get(oppField) != null) {
                                           op.put(pfms.npe01__Payment_Field__c, thisOpp.get(oppField));
                                        }
                                }
                            }

                        if (thisOpp.IsClosed && thisOpp.IsWon){
                            op.npe01__paid__c = true;
                            op.npe01__payment_date__c = thisOpp.closeDate;
                        }

                        if (!thisOpp.IsClosed){
                            op.npe01__paid__c = false;
                            op.npe01__scheduled_date__c = thisOpp.closeDate;
                        }

                        paymentsToInsert.add(op);
                    }
                    /*
                    else if (!thisOpp.IsClosed &&
                                    thisOpp.amount > 0 && thisOpp.npe01__payments_made__c == 0 && thisOpp.npe01__Number_of_Payments__c == 0 && !thisOpp.npe01__Do_Not_Automatically_Create_Payment__c) {
                        paymentsToInsert.add(new npe01__oppPayment__c(
                            npe01__opportunity__c = thisOpp.id,
                            npe01__scheduled_date__c = thisOpp.closeDate,
                            npe01__payment_amount__c = thisOpp.amount,
                            npe01__paid__c = false
                        ));
                    }
                    */
                }
                // put in the payment for closed opps       
                if (!paymentsToInsert.isEmpty()) 
                    dmlWrapper.objectsToInsert.addAll((list<SObject>) paymentsToInsert);
            }
            
            
            //IF Trigger is Update, keep synced Payments in Sync or delete if Opp is lost
            if( ta == TDTM_Runnable.Action.AfterUpdate ){
                list<Opportunity> oldOpps = oldOppsMap.values();
                for (Opportunity thisOpp : updatedOpps){
                    Opportunity oldOpp = oldOppsMap.get(thisOpp.id);
                    
                    boolean mappingsUpdated = false;
                    
                    //check to see if any of the custom mapped fields have been updated
                    for (string s : paymentMappings.keyset()){
                        if(thisOpp.get(paymentMappings.get(s).npe01__Opportunity_Field__c) != oldOpp.get(paymentMappings.get(s).npe01__Opportunity_Field__c)){
                            mappingsUpdated = true;
                        }
                    }

                    // Use a method to determine the value for total payments that takes Advanced Currency Management
                    // into consideration.
                    Decimal totalPaymentsMade = getPaymentsMade(thisOpp);

                    if (thisOpp.npe01__OppPayment__r.size() > 0){
                         // if opp is updated, update the automatic payment
                        if ( ((thisOpp.Amount != oldOpp.Amount) || (thisOpp.CloseDate != oldOpp.CloseDate) || mappingsUpdated == true) &&
                                (thisOpp.npe01__OppPayment__r[0].npe01__Scheduled_Date__c == oldOpp.CloseDate || thisOpp.npe01__OppPayment__r[0].npe01__Scheduled_Date__c == thisOpp.CloseDate) &&
                                (thisOpp.npe01__OppPayment__r[0].npe01__Payment_Amount__c == oldOpp.Amount || thisOpp.npe01__OppPayment__r[0].npe01__Payment_Amount__c == thisOpp.Amount) &&
                                thisOpp.npe01__OppPayment__r.size() == 1 &&
                                thisOpp.npe01__OppPayment__r[0].npe01__paid__c == False &&
                                //open opportunities only
                                !thisOpp.isClosed && thisOpp.amount > 0 &&
                                totalPaymentsMade == 0) {
                            thisOpp.npe01__OppPayment__r[0].npe01__scheduled_date__c = thisOpp.closeDate;
                            thisOpp.npe01__OppPayment__r[0].npe01__payment_amount__c = thisOpp.amount;
                            
                            
                            if (paymentMappings.size() > 0){
                                for (string s : paymentMappings.keyset()){
                                        npe01__Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
                                        string x = pfms.npe01__Opportunity_Field__c;
                                        if (thisOpp.get(x) != null)
                                           thisOpp.npe01__OppPayment__r[0].put(pfms.npe01__Payment_Field__c, thisOpp.get(x));
                                }
                            }
                         
                            paymentsToUpdate.add(thisOpp.npe01__OppPayment__r[0]);
                        }
                        else if ( ((thisOpp.Amount != oldOpp.Amount) || (thisOpp.CloseDate != oldOpp.CloseDate) || (thisOpp.isWon != oldOpp.IsWon)) &&
                                (thisOpp.npe01__OppPayment__r[0].npe01__scheduled_Date__c == oldOpp.CloseDate || thisOpp.npe01__OppPayment__r[0].npe01__scheduled_Date__c == thisOpp.CloseDate || thisOpp.npe01__OppPayment__r[0].npe01__Payment_Date__c == oldOpp.CloseDate || thisOpp.npe01__OppPayment__r[0].npe01__Payment_Date__c == thisOpp.CloseDate) &&
                                (thisOpp.npe01__OppPayment__r[0].npe01__Payment_Amount__c == oldOpp.Amount || thisOpp.npe01__OppPayment__r[0].npe01__Payment_Amount__c == thisOpp.Amount) &&
                                thisOpp.npe01__OppPayment__r.size() == 1 &&
                                thisOpp.npe01__OppPayment__r[0].npe01__paid__c == False &&
                                //closed/won opportunities only
                                thisOpp.isClosed && thisOpp.isWon && thisOpp.amount > 0 &&
                                totalPaymentsMade == 0) {
                            thisOpp.npe01__OppPayment__r[0].npe01__payment_date__c = thisOpp.closeDate;
                            thisOpp.npe01__OppPayment__r[0].npe01__payment_amount__c = thisOpp.amount;
                            thisOpp.npe01__OppPayment__r[0].npe01__paid__c = true;
                            paymentsToUpdate.add(thisOpp.npe01__OppPayment__r[0]);
                      
                        }
                        //closed/lost opportunities only
                        else if ( thisOpp.isClosed && !thisOpp.isWon) {
                            
                            for(npe01__OppPayment__c thisPayment : thisOpp.npe01__OppPayment__r){
                                if(thisPayment.npe01__Paid__c == False && thisPayment.npe01__Written_Off__c == False){
                                    thisPayment.npe01__Written_Off__c = true;
                                    paymentsToUpdate.add(thisPayment);
                                }
                            }
                        }
                    }
                    
                    // we may need to add payments if the open opp amount has been changed from $0
                    else if (
                            thisOpp.Amount != null && thisOpp.Amount != 0 && 
                            (thisOpp.IsClosed == false || thisOpp.IsWon == true) &&
                            (oldOpp.Amount == null || oldOpp.Amount == 0) && 
                            isNoPaymentForOpp(thisOpp) == false
                        ) {
                        
                        paymentsToInsert.add(createOpportunityPayment(thisOpp, paymentCurrencyField, oppCurrencyField));                                              
                    }
                }
                // update or delete payments     
                if (!paymentsToUpdate.isEmpty())
                    dmlWrapper.objectsToUpdate.addAll((list<SObject>)paymentsToUpdate);
                if (!paymentsToInsert.isEmpty())
                    dmlWrapper.objectsToInsert.addAll((list<SObject>)paymentsToInsert);
            }
        }
    }

    /**
     * @description Creates a Payment for the input Opportunity
     * @param newOpportunity the new value of the updated Opportunity
     * @param paymentCurrencyField The Payment Object Currency Field
     * @param oppCurrencyField The Opportunity Object Currency Field
     * @return npe01__OppPayment__c The Opportunity Payment created
     */
    private npe01__OppPayment__c createOpportunityPayment(Opportunity newOpportunity, SObjectField paymentCurrencyField, SObjectField oppCurrencyField) {
        npe01__OppPayment__c opportunityPayment = new npe01__OppPayment__c(
            npe01__Opportunity__c = newOpportunity.Id,
            npe01__Paid__c = newOpportunity.IsClosed,
            npe01__Payment_Amount__c = newOpportunity.Amount
        );

        if (opportunityPayment.npe01__Paid__c) {
            opportunityPayment.npe01__Payment_Date__c = newOpportunity.CloseDate;
        } else {
            opportunityPayment.npe01__Scheduled_Date__c = newOpportunity.CloseDate;
        }
                
        //in multicurrency SFDC set the payment currency field to equal to the opp currency
        if (paymentCurrencyField != null && oppCurrencyField != null) {
            opportunityPayment.put(paymentCurrencyField, newOpportunity.get(oppCurrencyField));
        }
        
        for (npe01__Payment_Field_Mapping_Settings__c paymentMapping : paymentMappings.values()) {
            if (newOpportunity.get(paymentMapping.npe01__Opportunity_Field__c) != null) {
                opportunityPayment.put(
                    paymentMapping.npe01__Payment_Field__c, 
                    newOpportunity.get(paymentMapping.npe01__Opportunity_Field__c)
                );
            }
        }

        return opportunityPayment;
    }

    /**
     * @description Close an opportunity if all payments have been received.
     * This will update the StageName of newOpp, in place, if "all payments
     * received" conditions are satisfied.
     * This method will not execute if Advanced Currency Mgt is enabled. In that
     * case, a trigger on the Payment object is used to auto-close the Opportunity.
     * @param oldOpp The opportunity before being updated
     * @param newOpp The opportunity after being updated
     * @param closedStageName The name of an opportunity stage that corresponds to Closed/Won to transition to if all payments are determined to be received
     * @param totalPaymentAmount The total amount of all Paid Payment records for the Opportunity
     * @return void
     */
    private void closeOpportunityIfAllPaymentsReceived(Opportunity oldOpp, Opportunity newOpp, String closedStageName,
            Decimal totalPaymentAmount) {
        Boolean amountUpdated = (oldOpp.Amount != newOpp.Amount);
        Boolean paymentAmountReceivedUpdated = (oldOpp.npe01__Payments_Made__c != totalPaymentAmount);
        Boolean amountPositive = (newOpp.Amount > 0);
        Boolean isNotAndWasNotClosed = (!oldOpp.IsClosed && !newOpp.IsClosed);
        Boolean amountEqualPaymentReceived = (newOpp.Amount == totalPaymentAmount);
        Boolean stageNameSpecified = !String.isEmpty(closedStageName);

        if (
            (amountUpdated || paymentAmountReceivedUpdated)
            && amountPositive
            && isNotAndWasNotClosed
            && amountEqualPaymentReceived
            && stageNameSpecified
        ) {
            newOpp.StageName = closedStageName;
        }
    }

    /*******************************************************************************************************
    * @description When Advanced Currency Management is enabled in an org, the packaged rollups and formula
    * from the Payment object will not work. This method will detect that scenario and return either the
    * value from the formula or calculate the Amount Outstanding from the payment records
    * track this.
    * @param currentOpp = Opportunity object with a subquery on all Payment records
    * @return Decimal amount outstanding
    */
    public static Decimal getAmountOutstanding(Opportunity currentOpp) {
        if (!UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled()) {
            return currentOpp.npe01__Amount_Outstanding__c;
        } else {
            // calculate the value since the roll-ups and formula are not functional with ACM
            Decimal totalPayments = 0;
            Decimal amtWrittenOff = 0;
            for (npe01__OppPayment__c pmt : currentOpp.npe01__OppPayment__r) {
                if (pmt.npe01__Paid__c == true) {
                    totalPayments += pmt.npe01__Payment_Amount__c;
                }
                if (pmt.npe01__Written_Off__c == true) {
                    amtWrittenOff += pmt.npe01__Payment_Amount__c;
                }
            }
            return (currentOpp.Amount - totalPayments - amtWrittenOff);
        }
    }

    /*******************************************************************************************************
    * @description When Advanced Currency Management is enabled in an org, the packaged rollups and formula
    * from the Payment object will not work. This method will detect that scenario and return either the
    * value from the formula or calculate the Total Payments (Paid) from the payment records
    * track this.
    * @param currentOpp = Opportunity object with a subquery on all Payment records
    * @return Decimal total of payment records where Paid = True
    */
    public static Decimal getPaymentsMade(Opportunity currentOpp) {
        if (!UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled()) {
            return currentOpp.npe01__Payments_Made__c;
        } else {
            // calculate the value since the roll-ups and formula are not functional with ACM
            Decimal totalPayments = 0;
            for (npe01__OppPayment__c pmt : currentOpp.npe01__OppPayment__r) {
                if (pmt.npe01__Paid__c == true) {
                    totalPayments += pmt.npe01__Payment_Amount__c;
                }
            }
            return totalPayments;
        }
    }

    /**
     * @description Build a query string to retrieve a list of Opportunities with a subquery on the Payments object.
     * Does not include a Where clause.
     * @return SOQL string
     */
    private static String buildOppsQuery() {
        String soqlStatement = '';
        soqlStatement += 'SELECT Id, CloseDate, Amount, isClosed, isWon, npe01__Do_Not_Automatically_Create_Payment__c, Type, ';
        if (OppRecordTypeId != null) {
            soqlStatement += 'RecordTypeId, ';
        }
        for (string s : paymentMappings.keyset()) {
            npe01__Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
            if (!soqlStatement.contains(pfms.npe01__Opportunity_Field__c)) {
                soqlStatement += pfms.npe01__Opportunity_Field__c + ', ';
            }
        }
        if (OppCurrencyField!=null) {
            soqlStatement += 'CurrencyIsoCode, ';
        }
        soqlStatement += 'npe01__payments_made__c, ';
        string soqlSub = '(SELECT id, npe01__Paid__c, npe01__Payment_Amount__c, npe01__Payment_Date__c, npe01__Written_Off__c, ';
        for (string s : paymentMappings.keyset()) {
            npe01__Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
            if (!soqlSub.contains(pfms.npe01__Payment_Field__c)) {
                soqlSub += pfms.npe01__Payment_Field__c + ', ';
            }
        }
        soqlStatement += soqlSub;
        soqlStatement += 'npe01__scheduled_date__c ';
        soqlStatement += 'FROM Opportunity.npe01__OppPayment__r) FROM Opportunity ';

        return soqlStatement;
    }
}