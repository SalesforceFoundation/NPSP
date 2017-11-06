Feature: Batch Data Entry test

  Background:
    Given I navigate to Batch Data Entry page
    When I select New Batch for "Lead"

  @smoketest
  Scenario: Batch Data Entry fields for Lead
    Then Batch Name should contain "Leads"
      And Batch Status should be "In Progress"
      And I should see a Description textarea
      And I should see four text fields
      And the Save button should be clickable

  @chrome
  Scenario: Pinned fields persist over multiple records
    When I enter "Lastname" for Last Name value
      And I enter "Company" for Company value
      And I click the pin buttons for Last Name and for Company
      And I click the BDE Save button
    Then the Saved Record list should show the saved record
      And the Last Name field should contain "Lastname"
      And the Company field should contain "Company"
      And the Save button should be clickable
