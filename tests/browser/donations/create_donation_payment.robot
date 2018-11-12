*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Donation and Opportunity and Create Payment Manually
    &{contact} =  API Create Contact    Email=skristem@robot.com
    &{opportunity} =  API Create Opportunity    &{Contact}[AccountId]    Donation    Name=Sravani $100 donation
    Go To Record Home  &{opportunity}[Id]
    Load Related List    Payments
    Select Related Dropdown    Payments
    Click Link    link=New
    #Sleep    2
    Select Window
    Populate Field    Payment Amount    100
    Click Dropdown    Payment Method
    Click Link    link=Credit Card
    Click Dropdown    Payment Date
    Pick Date    Today
    Click Modal Button        Save
    #Sleep    2
    Verify Occurance    Payments    1
   