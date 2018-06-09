*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Primary Affiliation for Contact
    # Create Organization Account
    ${account_id} =  Create Organization Foundation
    &{account} =  Salesforce Get  Account  ${account_id}
    
    # Create Contact
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}   
    Select Tab    Details
    Execute JavaScript    window.scrollTo(100,300)
    Click Element    //*[@title='Edit Primary Affiliation']
    Populate Lookup Field    Primary Affiliation    &{account}[Name]
    Click Record Button    Save
    Go To Object Home          Account
    Click Link    link=&{account}[Name]
    Page Should Contain    &{contact}[LastName]
    