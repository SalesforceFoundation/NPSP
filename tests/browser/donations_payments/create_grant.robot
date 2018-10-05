*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Grant
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    Go To Object Home         Opportunity
    Click Object Button       New
    Select Record Type        Grant 
    Sleep    2
    Create Opportunities    Robot $100 grant    &{Contact}[LastName] Household
    Sleep     5
    ${grant_name}    Get Main Header
    Go To Object Home         Opportunity
    Click Link    link=${grant_name} 
    Sleep    2