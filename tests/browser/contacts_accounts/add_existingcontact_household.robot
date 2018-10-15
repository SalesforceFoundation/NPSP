*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add Existing Contact to Existing Household 
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    &{contact2} =  API Create Contact
    Go To Record Home  &{contact2}[Id]
    Click Link    link=Edit
    Delete Icon    Account Name    &{contact2}[LastName] Household
    Populate Lookup Field    Account Name    &{contact1}[LastName] Household
    Click Modal Button    Save
    #Sleep    5
    Go To Object Home          Account
    Reload Page
    Click Link    link=&{contact1}[LastName] and &{contact2}[LastName] Household
    #Sleep    5   
    Verify Related List Items    Contacts    &{contact2}[FirstName] &{contact2}[LastName]
