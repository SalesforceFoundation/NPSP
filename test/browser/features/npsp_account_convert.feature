
Feature: Account Convert

  @smoketest @chrome
  Scenario: Account Convert screen
    Given I navigate to the Account Conversions page
      And the Begin button is disabled
      And the Account Field is visible
    When I check all the boxes
    Then the Begin button is not disabled
