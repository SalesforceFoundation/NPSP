*** Settings ***

Resource  cumulusci/robotframework/Salesforce.robot

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
    Go To Setup Home
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
    
Create Organization Foundation   
    ${account_name} =          Generate Random String
    Go To Setup Home
    Go To Object Home          Account
    Click Object Button        New
    Select Record Type         Organization
    Populate Form
    ...                        Account Name=${account_name}
    Click Link                 link=--None--
    Click Link                 link=Foundation
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