
Feature: Data Import page

  @chrome @flaky
  Scenario: Data Import page
    When I navigate to NPSP Data Import
      And I set Batch Size to 60
      And I set Contact Matching Rule to "First Name and Last Name"
      And I set Contact Custom Unique ID to "--None--"
      And I set Account Custom Unique ID to "--None--"
      And I click Begin Data Import Process
    Then I should see the Data Import status
