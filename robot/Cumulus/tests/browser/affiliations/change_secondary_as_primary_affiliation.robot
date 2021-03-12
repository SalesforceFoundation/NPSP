*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/AffiliationPageObject.py
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

Create Secondary Affiliation for Contact
    [Documentation]                   Creates a contact, organization account and secondary affiliation via API
    ...                               Open contact and open affiliation record. Edit affiliation record to select Primary checkbox and save.
    ...                               Verify that Affiliation now shows under Primary affiliation field.
    [tags]                            W-037651                     feature:Affiliations             unstable            notonfeaturebranch
    Go To Page                        Details                      Contact                 object_id=${contact}[Id]
    Select Tab                        Related
    Click Related Table Item Link     Organization Affiliations    ${account}[Name]
    Current Page Should be            Details                      npe5__Affiliation__c
    Edit Record Checkbox              Primary                      checked
    Save Affiliation Record
    Go To Page                        Details                      Contact                 object_id=${contact}[Id]
    Select Tab                        Details
    Navigate To And Validate Field Value                Primary Affiliation          contains                ${account}[Name]
