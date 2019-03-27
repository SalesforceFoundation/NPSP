*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Open Recurring Donation With Monthly Installment
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Go To Record Home  &{contact}[Id]
    Click Link    link=Show more actions
    Click Link    link=New Open Recurring Donation
    Wait Until Modal Is Open
    Populate Form
    ...                       Recurring Donation Name= Robot Recurring Donation
    ...                       Amount=100 
    Click Dropdown    Installment Period
    Click Link        link=Monthly
    Click Modal Button        Save
    Reload Page
    Select Tab  Related
    Load Related List    Recurring Donations
    Check Related List Values    Recurring Donations    Robot Recurring Donation
    Load Related List    Opportunities
    Click ViewAll Related List    Opportunities
    ${return_value}    Verify Payment Details
    Should be equal as strings    ${return_value}    12
    # Verify Opportunities    12
