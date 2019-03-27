*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from a Contact
    [tags]  unstable
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact}[AccountId]
    Go To Record Home  &{contact}[Id]
    Click Object Button  New Donation
    Populate Form
    ...                       Amount=100
    Click Dropdown    Stage
    Click Link    link=Closed Won
    Open Date Picker    Close Date
    Pick Date    10
    Click Modal Button        Save
    ${value}    Return Locator Value    alert
    Go To Object Home         Opportunity
    Click Link    ${value}
    ${id}    Get Current Record Id
    Store Session Record    Opportunity    ${id}
    Select Tab    Related
    Load Related List    Payments
    Verify Occurrence    Payments    1
