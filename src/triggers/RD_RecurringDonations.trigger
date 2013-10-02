/*
    Copyright (c) 2009, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
trigger RD_RecurringDonations on npe03__Recurring_Donation__c (before insert, before update, before delete, 
after insert, after update, after delete, after undelete) {
    
    /// <name> triggerAction </name>
    /// <summary> contains possible actions for a trigger </summary>
    npe03__Recurring_Donations_Settings__c rds = RD_RecurringDonations.getRecurringDonationsSettings();
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
    
    if (!rds.npe03__DISABLE_RecurringDonations_trigger__c && RD_ProcessControl.hasRun != true){ 
    
        if(Trigger.isBefore && Trigger.isInsert){
            RD_RecurringDonations process = new RD_RecurringDonations (trigger.new, trigger.old, triggerAction.beforeInsert);
        }        
        if(Trigger.isBefore && Trigger.isDelete ){
            RD_RecurringDonations process = new RD_RecurringDonations (trigger.oldMap, trigger.oldMap, triggerAction.beforeDelete);
        }
        if(Trigger.isInsert && Trigger.isAfter){
            //James Melville 05/03/2011 Dynamically build Recurring donation query to allow currency to be included if needed.
            //build start of dynamic query
            
            set<string> existingFields = new set<string>{  'npe03__open_ended_status__c', 'npe03__next_payment_date__c', 'name',
                                                           'npe03__organization__c', 'npe03__contact__c', 'npe03__installment_amount__c',
                                                           'npe03__installments__c', 'npe03__amount__c', 'npe03__total__c', 'npe03__installment_period__c',
                                                           'npe03__date_established__c', 'npe03__donor_name__c', 'npe03__schedule_type__c', 
                                                           'npe03__recurring_donation_campaign__c', 'npe03__total_paid_installments__c'};
            
            String queryRCD = 'select id';
            for (string s : existingFields){
                queryRCD += ', ' + s;               
            }
       
            //add any custom mapping to make sure we have the required fields
            map<string, npe03__Custom_Field_Mapping__c> cfmMap = new map<string, npe03__Custom_Field_Mapping__c>();
            cfmMap = npe03__Custom_Field_Mapping__c.getAll();
            for (string s : cfmMap.keySet()){
                string RDFieldName = cfmMap.get(s).npe03__Recurring_Donation_Field__c;             
                if (!existingFields.contains(RDFieldName.toLowerCase()) && s != 'id'){
                   queryRCD = queryRCD + ',' + cfmMap.get(s).npe03__Recurring_Donation_Field__c;
                   existingFields.add(RDFieldName.toLowerCase());   
                }
            }       
       
            //if currencyiso field exists add it to query for use later
            if(Schema.sObjectType.npe03__Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode') != null)
                queryRCD = queryRCD + ',CurrencyIsoCode';
       
            //continue building query - dynamic apex does not allow nested binds (:Trigger.new) so we build a list
            List<Id> ids = new List<Id>();
        
            for(npe03__Recurring_Donation__c r : Trigger.new){
                ids.add(r.Id);
            }
        
            //Trigger.new.Id;
            queryRCD=queryRCD+' from npe03__Recurring_Donation__c where Id in :ids';
            //execute query
            npe03__Recurring_Donation__c[] updatedRecurringDonations = Database.query(queryRCD);
            map<id, npe03__Recurring_Donation__c> updatedRDs = new map<id, npe03__Recurring_Donation__c>();
            for (npe03__Recurring_Donation__c rd : updatedRecurringDonations){
                updatedRDs.put(rd.id, rd);            
            }
            RD_RecurringDonations process = new RD_RecurringDonations (updatedRDs, trigger.oldMap, triggerAction.afterInsert);
        }
    
        if(Trigger.isUpdate && Trigger.isAfter){
            RD_RecurringDonations process = new RD_RecurringDonations (trigger.newMap, trigger.oldMap, triggerAction.afterUpdate);
        }
    }    
}