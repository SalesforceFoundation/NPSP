/*
    Copyright (c) 2012, Salesforce.com Foundation
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
/**
* @author Salesforce.com Foundation
* @date 2012 (2.0)
* @description Supports the automatic scheduling of recurring donation updates  
*/
global class RD_RecurringDonations_SCHED implements Schedulable {

    global void execute(SchedulableContext SC) { 
        string openLabel = system.label.npe03.RecurringDonationOpenStatus;
        string queryRCD = 'select id,npe03__Open_Ended_Status__c, npe03__Next_Payment_Date__c, npe03__Organization__c, ' + 
            'npe03__Contact__c,npe03__Installment_Amount__c,npe03__Installments__c,npe03__Amount__c,npe03__Total__c,npe03__Installment_Period__c, ' +
            'npe03__Date_Established__c,npe03__Donor_Name__c,npe03__Schedule_Type__c,npe03__Recurring_Donation_Campaign__c,npe03__Total_Paid_Installments__c ';
            //add any custom mapping to make sure we have the required fields
        map<string, npe03__Custom_Field_Mapping__c> cfmMap = new map<string, npe03__Custom_Field_Mapping__c>();
        cfmMap = npe03__Custom_Field_Mapping__c.getAll();
        for (string s : cfmMap.keySet()){
            queryRCD = queryRCD + ',' + cfmMap.get(s).npe03__Recurring_Donation_Field__c;
        }
            //if currencyiso field exists add it to query for use later
        if(Schema.sObjectType.npe03__Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode') != null)
            queryRCD = queryRCD + ',CurrencyIsoCode';
        queryRCD=queryRCD+' from npe03__Recurring_Donation__c where npe03__Open_Ended_Status__c = \'' + openLabel + '\'';
        
        //call the batch job, processing 50 at a time 
        Id batchInstanceId = Database.executeBatch(new RD_RecurringDonations_BATCH(queryRCD), 50);    
    }
       
}