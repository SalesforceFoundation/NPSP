*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Matching Donation
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Go To Object Home         Opportunity
    Click Object Button       New
    Select Record Type        Matching 
    #Sleep    2
    Create Opportunities    Robot $100 matching donation    &{Contact}[LastName] Household
    #Sleep     5
    ${match_name}    Get Main Header
    Go To Object Home         Opportunity
    #Sleep    2
    Click Link    link=${match_name} 
    #Sleep    2