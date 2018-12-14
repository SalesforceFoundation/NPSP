*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Delete Contact with Closed Won Opportunity from Household
    #1 contact HouseHold Validation
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    # &{Contact} =  API Create Contact    Email=skristem@robot.com
    # Go To Record Home  &{Contact}[Id]
    Select Tab  Related
    Click Object Button  New Donation
    Populate Form
    ...                       Opportunity Name= Sravani $100 donation
    ...                       Amount=100 
    Click Dropdown    Stage
    Click Link    link=Closed Won
    Click Dropdown    Close Date
    Pick Date    10
    Click Modal Button        Save
    #Sleep    5
    Go To Object Home    Contact    
    Select Row    &{Contact}[FirstName] &{Contact}[LastName]
    Click Link    link=Delete
    #Sleep    5    
    Select Frame With ID    vfFrameId
    Click Button With Value    Delete Account
    #Sleep    5
    Page Should Contain    Error
