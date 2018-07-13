*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Household With Name Only
    ${contact_id} =  Create Contact
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Page Should Contain  &{contact}[LastName] Household
    Header Field Should Have Link  Account Name
    Go To Object Home         Contact
    ${con_name}    Verify Record    &{contact}[FirstName] &{contact}[LastName]
    Should Be Equal As Strings    ${con_name}    True
    
Create Household With Name and Email
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Page Should Contain  &{contact}[LastName] Household
    Header Field Should Have Link  Account Name
    Page Should Contain    skristem@salesforce.com
    Go To Object Home         Contact
    ${con_name}    Verify Record    &{contact}[FirstName] &{contact}[LastName]
    Should Be Equal As Strings    ${con_name}    True
    
Create Household with Name and Address
    ${contact_id} =  Create Contact with Address
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Page Should Contain  &{contact}[LastName] Household
    Header Field Should Have Link  Account Name
    Select Tab    Details 
    Page Should Contain    50 Fremont Street  
    Go To Object Home         Contact
    ${con_name}    Verify Record    &{contact}[FirstName] &{contact}[LastName]
    Should Be Equal As Strings    ${con_name}    True
         