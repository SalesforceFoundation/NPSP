*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
Setup Test Data
    &{contact} =              API Create Contact        Email=automation@robot.com 
    Set suite variable        &{contact}
    Store Session record      Account                   &{contact}[AccountId] 
    &{opportunity} =          API Create Opportunity    &{Contact}[AccountId]        Donation    Name=Sravani $100 donation
    Set suite variable        &{opportunity}

*** Test Cases ***

Delete Contact with Closed Won Opportunity from Household
    [Documentation]
    Go To Page                        Listing                                        Contact    
    Select Row                        &{Contact}[FirstName] &{Contact}[LastName]
    Click Link                        title=Delete
    Click Delete Account Button
    Page Should Contain               Error
