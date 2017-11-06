Feature: Matching Donation test

  @flaky
  Scenario: Invoke Matching Donation
    Given I create two Opportunities to be matched
    When I navigate to Find Matching Gifts for the original Opportunity
    Then I should see the information for my opportunity
      And I should see the headers for matching opportunities
      And I should be able to search for matching opportunities
      And I should see a Cancel button
      And when I click Search I should see an error "Warning" and "Please specify one or more filters in order to search."

  Scenario: Find Matching Gift
    Given I create two Opportunities to be matched
    When I navigate to Find Matching Gifts for the original Opportunity
      And I click the checkbox for the matching Opportunity
      And I click Matching Gift Save
    Then I should be on the Opportunity page for the original Opportunity