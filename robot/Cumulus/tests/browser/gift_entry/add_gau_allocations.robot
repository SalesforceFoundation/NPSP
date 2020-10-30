*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${TEMPLATE}       GAU Widget Template
&{CONTACT}        Email=test@example.com

*** Keywords ***
Setup Test Data
    &{DEFAULT_GAU} =      API Create GAU
    Set suite variable    &{DEFAULT_GAU}
    &{GAU1} =      API Create GAU
    Set suite variable    &{GAU1}
    &{GAU2} =      API Create GAU
    Set suite variable    &{GAU2}
    ${ns} =  Get NPSP Namespace Prefix
    Set suite variable    ${NS}

*** Test Cases ***

Test GAU Allocations with Default Allocations Disabled
    [Documentation]                         Create a template with GAU widget. Create a batch with new template and verify GAU widget is added to form
    [tags]                                  feature:GE                    W-039556
    API Modify Allocations Setting
    ...        ${ns}Default_Allocations_Enabled__c=false
    ...        ${ns}Default__c=None
    Go To Page                              Landing                        GE_Gift_Entry
    Click Link                              Templates
    Click Gift Entry Button                 New Single Gift
    Current Page Should Be                  Form                            Gift Entry
    Page Should Not Contain                 ${DEFAULT_GAU}[Name]
    Fill Gift Entry Form
    ...                                     Donor Type=Contact1
    ...                                     Contact First Name=${faker.first_name()}
    ...                                     Contact Last Name=${faker.last_name()}
    ...                                     Donation Amount=100
    ...                                     Donation Date=Today
    Click Gift Entry Button                 Add New Allocation
    Fill Gift Entry Form
    ...                                     General Accounting Unit 0=${GAU1}[Name]
    ...                                     Percent 0=70
    Click Gift Entry Button                 Add New Allocation
    Fill Gift Entry Form
    ...                                     General Accounting Unit 1=${GAU1}[Name]
    ...                                     Amount 1=50
    Validate Error Message                  Allocation Error=Total amount doesn't match the Donation Amount


