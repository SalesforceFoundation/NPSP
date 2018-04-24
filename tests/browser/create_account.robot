*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Organization
    ${account_id} =  Create Organization
    &{account} =  Salesforce Get  Account  ${account_id}
    Page Should Contain  &{account}[Name]
    Header Field Should Have Link  Account Owner

Create HouseHold
    ${account_id} =  Create HouseHold
    &{account} =  Salesforce Get  Account  ${account_id}
    Page Should Contain  &{account}[Name]
    Header Field Should Have Link  Account Owner

