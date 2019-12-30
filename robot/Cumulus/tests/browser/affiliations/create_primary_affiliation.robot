*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
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
    Select Tab    Related
    Verify Affiliated Contact    Affiliated Contacts    &{contact}[FirstName]    &{contact}[LastName]    Y  
    Click Related Item Link      Affiliated Contacts    &{contact}[FirstName] &{contact}[LastName]
    Save Current Record ID For Deletion    npe5__Affiliation__c    
