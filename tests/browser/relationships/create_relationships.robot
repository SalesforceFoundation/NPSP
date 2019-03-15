*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Relationships for contacts
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact1}[AccountId]
    Go To Record Home  &{contact1}[AccountId]
    
    #2 Create a new contact under HouseHold Validation
    ${contact_id2} =  New Contact for HouseHold
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Store Session Record    Account    &{contact2}[AccountId]
    Page Should Contain  &{contact1}[LastName] and &{contact2}[LastName] Household
    Select Tab  Related
    Click Related List Button  Relationships    New
    Populate Lookup Field    Related Contact    &{contact1}[FirstName] &{contact1}[LastName]
    Click Dropdown            Type
    Click link    link=Parent
    Click Modal Button        Save
    ${expected result1}        Catenate    &{contact1}[FirstName] &{contact1}[LastName]    is    &{contact2}[FirstName] &{contact2}[LastName]'s    Parent
    Log to Console    ${expected result1}
    ${id}    ${status1}    Check Status    &{contact1}[FirstName] &{contact1}[LastName]
    Should Be Equal As Strings    ${status1}    ${expected result1}
    Click Link    link=Show more actions
    Click Link    link=Relationships Viewer
    Sleep    5 
    Capture Page Screenshot
    Go To Record Home    &{contact1}[Id]
    Select Tab  Related
    Load Related List    Relationships
    ${expected result2}        Catenate    &{contact2}[FirstName] &{contact2}[LastName]    is    &{contact1}[FirstName] &{contact1}[LastName]'s    Child
    Log to Console    ${expected result2}
    ${id}    ${status2}    Check Status    &{contact2}[FirstName] &{contact2}[LastName]
    Should Be Equal As Strings    ${status2}    ${expected result2}
    Click Related Item Link      Relationships    &{contact2}[FirstName] &{contact2}[LastName]
    ${id}    Get Current Record Id
    Store Session Record    npe4__Relationship__c    ${id}
