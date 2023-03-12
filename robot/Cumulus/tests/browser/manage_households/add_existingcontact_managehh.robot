*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/ManageHouseHoldPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***

Setup Test Data
    &{contact1} =         API Create Contact                    Email=${EMAIL1}
    Store Session Record  Account                               ${contact1}[AccountId]
    Set suite variable    &{contact1}
    &{contact2} =         API Create Contact
    Store Session Record  Account                               ${contact2}[AccountId]
    Set suite variable    &{contact2}

*** Variables ***
${EMAIL1}  user1@automation.com

*** Test Cases ***

Add Existing Contact to Existing Household through Manage Household Page

    [Documentation]                      Create two contacts using the backend API
    ...                                  Navigate to the First contact's account details page
    ...                                  From the manage household page's lookup field, try to find and add exisitng contact, contact#2
    ...                                  Verify the new address persists under both Mailing and Billing address details.

    [tags]                               feature:Manage Households  unstable   api


    Go To Page                           Details
    ...                                  Account
    ...                                  object_id=${contact2}[AccountId]

    Click Button                         Manage Household
    Go To Page                           Custom                             ManageHousehold
    Current Page Should Be               Custom                             ManageHousehold
    Add contact                          Existing                           ${contact1}[FirstName] ${contact1}[LastName]
    Current Page Should Be               Details                            Account

    Wait Until Page Contains             Account Owner
    Wait For Record To Update            ${contact2}[AccountId]             ${contact2}[LastName] and ${contact1}[LastName] Household
    Select Tab                           Related
    Load Related List                    Contacts
    Verify Related List Items            Contacts                           ${contact1}[FirstName] ${contact1}[LastName]
