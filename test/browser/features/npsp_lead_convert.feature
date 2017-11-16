Feature: Lead Convert test

  Background:
    Given I create a new Lead via the API
    When I navigate to Lead Convert page for the Lead

  @flaky
  Scenario: Check Lead Convert page
    Then I should see the Lead Convert page for the Lead

  @flaky
  Scenario: Convert Lead to Contact
    When I change some settings
      And I click Convert
    Then I should be on the new Contact page for the Lead
      And I should be able to click the link to the Household Account for the contact
      And the Lead record for this person should no longer exist

  Scenario: Cancel button reverts to Lead page
    When I change some settings
      And I click Cancel
    Then I should be on the Lead page for the Contact