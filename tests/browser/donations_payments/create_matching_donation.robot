*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Matching Donation
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    Go To Object Home         Opportunity
    Click Object Button       New
    Select Record Type        Matching Donation 
    Sleep    2
    Create Opportunities    Robot $100 matching donation    &{Contact}[LastName] Household
    Sleep     5
    ${match_name}    Get Main Header
    Go To Object Home         Opportunity
    Sleep    2
    Click Link    link=${match_name} 
    Sleep    2