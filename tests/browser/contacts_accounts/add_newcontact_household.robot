*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add New Contact to Household With Different LastName 
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    Go To Record Home  &{contact1}[AccountId]
    ${id}  Get Current Record Id
    Store Session Record    Account    ${id}
    #Create a new contact under HouseHold Validation
    ${contact_id2} =  New Contact for HouseHold
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Header Field Value    Account Name    &{contact1}[LastName] and &{contact2}[LastName] Household
