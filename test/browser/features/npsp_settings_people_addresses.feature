Feature: NPSP Settings People Addresses

  Background:
    Given I navigate to NPSP Settings
      And I navigate to Settings People Addresses

  @smoketest
  Scenario: General Address Settings
    When I click Household Account Addresses Disabled
      And I click Organizational Account Addresses Enabled
      And I click Simple Address Change Treated as Update
    Then all three checkboxes should be clicked

  Scenario: Automatic Verification
    When I click Enable Automatic Verification
      And I select "The Google Geocoding API"
      And I type "foo bar baz" into Auth Token text area
      And I click Reject Ambiguous Addresses
    Then Enable Automatic Verification should be checked
      And "The Google Geocoding API" should be selected
      And the text "Cicero" should not be visible on the page
      And the text "SmartyStreets" should not be visible on the page
      And the text "foo bar baz" should not be visible on the page
      And Reject Ambiguous Addresses should be checked
