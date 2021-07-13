@isTest
private class Donation_TEST {
    @isTest
    static void shouldHaveOpportunityWith3UnpaidPayments() {
        Opportunity parentOpportunity = new Opportunity(
            Id=UTIL_UnitTestData_TEST.mockId(Opportunity.getSObjectType()),
            Name='Dummy Opp',
            StageName=UTIL_UnitTestData_TEST.getOpenStage(),
            Amount=1,
            CloseDate=Date.today()
        );

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

        Opportunity opportunityWithChildPayments = mockRelationshipFor(parentOpportunity, payments);
        Donation donation = new Donation(opportunityWithChildPayments);

        System.assertEquals('Dummy Opp', donation.opportunity().Name);
        System.assertEquals(3, donation.unpaidPayments().size());
        System.assertEquals(parentOpportunity.Id, donation.unpaidPayments()[0].npe01__Opportunity__c);
    }

    @isTest
    static void shouldHaveOpportunityWithoutPayments() {
        Opportunity parentOpportunity = new Opportunity(
            Id=UTIL_UnitTestData_TEST.mockId(Opportunity.getSObjectType()),
            Name='Dummy Opp 1',
            StageName=UTIL_UnitTestData_TEST.getOpenStage(),
            Amount=1,
            CloseDate=Date.today()
        );
        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();

        Opportunity opportunityWithoutOpenPayments = mockRelationshipFor(parentOpportunity, payments);
        Donation donation = new Donation(opportunityWithoutOpenPayments);

        System.assertEquals('Dummy Opp 1', donation.opportunity().Name);
        System.assertEquals(0, donation.unpaidPayments().size());
    }

    private static Opportunity mockRelationshipFor(
        Opportunity parentOpportunity,
        List<npe01__OppPayment__c> childPayments) {

            String parentJSON = JSON.serialize(parentOpportunity);
            String childPaymentsJSON = '"npe01__OppPayment__r": {'
                + '"totalSize": ' + childPayments.size() + ', '
                + '"done": true,'
                + '"records": ' + JSON.serialize(childPayments)
                + '}';

            parentJSON = parentJSON.substring(0, parentJSON.length() - 1)
                + ','
                + childPaymentsJSON
                + '}';

            return (Opportunity) JSON.deserialize(parentJSON, Opportunity.class);
    }
}
