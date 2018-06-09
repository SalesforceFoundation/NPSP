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
    Click Link    link=&{contact2}[LastName] Household
    Header Field Should Have Link  Account Name
    Click Link    link=Show more actions
    Click Link    link=Manage Household    
    Sleep     15     Input-textbox-notloaded-properly    
    Select Frame   //iframe[@title= 'Manage Household']
    Click Element     //input
    Press Key      //input    &{contact1}[FirstName] &{contact1}[LastName]
    Click Element      //*[@title= 'Add']
    Sleep  5  Input-textbox-notloaded-properly
    Click Button       //*[contains(@title, "Save")]
    Sleep  10
    Page Should Contain  &{contact2}[LastName] and &{contact1}[LastName] Household

