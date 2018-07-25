*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add New Contact to Household With Different LastName 
    #1 contact HouseHold Validation
    ${contact_id1} =  Create Contact with Email
    &{contact1} =  Salesforce Get  Contact  ${contact_id1}
    Header Field Value    Account Name    &{contact1}[LastName] Household
    Click Link                link= &{contact1}[LastName] Household
    
    #2 Create a new contact under HouseHold Validation
    ${contact_id2} =  New Contact for HouseHold
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Header Field Value    Account Name    &{contact1}[LastName] and &{contact2}[LastName] Household
