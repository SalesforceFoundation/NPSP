*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${template}       Robot Template
&{method}         Default Value=Check
&{check}          Default Value=abc11233
&{date}           Default Value=Today
&{amount}         Required=checked

*** Test Cases ***

Edit GE Template And Verify Changes
    [Documentation]                           This test case checks if advanced mapping is enabled and if disabled, enables it. 
    ...                                       Checks if gift entry is disabled and if enabled, disables it and verifies that GE page has error. 
    ...                                       Then enables gift entry and verifies that gift entry page lands on templates page and has default template  
    [tags]                                    unstable  feature:GE          W-039559   
    # &{temp} =   API Create GE Template  
    # Go To Page                                Landing              GE_Gift_Entry
    # Select Template Action                    &{temp}[Name]          Edit                         
    Go To Page                                Landing              GE_Gift_Entry
    Click Gift Entry Button                   Create Template
    Current Page Should Be                    Template             GE_Gift_Entry 
    Enter Value In Field
    ...                                       Template Name=${template}
    ...                                       Description=This is created by automation script  
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing              GE_Gift_Entry
    Store Template Record Id                  ${template}
    Select Template Action                    ${template}          Edit
    Current Page Should Be                    Template             GE_Gift_Entry
    Click Gift Entry Button                   Next: Form Fields
    Select Object Group Field                 Account 1            custom_acc_text 
    Fill GE Form                      
    ...                                       Opportunity: Amount=&{amount}
    ...                                       Opportunity: Close Date=&{date}
    ...                                       Payment: Check/Reference Number=&{check}
    ...                                       Payment: Payment Method=&{method} 
    Add Field Bundle TO New Section           GAU Allocations
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing              GE_Gift_Entry