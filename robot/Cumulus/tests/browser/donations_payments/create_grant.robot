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
    Create Opportunities    Robot $100 grant    &{Contact}[LastName] Household    Awarded
    ${grant_name}    Get Main Header
    Go To Object Home         Opportunity
    Click Link    link=${grant_name} 
