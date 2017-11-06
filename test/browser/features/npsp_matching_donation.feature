Feature: Matching Donation test

  @flaky
  # needs new navigation to matching donation for opportunity
  Scenario: Invoke Matching Donation
    Given I create a new Contact via the API
      And I create a new Opportunity via the API with stage name "Qualification" and close date "2020-01-01" and amount "1000"
    When I navigate to Matching Donation for that Opportunity
    Then Matching Donation Opportunity Name should match "Matching Donation" plus the Contact Account Name
      And Account Name shoujld be the Account for the Contact created
      And Amount should be "1,000.00"
      And Close Date should be "01/01/2020"
      And Stage should be "--None--"
      And Save button should be enabled
