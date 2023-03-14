*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***
Setup Test Data
    &{contact1} =                        API Create Contact    Email=automation@example.com
    Store Session record                 Account               ${contact1}[AccountId] 
    Set suite variable                   &{contact1}
    &{contact2} =                        API Create Contact    AccountId=${contact1}[AccountId]
    Set suite variable                   &{contact2}


*** Test Cases ***

Delete Contact from Household
    [Documentation]                      Create two contacts with API which inturn creates 2 household accounts.
    ...                                  Navigate to contacts listing page and select second contact. Delete the contact and validate that there is only primary household account
    ...                                  Now try to delete the primary household account and verify that a warning message is displayed.
    [tags]                               feature:Contacts And Accounts   unit
    Go To Page                           Listing               Contact
    Delete Record                        ${Contact2}[FirstName] ${Contact2}[LastName]
    Go To Page                           Details               Account                                object_id=${contact1}[Id]
    Page Should Contain                  ${contact1}[LastName] Household
    Go To Page                           Listing               Contact
    Select Row                           ${Contact1}[FirstName] ${Contact1}[LastName]
    Click Link                           title=Delete
    Wait Until Page Contains             Warning


