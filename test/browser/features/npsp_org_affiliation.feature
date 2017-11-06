Feature: Organization Affiliations

  @smoketest
  Scenario: Create Primary Affiliation
    Given I create a new Contact via the API
      And I create a new organization account via the API
    When I navigate to affiliations
      And I fill in account and contact information
      And I click primary
      And I click Affiliations Save
    Then I should see my affiliations record
