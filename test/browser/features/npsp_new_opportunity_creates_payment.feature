
Feature: NPSP New Opportunity creates Payment record

  @flaky
  Scenario: NPSP New Opportunity creates Payment record
    Given I navigate to Opportunity
    When I create a new Opportunity with name "aaa" and close date today and amount "100" and stage "Closed Won"
      And I navigate from Opportunity to the Payment
    Then I should see the Payment page
      And the payment amount should be "$100.00"
