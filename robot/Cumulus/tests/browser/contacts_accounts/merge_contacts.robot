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
    ${first_name2} =       Generate Random String
    Set suite variable    ${first_name2}
    ${last_name} =        Generate Random String
    Set suite variable    ${last_name}
    &{contact1} =         API Create Contact    Email=${EMAIL1}     LastName=${last_name}   FirstName=${first_name}
    Set suite variable    &{contact1}
    &{contact2} =         API Create Contact    Email=${EMAIL2}     LastName=${last_name}   FirstName=${first_name2}
    Set suite variable    &{contact2}

*** Variables ***
${EMAIL1}  user1@example.com
${EMAIL2}  user2@example.com

*** Test Cases ***

Merge Two Contacts with Same LastName
    [Documentation]                         Create two contacts using the backend API. Navigate to the 
    ...                                     Contact Merge page and merge the contacts
    [tags]                                  feature:Contacts And Accounts   unit    unstable

    Load Page Object                        Custom                          ContactMerge
    Navigate To Contact Merge Page
    Click Search Contacts Button            ${last_name}
    Select Contact Checkbox                 1
    Select Contact Checkbox                 2
    Click Next Button
    Click Radio Button                      ${first_name}
    Click Merge Button
    Navigate To And Validate Field Value    Name            contains        ${first_name} ${last_name}
