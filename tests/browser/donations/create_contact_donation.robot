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
    Scroll Page To Location    0    500
    Sleep    5
    Click Special Related List Button   Opportunities    New Contact Donation
    Choose Frame    New Opportunity
    Click Element    p3
    Select Option    Donation    
    Click Element    //input[@title='Continue']
    Sleep    5  
    Select Window
    Sleep    5   
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
    Sleep    2
    Verify Occurance    Payments    0
    