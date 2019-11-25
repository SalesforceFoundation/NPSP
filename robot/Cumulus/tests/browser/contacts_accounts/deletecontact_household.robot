*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${EMAIL} =       skristem@robot.com

*** Test Cases ***

Delete Contact from Household
    [Documentation]                    This test creates and Organization account and verifies that the account shows under
    ...                                Recently Viewed, Organization Accounts, My Accounts and does not show under Household Accounts

    [tags]  unstable
    &{contact1} =  API Create Contact       Email=${EMAIL}
    Go To Record Home                       &{contact1}[AccountId]
    ${contact_id2} =                        New Contact for HouseHold
    Store Session Record    Contact         ${contact_id2}
    Store Session Record    Account         &{contact1}[AccountId]
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Header Field Value    Account Name      &{contact1}[LastName] and &{contact2}[LastName] Household
    Go To Page                              Listing     Contact
    Select Row                              &{Contact2}[FirstName] &{Contact2}[LastName]
    Click Link                              title=Delete
    Sleep    3
    #Go To Page                             Listing     Account
    Page Should Contain Link                link=&{contact1}[LastName] Household
    Go To Page                              Listing     Contact
    Select Row                              &{Contact1}[FirstName] &{Contact1}[LastName]
    Click Link                              title=Delete
    Page Should Contain                     Warning
