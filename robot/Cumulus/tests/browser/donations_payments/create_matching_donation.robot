*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Matching Donation
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Go To Page                Listing    Opportunity    
    Click Object Button       New
    Select Record Type        Matching Gift

    Populate Form
    ...                       Opportunity Name= Robot $100 matching donation
    ...                       Amount=100
    Select Value From Dropdown    Stage    Closed Won
    Populate Lookup Field    Account Name    &{Contact}[LastName] Household
    Open Date Picker    Close Date
    Pick Date    Today
    Set Checkbutton To    Do Not Automatically Create Payment    checked
    Click Modal Button        Save
    ${match_name}    Get Main Header
    Go To Page                Listing    Opportunity
    Click Link    link=${match_name} 
