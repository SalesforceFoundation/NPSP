*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***
Setup Test Data
    &{contact} =              API Create Contact        Email=automation@example.com 
    Set suite variable        &{contact}
    Store Session record      Account                   ${contact}[AccountId] 
    &{opportunity} =          API Create Opportunity    ${Contact}[AccountId]        Donation    Name=Sravani $100 donation
    Set suite variable        &{opportunity}

*** Test Cases ***

Delete Contact with Closed Won Opportunity from Household
    [Documentation]                   Create a contact and an opportunity for the contact in closed won stage via API. 
    ...                               On trying to delete the contact verify that a error is thrown     
    [tags]                            feature:Contacts and Accounts   unit
    Go To Page                        Listing                                        Contact    
    Select Row                        ${Contact}[FirstName] ${Contact}[LastName]
    Click Link                        title=Delete
    Click Delete Account Button
    Wait Until Page Contains          Error: You can't delete
