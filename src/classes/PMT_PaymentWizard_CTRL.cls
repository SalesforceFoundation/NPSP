/*
    Copyright (c) 2011, Salesforce.com Foundation
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
* @author Evan Callahan & Steve Andersen
* @date 2008/7 (2.1)
* @description Controller for payment creation wizard
*/
public with sharing class PMT_PaymentWizard_CTRL {

    //Opportunity for the opp we're coming from
    public Opportunity CurrentOpp { get; private set; }

    public boolean haveAmount { get; private set; }
    
    // Class that stores numbered payment
    public class payment {
        public integer paymentNumber { get; private set; }
        public npe01__OppPayment__c oppPayment { get; set; }
        
        public payment(integer i) {
            paymentNumber = i;
            oppPayment = new npe01__OppPayment__c();
        }
    }

    //values from payments mappings
    public static map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappings = new map<string, npe01__Payment_Field_Mapping_Settings__c>();
    public static map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappingsAll = new map<string, npe01__Payment_Field_Mapping_Settings__c>();
    public static map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappingsToRemove = new map<string, npe01__Payment_Field_Mapping_Settings__c>();
    
    //which wizard?
    public boolean isWriteoffWizard{get; set;}
    public boolean isScheduleWizard{get; set;}
    
    
    //list of payments
    list<payment> newPayments = new list<payment>();
    //get the payments
    public List<payment> getPayments() {
        return newPayments ;
    }
  
    public npe01__oppPayment__c samplePayment { get; set; }
    public npe01__oppPayment__c writeoffPayment { get; set; }
    
    //number of outstanding payments for the opp
    public integer outstanding_payments {get; set;}
    
    //decimal for amount float
    public Decimal OppAmountFloat { get; set; }

    //integer for the number of installments to create
    public Integer numberOfPayments { get; set; }

    //integer to hold the interval chosen
    public Integer interval { get; set; }
    
    //boolean to remove paid payments and create a new schedule
    public boolean removePaidPayments { get; set; }

    //public npe01__Payments_Settings__c PaymentsSettings;
    public npe01__Contacts_and_Orgs_Settings__c PaymentsSettings;
    
    public npe01__Contacts_and_Orgs_Settings__c getPaymentsSettings(){
        if (PaymentsSettings == null)
           PaymentsSettings = UTIL_CustomSettingsFacade.getContactsSettings();
        
        return PaymentsSettings;
    }
  
    //constructor
    public PMT_PaymentWizard_CTRL() {
        
        if(ApexPages.currentPage().getParameters().get('wtype') == 'writeoff'){
            PaymentWriteoffWizard();
            isWriteoffWizard = true;
            isScheduleWizard = false;
            
        }
        else if (ApexPages.currentPage().getParameters().get('wtype') == 'payment'){
            SetupPaymentWizard();
            isWriteoffWizard = false;
            isScheduleWizard = true;            
        }
        else{           
            //error?
        }       
    }
    
    public void SetupPaymentWizard() {
        String id = ApexPages.currentPage().getParameters().get('id');
        String query = 'select name, amount, stagename, npe01__payments_made__c, npe01__amount_outstanding__c, description, closedate, npe01__Number_of_Payments__c';
       
        //if currencyiso field exists add it to query for use later
        if(Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode') != null)
            query = query + ',CurrencyIsoCode';
            
        query += ' from Opportunity where id = :id';
        opportunity[] o = Database.query(query);
        if (o.isEmpty()) {
            haveAmount = false;
        } else {
            currentOpp = o[0];
            haveAmount = (currentOpp.npe01__amount_outstanding__c > 0);
            samplePayment = new npe01__OppPayment__c();
            samplePayment.npe01__Scheduled_Date__c = system.today();
            numberOfPayments = 12;
            interval = 1;
            intervalUnit = 'Month';
        }
    }
    
    public void PaymentWriteoffWizard() {
        opportunity[] o = [select name, amount, stagename, npe01__payments_made__c, npe01__amount_outstanding__c, description, closedate, npe01__Number_of_Payments__c from Opportunity where id =:ApexPages.currentPage().getParameters().get('id')];
        if (o.isEmpty()) {
            haveAmount = false;
        } else {
            currentOpp = o[0];
            integer paymentcount = 0;
            paymentcount = [select count() from npe01__OppPayment__c where npe01__Opportunity__c = :o[0].id and npe01__Paid__c != true];
            
            outstanding_payments = paymentcount;
            haveAmount = (currentOpp.npe01__amount_outstanding__c > 0);
            writeoffPayment = new npe01__OppPayment__c();
            writeoffPayment.npe01__Payment_Amount__c = currentOpp.npe01__amount_outstanding__c;
            writeoffPayment.npe01__Written_Off__c = true;
            writeoffPayment.npe01__Opportunity__c = currentOpp.Id;
            writeoffPayment.npe01__Payment_Date__c = system.today();
        }
    }
    
    public pageReference calculate() {
        if (haveAmount || removePaidPayments) {
            // clear the list
            newPayments.clear();
                        
            Decimal OppAmountFloat = currentOpp.npe01__Amount_Outstanding__c;
            if (removePaidPayments == true)
                OppAmountFloat = currentOpp.Amount;
    
            //divide the amount by the number of installments, and deal with the remainder
            Decimal paymentAmount = OppAmountFloat.divide(numberOfPayments, 2, system.roundingmode.FLOOR);
            decimal remainder = OppAmountFloat - (paymentAmount * numberOfPayments);
    
            // get the start date
            date nextDate = samplePayment.npe01__Scheduled_Date__c;
            
            // Multicurrency support
            // James Melville 05/03/2011 Added to support multi-currency sfdc.  */
            // CurrencyIsoCode doesn't exist in non-multi-currency orgs
            SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
            SObjectField PaymentCurrencyField = Schema.sObjectType.npe01__OppPayment__c.fields.getMap().get('CurrencyIsoCode');
            
            for(Integer i=1; i <= numberOfPayments; i++){

                // create the payment record    
                payment thisPayment = new payment(i);
                // set values on the oppPayment object
                thisPayment.oppPayment.npe01__Opportunity__c=currentOpp.id;
                thisPayment.oppPayment.npe01__Scheduled_Date__c=nextDate;
                thisPayment.oppPayment.npe01__payment_method__c=samplePayment.npe01__payment_method__c;

                // add the extra pennies, if any
                if (remainder > 0) {
                    thisPayment.oppPayment.npe01__Payment_Amount__c = paymentAmount + .01;
                    remainder-=.01;
                } else {
                    thisPayment.oppPayment.npe01__Payment_Amount__c = paymentAmount;
                }
                
                //in multicurrency SFDC set the payment currency field to equal the opp currency
                if(PaymentCurrencyField != null && OppCurrencyField != null)
                    thisPayment.oppPayment.put(PaymentCurrencyField,CurrentOpp.get(OppCurrencyField));
                
                //put the payment in the list
                newPayments.add(thisPayment);
    
                //add the interval unit
                if (intervalUnit == 'Week') {
                    nextDate = nextDate.addDays(7 * interval); 
                } else if (intervalUnit == 'Month') {
                    nextDate = nextDate.addMonths(interval); 
                } else if (intervalUnit == 'Year') {
                    nextDate = nextDate.addYears(interval);
                } 
            }
        }
        return null;
    }
    
    public pageReference writeoff() {
    	Savepoint sp = Database.setSavepoint();
    	try {
	        list<npe01__OppPayment__c> paymentsToDelete = new list<npe01__OppPayment__c>();
	        npe01__OppPayment__c[] delPymnts = [select id, npe01__Paid__c from npe01__OppPayment__c where npe01__OppPayment__c.npe01__Opportunity__c = :CurrentOpp.Id];
	        
	        for (npe01__OppPayment__c thisPayment : delPymnts){
	            if(thisPayment.npe01__Paid__c == False){
	                paymentsToDelete.add(thisPayment);
	            }
	        }
	        if (!paymentsToDelete.isEmpty()) delete paymentsToDelete;
	        insert writeoffPayment;
	        PageReference oldOppPage = new PageReference('/' + currentOpp.id);
	        oldOppPage.setRedirect(true);
	        return oldOppPage;
    	} catch(Exception e) {
    		Database.rollback(sp);
    		ERR_Handler.processError(e, ERR_Handler_API.Context.PMT);
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    		return null;
    	}
    }

    //list of items for picklist of the number of payments to be created
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        Decimal maxPayments;
        if (getPaymentsSettings().Max_Payments__c != null)
            maxPayments = PaymentsSettings.Max_Payments__c;
        else
            maxPayments = 12;
        
        for (integer i=1; i<=maxPayments; i++) {
            string s=i.format();
            options.add(new SelectOption(s, s));
        }
        return options;
    }

    //list of items for picklist of the interval between payments to be created
    public List<SelectOption> getIntervals() {
        List<SelectOption> options = new List<SelectOption>();
        for (integer i=1; i<=12; i++) {
            string s=i.format();
            options.add(new SelectOption(s, s));
        }
        return options;
    }

    //the unit of the interval
    public String intervalUnit { get; set; }

    //list of items for picklist of the interval unit between payments to be created
    public List<SelectOption> getIntervalUnits() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Week','Week'));
        options.add(new SelectOption('Month','Month'));
        options.add(new SelectOption('Year','Year'));
        return options;
    }

    public PageReference createPayments() {
    	Savepoint sp = Database.setSavepoint();
        try {
	        // first delete unpaid payments
	        npe01__oppPayment__c[] old = [select id from npe01__oppPayment__c where npe01__opportunity__c = :currentOpp.id and npe01__paid__c = false];
	        if (!old.isEmpty()) delete old;
	        
	        // If deleting paid Payments, delete paid payments
	        npe01__oppPayment__c[] oldPaid = [select id from npe01__oppPayment__c where npe01__opportunity__c = :currentOpp.id and npe01__paid__c = true];
	        if (!oldPaid.isEmpty() && removePaidPayments == true) delete oldPaid;
	        
	        // get the new payments into a list
	        npe01__oppPayment__c[] pmts = new npe01__oppPayment__c[0];
	        for (payment p : newPayments) pmts.add(p.oppPayment);
	        
	        // create the payment records
	        insert pmts;
	        
	        // Send the user to the detail page for the new account.
	        PageReference oldOppPage = new PageReference('/' + currentOpp.id);
	        oldOppPage.setRedirect(true);
	        return oldOppPage;
        
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.PMT);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
    
    public pageReference RemovePaidPayments() {
        removePaidPayments = true;
        return null;
    }
   
}