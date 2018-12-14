*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from a Contact
    [tags]  unstable
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Go To Record Home  &{contact}[Id]
    Load Related List    Opportunities
    Click Special Related List Button   Opportunities    New Contact Donation
    Choose Frame    New Opportunity
    Click Element    p3
    Select Option    Donation    
    Click Button With Value    Continue
    #Sleep    5  
    Create Opportunities    Test $100 donation    &{Contact}[LastName] Household
    #Sleep    2
    Verify Occurrence    Payments    0
    
