Feature: New Contact Donation test

  @flaky
  Scenario: New Contact Donation page
    Given I create a new Contact via the API
    When I navigate to New Contact Donation Page
    Then I should see the New Opportunity page
      And Opportunity Name should be set to the correct value
      And Account Name should be set to the correct value

  @flaky
  Scenario: New Contact not Primary Donation page
    Given I create two Contacts in the same Household via the API
    When I navigate to New Contact Donation Page
    Then I should see the New Opportunity page
      And Opportunity Name should be set to the correct value
      And Account Name should be set to the two contact Household
