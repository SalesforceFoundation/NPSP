*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add Existing Contact to Existing Household 
    #1 contact HouseHold Validation
    ${contact_id1} =  Create Contact with Email
    &{contact1} =  Salesforce Get  Contact  ${contact_id1}
    Page Should Contain   &{contact1}[LastName] Household
    Header Field Should Have Link  Account Name   
    
    #2 Create a new contact and add to contact1 HouseHold Validation
    ${contact_id2} =  Create Contact
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Page Should Contain  &{contact2}[LastName] Household
    Click Link    link=Edit
    Delete Icon    Account Name    &{contact2}[LastName] Household
    Populate Lookup Field    Account Name    &{contact1}[LastName] Household
    Click Modal Button    Save
    Sleep    5
    Go To Object Home          Account
    Click Link    link=&{contact1}[LastName] and &{contact2}[LastName] Household
    Sleep    5  
    Page Should Contain Link  &{contact2}[FirstName] &{contact2}[LastName]  
    
