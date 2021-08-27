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
* @description DonationSelector tests.
*/
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
                'FROM OpportunityContactRoles ' +
                'WHERE isPrimary = false) ' +
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
