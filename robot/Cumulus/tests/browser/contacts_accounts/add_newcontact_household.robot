*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Variables
Suite Teardown  Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${first_name} =           Generate Random String
    Set suite variable    ${first_name}
    ${last_name} =            Generate Random String
    Set suite variable    ${last_name}

*** Variables ***
 ${EMAIL1} =       user1@robot.com
 ${EMAIL2} =       user2@robot.com

*** Test Cases ***

Add New related Contact to Household With Different LastName
    [Documentation]                       Create a contact using the backend API. Navigate to the Account details
    ...                                   create another Linked contact with different name,address and email.
    [tags]                                  W-037650                                feature:Contacts&Accounts

    &{contact1} =                           API Create Contact                      Email=${EMAIL1}
    Go To Page                              Details                                 Account                                object_id=&{contact1}[AccountId]
    Save Session Record For Deletion        Account

    #Add a new related contact with name, work and email different from the first contact under HouseHold Validation
    Select Tab                              Related
    Click Related List Button               Contacts                                New
    Populate Form
    ...                                     First Name=${first_name}
    ...                                     Last Name=${last_name}
    ...                                     Work Email=${EMAIL2}
    Save Form
    Go To Page                              Listing                                 Contact
    Click Link                              link= ${first_name} ${last_name}
    Current Page Should Be                  Details                                 Contact
    ${contact_id2} =                        Save Session Record For Deletion        Account
    &{contact2}=                            Verify Record Is Created In Database    Contact                                ${contact_id2}
    Header Field Value                      Account Name                            &{contact1}[LastName] and &{contact2}[LastName] Household
