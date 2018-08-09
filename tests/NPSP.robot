*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Library        tests/NPSP.py

*** Variables ***
${task1}  Send Email1
${sub_task}    Welcome Email1
${task2}     Make a Phone Call1


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
    
Create Opportunities
    [Arguments]    ${opp_name}    ${hh_name}  
    Select Window
    Sleep    2   
    Populate Form
    ...                       Opportunity Name= ${opp_name}
    ...                       Amount=100 
    Click Dropdown    Stage
    Click Link    link=Closed Won
    Populate Lookup Field    Account Name    ${hh_name}
    Click Dropdown    Close Date
    Pick Date    10
    Select Modal Checkbox    Do Not Automatically Create Payment
    Click Modal Button        Save

Create Engagement Plan
    ${plan_name} =     Generate Random String
    Go To Object Home         npsp__Engagement_Plan_Template__c
    Click Special Object Button       New
    Sleep    2
    Select Frame With Title    Manage Engagement Plan Template
    Enter Eng Plan Values
    ...             Engagement Plan Template Name=${plan_name}
    ...             Description=This plan is created via Automation  
    Click Task Button    Add Task
    Enter Task Id and Subject    5    ${task1}
    Click Task Button    Add Dependent Task
    Enter Task Id and Subject    32    ${sub_task}
    Click Task Button    Add Task
    Enter Task Id and Subject    59    ${task2}
    Scroll Page To Location    50    0
    Click Task Button    Save
    Sleep    2
    [Return]    ${plan_name}    ${task1}    ${sub_task}     ${task2}
     
Verify Engagement Plan
    [Arguments]       ${plan_name}     @{others}
    Go To Object Home         npsp__Engagement_Plan_Template__c
    Click Link    link=${plan_name}
    Check Field Value    Engagement Plan Template Name    ${plan_name}
    Select Tab    Related
    Check Related List Values    Engagement Plan Tasks      @{others}
       
    
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
    