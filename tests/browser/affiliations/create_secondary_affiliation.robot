*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Secondary Affiliation for Contact
    &{account} =  API Create Organization Account   
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact}[AccountId]
    Create Secondary Affiliation    &{account}[Name]    &{contact}[Id]
    Page Should Contain    &{contact}[LastName]
    Page Should Contain    &{account}[Name]
    ${value}    Get NPSP Locator    alert
    Click Element    ${value}
    ${id}    Get Current Record Id
    Store Session Record    npe5__Affiliation__c    ${id}