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
    static void shouldReturn1OpportunityWith3SoftCredits() {
        // Arrange
        List<Id> opportunityIds = setupTestOpportunitiesWithOpportunityContactRoles(1, 3);
        DonationSelector donationSelector = new DonationSelector();

        // Act
        List<Opportunity> opportunities = DonationSelector.getDonation(opportunityIds[0]);

        // Assert
        System.assertEquals(1, opportunities.size(),
            'Should return 1 opportunity');
        System.assertEquals(3, opportunities.get(0).OpportunityContactRoles.size(),
            'Should return 3 soft credits for opportunity');
    }

    @isTest
    static void shouldReturn5OpportunitiesWith2SoftCreditsEach() {
        // Arrange
        List<Id> opportunityIds = setupTestOpportunitiesWithOpportunityContactRoles(5, 2);
        DonationSelector donationSelector = new DonationSelector();

        // Act
        List<Opportunity> opportunities = donationSelector.getDonations(opportunityIds);

        // Assert
        System.assertEquals(5, opportunities.size(),
            'Should return 5 opportunities');
        System.assertEquals(2, opportunities.get(0).OpportunityContactRoles.size(),
            'Should return 2 soft credits for first opportunity');
        System.assertEquals(2, opportunities.get(1).OpportunityContactRoles.size(),
            'Should return 2 soft credits for second opportunity');
        System.assertEquals(2, opportunities.get(2).OpportunityContactRoles.size(),
            'Should return 2 soft credits for third opportunity');
        System.assertEquals(2, opportunities.get(3).OpportunityContactRoles.size(),
            'Should return 2 soft credits for fourth opportunity');
        System.assertEquals(2, opportunities.get(4).OpportunityContactRoles.size(),
            'Should return 2 soft credits for fifth opportunity');
    }

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

    private static List<Id> setupTestOpportunitiesWithOpportunityContactRoles(
        Integer opportunityCount, Integer softCreditCount) {

        Contact dummyContact = new Contact(LastName = 'Dummy Last Name', FirstName = 'Dummy First Name');
        insert dummyContact;

        List<Opportunity> dummyOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < opportunityCount; i++) {
            Opportunity dummyOpportunity = new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = UTIL_UnitTestData_TEST.getOpenStage(),
                CloseDate = Date.today(),
                Amount = 100
            );

            dummyOpportunities.add(dummyOpportunity);
        }
        insert dummyOpportunities;

        List<OpportunityContactRole> dummyOpportunityContactRoles = new List<OpportunityContactRole>();
        for (Integer i = 0; i < opportunityCount; i++) {
            for (Integer ii = 0; ii < softCreditCount; ii++) {
                OpportunityContactRole dummyOpportunityContactRole = new OpportunityContactRole(
                    OpportunityId = dummyOpportunities[i].Id,
                    ContactId = dummyContact.Id,
                    Role = 'Soft Credit'
                );
                dummyOpportunityContactRoles.add(dummyOpportunityContactRole);
            }
        }
        insert dummyOpportunityContactRoles;

        List<Id> opportunityIds = new List<Id>();
        for (Integer i = 0; i < opportunityCount; i++) {
            opportunityIds.add(dummyOpportunities[i].Id);
        }

        return opportunityIds;
    }

    @IsTest
    private static void shouldReturnYearsForFilter() {
        
        Date myDateTime = Date.newInstance(2020, 2, 2);
        Date dateTimeInPast = Date.newInstance(2019, 2, 2);
        List<Contact> contacts = UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 3, 1);
        Account accSrc = UTIL_UnitTestData_TEST.listAccT[0];
        list<Contact> listConSrc = UTIL_UnitTestData_TEST.listConT;

        Opportunity opportunityHardCreditOfContact0 = new Opportunity(
            Name='HardCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );

        Opportunity opportunityAnotherHardCreditOfContact0 = new Opportunity(
            Name='HardCredit2', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=dateTimeInPast
        );

        insert new List<Opportunity> { opportunityHardCreditOfContact0, opportunityAnotherHardCreditOfContact0};

       
        List<String> donationsYears = new DonationHistorySelector().getYearsWithDonationForContact(contacts[0].id);
        System.assertNotEquals(null, donationsYears, 'donationsYears should not be null');
        System.assertEquals(2, donationsYears.size(), 'donationsYears should have 2 elements');
        System.assertEquals('2020', donationsYears[0], 'donationsYears should be in descendent order');

    }

    @IsTest
    private static void shouldReturn1asNumberOfRecordFor2019() {
        Date myDateTime = Date.newInstance(2020, 2, 2);
        Date dateTimeInPast = Date.newInstance(2019, 2, 2);
        List<Contact> contacts = UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 3, 1);
        Account accSrc = UTIL_UnitTestData_TEST.listAccT[0];
        list<Contact> listConSrc = UTIL_UnitTestData_TEST.listConT;

        Opportunity opportunityHardCreditOfContact0 = new Opportunity(
            Name='HardCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );

        Opportunity opportunityAnotherHardCreditOfContact0 = new Opportunity(
            Name='HardCredit2', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=dateTimeInPast
        );

        insert new List<Opportunity> { opportunityHardCreditOfContact0, opportunityAnotherHardCreditOfContact0};

        Integer donationsYears = new DonationHistorySelector().getTotalNumberOfRecordsWithYear(contacts[0].Id, 2019);
        System.assertEquals(1, donationsYears, 'Should return only 1 record');
    }

    @IsTest
    private static void shouldReturn2AsNumberOfRecords() {
        Date myDateTime = Date.newInstance(2020, 2, 2);
        Date dateTimeInPast = Date.newInstance(2019, 2, 2);
        List<Contact> contacts = UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 3, 1);
        Account accSrc = UTIL_UnitTestData_TEST.listAccT[0];
        list<Contact> listConSrc = UTIL_UnitTestData_TEST.listConT;

        Opportunity opportunityHardCreditOfContact0 = new Opportunity(
            Name='HardCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );

        Opportunity opportunityAnotherHardCreditOfContact0 = new Opportunity(
            Name='HardCredit2', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=dateTimeInPast
        );

        insert new List<Opportunity> { opportunityHardCreditOfContact0, opportunityAnotherHardCreditOfContact0};

        Integer donationsYears = new DonationHistorySelector().getTotalNumberOfRecords(contacts[0].Id);
        System.assertEquals(2, donationsYears, 'Should return only 1 record');
    }

    @IsTest
    private static void shouldReturn2Opportunities() {
        Date myDateTime = Date.newInstance(2020, 2, 2);
        Date dateTimeInPast = Date.newInstance(2019, 2, 2);
        List<Contact> contacts = UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 3, 1);
        Account accSrc = UTIL_UnitTestData_TEST.listAccT[0];
        list<Contact> listConSrc = UTIL_UnitTestData_TEST.listConT;

        Opportunity opportunityHardCreditOfContact0 = new Opportunity(
            Name='HardCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );

        Opportunity opportunityAnotherHardCreditOfContact0 = new Opportunity(
            Name='HardCredit2', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=dateTimeInPast
        );

        insert new List<Opportunity> { opportunityHardCreditOfContact0, opportunityAnotherHardCreditOfContact0};

        System.assertEquals(2, new DonationHistorySelector().getWonOpportunitiesByContactId(contacts[0].id, 0).size(), 'Should return 2 records of opportunities');
    }

    @IsTest
    private static void shouldReturn1OpportunitiesFor2019() {
        Date myDateTime = Date.newInstance(2020, 2, 2);
        Date dateTimeInPast = Date.newInstance(2019, 2, 2);
        List<Contact> contacts = UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 3, 1);
        Account accSrc = UTIL_UnitTestData_TEST.listAccT[0];
        list<Contact> listConSrc = UTIL_UnitTestData_TEST.listConT;

        Opportunity opportunityHardCreditOfContact0 = new Opportunity(
            Name='HardCredit1', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=myDateTime
        );

        Opportunity opportunityAnotherHardCreditOfContact0 = new Opportunity(
            Name='HardCredit2', 
            AccountId=accSrc.Id, 
            Primary_Contact__c=listConSrc[0].Id, 
            Amount=400, 
            StageName='Closed Won', 
            CloseDate=dateTimeInPast
        );

        insert new List<Opportunity> { opportunityHardCreditOfContact0, opportunityAnotherHardCreditOfContact0};

        System.assertEquals(1, new DonationHistorySelector().getWonOpportunitiesByContactIdAndYear(contacts[0].id, 0, 2019).size(), 'Should return 1 records of opportunities');
    }
}
