*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
&{method}         Default Value=Check
&{check}          Default Value=abc11233
&{date}           Default Value=Today
&{custom}         Required=checked

*** Test Cases ***

Edit GE Template And Verify Changes
    [Documentation]                           This test case makes edits to Default gift entry template and verifies that edits are saved 
    ...                                       and available when a Single gift or batch gift are created. 
 
    [tags]                                    unstable  feature:GE          W-039559   
                       
    Go To Page                                Landing                       GE_Gift_Entry
    Select Template Action                    Default Gift Entry Template   Edit
    Current Page Should Be                    Template                      GE_Gift_Entry
    Click Gift Entry Button                   Next: Form Fields
    Select Object Group Field                 Account 1                     custom_acc_text 
    Select Object Group Field                 Opportunity                   Donation Imported
    Fill GE Form                      
    ...                                       Account 1: custom_acc_text=&{custom}
    ...                                       Opportunity: Close Date=&{date}
    ...                                       Payment: Check/Reference Number=&{check}
    ...                                       Payment: Payment Method=&{method} 
    Add Field Bundle TO New Section           GAU Allocations
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing              GE_Gift_Entry