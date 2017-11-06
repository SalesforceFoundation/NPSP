
Feature: NPSP Settings People Households

  Background:
    Given I navigate to NPSP Settings
    When I navigate to Settings People Households
      And I click Edit Household Name Settings

  Scenario: Household Name Settings set values
      And I retrieve existing values
      And I uncheck Automatic Household Naming
      And I set Household Name Format to "{!{!FirstName}} {!LastName} Household"
      And I set Formal Greeting Format to "{!{!FirstName}} {!LastName}"
      And I set Informal Greeting Format to "{!{!FirstName}} {!LastName}"
      And I set Name Connector to "foo"
      And I set Name Overrun to "bar"
      And I set Contact Overrun Count to "11"
      And I set Implementing Class to "baz"
      And I set Household Object Rules to "All Individual Contacts"
      And I click Cancel
      And I wait for the page to revert
    Then I should see the original Household Settings on the page

  Scenario: Smith Household real time example updates
    When I set Household Name Format to "{!LastName} ({!{!FirstName}}) Household"
      And I set Name Connector to "foo"
    Then Examples for Household Name Format should reflect my changes

  @reset_these_settings
  Scenario: Actually save Household Naming Settings
    When I set Household Name Format to "{!{!FirstName}} {!LastName} Household"
      And I click Save Household Naming Settings
    Then my Household Naming Settings should be saved
      And when I refresh the page my Household Naming Settings should be saved
