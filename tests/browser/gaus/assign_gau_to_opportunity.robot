*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Assign GAU to Opportunity
    &{gau1} =  API Create GAU
    &{gau2} =  API Create GAU
    &{contact} =  API Create Contact    Email=skristem@robot.com
    &{opportunity} =  API Create Opportunity    &{Contact}[AccountId]    Name=Test GAU donation
    Go To Record Home  &{opportunity}[Id]
    Page Scroll To Locator    record.related.title    GAU Allocations
    Select Related Dropdown    GAU Allocations
    Click Link    link=Manage Allocations
    #Sleep    2
    Select Frame With Title    Manage Allocations
    Select Search    0    &{gau1}[Name]
    Add GAU Allocation    percentage    0    50
    Click Task Button    Add Row    
    Select Search    1    &{gau2}[Name] 
    #sleep    2   
    Add GAU Allocation    amount    1    20
    Click Save    GAU
    Verify Occurance    GAU Allocations    2
   