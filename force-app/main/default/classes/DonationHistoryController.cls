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
        @AuraEnabled public Boolean isPrimary;
        @AuraEnabled public Date closeDate;
        @AuraEnabled public String role;
        @AuraEnabled public String creditType;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String paymentMethod;
        public DonationHistoryView(OpportunityContactRole ocr, String type){
            this.id = ocr.Id;
            this.isPrimary = ocr.isPrimary;
            this.closeDate = ocr.Opportunity.CloseDate;
            this.role = ocr.Role;
            this.amount = ocr.Opportunity.Amount;
            this.creditType = type;
            this.paymentMethod = 'Cash';
        }
    }

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
            service.buildDonationHistory();
            donationHistories.addAll(buildHistoryFromOCRs(service.getHardCredits(), System.Label.CRLP_HardCredit));
            donationHistories.addAll(buildHistoryFromOCRs(service.getSoftCredits(), System.Label.CRLP_SoftCredit));
            donationHistories.addAll(buildHistoryFromOCRs(service.getPartialSoftCredits(), service.getSoftCreditLabel()));
            return donationHistories;
        } catch(AuraHandledException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static List<DonationHistoryView> buildHistoryFromOCRs(List<OpportunityContactRole> contactRoles, String type) {
        List<DonationHistoryView> donationHistories = new List<DonationHistoryView>();
        for(OpportunityContactRole role : contactRoles) {
            donationHistories.add(new DonationHistoryView(role, type));
        }
        return donationHistories;
    }
}