public with sharing class DonationSelector {
    
    public DonationSelector() {}

    public List<Opportunity> getOpenDonations(String relationshipField, Id donorId) {
        return Database.query(openDonationsQueryString(relationshipField, donorId));
    }

    @TestVisible
    private String openDonationsQueryString(String relationshipField, String donorId) {
        List<String> opportunityFields = new List<String> {
            String.valueOf(Opportunity.Id),
            String.valueOf(Opportunity.Name),
            String.valueOf(Opportunity.StageName),
            String.valueOf(Opportunity.CloseDate),
            String.valueOf(Opportunity.IsClosed),
            String.valueOf(Opportunity.Amount),
            String.valueOf(Opportunity.npe01__Number_of_Payments__c),
            paymentsSubqueryString(),
            opportunityContactRoleSubqueryString()
        };

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
            .build();

        return '(' + opportunityContactRoleSubqueryString + ')';
    }
}
