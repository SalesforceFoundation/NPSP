*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
Create Primary Affiliation for Contact    
    ${acc}    ${con}    Create Primary Affiliation
    &{account} =  Salesforce Get  Account  ${acc}
    &{contact} =  Salesforce Get  Contact  ${con}
    Go To Object Home          Account
    Click Link    link=&{account}[Name]
    Verify Affiliated Contact    Affiliated Contacts    &{contact}[FirstName]    &{contact}[LastName]    Y    
   