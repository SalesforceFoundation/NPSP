*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
Create Primary Affiliation for Contact
    &{account} =  API Create Organization Account   
    &{contact} =  API Create Contact    Email=skristem@robot.com 
    Store Session Record    Account    &{contact}[AccountId]
    Create Primary Affiliation    &{account}[Name]    &{contact}[Id]    
    Go To Object Home          Account
    Click Link    link=&{account}[Name]
    Verify Affiliated Contact    Affiliated Contacts    &{contact}[FirstName]    &{contact}[LastName]    Y  
    Click Related Item Link      Affiliated Contacts    &{contact}[FirstName] &{contact}[LastName]
    ${id}    Get Current Record Id
    Store Session Record    npe5__Affiliation__c    ${id}
   