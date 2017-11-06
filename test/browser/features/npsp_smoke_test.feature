@smoketest
Feature: NPSP Smoke Test

  Scenario: Recurring Donations link works
    When I click the Recurring Donations link
    Then I should see the Recurring Donations home page
      And I should be able to click the New button

  Scenario: NPSP controls link works
    When I navigate to NPSP Settings
    Then I should see the NPSP Application Settings page
