/*
    Copyright (c) 2021, Salesforce.org
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
* @date 2021
* @group Donation
* @description Class for list donation history by credit type.
*/
public with sharing class DonationHistoryController {

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Donation History inner class.
    */
    public class DonationHistoryView{
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Date closeDate;
        @AuraEnabled public String creditType;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String paymentMethod;

        public DonationHistoryView(Opportunity ocr, String paymentMethod){
            this.id = ocr.Id;
            this.name = ocr.Name;
            this.closeDate = ocr.CloseDate;
            this.amount = ocr.Amount;
            this.creditType = System.Label.CRLP_HardCredit;
            this.paymentMethod = paymentMethod;
        }
    }
    
    private static String EMPTY_PAYMENT_METHOD = '-';


    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History list.
    */
    @AuraEnabled(cacheable=true)
    public static List<DonationHistoryView> getDonationHistory(Id contactId) {
        DonationHistoryService service = new DonationHistoryService(contactId);
        try {
            List<DonationHistoryView> donationHistories = new List<DonationHistoryView>();
            donationHistories.addAll(buildHistoryFromOCRs(service.getDonationHistory()));
            return donationHistories;
        } catch(AuraHandledException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return whether or not Payments are enabled in org
    * @return boolean isPaymentEnabled
    */
    @AuraEnabled(cacheable=true)
    public static boolean arePaymentsEnabled(){
        npe01__Contacts_And_Orgs_Settings__c settings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
		boolean isPaymentEnabled = settings.npe01__Payments_Enabled__c;
		return isPaymentEnabled;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method creates list of DonationHistoryView to return to LWC
    * @return List<DonationHistoryView>
    */
    private static List<DonationHistoryView> buildHistoryFromOCRs( List<Opportunity> contactRoles) {
        boolean isPaymentEnabled = arePaymentsEnabled();
        List<DonationHistoryView> donationHistories = new List<DonationHistoryView>();
        if(isPaymentEnabled){
            for(Opportunity role : contactRoles) {
            	donationHistories.add(new DonationHistoryView(role, role.npe01__OppPayment__r.get(0).npe01__Payment_Method__c));
        	}
        }else{
            for(Opportunity role : contactRoles) {
            	donationHistories.add(new DonationHistoryView(role, EMPTY_PAYMENT_METHOD));
        	}
        }
        return donationHistories;
    }
}