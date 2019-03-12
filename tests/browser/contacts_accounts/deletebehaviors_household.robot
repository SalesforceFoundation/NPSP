*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Delete Contact with Closed Won Opportunity from Household
    &{contact} =  API Create Contact    Email=skristem@robot.com 
    Store Session record    Account    &{contact}[AccountId] 
    &{opportunity} =  API Create Opportunity    &{Contact}[AccountId]    Donation    Name=Sravani $100 donation
    Go To Object Home    Contact    
    Select Row    &{Contact}[FirstName] &{Contact}[LastName]
    Click Link    title=Delete
    Select Frame with Name    vfFrameId
    Click Button With Value    Delete Account
    Page Should Contain    Error
