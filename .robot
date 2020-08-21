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

*** Keywords ***

Setup Test Data
    ${first_name} =       Generate Random String
    Set suite variable    ${first_name}
    ${last_name} =        Generate Random String
    Set suite variable    ${last_name}
    &{contact1} =         API Create Contact                    Email=${EMAIL1}
    Store Session Record  Account                               &{contact1}[AccountId]
    Set suite variable    &{contact1}

*** Variables ***

${EMAIL1}  user1@example.com
${EMAIL2}  user2@example.com

*** Test Cases ***

Add New related Contact to Household With Different LastName
    [Documentation]                       Create a contact using the backend API. Navigate to the Account details
    ...                                   create another Linked contact with different name,address and email.
    [tags]                                  W-037650                                feature:Contacts And Accounts
   Go To Page                   Details          Contact    object_id=&{contact1}[Id]

