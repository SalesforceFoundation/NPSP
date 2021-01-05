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
    Store Session Record                 Account               ${contact1}[AccountId]
    Set suite variable                   &{contact1}
    &{contact2} =                        API Create Contact
    Store Session Record                 Account               ${contact2}[AccountId]
    Set suite variable                   &{contact2}


*** Test Cases ***

Add Existing Contact to Existing Household
    [Documentation]                      Create 2 contacts with API which inturn creates 2 household accounts.
    ...                                  Open contact2 record and change the account name to contact1 account
    ...                                  verify that both the contacts are now showing under contact1 account
    [tags]                               W-037650              feature:Contacts and Accounts
    Go To Page                           Details               Contact                                object_id=${contact2}[Id]
    Edit Record
    Wait For Modal                       New                   Contact                                expected_heading=Edit ${contact2}[FirstName] ${contact2}[LastName]

    #Update account on contact2 and Save
    Update Field Value                   Account Name          ${contact2}[LastName] Household        ${contact1}[LastName] Household
    Click Modal Button                   Save
    Wait Until Modal Is Closed

    #Verify both contacts are displayed under household account1
    Go To Page                           Details               Account                                object_id=${contact1}[AccountId]
    Select Tab                           Related
    Verify Related List Items            Contacts              ${contact1}[FirstName] ${contact1}[LastName]
    Verify Related List Items            Contacts              ${contact2}[FirstName] ${contact2}[LastName]
