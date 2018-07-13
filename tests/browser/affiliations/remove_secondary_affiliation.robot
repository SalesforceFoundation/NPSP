*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
Remove Secondary Affiliation for Contact    
    ${acc}    ${con}    Create Secondary Affiliation
    &{account} =  Salesforce Get  Account  ${acc}
    &{contact} =  Salesforce Get  Contact  ${con}
    Go To Object Home          Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    Sleep    5
    Scroll Page To Location    50    600
    Select Related Row    &{account}[Name]
    Click Link    link=Delete
    Click Modal Button    Delete
    Go To Object Home    Account
    Sleep    5
    Click Link    link=&{account}[Name]
    Page Should not Contain Link     &{contact}[FirstName]
 
    
