Feature: NPSP Recurring Donations

  Background:
   Given I navigate to Recurring Donations

  Scenario: Recurring Donations generated on save
    When I create a "Monthly" recurring donation for "12" months for "1000.00"
    Then I should see "12" monthly donations for "$83.33"

  @flaky
  Scenario: Recurring Donation Refresh Opportunities open
    When I create a "Monthly" recurring donation for "12" months for "1000.00"
      And I delete two of the payments
      And I click Refresh Opportunities
    Then I should see "12" monthly donations for "$83.33"
