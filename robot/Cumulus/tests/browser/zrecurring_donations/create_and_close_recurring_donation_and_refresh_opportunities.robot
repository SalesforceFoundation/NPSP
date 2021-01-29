*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
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
    #Create a Recurring Donation
    &{contact1_fields}=   Create Dictionary                     Email=test@example.com
    &{recurringdonation_fields} =	Create Dictionary           Name=Julian Recurring Donation
                ...                                             npe03__Installment_Period__c=Monthly
                ...                                             npe03__Amount__c=100
                ...                                             npe03__Installments__c=12
                ...                                             npe03__Open_Ended_Status__c=Open
                ...                                             npe03__Date_Established__c=2019-07-08

    Setupdata   contact         ${contact1_fields}    recurringdonation_data=${recurringdonation_fields}


*** Test Cases ***

Create and Close a Recurring Donation and Refresh Opportunities
    [Documentation]              This test verifies that Opportunities for a Recurring Donation are properly closed when the recurring
    ...                          donation is closed.
    [tags]                       unstable            W-039820                            feature:Recurring Donations

    #Find 1st Opportunity for Recurring Donation and Close It
    @{opportunity1} =            API Query Installment          ${data}[contact_rd][Id]    (1)
    Store Session Record         Opportunity                    ${opportunity1}[0][Id]
    Go To Page                   Details                        Opportunity                 object_id=${opportunity1}[0][Id]
    Click Object Button          Edit
    Wait Until Modal Is Open
    Select Value From Dropdown   Stage                          Closed Won
    Click Modal Button           Save
    Wait Until Modal Is Closed

    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity2} =            API Query Installment          ${data}[contact_rd][Id]               (2)
    Store Session Record         Opportunity                    ${opportunity2}[0][Id]
    Go To Page                   Details                        Opportunity                           object_id=${opportunity2}[0][Id]
    Click Object Button          Edit
    Wait Until Modal Is Open
    Select Value From Dropdown   Stage                          Closed Won
    Click Modal Button           Save
    Wait Until Modal Is Closed
    #Close Recurring Donation and Refresh Opportunities
    Go To Page                   Details                        npe03__Recurring_Donation__c          object_id=${data}[contact_rd][Id]
    Click Actions Button         Edit
    Click Flexipage Dropdown     Open Ended Status              Closed
    Click Button                 npsp:button-text:Save
    Wait Until Modal Is Closed
    Refresh Opportunities

    #Find 3rd Opportunity for Recurring Donation
    @{opportunity3} =            API Query Installment          ${data}[contact_rd][Id]              (3)
    Go To Page                   Details                        Opportunity                          object_id=${opportunity3}[0][Id]
    Select Tab                   Details
    Navigate To And Validate Field Value                        Stage                   contains      Closed Lost