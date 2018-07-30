*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from a Contact and Delete Opportunity
    #1 contact HouseHold Validation
    ${contact_id1} =  Create Contact with Email
    &{contact1} =  Salesforce Get  Contact  ${contact_id1}
    Header Field Value    Account Name    &{contact1}[LastName] Household
    Scroll Page To Location    0    500
    Sleep    5
    Click Special Related List Button   Opportunities    New Contact Donation
    Choose Frame    New Opportunity
    Click Element    p3
    Select Option    Donation    
    Click Element    //input[@title='Continue']
    Sleep    5  
    Create Opportunities    Delete test $100 donation    &{contact1}[LastName] Household
    Sleep    2
    ${donation_name}    Get Main Header
    Go To Object Home         Opportunity
    Select Row    ${donation_name}
    Sleep    5
    Click Link    link=Delete
    Click Modal Button        Delete
    Sleep    5 
    Page Contains Record    ${donation_name}