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
    #Create a Recurring Donation
    &{contact1_fields}=   Create Dictionary                     Email=test@example.com
    &{recurringdonation_fields} =	Create Dictionary           Name=Julian Recurring Donation
            ...                                                 npe03__Installment_Period__c=Monthly
            ...                                                 npe03__Amount__c=100
            ...                                                 npe03__Installments__c=12
            ...                                                 npe03__Schedule_Type__c=Divide By

    Setupdata   contact         ${contact1_fields}    recurringdonation_data=${recurringdonation_fields}


*** Test Cases ***

Create Recurring Donation And Check Rollups
    [Documentation]              This test verifies that Account, Contact, and Soft Credit Contact rollups are udpated
    ...                          when a Recurring Donation's Opportunities are Closed Won.
    [tags]                       feature:Recurring Donations  unstable   unit

    #Find 1st Opportunity for Recurring Donation and Close It
    @{opportunity1} =            API Query Installment          ${data}[contact_rd][Id]    (1 of 12)
    Store Session Record         Opportunity                    ${opportunity1}[0][Id]
    Go To Page                   Details                        Opportunity                 object_id=${opportunity1}[0][Id]
    Click Object Button          Edit
    Wait Until Modal Is Open
    Select Value From Dropdown   Stage                          Closed Won
    Click Modal Button           Save
    Wait Until Modal Is Closed
    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity2} =            API Query Installment          ${data}[contact_rd][Id]    (2 of 12)
    Store Session Record         Opportunity                    ${opportunity2}[0][Id]
    Go To Page                   Details                        Opportunity                 object_id=${opportunity2}[0][Id]
    Click Object Button          Edit
    Wait Until Modal Is Open
    Select Value From Dropdown   Stage                          Closed Won
    Click Modal Button           Save
    Wait Until Modal Is Closed
    #Open NPSP Settings and run Rollups Donations Batch job
    Run Donations Batch Process

    #Check Rollups on Recurring Donation
    Go To Page                   Details                npe03__Recurring_Donation__c   object_id=${data}[contact_rd][Id]
    Navigate To And Validate Field Value                Number Of Paid Installments    contains    2
    Navigate To And Validate Field Value                Total Paid Amount              contains    $16.66

    #Check Rollups on Recurring Contact
    Go To Page                   Details                Contact                      object_id=${data}[contact][Id]
    Select Tab                   Details
    Navigate To And Validate Field Value                Total Gifts This Year        contains    $16.66    section=Soft Credit Total
    Navigate To And Validate Field Value                Total Gifts                  contains    $16.66    section=Soft Credit Total

    #Check Rollups on Recurring Account
    @{account} =                 Salesforce Query       Account
    ...                          select=Id
    ...                          npe01__One2OneContact__c=${data}[contact][Id]
    Go To Page                   Details                Account                        object_id=${account}[0][Id]
    Wait Until Loading Is Complete
    Select Tab                   Details
    Navigate To And Validate Field Value                Total Gifts                    contains        $16.66    section=Membership Information
    Navigate To And Validate Field Value                Total Number of Gifts          contains        2         section=Membership Information

    #Open NPSP Settings and run Recurring Donations Batch job
    Open NPSP Settings           Bulk Data Processes           Recurring Donations Batch
    Click Settings Button        idPanelRDBatch                Run Batch
    Wait For Batch To Process    RD_RecurringDonations_BATCH   Completed

    #Check Rollups on Recurring Donation
    Go To Page                   Details           npe03__Recurring_Donation__c                   object_id=${data}[contact_rd][Id]
    Wait Until Loading Is Complete
    Navigate To And Validate Field Value           Number Of Paid Installments    contains        2
    Navigate To And Validate Field Value           Total Paid Amount              contains        $16.66

    #Check Rollups on Recurring Contact
    Go To Page                   Details          Contact                        object_id=${data}[contact][Id]
    Wait Until Loading Is Complete
    Select Tab                   Details
    Navigate To And Validate Field Value          Total Gifts This Year          contains        $16.66    section=Soft Credit Total
    Navigate To And Validate Field Value          Total Gifts                    contains        $16.66    section=Soft Credit Total

    #Check Rollups on Recurring Account
    Go To Page                   Details          Account                        object_id=${account}[0][Id]
    Wait Until Loading Is Complete
    Select Tab                   Details
    Navigate To And Validate Field Value          Total Gifts                    contains        $16.66    section=Membership Information
    Navigate To And Validate Field Value          Total Number of Gifts          contains        2         section=Membership Information