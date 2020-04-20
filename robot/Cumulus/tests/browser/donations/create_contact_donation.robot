*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
# Setup a contact with parameters specified
Setup Test Data
    Setupdata   contact   ${contact1_fields}

*** Variables ***
${Date}  10
${Amount}  100
${Stage_Type}  Closed Won
&{contact1_fields}  Email=test@example.com


*** Test Cases ***

Create Donation from a Contact
    [Documentation]                      Create Opportunity from Contact with closed-won status.

    [tags]                               W-038461                 feature:Donations

    Go To Page                           Details
    ...                                  Contact
    ...                                  object_id=${data}[contact][Id]

    Click Object Button                  New Donation
    Wait For Modal                       New                       Donation
    Populate Modal Form
    ...                                  Stage=${Stage_Type}
    ...                                  Amount=${Amount}

    Open Date Picker                     Close Date
    Pick Date                            ${Date}
    Click Modal Button                   Save
    Wait Until Modal Is Closed
    ${value}                             Return Locator Value      alert
    Go To Page                           Listing                   Opportunity
    Click Link                           ${value}
    Current Page Should Be               Details                   Opportunity
    Save Current Record ID For Deletion  Opportunity
    Validate Related Record Count        Payments                     1

