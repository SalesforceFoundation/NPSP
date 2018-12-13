*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Secondary Affiliation for Contact
    &{account} =  API Create Organization Account   
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Create Secondary Affiliation    &{account}[Name]    &{contact}[Id]
    Page Should Contain    &{contact}[LastName]
    Page Should Contain    &{account}[Name]
