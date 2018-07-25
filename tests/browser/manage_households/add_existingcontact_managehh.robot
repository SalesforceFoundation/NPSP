*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add Existing Contact to Existing Household 
    #1 contact HouseHold Validation
    ${contact_id1} =  Create Contact with Email
    &{contact1} =  Salesforce Get  Contact  ${contact_id1}
    Header Field Value    Account Name    &{contact1}[LastName] Household  
    
    #2 Create a new contact and add to existing contact1 HouseHold Validation using Manage Household page
    ${contact_id2} =  Create Contact
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Header Field Value    Account Name    &{contact2}[LastName] Household    
    Click Link    link=&{contact2}[LastName] Household    
    Click Link    link=Show more actions
    Click Link    link=Manage Household    
    Sleep     15     Input-textbox-notloaded-properly    
    Select Frame With Title   Manage Household
    Click Element     //input
    Press Key      //input    &{contact1}[FirstName] &{contact1}[LastName]
    Click Edit Button      Add
    Sleep  5  Input-textbox-notloaded-properly
    Click Managehh Button       Save
    Sleep  10
    Header Field Value    Account Name    &{contact2}[LastName] and &{contact1}[LastName] Household
    Verify Related List Items    Contacts    &{contact1}[FirstName] &{contact1}[LastName]
    

