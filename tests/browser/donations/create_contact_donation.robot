*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from a Contact
    [tags]  unstable
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Go To Record Home  &{contact}[Id]
    Click Object Button  New Donation
    Populate Form
    ...                       Opportunity Name= Test $100 donation
    ...                       Amount=100
    Click Dropdown    Stage
    Click Link    link=Closed Won
    Click Dropdown    Close Date
    Pick Date    10
    Click Modal Button        Save
    Verify Occurrence    Payments    0
