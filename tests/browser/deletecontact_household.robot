*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Delete Contact from Household
    #1 contact HouseHold Validation
    ${contact_id1} =  Create Contact with Email
    &{contact1} =  Salesforce Get  Contact  ${contact_id1}
    Click Link                link= &{contact1}[LastName] Household
    
    #2 Create a new contact under HouseHold Validation
    ${contact_id2} =  New Contact for HouseHold
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Page Should Contain  &{contact1}[LastName] and &{contact2}[LastName] Household
    Go To Object Home    Contact
    Click Element     //span/span/label/span
    Click Link    link=Show More
    Click Link    link=Delete
    Go To Object Home    Account
    Page Should Contain Link   link=&{contact1}[LastName] Household