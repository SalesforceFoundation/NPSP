Feature: Relationship Viewer test

  @flaky
  Scenario: Invoke Relationship Viewer
    Given I create a new Contact via the API
      And I create a new Contact via the API
      And I create a Relationship for those contacts
    When I navigate to Relationship Viewer for the Primary Contact
    Then I should see the relationship in Relationship Viewer
