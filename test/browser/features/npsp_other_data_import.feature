Feature: Data Import page

  @flaky
  Scenario: Data Import New button
    When I navigate to the other NPSP Data Import
      And I click New
    Then I should see the NPSP Data Import Edit page

  @flaky
  Scenario: Start Data Import button links to NPSP Data import
    When I navigate to the other NPSP Data Import
      And I click View All
      And I click Start Data Import
    Then I should see the NPSP Batch Data Entry page
