@isTest
private class DonationSelector_TEST {

    @isTest
    static void shouldReturnCorrectQueryString() {
        DonationSelector selector = new DonationSelector();

        String expectedQueryStringForOrganizationDonor = expectedQueryString(Account.getSObjectType());
        String actualQueryStringForOrganizationDonor = selector.openDonationsQueryString(
            SObjectType.Opportunity.fields.AccountId.Name, 'DUMMY_ID');
        System.assertEquals(expectedQueryStringForOrganizationDonor, actualQueryStringForOrganizationDonor);

        String expectedQueryStringForContactDonor = expectedQueryString(Contact.getSObjectType());
        String actualQueryStringForContactDonor = selector.openDonationsQueryString(
            SObjectType.Opportunity.fields.Primary_Contact__c.Name, 'DUMMY_ID');
        System.assertEquals(expectedQueryStringForContactDonor, actualQueryStringForContactDonor);
    }

    private static String expectedQueryString(SObjectType donorType) {
        return 'SELECT Id, ' +
            'Name, ' +
            'StageName, ' +
            'CloseDate, ' +
            'IsClosed, ' +
            'Amount, ' +
            'npe01__Number_of_Payments__c, ' +
                '(SELECT Id, ' +
                    'Name, ' +
                    'npe01__Scheduled_Date__c, ' +
                    'npe01__Opportunity__r.Name, ' +
                    'npe01__Opportunity__c, ' +
                    'npe01__Payment_Amount__c, ' +
                    'npe01__Payment_Date__c, ' +
                    'npe01__Paid__c, ' +
                    'npe01__Written_Off__c, ' +
                    String.valueOf(npe01__OppPayment__c.Elevate_Payment_API_Status__c) + ' ' +
                'FROM npe01__OppPayment__r ' +
                'WHERE npe01__Written_Off__c = false ' +
                'AND npe01__Paid__c = false), ' +
                '(SELECT Id, ' +
                    'Role, ' +
                    'ContactId ' +
                'FROM OpportunityContactRoles) ' +
            'FROM Opportunity ' +
            'WHERE ' + getRelationshipFieldFor(String.valueOf(donorType)) + ' = :donorId ' +
            'AND IsClosed = false ' +
            'WITH SECURITY_ENFORCED ' +
            ' ORDER BY CloseDate ASC';
    }

    private static String getRelationshipFieldFor(String donorType) {
        String relationshipField;
        if (donorType == SObjectType.Account.Name) {
            relationshipField = SObjectType.Opportunity.fields.AccountId.Name;
        } else if (donorType == SObjectType.Contact.Name) {
            relationshipField = SObjectType.Opportunity.fields.Primary_Contact__c.Name;
        }
        return relationshipField;
    }
}
