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
* @description Donation tests.
*/
@isTest
private class Donation_TEST {
    @isTest
    static void shouldHaveOpportunityWith3UnpaidPayments() {
        Opportunity parentOpportunity = buildDummyOpportunity();

        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c> {
            new npe01__OppPayment__c(
                npe01__Paid__c=false,
                npe01__Written_Off__c=false,
                npe01__Opportunity__c=parentOpportunity.Id
            ),
            new npe01__OppPayment__c(
                npe01__Paid__c=false,
                npe01__Written_Off__c=false,
                npe01__Opportunity__c=parentOpportunity.Id
            ),
            new npe01__OppPayment__c(
                npe01__Paid__c=false,
                npe01__Written_Off__c=false,
                npe01__Opportunity__c=parentOpportunity.Id
            ),
            new npe01__OppPayment__c(
                npe01__Paid__c=false,
                npe01__Written_Off__c=true,
                npe01__Opportunity__c=parentOpportunity.Id
            )
        };

        Opportunity opportunityWithChildPayments = mockRelationshipFor(
            parentOpportunity, payments, npe01__OppPayment__c.getSObjectType());
        Donation donation = new Donation(opportunityWithChildPayments);

        System.assertEquals('Dummy Opp', donation.opportunity().Name);
        System.assertEquals(3, donation.unpaidPayments().size());
        System.assertEquals(parentOpportunity.Id, donation.unpaidPayments()[0].npe01__Opportunity__c);
    }

    @isTest
    static void shouldHaveOpportunityWithoutPayments() {
        Opportunity parentOpportunity = buildDummyOpportunity();
        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();

        Opportunity opportunityWithoutOpenPayments = mockRelationshipFor(
            parentOpportunity, payments, npe01__OppPayment__c.getSObjectType());
        Donation donation = new Donation(opportunityWithoutOpenPayments);

        System.assertEquals('Dummy Opp', donation.opportunity().Name);
        System.assertEquals(0, donation.unpaidPayments().size());
    }

    @isTest
    static void shouldHaveOpportunityWith3SoftCredits() {
        Opportunity parentOpportunity = buildDummyOpportunity();

        SObjectType contactType = Contact.getSObjectType();
        Id DUMMY_CONTACT_ID_0 = UTIL_UnitTestData_TEST.mockId(contactType);
        Id DUMMY_CONTACT_ID_1 = UTIL_UnitTestData_TEST.mockId(contactType);

        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole> {
            new OpportunityContactRole(Role='DUMMY_ROLE_INFLUENCER', ContactId=DUMMY_CONTACT_ID_0),
            new OpportunityContactRole(Role='DUMMY_ROLE_ANY', ContactId=DUMMY_CONTACT_ID_0),
            new OpportunityContactRole(Role='DUMMY_ROLE_INFLUENCER', ContactId=DUMMY_CONTACT_ID_1)
        };

        parentOpportunity = mockRelationshipFor(
            parentOpportunity, opportunityContactRoles, OpportunityContactRole.getSObjectType());

        Donation donation = new Donation(parentOpportunity);
        System.assertEquals(3, donation.softCredits().size());
    }

    @isTest
    static void shouldHaveOpportunityWith0SoftCredits() {
        Opportunity parentOpportunity = buildDummyOpportunity();
        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();

        parentOpportunity = mockRelationshipFor(
            parentOpportunity, opportunityContactRoles, OpportunityContactRole.getSObjectType());

        Donation donation = new Donation(parentOpportunity);
        System.assertEquals(0, donation.softCredits().size());
    }

    @isTest
    static void shouldThrowExceptionWhenNoOpportunityFound() {
        Id dummyOpportunityId = UTIL_UnitTestData_TEST.mockId(Opportunity.sObjectType);

        try {
            Donation dummyDonation = new Donation(dummyOpportunityId);
        } catch(Exception ex) {
            System.assertEquals('No opportunity found.', ex.getMessage());
        }
    }

    private static final Id DUMMY_OPPORTUNITY_ID = UTIL_UnitTestData_TEST.mockId(Opportunity.getSObjectType());

    private static Opportunity mockRelationshipFor(
        Opportunity parentOpportunity,
        List<Object> children,
        SObjectType childSObjectType) {

            Map<SObjectType, String> relationshipNameByChildObjectName = new Map<SObjectType, String>();
            for (Schema.ChildRelationship cr : Schema.SObjectType.Opportunity.getChildRelationships()) {
                String relationship = String.valueOf(cr.getRelationshipName());
                relationshipNameByChildObjectName.put(cr.getChildSObject(), relationship);
            }

            String relationshipName = relationshipNameByChildObjectName.get(childSObjectType);
            String parentJSON = JSON.serialize(parentOpportunity);
            String childrenJSON = '"' + relationshipName + '": {'
                + '"totalSize": ' + children.size() + ', '
                + '"done": true,'
                + '"records": ' + JSON.serialize(children)
                + '}';

            parentJSON = parentJSON.substring(0, parentJSON.length() - 1)
                + ','
                + childrenJSON
                + '}';

            return (Opportunity) JSON.deserialize(parentJSON, Opportunity.class);
    }

    private static Opportunity buildDummyOpportunity() {
        return new Opportunity(
            Id=DUMMY_OPPORTUNITY_ID,
            Name='Dummy Opp',
            StageName=UTIL_UnitTestData_TEST.getOpenStage(),
            Amount=1,
            CloseDate=Date.today()
        );
    }
}
