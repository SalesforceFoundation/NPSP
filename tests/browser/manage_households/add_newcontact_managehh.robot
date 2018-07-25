*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add New Contact to Existing Household 
    #1 contact HouseHold Validation
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value  Account Name   &{contact}[LastName] Household
    
    #2 Create a new contact using Manage Household Page and add to contact1 HouseHold Validation 
    Click Link    link=&{contact}[LastName] Household
    Click Link    link=Show more actions
    Click Link    link=Manage Household    
    Sleep     15     Input-textbox-notloaded-properly    
    Select Frame With Title   Manage Household
    Click Element     //input
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    Press Key      //input    ${first_name} ${last_name}
    Sleep    2
    Click Button    //*[text()="New Contact"]
    Sleep  5  Input-textbox-notloaded-properly
    Click Managehh Special Button    New Contact
    Sleep    2
    Click Managehh Button       Save
    Sleep  5
    Header Field Value    Account Name    &{contact}[LastName] and ${last_name} Household
    Verify Related List Items    Contacts    ${first_name} ${last_name}


