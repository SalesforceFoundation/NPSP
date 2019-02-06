*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Donation and Opportunity and Create Payment Manually
    [tags]  unstable
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Go To Object Home         Opportunity
    Click Object Button       New
    Select Record Type        Donation
    Create Opportunities    Sravani $100 donation    &{Contact}[LastName] Household    Closed Won
    Select Tab    Related
    Load Related List    Payments
    Verify Occurrence    Payments    0
    Click Related List Button    Payments    New
    Select Window
    Populate Field    Payment Amount    100
    Click Dropdown    Payment Method
    Click Link    link=Credit Card
    Open Date Picker    Payment Date
    Pick Date    Today
    Click Modal Button        Save
    Verify Occurrence    Payments    1
