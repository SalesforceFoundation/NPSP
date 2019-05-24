*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Household With Name Only
    ${contact_id} =  Create Contact
    &{contact} =  Salesforce Get  Contact  ${contact_id} 
    Header Field Value    Account Name    &{contact}[LastName] Household
    Go To Object Home         Contact
    Verify Record    &{contact}[FirstName] &{contact}[LastName]

    
Create Household With Name and Email
    [tags]  unstable
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    Header Field Value    Email    skristem@salesforce.com
    Go To Object Home         Contact
    Verify Record    &{contact}[FirstName] &{contact}[LastName]

    
Create Household with Name and Address
    ${contact_id} =  Create Contact with Address
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    Page Should Contain    50 Fremont Street  
    Go To Object Home         Contact
    Verify Record    &{contact}[FirstName] &{contact}[LastName]
