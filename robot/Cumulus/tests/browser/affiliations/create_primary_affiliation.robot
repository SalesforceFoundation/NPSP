*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AffiliationPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    &{account} =          API Create Organization Account
    Set suite variable    &{account}
    &{contact} =          API Create Contact                 Email=automation@example.com
    Set suite variable    &{contact}
    Store Session Record  Account                            ${contact}[AccountId]

*** Test Cases ***
Create Primary Affiliation for Contact
    [Documentation]                      Creates a contact and organization account via API and open contact
    ...                                  Edit Primary Affiliation field and add affiliation to organization account.
    ...                                  Verifies that affiliation to account shows under organization affiliation related list as current
    [tags]                               feature:Affiliations   unstable    unit       quadrant:q3
    Go To Page                           Details                      Contact                     object_id=${contact}[Id]
    Current Page Should Be               Details                      Contact
    Select Tab                           Details
    Edit Record Field Value              Primary Affiliation          ${account}[Name]
    Save Record
    Validate Related Record Count        Organization Affiliations                        1
    Verify Allocations                   Organization Affiliations    ${account}[Name]=Current
    Click Related Table Item Link        Organization Affiliations    ${account}[Name]
    Current Page Should Be               Details                      npe5__Affiliation__c
    Save Current Record ID For Deletion  npe5__Affiliation__c