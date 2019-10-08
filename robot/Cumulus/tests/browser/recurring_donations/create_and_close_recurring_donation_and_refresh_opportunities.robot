*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Variables
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${ns} =                      Get NPSP Namespace Prefix
    Set Suite Variable           ${ns}

Setup Test Data
    #Create a Recurring Donation
    &{contact} =                 API Create Contact             Email=jjoseph@robot.com
    Set Suite Variable           ${contact}
    Store Session Record         Account                        &{contact}[AccountId]
    &{recurringdonation} =       API Create Recurring Donation  npe03__Contact__c=&{contact}[Id]
    ...                          Name=Julian Recurring Donation
    ...                          npe03__Amount__c=100
    ...                          npe03__Installments__c=12
    ...                          npe03__Open_Ended_Status__c=Open
    ...                          npe03__Installment_Period__c=Monthly
    ...                          npe03__Date_Established__c=2019-07-08
    Set Suite Variable           ${recurringdonation}

*** Test Cases ***

Create and Close a Recurring Donation and Refresh Opportunities
    [Documentation]              This test verifies that Opportunities for a Recurring Donation are properly closed when the recurring
    ...                          donation is closed.

    #Find 1st Opportunity for Recurring Donation and Close It
    @{opportunity1} =            API Query Installment          &{recurringdonation}[Id]    (1)
    Store Session Record         Opportunity                    ${opportunity1}[0][Id]
    Go To Record Home            ${opportunity1}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity2} =            API Query Installment          &{recurringdonation}[Id]    (2)
    Store Session Record         Opportunity                    ${opportunity2}[0][Id]
    Go To Record Home            ${opportunity2}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Close Recurring Donation and Refresh Opportunities
    Go To Record Home            &{recurringdonation}[Id]
    Click Link                   link=Edit
    Click Dropdown               Open Ended Status
    Click Link                   link=Closed
    Click Modal Button           Save
    Click Link                   link=Show more actions
    Click Link                   link=Refresh Opportunities

    #Find 3rd Opportunity for Recurring Donation
    @{opportunity3} =            API Query Installment          &{recurringdonation}[Id]    (3)
    Go To Record Home            ${opportunity3}[0][Id]
    Select Tab                   Details
    Confirm Value                Stage                          Closed Lost    Y