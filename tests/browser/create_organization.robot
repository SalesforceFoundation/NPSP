*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Organization Foundation
    ${account_id} =  Create Organization Foundation
    &{account} =  Salesforce Get  Account  ${account_id}
    Page Should Contain  &{account}[Name]
    Page Should Contain  Foundation
    Header Field Should Have Link  Account Owner