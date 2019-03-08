*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Delete Contact from Household
    [tags]  unstable
    &{contact1} =  API Create Contact    Email=skristem@robot.com
    Go To Record Home  &{contact1}[AccountId]
    ${contact_id2} =  New Contact for HouseHold
    Store Session Record    Contact    ${contact_id2}
    Store Session Record    Account    &{contact1}[AccountId]
    &{contact2} =  Salesforce Get  Contact  ${contact_id2}
    Header Field Value    Account Name    &{contact1}[LastName] and &{contact2}[LastName] Household
    Go To Object Home    Contact
    Select Row    &{Contact2}[FirstName] &{Contact2}[LastName]
    Click Link    title=Delete
    Sleep    2
    Go To Object Home    Account
    Page Should Contain Link   link=&{contact1}[LastName] Household
    Go To Object Home    Contact
    Select Row    &{Contact1}[FirstName] &{Contact1}[LastName]
    Click Link    title=Delete
    Page Should Contain    Warning
