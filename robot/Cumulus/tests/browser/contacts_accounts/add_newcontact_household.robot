*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
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

Add New Contact to Household With Different LastName
    [Documentation]                       Create a contact using the backend API. Navigate to the Account details
    ...                                   create another Linked contact with different name,address and email.

    &{contact1} =  API Create Contact       Email=${EMAIL1}
    Go To Record Home                       &{contact1}[AccountId]
    ${contact_id1} =                        Save Session Record For Deletion   Account

    #Add a new related contact with name, work and email different from the first contact under HouseHold Validation

    Click Related List Button               Contacts    New
    Populate Form
    ...                                     First Name=${first_name}
    ...                                     Last Name=${last_name}
    ...                                     Work Email=${EMAIL2}
    Save Form
    Go To Page                              Listing     Contact
    Click Link                              link= ${first_name} ${last_name}
    Current Page Should Be                  Details        Contact
    ${contact_id2} =                        Save Session Record For Deletion   Account
    &{contact2} =                           Salesforce Get  Contact  ${contact_id2}
    Should Not Be Empty                     ${contact2}
    Header Field Value    Account Name      &{contact1}[LastName] and &{contact2}[LastName] Household
