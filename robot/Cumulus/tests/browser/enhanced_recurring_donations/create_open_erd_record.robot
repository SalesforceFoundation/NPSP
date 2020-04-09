*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
# Setup a contact with parameters specified
Setup Test Data
    Setupdata           account      None    None    ${account_fields}
    ${date} =           Get Current Date      result_format=%-m/%-d/%Y
    Set Suite Variable  ${date}
    ${currdate}=        Get Current Date  result_format=datetime
    ${currentvalue} =   Evaluate  ${12-${currdate.month}}*100
    Set Suite Variable  ${currentvalue}
    ${ns} =             Get NPSP Namespace Prefix
    Set Suite Variable  ${ns}

*** Variables ***
&{account_fields}  Type=Organization
${installments}  1
${frequency}  1
${amount}  100
${method}  Credit Card
${type}    Open

*** Test Cases ***

Create Open Recurring Donation With Monthly Installment
    [Documentation]              This test verifies that an enhanced recurring donation of type open can be created through the UI.
    ...                          Verifies that all the new fields and sections are getting populated and displayed on UI.
    ...                          Verify the values under donation statistics, upcoming installments sections


    [tags]                                 W-040346                                  feature:Enhanced Recurring Donations
    Open NPSP Settings                     Recurring Donations                       Upgrade to Enhanced Recurring Donations
    Launch Meta Deploy
    Go To Page                             Listing                                   npe03__Recurring_Donation__c
    Click Object Button                    New
    Wait For Modal                         New                                       Recurring Donations

    # Create Enhanced recurring donation of type Open
    Populate Modal Form
    ...                                    Recurring Donation Name=ERD Recurring Donation Fixed
    ...                                    Amount= ${amount}
    ...                                    Installment Frequency= ${frequency}
    ...                                    Number of Planned Installments= ${installments}

    Populate Lookup Field                  Account                                   ${data}[account][Name]
    Select Value From Dropdown             Recurring Type                            ${type}
    Select Value From Dropdown             Payment Method                            ${method}
    Select Value From Dropdown             Day of Month                               1
    Click Modal Button                     Save
    Wait Until Modal Is Closed
    Current Page Should Be                 Details                                   npe03__Recurring_Donation__c

    ${rd_id}                               Save Current Record ID For Deletion       npe03__Recurring_Donation__c

    Validate Field Values Under Section
    ...                                     Recurring Donation Name=${data}[account][Name] $${amount} - Recurring
    ...                                     Account=${data}[account][Name]
    ...                                     Amount=$100.00
    ...                                     Status=Active

    # Validate the fields under Current Schedule card
    Validate Field Values Under Section     Current Schedule
     ...                                    Amount=$100.00
     ...                                    Payment Method=${method}
     ...                                    Effective Date=${date}
     ...                                    Installment Period=Monthly
     ...                                    Day of Month=1
    # Validate upcoming installments
    Validate_Upcoming_Schedules             12                                      ${date}

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${rd_id}
    Wait Until Loading Is Complete

    # validate recurring donation statistics current and next year value
    Validate Field Values Under Section     Recurring Donation Statistics
        ...                                 Current Year Value=$${currentvalue}.00
        ...                                 Next Year Value=$1,200.00

    #Validate the number of opportunities on UI, Verify Opportinity got created in the backend and validate the stage on opportunity is Pledged
    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${rd_id}
    Validate Related Record Count           Opportunities                                                    1
    @{opportunity1} =                       API Query Opportunity For Recurring Donation                   ${rd_id}
    Store Session Record                    Opportunity                                                    ${opportunity1}[0][Id]
    Go To Page                              Details                        Opportunity                     object_id=${opportunity1}[0][Id]
    Navigate To And Validate Field Value    Stage                          contains                        Pledged
