*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Grant
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Go To Object Home         Opportunity
    Click Object Button       New
    Select Record Type        Grant
    Populate Form
    ...                       Opportunity Name= Robot $100 grant
    ...                       Amount=100
    Select Value From Dropdown    Stage    Awarded
    Populate Lookup Field    Account Name    &{Contact}[LastName] Household
    Open Date Picker    Close Date
    Pick Date    Today
    Set Checkbutton To    Do Not Automatically Create Payment    checked
    Click Modal Button        Save
    Wait Until Modal Is Closed
    ${grant_name}    Get Main Header
    Go To Object Home         Opportunity
    Click Link    link=${grant_name} 
