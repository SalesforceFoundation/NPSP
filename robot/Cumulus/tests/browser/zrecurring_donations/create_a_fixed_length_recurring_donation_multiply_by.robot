*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Variables
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${ns} =                      Get NPSP Namespace Prefix
    Set Suite Variable           ${ns}

Setup Test Data
    #Create two Contacts in the Same Household

    &{contact1_fields}=   Create Dictionary                     Email=test@example.com
    &{recurringdonation_fields} =	Create Dictionary           Name=Julian Recurring Donation
                ...                                             npe03__Installment_Period__c=Weekly
                ...                                             npe03__Amount__c=10
                ...                                             npe03__Installments__c=50
                ...                                             npe03__Schedule_Type__c=Multiply By

    Setupdata    contact1         ${contact1_fields}
    &{contact2_fields}=   Create Dictionary                     AccountId=${data}[contact1][AccountId]
    setupdata    contact2         ${contact2_fields}
    setupdata    contact1         recurringdonation_data=${recurringdonation_fields}

*** Test Cases ***

Create Fixed Length Recurring Donation Multiply By
    [Documentation]              This test verifies that Opportunities with the proper mulitplied amount are created for a Recurring Donation.
    ...                          This test case also verified the correct number of opportunities are created and related Account, Contact,
    ...                          and Soft Credit Contact rollups are udpated.
    [tags]                       feature:Recurring Donations     unstable   unit

    #Find 1st Opportunity for Recurring Donation and Close It
    @{opportunity1} =            API Query Installment         ${data}[contact1_rd][Id]     (1 of 50)
    Store Session Record         Opportunity                   ${opportunity1}[0][Id]
    Go To Page                   Details                       Opportunity                 object_id=${opportunity1}[0][Id]
    Click Object Button          Edit
    Wait Until Modal Is Open
    Select Value From Dropdown   Stage                          Closed Won
    Click Modal Button           Save
    Wait Until Modal Is Closed
    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity2} =            API Query Installment         ${data}[contact1_rd][Id]     (2 of 50)
    Store Session Record         Opportunity                   ${opportunity2}[0][Id]
    Go To Page                   Details                       Opportunity                 object_id=${opportunity2}[0][Id]
    Click Object Button          Edit
    Wait Until Modal Is Open
    Select Value From Dropdown   Stage                          Closed Won
    Click Modal Button           Save
    Wait Until Modal Is Closed

    #Open NPSP Settings and run Rollups Donations Batch job
    Run Donations Batch Process

    #Check if 50th Opportunity for Recurring Donation Exists
    @{opportunity50} =           API Query Installment          ${data}[contact1_rd][Id]     (50 of 50)
    Go To Page                   Details                        Opportunity                 object_id=${opportunity50}[0][Id]

    #Check Rollups on Recurring Donation
    Go To Page                   Details          npe03__Recurring_Donation__c             object_id=${data}[contact1_rd][Id]
    Navigate To And Validate Field Value          Number Of Paid Installments    contains    2
    Navigate To And Validate Field Value          Total Paid Amount              contains    $20.00

    #Check Soft Credit Rollups on Household Contact
    Go To Page                   Details         Contact                                   object_id=${data}[contact2][Id]
    Select Tab                   Details
    Navigate To And Validate Field Value          Soft Credit Total              contains    $20.00
    Navigate To And Validate Field Value          Number of Soft Credits         contains    2

    #Check Rollups on Recurring Account
    Go To Page                   Details         Account                                    object_id=${data}[contact1][Id]
    Select Tab                   Details
    Navigate To And Validate Field Value          Total Gifts                    contains    $20.00
    Navigate To And Validate Field Value          Total Number of Gifts          contains    2