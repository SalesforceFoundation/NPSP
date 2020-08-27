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

${frequency}  1
${day_of_month}  2
${amount}  100
${method}  Credit Card


*** Test Cases ***

Create Open Recurring Donation With Monthly Installment
    [Documentation]              This test verifies that an enhanced recurring donation of type open can be created through the UI.
    ...                          Verifies that all the new fields and sections are getting populated and displayed on UI.
    ...                          Verify the values under donation statistics, upcoming installments sections


    [tags]                       unstable               W-040346                     feature:RD2

    Go To Page                             Listing                                   npe03__Recurring_Donation__c
    Click Object Button                    New
    Wait For Modal                         New                                       Recurring Donation
    # Reload page is a temporary fix till the developers fix the ui-modal
    Reload Page
    Wait For Modal                         New                                       Recurring Donation

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
     ...                                    Day of Month=2
    # Validate upcoming installments
    Validate_Upcoming_Schedules             12                 ${date}                ${day_of_month}

    Go To Page                              Details
    ...                                     npe03__Recurring_Donation__c
    ...                                     object_id=${rd_id}
    Reload Page

    # validate recurring donation statistics current and next year value
    Validate Field Values Under Section     Statistics
    ...                                     Current Year Value=$${currentvalue}.00
    ...                                     Next Year Value=$1,200.00

    @{opportunity1} =                       API Query Opportunity For Recurring Donation                   ${rd_id}
    Store Session Record                    Opportunity                                                    ${opportunity1}[0][Id]
    Go To Page                              Details                        Opportunity                     object_id=${opportunity1}[0][Id]
    Navigate To And Validate Field Value    Stage                          contains                        Pledged


