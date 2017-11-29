@smoketest
Feature: NPSP Engagement Plan

  Scenario: Create Engagement Plan Template in UI
    Given I navigate to Engagement Plan Template
    When I fill in EPT information
      And I create a Task and a Subtask
      And I save my EPT
    Then my EPT should exist


