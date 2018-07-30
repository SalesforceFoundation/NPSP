*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from Contact and Verify Contact Roles on Opportunity Page
    #1 contact HouseHold Validation
    ${contact_id1} =  Create Contact with Email
    &{contact1} =  Salesforce Get  Contact  ${contact_id1}
    Header Field Value    Account Name    &{contact1}[LastName] Household
    Click Link            link= &{contact1}[LastName] Household
    ${contact_id2} =  New Contact for HouseHold
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Header Field Value    Account Name    &{contact1}[LastName] and &{contact2}[LastName] Household
    Scroll Page To Location    0    500
    Sleep    5
    Click Special Related List Button   Opportunities    New Contact Donation
    Choose Frame    New Opportunity
    Click Element    p3
    Select Option    Donation    
    Click Element    //input[@title='Continue']
    Sleep    5  
    Create Opportunities    Role test $100 donation    &{contact1}[LastName] and &{contact2}[LastName] Household
    Sleep    2
    ${donation_name}    Get Main Header
    Go To Object Home         Opportunity
    Click Link    link=${donation_name}
    Sleep    5 
    Select Relatedlist    Contact Roles
    sleep    2
    Verify Contact Roles
    ...                     &{contact1}[FirstName] &{contact1}[LastName]=Donor
    ...                     &{contact2}[FirstName] &{contact2}[LastName]=Household Member  