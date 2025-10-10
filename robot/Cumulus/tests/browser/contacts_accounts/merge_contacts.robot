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

*** Keywords ***
Setup Test Data
    ${first_name} =       Generate Random String
    Set suite variable    ${first_name}
    ${last_name} =        Generate Random String
    Set suite variable    ${last_name}
    &{contact1} =         API Create Contact    Email=${EMAIL1}     LastName=${last_name}
    Set suite variable    &{contact1}
    &{contact2} =         API Create Contact    Email=${EMAIL2}     LastName=${last_name}
    Set suite variable    &{contact2}

*** Variables ***
${EMAIL1}  user1@example.com
${EMAIL2}  user2@example.com

*** Test Cases ***

Add New related Contact to Household With Different LastName
    [Documentation]                         Create two contacts using the backend API. Navigate to the 
    ...                                     Contact Merge page and merge the contacts
    [tags]                                  feature:Contacts And Accounts   unit

    Load Page Object                        Custom                          ContactMerge
    Navigate To Contact Merge Page
    Click Search Contacts Button            ${last_name}
    Select Contact Checkbox                 1
    Select Contact Checkbox                 2
    Click Next Button
    Click Merge Button
