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
    &{account1} =                     API Create Organization Account
    Set suite variable                &{account1}
    &{contact1} =                     API Create Contact                 Email=automation@example.com
    Set suite variable                &{contact1}
    Store Session Record              Account                            ${contact1}[AccountId]
    API Create Primary Affiliation    ${account1}[Id]                    ${contact1}[Id]

    #Test data for second test case
    &{account2} =                     API Create Organization Account
    Set suite variable                &{account2}
    &{contact2} =                     API Create Contact                 Email=automation@example.com
    Set suite variable                &{contact2}
    Store Session Record              Account                            ${contact2}[AccountId]
    API Create Primary Affiliation    ${account2}[Id]                    ${contact2}[Id]

*** Test Cases ***
Remove Primary Affiliation for Contact
    [Documentation]                   Creates a contact, organization account and primary affiliation via API
    ...                               Open contact and delete affiliation from organization affiliation related list
    ...                               Verifies that contact does not show under affiliated contacts in the account page
    [tags]                            W-037651                     feature:Affiliations     unstable             notonfeaturebranch
    Go To Page                        Details                      Contact                 object_id=${contact1}[Id]
    Select Tab                        Related
    Click Related Item Popup Link     Organization Affiliations    ${account1}[Name]       Delete
    Wait For Modal                    New                          Affiliation             expected_heading=Delete Affiliation
    Click Modal Button                Delete
    Wait Until Modal Is Closed
    Go To Page                        Details                      Account                 object_id=${account1}[Id]
    Select Tab                        Related
    Verify Related List               Affiliated Contacts          does not contain        ${contact1}[FirstName] ${contact1}[LastName]

Remove Primary Affiliation for Contact2
    [Documentation]                   Creates a contact, organization account and primary affiliation via API. Open Contact
    ...                               Edit Primary Affiliation field and delete affiliation to organization account.
    ...                               Verifies that affiliation to account shows under organization affiliation as former
    ...                               Verifies that on account page contact shows under affiliated contacts as former
    [tags]                            W-037651                     feature:Affiliations         unstable           notonfeaturebranch
    Go To Page                        Details                      Contact                 object_id=${contact2}[Id]
    Select Tab                        Details
    Delete Record Field Value         Primary Affiliation          ${account2}[Name]
    Save Record
    Select Tab                        Related
    Verify Allocations                Organization Affiliations    ${account2}[Name]=Former
    Go To Page                        Details                      Account                 object_id=${account2}[Id]
    Select Tab                        Related
    Load Related List                 Affiliated Contacts
    Verify Allocations                Affiliated Contacts
    ...                               ${contact2}[FirstName] ${contact2}[LastName]=Former

