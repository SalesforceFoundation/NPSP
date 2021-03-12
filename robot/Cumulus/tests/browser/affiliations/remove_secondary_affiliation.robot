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
    &{account} =                      API Create Organization Account
    Set suite variable                &{account}
    &{contact} =                      API Create Contact                 Email=automation@example.com
    Set suite variable                &{contact}
    Store Session Record              Account                            ${contact}[AccountId]
    API Create Secondary Affiliation  ${account}[Id]                     ${contact}[Id]

*** Test Cases ***
Remove Secondary Affiliation for Contact
    [Documentation]                   Creates a contact, organization account and secondary affiliation via API
    ...                               Open contact and delete affiliation from organization affiliation related list
    ...                               Verifies that contact does not show under affiliated contacts in the account page
    [tags]                            W-037651                feature:Affiliations          unstable             notonfeaturebranch
    Go To Page                        Details                      Contact                 object_id=${contact}[Id]
    Current Page Should Be            Details                      Contact
    Select Tab                        Related
    Click Related Item Popup Link     Organization Affiliations    ${account}[Name]        Delete
    Wait For Modal                    New                          Affiliation             expected_heading=Delete Affiliation
    Click Modal Button                Delete
    Wait Until Modal Is Closed
    Go To Page                        Details                      Account                 object_id=${account}[Id]
    Select Tab                        Related
    Verify Related List               Affiliated Contacts          does not contain        ${contact}[FirstName] ${contact}[LastName]
