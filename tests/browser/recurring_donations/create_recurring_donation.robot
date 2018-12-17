*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Open Recurring Donation With Monthly Installment
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Go To Record Home  &{contact}[Id]
    Select Tab  Related
    Click Related List Button  Recurring Donations    New
    Populate Form
    ...                       Recurring Donation Name= Robot Recurring Donation
    ...                       Amount=100 
    ...                       Installments=1 
    Click Dropdown    Date Established
    Change Month      Go to previous month
    Pick Date         10 
    Click Dropdown    Open Ended Status
    Click Link        link=Open
    Click Dropdown    Installment Period
    Click Link        link=Monthly
    Click Dropdown    Schedule Type
    Click Link        link=Multiply By
    Click Modal Button        Save
    Check Related List Values    Recurring Donations    Robot Recurring Donation
    Reload Page
    Select Tab  Related
    Load Related List    Opportunities
    Click ViewAll Related List    Opportunities
    ${return_value}    Verify Payment Details
    Should be equal as strings    ${return_value}    12
    Verify Opportunities    12
