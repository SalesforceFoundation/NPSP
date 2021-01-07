*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***


*** Keywords ***
Setup Test Data
    &{contact} =    API Create Contact                 FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable    &{contact}
    &{account} =    API Create Organization Account    Name=${faker.company()}
    Set suite variable    &{account}
    ${org_ns} =     Get Org Namespace Prefix
    Set suite variable    ${org_ns}
    ${ns} =         Get NPSP Namespace Prefix
    Set suite variable    ${ns}
    ${ui_date} =    Get Current Date                   result_format=%b %-d, %Y
    Set suite variable    ${ui_date}
    ${date} =       Get Current Date                   result_format=%Y-%m-%d
    Set suite variable    ${date}

Verify Error Message on AM Page And Object Group
    Go To Page                     Custom          NPSP_Settings
    Open Main Menu                 System Tools
    Click Link With Text           Advanced Mapping for Data Import & Gift Entry

*** Test Cases ***

Validate Errors When Field Is Renamed
    [Documentation]

    [tags]                           unstable                      feature:GE          W-8292840
    # Go To Page                       Landing                       GE_Gift_Entry
    # Click Gift Entry Button          New Single Gift
    # Current Page Should Be           Form                          Gift Entry
    # Wait Until Page Contains         Account 1: custom_acc_text
    Load Page Object                 Custom                        ObjectManager
    Rename Object Field              Account                       custom_acc_text     custom_acc_texts
    # Delete Object Field              Account                       custom_acc_text
