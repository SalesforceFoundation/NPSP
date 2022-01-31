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
    
    static final String NPSP_CREDIT_ROLES = 'NPSP_OppsSoftCreditRoles';
    private List<Opportunity> credits;
    private Id contactId;
    private Integer offset;
    
    public DonationHistoryService(Id contactId, Integer offset) {
        this.contactId = contactId;
        this.offset    = offset;
    }

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

    private DonationHistorySelector selector {
        get {
            if(selector == null) {
                selector = new DonationHistorySelector();
            }
            return selector;
        }
        set;
    }

    private Boolean hasAccessToDonationHistory() {
        return permissions.canRead(Opportunity.SObjectType, new Set<SObjectField>{
            Opportunity.Amount,
            Opportunity.CloseDate,
            Opportunity.Name
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
    public List<Opportunity> getDonationHistory() {
        if (hasAccessToDonationHistory()) {
            return selector.getWonOpportunitiesByContactId(this.contactId, this.offset);
        } else {
            throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
        }
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History Number of Records for infinite scroll.
    * @param contactId contact id which is going to be requested.
    */
    public Integer getTotalNumberOfRecords() {
        return selector.getTotalNumberOfRecords(this.contactId);
    }

}