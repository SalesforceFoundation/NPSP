@flaky
Feature: Contact Merge test

  Background:
    Given I create three Contacts "aaa1" and "aaa2" and "aaa3"
      And I navigate to Contact Merge
      And I do a Contact Merge search for "aaa"
    When I select the second Contact as the winning Contact


  @flaky
  Scenario: Contact Merge select and merge
    And I merge the contacts
    Then I should see "aaa2" in All Contacts
      And I should not see "aaa1" or "aaa3" in All Contacts

  @flaky
  Scenario: Contact Merge capture detail
    When I select details among the three Contact records
    And I merge the contacts
    Then I should see the details captured in the resulting contact record
