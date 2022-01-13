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
* @description Selector class for Opportunities
*              and its Payments and OpportunityContactRoles in NPSP.
*/
public with sharing class DonationSelector {
    
    public DonationSelector() {}

    public List<Opportunity> getOpenDonations(String relationshipField, Id donorId) {
        return Database.query(openDonationsQueryString(relationshipField, donorId));
    }

    public List<Opportunity> getDonation(Id opportunityId) {
        return getDonations(new List<Id> { opportunityId });
    }

    public List<Opportunity> getDonations(List<Id> opportunityIds) {
        List<String> selectFields = new List<String> {
            opportunityContactRoleSubqueryString()
        };
        selectFields.addAll(opportunityFields());

        String soql = new UTIL_Query()
            .withFrom(Opportunity.SObjectType)
            .withSelectFields(selectFields)
            .withWhere('Id IN :opportunityIds')
            .withSecurityEnforced()
            .build();

        return Database.query(soql);
    }

    @TestVisible
    private String openDonationsQueryString(String relationshipField, String donorId) {
        List<String> opportunityFields = new List<String> {};
        opportunityFields.addAll(opportunityFields());
        opportunityFields.add(paymentsSubqueryString());
        opportunityFields.add(opportunityContactRoleSubqueryString());

        List<String> whereClause = new List<String> {
            relationshipField +' = :donorId',
            String.valueOf(Opportunity.IsClosed) + ' = false'
        };

        String soql = new UTIL_Query()
            .withFrom(Opportunity.SObjectType)
            .withSelectFields(opportunityFields)
            .withWhere(whereClause)
            .withOrderBy(String.valueOf(Opportunity.CloseDate) + ' ASC')
            .withSecurityEnforced()
            .build();

        return soql;
    }

    private List<String> opportunityFields() {
        return new List<String> {
            String.valueOf(Opportunity.Id),
            String.valueOf(Opportunity.Name),
            String.valueOf(Opportunity.StageName),
            String.valueOf(Opportunity.CloseDate),
            String.valueOf(Opportunity.IsClosed),
            String.valueOf(Opportunity.Amount),
            String.valueOf(Opportunity.npe01__Number_of_Payments__c)
        };
    }

    private String paymentsSubqueryString() {
        List<String> paymentFields = new List<String> {
            String.valueOf(npe01__OppPayment__c.Id),
            String.valueOf(npe01__OppPayment__c.Name),
            String.valueOf(npe01__OppPayment__c.npe01__Scheduled_Date__c),
            'npe01__Opportunity__r.Name',
            String.valueOf(npe01__OppPayment__c.npe01__Opportunity__c),
            String.valueOf(npe01__OppPayment__c.npe01__Payment_Amount__c),
            String.valueOf(npe01__OppPayment__c.npe01__Payment_Date__c),
            String.valueOf(npe01__OppPayment__c.npe01__Paid__c),
            String.valueOf(npe01__OppPayment__c.npe01__Written_Off__c),
            String.valueOf(npe01__OppPayment__c.Elevate_Payment_API_Status__c)
        };

        List<String> whereClause = new List<String> {
            String.valueOf(npe01__OppPayment__c.npe01__Written_Off__c) + ' = false',
            String.valueOf(npe01__OppPayment__c.npe01__Paid__c) + ' = false'
        };

        String paymentsSubqueryString = new UTIL_Query()
            .withFrom('npe01__OppPayment__r')
            .withSelectFields(paymentFields)
            .withWhere(whereClause)
            .build();

        return '(' + paymentsSubqueryString + ')';
    }

    private String opportunityContactRoleSubqueryString() {
        List<String> opportunityContactRoleFields = new List<String> {
            String.valueOf(OpportunityContactRole.Id),
            String.valueOf(OpportunityContactRole.Role),
            String.valueOf(OpportunityContactRole.ContactId)
        };

        String opportunityContactRoleSubqueryString = new UTIL_Query()
            .withFrom('OpportunityContactRoles')
            .withSelectFields(opportunityContactRoleFields)
            .withWhere('isPrimary = false')
            .build();

        return '(' + opportunityContactRoleSubqueryString + ')';
    }
}
