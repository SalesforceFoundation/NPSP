Feature: NPSP Manage Allocations Page Test

  Background:
    Given I create a new Opportunity via the API with stage name "Qualification" and close date "2020-01-01" and amount "1000"
      And I create a GAU named "first"
      And I create a GAU named "second"

  @flaky
  Scenario: Manage Allocations
    When I navigate to the Manage Allocations page
      And I add a row
      And I enter "100" in the Amount for the first row for the first GAU
      And I enter "10" in the Percent for the second row for the second GAU
    Then Delete Row should be present
      And Percent in the first row should be disabled
      And Amount in the second row should be disabled
      And Save should be present

  @flaky
  Scenario: Manage Allocations amount error
    When I navigate to the Manage Allocations page
      And I enter "1001" in the Amount for the first row for the first GAU
    Then I should see a remainder of "-1.00"
      And I should see the Save button disabled

  @flaky
  Scenario: Manage Allocations percent error
    When I navigate to the Manage Allocations page
      And I enter "101" in the Percent for the first row for the first GAU
    Then I should see a remainder of "-10.00"
      And I should see the Save button disabled

  @flaky
  Scenario: Manage Allocations GAU error
    When I navigate to the Manage Allocations page
    And I add a row
      And I enter "1000" in the Amount for the first row for the first GAU
      And I enter "10" in the Percent for the second row for the first GAU
    Then I should see a remainder of "-100.00"
      And I should see the Save button disabled
