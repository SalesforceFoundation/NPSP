*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects

...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***
# Sets test data contact and an opportunity for the contact
Setup Test Data
    Setupdata   contact   ${contact1_fields}

*** Variables ***
&{contact1_fields}       Email=test@example.com

*** Test Cases ***

Create Matching Donation
    [Documentation]                      Create a Matching Gift Donation
    [tags]                                feature:Donations and Payments   unstable  unit
    Go To Page                            Listing
    ...                                  Opportunity

    Click Object Button                   New
    Wait For Modal                        New                       Opportunity
    Select Record Type                    Matching Gift
    Populate Form
    ...                                   Opportunity Name= Robot $100 matching donation
    ...                                   Amount=100
    Populate Lookup Field                 Account Name              ${data}[contact][LastName] Household
    Set Checkbutton To                    Do Not Automatically Create Payment       checked
    Select Value From Dropdown            Stage                     Closed Won
    Select Date From Datepicker           Close Date                Today
    Click Modal Button                    Save
    Wait Until Modal Is Closed
    ${matching_gift}                      Get Main Header
    Go To Page                            Listing
    ...                                   Opportunity
    Click Link                            link=${matching_gift}

