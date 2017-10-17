@flaky
Feature: Manage Household UI
# needs to fix manage household navigation step, then will work.
  Background:
    Given I create a new Contact via the API with address "automation street" "automation city" "automation state" "automation country" "automation zip"
      And I create a new random account via the API

  Scenario: Navigate to Manage Households UI and do basic checks
    When I navigate to Manage Households UI
    Then I should see the Household Members section
      And I should see the Add Members search field
      And I should see the Household Details section
      And I should see breadcrumbs for the account

  Scenario: Add Members to Household
    Given I create two Contacts "aaa" and "bbb" to be added to Household
      And I navigate to Manage Households UI
    When I type "aaa" into search box
      And I add to household with Add option
      And I type "bbb" into search box
      And I add to household with Add option
    Then I should see two Household Member entries

  Scenario: Delete Members from Household
    Given I create two Contacts "aaa" and "bbb" to be added to Household
      And I navigate to Manage Households UI
    When I type "aaa" into search box
      And I add to household with Add option
      And I type "bbb" into search box
      And I add to household with Add option
      And I delete the last Contact from the Household
    Then I should see one Household Member entry

  Scenario: Change Household address
    Given I navigate to Manage Households UI for contact
      And I see Contact name
      And I see existing address fields
      And I see the Household Name
    When I click Change on Household Address
      And I click Select an existing address
      #And I click Enter a new address #THIS IS A UX PROBLEM BOTH CONTROLS ARE NOW THE SAME TOGGLE
      And I fill in the five address fields
      And I click Set Address
      And the five address fields should appear in the Household Address section in the correct order
      And I click Manage Household Save
    Then I should be on the Account page for a single Household
      And I should see the new address containing "street" and "city" and "state" and "zip" and "country"

  Scenario: Copy Household address from added Contact
    Given I navigate to Manage Households UI for contact
      And I create a second Contact via the API with address "automation street TWO" "automation city TWO" "automation state TWO" "automation country TWO" "automation zip TWO"
    When I type the random string into search box
      And I add to household with Add option
      And I click Manage Household Save
    Then I should be on the Account page for a merged Household
      And I should see the new address containing "automation street" and "automation city" and "automation state" and "automation zip" and "automation country"

  Scenario: Cancel button returns to Manage Household page
    Given I create two Contacts "eee" and "fff" to be added to Household
      And I navigate to Manage Households UI
    When I type "fff" into search box
      And I add to household with Add option
      And I click Cancel
    Then I should be on the regular Households page

  Scenario: Modal when multiple Contacts in Household
    Given I create two contacts "ggg" and "hhh" in the same Household
      And I navigate to Manage Households UI for contact
    When I type "ggg" into search box
      And I add to household with Add option
      And I see the Cancel option
      And I see the Add One option
      And I add to household with Add All Members option
    Then I should see three Household Member entries

  Scenario: All the checkboxes
    Given I create two contacts "jjj" and "kkk" in the same Household
      And I navigate to Manage Households UI for contact
    When I type "jjj" into search box
      And I add to household with Add option
      And I see the Add One option
      And I add to household with Add All Members option
    Then I should be able to click all the checkboxes
      And I click Manage Household Save
      And I navigate to Manage Households UI for contact
      And checkboxes should be checked
