*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/RecurringDonationsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Enable RD2
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser


***Keywords***
# Setup a contact with parameters specified
Setup Test Data
    Setupdata           account      None    None    ${account_fields}
    ${now}              Evaluate            '01/10/{dt.year}'.format(dt=datetime.datetime.now())    modules=datetime
    ${date}             Convert Date        ${now}    result_format=%-m/%-d/%Y   date_format=%d/%m/%Y
    Set Suite Variable  ${date}
    ${ns} =             Get NPSP Namespace Prefix
    Set Suite Variable  ${ns}

*** Variables ***
&{account_fields}  Type=Organization

${frequency}  1
${day_of_month}  1
${amount}  100
${method}  Credit Card


*** Test Cases ***

Create Open Recurring Donation With Monthly Installment
    [Documentation]              This test verifies that an enhanced recurring donation of type open can be created through the UI.
    ...                          Verifies that all the new fields and sections are getting populated and displayed on UI.
    ...                          Verify the values under donation statistics, upcoming installments sections


    [tags]                                 feature:RD2     unstable
    Go To Page                             Listing                                   npe03__Recurring_Donation__c
    Reload Page
    Click Link                             New
    Wait For Rd2 Modal

    # Create Enhanced recurring donation of type Open
    Populate Rd2 Modal Form
    ...                                   Donor Type=Account
    ...                                   Account=${data}[account][Name]
    ...                                   Amount= ${amount}
    ...                                   Recurring Donation Name=Automation RD
    ...                                   Payment Method=Credit Card
    ...                                   Day of Month=${day_of_month}
    Click Rd2 Modal Button                Save
    Wait Until Modal Is Closed
    Sleep                                 1
    Current Page Should Be                Details                                   npe03__Recurring_Donation__c

    ${rd_id}                               Save Current Record ID For Deletion       npe03__Recurring_Donation__c
    Validate Field Values Under Section

    ...                                     Account=${data}[account][Name]
    ...                                     Amount=$100.00
    ...                                     Status=Active

    # Validate the fields under Current Schedule card
    Validate Field Values Under Section     Current Schedule
     ...                                    Amount=$100.00
     ...                                    Payment Method=${method}
     ...                                    Effective Date=${date}
     ...                                    Installment Period=Monthly
     ...                                    Day of Month=${day_of_month}
    # Validate upcoming installments
    Validate_Upcoming_Schedules             12                 ${date}                ${day_of_month}

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${rd_id}
    Reload Page

    @{opportunity1} =                       API Query Opportunity For Recurring Donation                   ${rd_id}
    Store Session Record                    Opportunity                                                    ${opportunity1}[0][Id]
    Go To Page                              Details                        Opportunity                     object_id=${opportunity1}[0][Id]
    Navigate To And Validate Field Value    Stage                          contains                        Pledged


