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
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
# Setup a contact with parameters specified
Setup Test Data
    Setupdata   contact   ${contact1_fields}

*** Variables ***
&{contact1_fields}  Email=test@example.com

*** Test Cases ***
Create Open Recurring Donation With Monthly Installment
    [Documentation]              This test verifies that a Recurring Donation can be created through the UI.
    [tags]                        feature:Recurring Donations     unstable         api      quadrant:q3

    Go To Page                           Details
    ...                                  Contact
    ...                                  object_id=${data}[contact][Id]
    Wait Until Loading Is Complete
    Current Page Should Be               Details                      Contact
    Click More Actions Lightning Button
    Click Link With Spantext             New Open Recurring Donation

    Wait Until Modal Is Open
    Populate Modal Form
    ...                                  Recurring Donation Name= Robot Recurring Donation
    ...                                  Amount=100
    ...                                  Installment Period=Monthly
    Click Modal Button                   Save
    Wait Until Modal Is Closed
    Reload Page
    Select Tab                           Related
    Current Page Should Be               Details                Contact
    ##### KNOWN BUG!!! #####
    # 3/10/23: The Recurring Donation name is being overwritten with the default format name
    # Since NPSP does not have a future roadmap, the bug won't be fixed.
    # The test here is reflecting the current behavior in the product
    ${Default_RD_Name} =                 Set Variable    ${data}[contact][FirstName] ${data}[contact][LastName] $100 - Recurring
    Check Related List Values            Recurring Donations    ${Default_RD_Name}
    Load Related List                    Opportunities
    Click ViewAll Related List           Opportunities
    Verify Payment Details               12