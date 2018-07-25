*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from a Contact
    #1 contact HouseHold Validation
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    Go To Object Home         Opportunity
    Click Object Button       New
    Select Record Type        Donation 
    Sleep    2  
    Select Window
    Sleep    2   
    Populate Form
    ...                       Opportunity Name= Sravani $100 donation
    ...                       Amount=100 
    Click Dropdown    Stage
    Click Link    link=Closed Won
    Populate Lookup Field    Account Name    &{Contact}[LastName] Household
    Click Dropdown    Close Date
    Pick Date    10
    Select Modal Checkbox    Do Not Automatically Create Payment
    Click Modal Button        Save
    Sleep    5
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
    