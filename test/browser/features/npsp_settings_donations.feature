Feature: NPSP Settings Donations

  Background:
    Given I navigate to NPSP Settings

  @reset_these_settings @chrome @flaky
  Scenario: Actually save Donations Batch Entry Settings
    Given I navigate to Settings Donations Batch Entry
    When I change Donations Batch Entry settings
      And I click Save Donations Batch Entry settings
    Then Donations Batch Entry settings should be saved
      And when I refresh the Donations Batch Entry page my changes should be visible
