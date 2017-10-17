Feature: NPSP Settings Error Settings

  @reset_these_settings @flaky
  Scenario: Actually save Error Settings
    Given I navigate to NPSP Settings
      And I navigate to System Tools Error Notifications
    When I change System Tools Error Notifications
      And I click Save System Tools Error Notifications
    Then System Tools Error Notifications settings should be saved
      And when I refresh the page my System Tools Error Notifications changes should be visible
