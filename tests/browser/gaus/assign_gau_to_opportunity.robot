*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Assign GAU to Opportunity
    [tags]  unstable
    &{gau1} =  API Create GAU
    &{gau2} =  API Create GAU
    &{contact} =  API Create Contact    Email=skristem@robot.com
    &{opportunity} =  API Create Opportunity    &{Contact}[AccountId]    Donation    Name=Test GAU donation
    Go To Record Home  &{opportunity}[Id]
    Select Tab    Related
    Click Special Related List Button    GAU Allocations    Manage Allocations
    Wait For Locator    frame    Manage Allocations
    Select Frame With Title    Manage Allocations
    Select Search    General Accounting Unit 0    &{gau1}[Name]
    Add GAU Allocation    Percent 0    50
    Click Link    Add Row    
    Select Search    General Accounting Unit 1    &{gau2}[Name]  
    Add GAU Allocation    Amount 1    20
    Click Button    Save
    Wait Until Page Does Not Contain    Add Row
    Select Window
    Page Scroll To Locator    record.related.check_occurrence    GAU Allocations
    Verify Occurrence    GAU Allocations    2
   