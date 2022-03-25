/*
    Copyright (c) 2021 Salesforce.org
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
* @description Donation History Service class in NPSP.
*/
public with sharing class DonationHistoryService {

    @TestVisible
    private UTIL_Permissions permissions {
        get {
            if(permissions == null) {
                permissions = new UTIL_Permissions();
            }
            return permissions;
        }
        set;
    }

    @TestVisible
    private DonationHistorySelector selector {
        get {
            if(selector == null) {
                selector = new DonationHistorySelector();
            }
            return selector;
        }
        set { 
            this.selector = value;
        }
    }

    private Boolean hasAccessToDonationHistory() {
        return permissions.canRead(Opportunity.SObjectType, new Set<SObjectField>{
            Opportunity.Amount,
            Opportunity.CloseDate
        }) && permissions.canRead(Contact.SObjectType, new Set<SObjectField>{
            Contact.Email,
            Contact.Name
        }) && permissions.canRead(User.SObjectType, new Set<SObjectField>{
            User.ContactId
        }) && permissions.canRead(npe01__OppPayment__c.SObjectType, new Set<SObjectField>{
            npe01__OppPayment__c.npe01__Payment_Method__c,
            npe01__OppPayment__c.npe01__Opportunity__c
        });
    }

    public Boolean checkIfPaymentsAreEnabled() {
        return npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults().npe01__Payments_Enabled__c;
    }

    public String getPaymentMethodLabel() {
        return Schema.DataImport__c.Payment_Method__c.getDescribe().getLabel();
    }
    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History list.
    * @return List<Opportunity> returns Opportunities and Payment Method for them.
    */
    public List<Opportunity> getDonationHistory(Id contactId, Integer offset, String filter) {
        if (hasAccessToDonationHistory()) {
            List<Opportunity> credits = null;
            if (shouldApplyFilterByYear(filter)) {
                credits = selector.getWonOpportunitiesByContactIdAndYear(contactId, offset, Integer.valueOf(filter));
            } else { 
                credits = selector.getWonOpportunitiesByContactId(contactId, offset);
            }
            return credits;
        } else {
            throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
        }
    }

    /** 
    * @description method to return Payment Method associated to Donations
    * @param paymentListForOpportunity List<npe01__OppPayment__c> for current opportunity
    * @return String with payment method for current opportunity. This returns the first Paid Payment Method unless
    * none are paid, in which case it returns the first Payment Method
    */
    public String getRequiredPaymentMethodForOpportunities(List<npe01__OppPayment__c> paymentListForOpportunity){
        String paymentMethodToReturn = '';
        for (npe01__OppPayment__c p : paymentListForOpportunity) {
            if (p.npe01__Paid__c) {
                paymentMethodToReturn = p.npe01__Payment_Method__c;
                break;
            }
            if (paymentMethodToReturn == '') {
                paymentMethodToReturn = p.npe01__Payment_Method__c;
                continue;
            }
        }
        return paymentMethodToReturn;
    }

    private boolean shouldApplyFilterByYear(String filter) {
        return filter != null && filter.isNumeric();
    }

    /**
     * @descritpion returns the years where the contact made at least 1 donation.
     * @param contactId the contact id.
     * @return List<String>
     */
    public List<String> getYearsWithDonationsForContact(Id contactId) {
        
        if (!hasAccessToDonationHistory()) {
            throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
        }
        return selector.getYearsWithDonationForContact(contactId);
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History Number of Records for infinite scroll.
    * @param contactId contact id which is going to be requested.
    */
    public Integer getTotalNumberOfRecords(Id contactId, String filter) {
        if (shouldApplyFilterByYear(filter)) {
            return selector.getTotalNumberOfRecordsWithYear(contactId, Integer.valueOf(filter));
        }
        return selector.getTotalNumberOfRecords(contactId);
    }
}