*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Assign GAU to Opportunity
    [tags]  unstable
    &{gau1} =  API Create GAU
    &{gau2} =  API Create GAU
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact}[AccountId]
    &{opportunity} =  API Create Opportunity    &{Contact}[AccountId]    Donation    Name=Test GAU donation
    Go To Record Home  &{opportunity}[Id]
    Select Tab    Related
    Click Special Related List Button    GAU Allocations    Manage Allocations
    Wait For Locator    frame    Manage Allocations
    Choose Frame    Manage Allocations
    Select Search    General Accounting Unit 0    &{gau1}[Name]
    Add GAU Allocation    Percent 0    50
    Click Link    Add Row    
    Select Search    General Accounting Unit 1    &{gau2}[Name]  
    Add GAU Allocation    Amount 1    20
    Click Button    Save
    Current Page Should Be     Details    Opportunity  
    Scroll Page To Location    0    0  
    Validate Related Record Count    GAU Allocations    2
