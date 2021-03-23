*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create via API
    [tags]                            unstable
    &{contact} =  API Create Contact
    Go To Record Home  ${contact}[Id]
    Page Should Contain  ${contact}[FirstName] ${contact}[LastName]
    Header Field Should Have Link  Account Name

*** Keywords ***

Get Random Contact Info
    ${first_name} =  Generate Random String
    ${last_name} =  Generate Random String
    Set Test Variable  ${first_name}  ${first_name}
    Set Test Variable  ${last_name}  ${last_name}
