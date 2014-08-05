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
* @date 2012 (2.2)
* @description The controller for the VF page invoked by using the Refresh Opportunities button
*/
public with sharing class RD_AddDonationsBTN_CTRL {

    public string returnURL{get; set;}
    public npe03__Recurring_Donation__c RecurringDonation{get; set;}    
    
    public RD_AddDonationsBTN_CTRL(ApexPages.StandardController controller){
        //set the return URL
        RecurringDonation = (npe03__Recurring_Donation__c)Controller.getRecord();
        PageReference pageRef = new PageReference('/' + RecurringDonation.id);
        returnurl = pageref.getUrl();
        
    }
    
    public PageReference buttonClick(){
        Savepoint sp = Database.setSavepoint();
        try {
            system.assert(RecurringDonation != null);
        
            // these must be lowercase so set.contains() will work
	        set<string> existingFields = new set<string>{  'npe03__open_ended_status__c', 'npe03__next_payment_date__c', 'name', 'npe03__paid_amount__c',
	                                                       'npe03__organization__c', 'npe03__contact__c', 'npe03__installment_amount__c',
	                                                       'npe03__installments__c', 'npe03__amount__c', 'npe03__total__c', 'npe03__installment_period__c',
	                                                       'npe03__date_established__c', 'npe03__donor_name__c', 'npe03__schedule_type__c', 
	                                                       'npe03__recurring_donation_campaign__c', 'npe03__total_paid_installments__c', 'ownerid'};                                                                       
            String qString = 'select id';
            for (string s : existingFields){
                qString += ', ' + s;               
            }
       
            //add any custom mapping to make sure we have the required fields
            map<string, npe03__Custom_Field_Mapping__c> cfmMap = new map<string, npe03__Custom_Field_Mapping__c>();
            cfmMap = npe03__Custom_Field_Mapping__c.getAll();
            for (string s : cfmMap.keySet()){
                string RDFieldName = cfmMap.get(s).npe03__Recurring_Donation_Field__c;             
                if (!existingFields.contains(RDFieldName.toLowerCase()) && s != 'id'){
                   qString = qString + ',' + cfmMap.get(s).npe03__Recurring_Donation_Field__c;
                   existingFields.add(RDFieldName.toLowerCase());   
                }
            }                                                  
                            
	        qString += ' from npe03__Recurring_Donation__c ';
	        qString += ' where id = \'' + RecurringDonation.id + '\'';
	        RecurringDonation = (npe03__Recurring_Donation__c)database.query(qString);
	        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{RecurringDonation});
	        
	        PageReference pageRef = new PageReference(returnurl);
	        pageRef.setRedirect(true);
	        return pageRef;
        
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.PMT);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        
    }
    

}