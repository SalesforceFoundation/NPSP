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

    @TestVisible
    private static DonationHistoryService historyService {
        get {
            if (historyService == null) {
                historyService = new DonationHistoryService();
            }
            return historyService;
        }

        set {
            historyService = value;
        }
    }
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Donation History App view inner class.
    */
    public class DonationHistoryAppView {
        @AuraEnabled public List<DonationHistoryView> donations;
        @AuraEnabled public Boolean isPaymentsEnabled;
        @AuraEnabled public String paymentMethodLabel;
        @AuraEnabled public Integer totalNumberOfRecords;
    }

    private static final String EMPTY_PAYMENT_METHOD = '-';
    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Donation History inner class.
    */
    public class DonationHistoryView {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Date closeDate;
        @AuraEnabled public String creditType;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String paymentMethod;
        public DonationHistoryView(Opportunity ocr, String paymentMethod) {
            this.id = ocr.Id;
            this.name = ocr.Name;
            this.closeDate = ocr.CloseDate;
            this.amount = ocr.Amount;
            this.creditType = System.Label.CRLP_HardCredit;
            this.paymentMethod = paymentMethod;
        }
    }

    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History list.
    */
    @AuraEnabled(cacheable=true)
    public static DonationHistoryAppView getDonationHistory(Id contactId, Integer offset, String filter) {
        contactId = (contactId == null ? getContactIdByUserId() : contactId );
        DonationHistoryService service = new DonationHistoryService();
        try {
            Boolean paymentsEnabled = historyService.checkIfPaymentsAreEnabled();
            DonationHistoryAppView donationHistories = new DonationHistoryAppView();
            donationHistories.donations = buildHistoryFromOpportunities(historyService.getDonationHistory(contactId, offset, filter), contactId, paymentsEnabled);
            donationHistories.totalNumberOfRecords = historyService.getTotalNumberOfRecords(contactId, filter);
            donationHistories.isPaymentsEnabled = paymentsEnabled;
            donationHistories.paymentMethodLabel = historyService.getPaymentMethodLabel();
            return donationHistories;
        } catch(AuraHandledException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description returns the years when the contact made at least 1 donation
     * @param contactId Id of the contact
     * @return List<String>
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getYearsWithDonations(Id contactId) {
        try {

            contactId = (contactId == null ? getContactIdByUserId() : contactId );
            return historyService.getYearsWithDonationsForContact(contactId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method creates list of DonationHistoryView to return to LWC
    * @return List<DonationHistoryView>
    */
    private static List<DonationHistoryView> buildHistoryFromOpportunities(List<Opportunity> opportunities, Id contactId, Boolean includePaymentMethod) {
        DonationHistoryService service = new DonationHistoryService();
        List<DonationHistoryView> donationHistories = new List<DonationHistoryView>();
        for (Opportunity opp : opportunities) {
            if(opp.npe01__OppPayment__r != null && opp.npe01__OppPayment__r.size() > 0){
                String paymentMethod = includePaymentMethod
                	? service.getRequiredPaymentMethodForOpportunities(opp.npe01__OppPayment__r)
                	: EMPTY_PAYMENT_METHOD;
            	donationHistories.add(new DonationHistoryView(opp, paymentMethod));
            } else {
                donationHistories.add(new DonationHistoryView(opp, EMPTY_PAYMENT_METHOD));
            }
        }
        return donationHistories;
    }

    @AuraEnabled(cacheable=true)
    public static Id getContactIdByUserId(){
        return USER_UserService.getContactIdByUserId();
    }
}