*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/RelationshipPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***

Capture Screenshot on Failure
    Run Keyword If Test Failed  Capture Page Screenshot

Setup Test Data
    &{contact1} =                        API Create Contact    Email=automation@example.com
    Store Session Record                 Account               ${contact1}[AccountId]
    Set suite variable                   &{contact1}
    &{contact2} =                        API Create Contact
    Store Session Record                 Account               ${contact2}[AccountId]
    Set suite variable                   &{contact2}

*** Test Cases ***

Create Relationships for contacts
    [Documentation]                      Create 2 contacts with API which inturn creates 2 household accounts.
    ...                                  Open contact2 record and create a new relationship with contact 1.
    ...                                  Verify the parent-child relationship is correctly established.

    [tags]                              feature:Relationships   unstable    unit

    Go To Page                          Details                                                     Contact                                     object_id=${contact2}[Id]
    Select Tab                          Related
    Wait Until Loading Is Complete
    Click Related List Button           Relationships                                               New
    Wait For Modal                      New                                                         Relationship

    Populate Lookup Field               Related Contact         ${contact1}[FirstName] ${contact1}[LastName]
    Click Flexipage Dropdown            Type                    Parent
    Click Button                        Save
    Current Page Should Be              Details                                                     Contact
    Validate Relation Status Message    ${contact1}[FirstName] ${contact1}[LastName]
    ...                                 ${contact2}[FirstName] ${contact2}[LastName]
    ...                                 Parent

    Open Relationships Viewer
    Wait Until Loading Is Complete
    #sleep for 5 seconds to allow image to load before trying to capture screenshot
    Sleep                               5
    Capture Page Screenshot
    Go To Page                          Details                                                     Contact                                     object_id=${contact1}[Id]
    Current Page Should Be              Details                                                     Contact

    Select Tab                          Related
    Validate Relation Status Message    ${contact2}[FirstName] ${contact2}[LastName]
    ...                                 ${contact1}[FirstName] ${contact1}[LastName]
    ...                                 Child

    Click Related Table Item Link       Relationships                                               ${contact2}[FirstName] ${contact2}[LastName]

    Current Page Should Be              Details                                                     npe4__Relationship__c
    Save Current Record ID For Deletion  npe4__Relationship__c

