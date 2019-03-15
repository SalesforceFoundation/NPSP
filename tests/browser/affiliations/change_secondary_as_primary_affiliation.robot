*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Secondary Affiliation for Contact
    &{account} =  API Create Organization Account
    &{contact} =  API Create Contact    Email=skristem@robot.com 
    Store Session Record    Account    &{contact}[AccountId]   
    API Create Secondary Affiliation    &{account}[Id]    &{contact}[Id]
    Go To Record Home  &{contact}[Id]
    Page Should Contain    &{contact}[LastName]
    Select Tab  Related
    Click Related Item Link  Organization Affiliations  &{account}[Name]
    # To make sure the field we want to edit has rendered,
    # scroll to the one below it
    Scroll Element Into View  text:Primary
    Click Button  title:Edit Primary
    Wait For Locator  checkbox  Primary
    Select Lightning Checkbox    Primary
    Click Record Button    Save
    #Sleep    5
    Go To Object Home    Contact
    Click link    link=&{contact}[FirstName] &{contact}[LastName]
    Verify Field Value    Primary Affiliation    &{account}[Name]    Y
