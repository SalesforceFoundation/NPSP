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
${EMAIL1}       user1@automation.com


*** Test Cases ***

Change Name Display Settings on Manage Household Page
    [Documentation]                      Create two contacts using the backend API
    ...                                  Using Manage Household, add the second contact part of the Contact#1's household
    ...                                  From the manage household page's name display settings, choose the options for both the contacts and save
    ...                                  Verify the selection made is retained and the right display is shown on the Details section
    [tags]                               feature:Manage Households  unstable   api

    Go To Page                              Details
    ...                                     Account
    ...                                     object_id=${contact1}[AccountId]
    Click Button                            Manage Household
    Go To Page                              Custom                                                              ManageHousehold
    Current Page Should Be                  Custom                                                              ManageHousehold
    Add contact                             Existing                                                            ${contact2}[FirstName] ${contact2}[LastName]
    Current Page Should Be                  Details                                                             Account
    Wait Until Loading Is Complete
    Click Button                            Manage Household
    Current Page Should Be                  Custom                                                              ManageHousehold

    # Choose the display option as Informal Greeting for contact#1

    Validate And Select Checkbox            ${contact1}[FirstName] ${contact1}[LastName]
    ...                                     Informal Greeting

    # Choose the display option as Formal Greeting for contact#2

    Validate And Select Checkbox            ${contact2}[FirstName] ${contact2}[LastName]
    ...                                     Formal Greeting

    Save Changes Made For Manage Household
    Current Page Should Be                  Details                                                             Account
    Wait Until Page Contains                Account Owner

    Go To Page                              Details
    ...                                     Account
    ...                                     object_id=${contact1}[AccountId]

    Select Tab                              Details
    Check Field Value                       Informal Greeting                                                   ${contact2}[FirstName]
    Check Field Value                       Formal Greeting                                                     ${contact1}[FirstName] ${contact1}[LastName]
