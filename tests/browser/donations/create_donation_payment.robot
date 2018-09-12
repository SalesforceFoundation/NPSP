*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Donation and Opportunity and Create Payment Manually
    #1 contact HouseHold Validation
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    Go To Object Home         Opportunity
    Click Object Button       New
    Select Record Type        Donation 
    Sleep    2
    Create Opportunities    Sravani $100 donation    &{Contact}[LastName] Household
    Sleep     5
    Select Related Dropdown    Payments
    Click Link    link=New
    Sleep    2
    Select Window
    Populate Field    Payment Amount    100
    Click Dropdown    Payment Method
    Click Link    link=Credit Card
    Click Dropdown    Payment Date
    Pick Date    Today
    Click Modal Button        Save
    Sleep    2
    Verify Occurance    Payments    1
   