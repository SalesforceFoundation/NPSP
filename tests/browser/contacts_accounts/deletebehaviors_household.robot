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
    #Scroll Page To Location    0    500
    #Sleep    5
    Load Related List    Opportunities
    Click Special Related List Button   Opportunities    New Contact Donation
    Choose Frame    New Opportunity
    Click Element    p3
    Select Option    Donation  
    Click Button With Value    Continue  
    #Sleep    5  
    Select Window
    #Sleep    5   
    Populate Form
    ...                       Opportunity Name= Sravani $100 donation
    ...                       Amount=100 
    Click Dropdown    Stage
    Click Link    link=Closed Won
    Populate Lookup Field    Account Name    &{Contact}[LastName] Household
    Open Date Picker    Close Date
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
    