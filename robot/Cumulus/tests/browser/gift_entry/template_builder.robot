*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${template}       Robot Template

*** Test Cases ***

Create a template and make changes
    [Documentation]                           This test case checks if advanced mapping is enabled and if disabled, enables it. 
    ...                                       Checks if gift entry is disabled and if enabled, disables it and verifies that GE page has error. 
    ...                                       Then enables gift entry and verifies that gift entry page lands on templates page and has default template  
    [tags]                                    feature:GE          W-0                              
    Go To Page                                Custom              GE_Gift_Entry
    Wait Until Page Contains                  Default Gift Entry Template
    Click Gift Entry Button                   Create Template
    Wait Until Page Contains                  Gift Entry Template Information
    Enter Value In Field
    ...                                       Template Name=${template}
    ...                                       Description=This is created by automation script  
    Click Gift Entry Button                   Next: Form Fields
    Click Gift Entry Button                   Next: Batch Header
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Custom              GE_Gift_Entry
    Page Should Contain                       ${template}
    Select Template Action                    ${template}         Edit
    Save Current Record ID For Deletion       Form_Template__c
