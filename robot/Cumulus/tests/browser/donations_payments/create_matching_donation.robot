*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects

...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
# Sets test data contact and an opportunity for the contact
Setup Test Data
    Setupdata   contact   ${contact1_fields}

*** Variables ***
&{contact1_fields}       Email=test@example.com

*** Test Cases ***

Create Matching Donation
       [Documentation]                      Create a Matching Gift Donation

       Go To Page                            Listing
        ...                                  Opportunity

       Click Object Button                   New
       Wait For Modal                        New                       Opportunity
       Select Record Type                    Matching Gift
       Populate Modal Form
       ...                                   Opportunity Name= Robot $100 matching donation
       ...                                   Amount=100
       ...                                   Account Name=${data}[contact][LastName] Household
       ...                                   Do Not Automatically Create Payment=checked
       Select Value From Dropdown            Stage                     Closed Won
       Open Date Picker                      Close Date
       Pick Date                             Today
       Click Modal Button                    Save
       Wait Until Modal Is Closed
       ${matching_gift}                      Get Main Header
       Go To Page                            Listing
       ...                                   Opportunity
       Click Link                            link=${matching_gift}

