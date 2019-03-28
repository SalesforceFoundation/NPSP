*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Organization Foundation
    ${account_id} =  Create Organization Foundation
    &{account} =  Salesforce Get  Account  ${account_id}
    Page Should Contain  &{account}[Name]
    Header Field Should Have Link  Account Owner
    Go To Object Home    Account
    #Sleep    2
    Verify Record    &{account}[Name]
