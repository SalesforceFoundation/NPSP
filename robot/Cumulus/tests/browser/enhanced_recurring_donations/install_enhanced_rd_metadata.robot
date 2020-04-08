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
    ${date} =     Get Current Date      result_format=%-m/%-d/%Y
    Set Suite Variable  ${date}
    ${ns} =                      Get NPSP Namespace Prefix
    Set Suite Variable           ${ns}

*** Variables ***
&{account_fields}  Type=Organization
${installments}  6
${frequency}  1
${amount}  100
${method}  Credit Card
${type}    Fixed

*** Test Cases ***

Make Changes to Settings and Verify Changes
    [Documentation]            Enable Enhanced RD by deploying Meta Data. After which create a new ERD by populating the
    ...                        new fields and save. Verify that new ERD record saves without any errors.

    [tags]                                     W-040346                        feature:Enhanced Recurring Donations

    Open NPSP Settings                         Recurring Donations             Upgrade to Enhanced Recurring Donations
    Launch Meta Deploy
    Go To Page                                 Listing                         npe03__Recurring_Donation__c
    Click Object Button                        New
    Wait For Modal                             New                             Recurring Donations


    # Create Enhanced recurring donation  by filling in the new fields
    Populate Modal Form
        ...                                    Recurring Donation Name=ERD Recurring Donation Fixed
        ...                                    Amount= ${amount}
        ...                                    Installment Frequency= ${frequency}
        ...                                    Number of Planned Installments= ${installments}

    Populate Lookup Field                      Account                               ${data}[account][Name]
    Select Value From Dropdown                 Recurring Type                        ${type}
    Select Value From Dropdown                 Payment Method                        ${method}
    Select Value From Dropdown                 Day of Month                               1
    Click Modal Button                         Save
    Wait Until Modal Is Closed
    Current Page Should Be                     Details                               npe03__Recurring_Donation__c
