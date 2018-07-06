*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Secondary Affiliation for Contact
    # Create Organization Account
    ${acc}    ${con}    Create Secondary Affiliation
    &{account} =  Salesforce Get  Account  ${acc}
    &{contact} =  Salesforce Get  Contact  ${con}
    Page Should Contain    &{contact}[LastName]
    Page Should Contain    &{account}[Name]
    