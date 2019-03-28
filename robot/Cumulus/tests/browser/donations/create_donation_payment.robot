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
    ${id}    Get Current Record Id
    Store Session Record    Opportunity    ${id}
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
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Go To Record Home  &{contact}[Id]
    Scroll Element Into View    text:Donation Totals
    Confirm Value           Last Gift Date    ${opp_date}    Y
    Scroll Element Into View    text:Soft Credit Total
    Confirm Value           Total Gifts    $100.00    Y
    Confirm Value           Total Number of Gifts    1    Y