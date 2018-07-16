*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add New Contact to Existing Household 
    #1 contact HouseHold Validation
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Page Should Contain   &{contact}[LastName] Household
    Header Field Should Have Link  Account Name   
    
    #2 Create a new contact and add to contact1 HouseHold Validation
    Click Link    link=&{contact}[LastName] Household
    Header Field Should Have Link  Account Name
    Click Link    link=Show more actions
    Click Link    link=Manage Household    
    Sleep     15     Input-textbox-notloaded-properly    
    Select Frame   //iframe[@title= 'Manage Household']
    Click Element     //input
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    Press Key      //input    ${first_name} ${last_name}
    Sleep    2
    Click Button    //*[text()="New Contact"]
    #Click Edit Button      Add
    Sleep  5  Input-textbox-notloaded-properly
    Click Element    //*[@id="newContactPopup"]//div[@class="slds-modal__footer"]//button[@title="New Contact"]/span
    #Click Modal Button        New Contact
    Sleep    2
    Click Button       //*[contains(@title, "Save")]
    Sleep  5
    Page Should Contain  &{contact}[LastName] and ${last_name} Household
    Page Should Contain Link    ${first_name} ${last_name}

