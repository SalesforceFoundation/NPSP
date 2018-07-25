*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Library        tests/NPSP.py


*** Keywords ***

API Create Contact
    ${first_name} =  Generate Random String
    ${last_name} =   Generate Random String
    ${contact_id} =  Salesforce Insert  Contact
    ...                  FirstName=${first_name}
    ...                  LastName=${last_name}
    &{contact} =     Salesforce Get  Contact  ${contact_id}
    [return]         &{contact}
  
Create Contact
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    Go To Object Home         Contact
    Click Object Button       New
    Populate Form
    ...                       First Name=${first_name}
    ...                       Last Name=${last_name}
    Click Modal Button        Save    
    Wait Until Modal Is Closed
    ${contact_id} =           Get Current Record Id
    Store Session Record      Contact  ${contact_id}
    [return]                  ${contact_id}
    
Create Contact with Email
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    Go To Object Home         Contact
    Click Object Button       New
    Populate Form
    ...                       First Name=${first_name}
    ...                       Last Name=${last_name}
    ...                       Work Email= skristem@salesforce.com
    Click Modal Button        Save    
    Wait Until Modal Is Closed
    ${contact_id} =           Get Current Record Id
    Store Session Record      Contact  ${contact_id}
    [return]                  ${contact_id}    
    
    
Create Contact with Address
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    Go To Object Home         Contact
    Click Object Button       New
    Populate Form
    ...                       First Name=${first_name}
    ...                       Last Name=${last_name}
    Click Dropdown            Primary Address Type
    Click Link                link=Work
    Populate Address          Mailing Street            50 Fremont Street  
    Populate Address          Mailing City              San Francisco
    Populate Address          Mailing Zip/Postal Code   95320
    Populate Address          Mailing State/Province    CA
    Populate Address          Mailing Country           USA  
    Click Modal Button        Save    
    Wait Until Modal Is Closed
    
    ${contact_id} =           Get Current Record Id
    Store Session Record      Contact  ${contact_id}
    [return]                  ${contact_id}     

New Contact for HouseHold
    Click Related List Button  Contacts    New 
    Wait Until Modal Is Open
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    Populate Form
    ...                       First Name=${first_name}
    ...                       Last Name=${last_name}
    Click Modal Button        Save    
    Wait Until Modal Is Closed
    Go To Object Home         Contact
    Click Link                link= ${first_name} ${last_name}
    ${contact_id} =           Get Current Record Id
    Store Session Record      Account  ${contact_id}
    [return]                  ${contact_id} 
        
Create Organization Foundation   
    ${account_name} =          Generate Random String
    Go To Object Home          Account
    Click Object Button        New
    Select Record Type         Organization
    Populate Form
    ...                        Account Name=${account_name}
    Click Modal Button         Save    
    Wait Until Modal Is Closed
    ${account_id} =            Get Current Record Id
    Store Session Record       Account  ${account_id}
    [return]                   ${account_id}
    
Create HouseHold    
    ${account_name} =         Generate Random String
    Go To Object Home         Account
    Click Object Button       New
    Select Record Type        Household Account
    Populate Form
    ...                       Account Name=${account_name}
    Click Modal Button        Save    
    Wait Until Modal Is Closed
    ${account_id} =           Get Current Record Id
    Store Session Record      Account  ${account_id}
    [return]                  ${account_id}

Create Primary Affiliation
    # Create Organization Account
    ${account_id} =  Create Organization Foundation
    &{account} =  Salesforce Get  Account  ${account_id}
    
    # Create Contact
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}   
    Select Tab    Details
    Scroll Page To Location    100    300
    Click Edit Button    Edit Primary Affiliation
    Populate Lookup Field    Primary Affiliation    &{account}[Name]
    Click Record Button    Save 
    [Return]         ${account_id}    ${contact_id}   

Create Secondary Affiliation
    # Create Organization Account
    ${account_id} =  Create Organization Foundation
    &{account} =  Salesforce Get  Account  ${account_id}
    
    # Create Contact
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}   
    Scroll Page To Location    50    400
    Click Related List Button   Organization Affiliations    New
    Populate Lookup Field    Organization    &{account}[Name]
    Click Modal Button    Save
    [Return]         ${account_id}    ${contact_id}
    
Choose Frame
    [Arguments]    ${frame}
    Select Frame    //iframe[contains(@title,'${frame}')]
    
Select Frame with ID
    [Arguments]    ${id}
    Select Frame    //iframe[contains(@id, '${id}')]    
    
Select Frame With Title
    [Arguments]    ${name}
    Select Frame    //iframe[@title= '${name}']    
    
Scroll Page To Location
    [Arguments]    ${x_location}    ${y_location}
    Execute JavaScript    window.scrollTo(${x_location},${y_location}) 
    