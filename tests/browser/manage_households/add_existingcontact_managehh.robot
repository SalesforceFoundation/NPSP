*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add Existing Contact to Existing Household through Manage Household Page
    &{contact1} =  API Create Contact    Email=skristem@robot.com   
    &{contact2} =  API Create Contact
    Go To Record Home  &{contact2}[AccountId] 
    Click Link    link=Show more actions
    Click Link    link=Manage Household 
    #Wait For Locator    frame    Manage Household    
    Sleep     5
    Select Frame With Title   Manage Household
    #Wait until element is visible    //div[text()="Household Address"]
    Populate Field By Placeholder    Find a Contact or add a new Contact to the Household    &{contact1}[FirstName] &{contact1}[LastName]
    Click Button  title=Add
    Sleep  5
    Click Managehh Button       Save
    Unselect Frame
    Wait For Locator    header    &{contact2}[LastName] and &{contact1}[LastName] Household
    Verify Header    &{contact2}[LastName] and &{contact1}[LastName] Household
    Verify Related List Items    Contacts    &{contact1}[FirstName] &{contact1}[LastName]
