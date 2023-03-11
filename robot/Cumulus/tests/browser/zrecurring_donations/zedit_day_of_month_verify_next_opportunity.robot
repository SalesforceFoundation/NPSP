*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Library         Collections
Suite Setup     Run keywords
...             Enable RD2
...             Open Test Browser
...             Setup Test Data
#Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***

Setup Test Data
    [Documentation]     Data setup needed for the testcase. Creates a recurring
    ...                 donation of type open linked to a contact using backend API
    ${NS} =             Get NPSP Namespace Prefix
    Set Suite Variable  ${NS}

    #Create a Recurring Donation
    &{contact1_fields}=   Create Dictionary                     Email=rd2tester@example.com
    &{recurringdonation_fields} =	Create Dictionary           Name=ERD Open Recurring Donation
    ...                                                         npe03__Installment_Period__c=Yearly
    ...                                                         npe03__Amount__c=100
    ...                                                         npe03__Open_Ended_Status__c=Open
    ...                                                         npe03__Date_Established__c=2019-07-08
    ...                                                         ${NS}Status__c=Active
    ...                                                         ${NS}Day_of_Month__c=20
    ...                                                         ${NS}InstallmentFrequency__c=1
    ...                                                         ${NS}PaymentMethod__c=Check

    Setupdata   contact         ${contact1_fields}             recurringdonation_data=${recurringdonation_fields}
    ${CURRENT_DATE}=            Get current date               result_format=%-m/%-d/%Y
    Set Suite Variable          ${CURRENT_DATE}

Validate Opportunity Details
    [Documentation]         Navigate to opportunity details page of the specified
    ...                     opportunity and validate stage and Close date fields
    [Arguments]                       ${opportunityid}          ${stage}
    Go To Page                              Details                        Opportunity                    object_id=${opportunityid}
    Wait Until Loading Is Complete
    Current Page Should Be                  Details                        Opportunity
    Navigate To And Validate Field Value    Stage                          contains                      ${stage}

Edit Opportunity Stage
    [Documentation]         Navigate to opportunity details page of the specified
    ...                     opportunity and update the opportunity stage detail
    [Arguments]                       ${opportunityid}          ${stage}
    Go To Page                              Details                        Opportunity                     object_id=${opportunityid}
    Wait Until Loading Is Complete
    Click Button                            Edit
    Wait until Modal Is Open
    Select Value From Dropdown              Stage                          ${stage}
    Sleep                                   2
    Click Modal Button                      Save
    Wait until Modal Is Closed

*** Test Cases ***

Edit Day Of Month For Enhanced Recurring donation record of type open
    [Documentation]               After creating an open recurring donation using API,
    ...                          The test ensures that there is only one opportunity.
    ...                          Closes the exisitng opportunity and verifies there is
    ...                          a new opportunity created. Edits the day of month on
    ...                          the recurring donation and verifies the closing dates
    ...                          for both the opportunities.
    [tags]                             feature:RD2     unstable     unit

    Go To Page                         Details
    ...                                npe03__Recurring_Donation__c
    ...                                object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete
    Current Page Should be             Details    npe03__Recurring_Donation__c
    #Validate the number of opportunities on UI, Verify Opportinity got created in the backend
    Validate Related Record Count      Opportunities                                    1
    @{opportunities} =                 API Query Opportunity For Recurring Donation     ${data}[contact_rd][Id]

    Edit Opportunity Stage             ${opportunities}[0][Id]                               Closed Won
    Run Recurring Donations Batch      RD2
    Go To Page                         Details
    ...                                npe03__Recurring_Donation__c
    ...                                object_id=${data}[contact_rd][Id]
    Current Page Should Be             Details                      npe03__Recurring_Donation__c
    Edit Recurring Donation Status
    ...                                Recurring Period=Monthly
    ...                                Day of Month=1
    Go To Page                         Details
    ...                                npe03__Recurring_Donation__c
    ...                                object_id=${data}[contact_rd][Id]
    Current Page Should Be             Details                      npe03__Recurring_Donation__c
    Wait Until Loading Is Complete
    ${next_payment_date}               Get Next Payment Date Number                    1
    Run Recurring Donations Batch      RD2
    Go To Page                         Details
    ...                                npe03__Recurring_Donation__c
    ...                                object_id=${data}[contact_rd][Id]
    Current Page Should Be             Details                        npe03__Recurring_Donation__c

    #Validate that the number of opportunities now show as 2 .
    Validate Related Record Count      Opportunities                                   2
    @{opportunity} =                   API Query Opportunity For Recurring Donation                  ${data}[contact_rd][Id]
    #Verify the details on the respective opportunities
    Validate Opportunity Details       ${opportunities}[0][Id]        Closed Won
    Go To Page                         Details
        ...                            npe03__Recurring_Donation__c
        ...                            object_id=${data}[contact_rd][Id]


    Current Page Should Be             Details                      npe03__Recurring_Donation__c