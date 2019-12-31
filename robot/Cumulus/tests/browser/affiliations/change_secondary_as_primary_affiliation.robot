*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
Setup Test Data
    &{account} =                      API Create Organization Account 
    Set suite variable                &{account}  
    &{contact} =                      API Create Contact                 Email=automation@example.com 
    Set suite variable                &{contact}
    Store Session Record              Account                            &{contact}[AccountId]
    API Create Secondary Affiliation  &{account}[Id]                     &{contact}[Id]
    

*** Test Cases ***

Create Secondary Affiliation for Contact
    [tags]  unstable
    [Documentation]                   Creates a contact, organization account and secondary affiliation via API 
    ...                               Open contact and delete affiliation from organization affiliation related list     
    ...                               Verifies that contact does not show under affiliated contacts in the account page
    [tags]                            W-037651                     feature:Affiliations     
    Go To Page                        Details                      Contact                 object_id=&{contact}[Id]
    Select Tab                        Related
    Click Related Item Link           Organization Affiliations    &{account}[Name]
    # To make sure the field we want to edit has rendered,
    # scroll to the one below it
    Scroll Element Into View  text:Primary
    Click Button  title:Edit Primary
    Wait For Locator  checkbox.model-checkbox  Primary
    Select Lightning Checkbox    Primary
    Click Button    Save
    Go To Page                        Details                      Contact                 object_id=&{contact}[Id]
    Select Tab                        Details
    Verify Field Value                Primary Affiliation          contains                &{account}[Name]    
