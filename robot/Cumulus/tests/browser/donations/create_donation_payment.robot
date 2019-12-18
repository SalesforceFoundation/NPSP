*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Donation and Opportunity and Create Payment Manually
    [tags]  unstable
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact}[AccountId]
    Go To Object Home         Opportunity
    Click Object Button       New
    Select Record Type        Donation
    Create Opportunities    Sravani $100 donation    &{Contact}[LastName] Household    Closed Won
    Save Current Record ID For Deletion    Opportunity   
    Select Tab    Related
    Load Related List    Payments
    Verify Occurrence    Payments    0
    Click Related List Button    Payments    New
    Select Window
    Populate Field    Payment Amount    100
    Select Value From Dropdown   Payment Method              Credit Card
    Open Date Picker    Payment Date
    Pick Date    Today
    Click Modal Button        Save
    Verify Occurrence    Payments    1
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Go To Record Home  &{contact}[Id]
    Scroll Element Into View    text:Donation Totals
    Confirm Field Value           Last Gift Date    contains    ${opp_date}    
    Scroll Element Into View    text:Soft Credit Total
    Confirm Field Value          Total Gifts    contains    $100.00    
    Confirm Field Value           Total Number of Gifts    contains    1    