*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${template}       Robot Template

*** Test Cases ***

Verify Error Message with GE Disabled and enable GE
    [Documentation]                           This test case checks if advanced mapping is enabled and if disabled, enables it. 
    ...                                       Checks if gift entry is disabled and if enabled, disables it and verifies that GE page has error. 
    ...                                       Then enables gift entry and verifies that gift entry page lands on templates page and has default template  
    [tags]                                    feature:GE          W-039559                              
    Go To Page                                Landing              GE_Gift_Entry
    Click Gift Entry Button                   Create Template
    Current Page Should Be                    Template             GE_Gift_Entry 
    Enter Value In Field
    ...                                       Template Name=${template}
    ...                                       Description=This is created by automation script  
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing              GE_Gift_Entry
    Select Template Action                    ${template}          Edit
    Current Page Should Be                    Template             GE_Gift_Entry
    Select Object Group Field                 Account1             custom_acc_text 
    Fill Gift Entry Form                      
    ...                                       Required Opportunity: Amount=checked
    ...                                       Default Value Opportunity: Close Date=Today
    ...                                       Default Value Payment: Check/Reference Number=abc11233
    ...                                       Default Value Payment: Payment Method=Check 

