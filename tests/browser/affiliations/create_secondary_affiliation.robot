*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Secondary Affiliation for Contact
    # Create Organization Account
    ${account_id} =  Create Organization Foundation
    &{account} =  Salesforce Get  Account  ${account_id}
    
    # Create Contact
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}   
    Execute JavaScript    window.scrollTo(50,300)
    Click Related List Button   Organization Affiliations    New
    Populate Lookup Field    Organization    &{account}[Name]
    Click Modal Button    Save
    Page Should Contain    &{contact}[LastName]
    Page Should Contain    &{account}[Name]
    