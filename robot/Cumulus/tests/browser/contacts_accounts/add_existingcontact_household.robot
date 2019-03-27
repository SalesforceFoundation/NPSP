*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add Existing Contact to Existing Household 
    [tags]  unstable
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    &{contact2} =  API Create Contact
    Go To Record Home  &{contact2}[Id]
    Click Link    link=Edit
    Delete Icon    Account Name    &{contact2}[LastName] Household
    Populate Lookup Field    Account Name    &{contact1}[LastName] Household
    Click Modal Button    Save
    Click Header Field Link  Account Name
    ${id}  Get Current Record Id
    Store Session Record    Account    ${id}
    Verify Related List Items    Contacts    &{contact1}[FirstName] &{contact1}[LastName]
    Verify Related List Items    Contacts    &{contact2}[FirstName] &{contact2}[LastName]
