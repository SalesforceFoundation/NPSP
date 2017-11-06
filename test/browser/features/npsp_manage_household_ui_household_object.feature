Feature: Manage Household UI One-to-One

  Background:
   Given I create new Contacts with Household Object via the API

  @flaky
  Scenario: Navigate to Manage Households UI and do basic checks
    When I navigate to Manage Households UI for Household Object
    Then I should see the Household Members section
      And I should see the Add Members search field
      And I should see the Household Details section

  Scenario: Add Members to Household
    Given I create two Contacts "aaa" and "bbb" to be added to Household
      And I navigate to Manage Households UI for Household Object
    When I type "aaa" into search box
      And I add to household with Add option
      And I type "bbb" into search box
      And I add to household with Add option
    Then I should see two Household Member entries

  Scenario: Change Household address
    Given I navigate to Manage Households UI for Household Object
    When I click Change on Household Address
      And I click Select an existing address
      And I fill in the five address fields
      And I click Set Address
    Then the five address fields should appear in the Household Address section in the correct order

  Scenario: Cancel button returns to Manage Household page
    Given I create two Contacts "eee" and "fff" to be added to Household
      And I navigate to Manage Households UI for Household Object
    When I type "fff" into search box
      And I add to household with Add option
      And I click Cancel
    Then I should be on the regular Households page
