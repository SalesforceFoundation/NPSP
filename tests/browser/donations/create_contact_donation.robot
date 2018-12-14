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
    Create Opportunities    Test $100 donation    Closed Won
    Verify Occurrence    Payments    0
