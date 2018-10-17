*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
Remove Secondary Affiliation for Contact    
    &{account} =  API Create Organization Account
    &{contact} =  API Create Contact    Email=skristem@robot.com    
    API Create Secondary Affiliation    &{account}[Id]    &{contact}[Id]
    Go To Object Home          Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    #Sleep    5
    Wait For Locator    record.related.title    Relationships    
    Scroll Page To Location    50    600
    Select Related Row    &{account}[Name]
    Click Link    link=Delete
    Click Modal Button    Delete
    Go To Object Home    Account
    #Sleep    5
    Click Link    link=&{account}[Name]
    Verify Affiliated Contact    Affiliated Contacts    &{contact}[FirstName]    &{contact}[LastName]    N
   
 
    
