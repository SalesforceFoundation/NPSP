*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Enable Payment Allocations
...             Setup Test Data
Suite Teardown  Run keywords
...             Disable Payment Allocations
...             Delete Records and Close Browser

*** Test Cases ***

Create Payment Allocations and Verify Opportunity Allocations Sync
    [tags]    unstable
    Go To Record Home  &{opportunity}[Id]
    Select Tab    Related
    Load Related List    GAU Allocations
    Click Link With Text    &{payment}[Name]    
    Select Window
    Select Tab    Related
    Load Page Object        Details    npe01__OppPayment__c
    Verify Payment Allocations    
    ...    &{def_gau}[Name]=$100.00
    Click Wrapper Related List Button    Payment Allocations    New
    Populate Lookup Field    General Accounting Unit    &{gau}[Name]
    Populate Field    Amount    40
    Click Modal Button    Save
    Wait Until Modal Is Closed
    Verify Payment Allocations    
    ...    &{def_gau}[Name]=$60.00
    ...    &{gau}[Name]=$40.00     
    Select Tab    Details
    Click Link    &{opportunity}[Name]
    Select Tab    Related
    Verify Allocations    GAU Allocations
    ...    &{def_gau}[Name]=$60.00
    ...    &{gau}[Name]=$40.00

Update GAU Allocations and Verify Payment Allocations Sync
    [tags]    unstable
    Go To Page    Details    Opportunity    object_id=&{opportunity}[Id]
    Select Tab    Related
    Click Special Related List Button  GAU Allocations    Manage Allocations
    Choose Frame    Manage Allocations
    Add GAU Allocation    Percent 0    60
    Click Button    Save
    Unselect Frame
    Verify Allocations    GAU Allocations
    ...    &{def_gau}[Name]=$40.00
    ...    &{gau}[Name]=$60.00
    # As a workaround for lightning cache issue, going to the payment record directly as it would reload the record
    Go To Page    Details    npe01__OppPayment__c    object_id=&{payment}[Id]
    Select Tab    Related
    Verify Payment Allocations    
    ...    &{def_gau}[Name]=$40.00
    ...    &{gau}[Name]=$60.00
    
***Keywords***

Enable Payment Allocations
    &{def_gau} =  API Create GAU    Name=default gau
    Set Global Variable     &{def_gau}    &{def_gau}
    Go To Setup Page    CustomSettings
    Select Frame And Click Element    Custom Settings    custom_settings.link    Allocations Settings    Manage
    Unselect Frame
    Wait Until Loading Is Complete
    Choose Frame    Custom Setting Allocations Settings
    Wait Until Element Is Visible  text:Default Organization Level Value
    Checkbox Status    Payment Allocations Enabled    Not Checked
    Checkbox Status    Default Allocations Enabled    Not Checked
    Click Button    Edit
    Choose Frame    Allocations Settings
    Set Checkbutton To    Default_Allocations_Enabled    checked
    Set Checkbutton To    Payment_Allocations_Enabled    checked
    Populate Field With Id    Default__c    &{def_gau}[Id]
    Click Button    Save    
    
Disable Payment Allocations
    Go To Setup Page    CustomSettings
    Select Frame And Click Element    Custom Settings    custom_settings.link    Allocations Settings    Manage
    Unselect Frame
    Wait Until Loading Is Complete
    Choose Frame    Custom Setting Allocations Settings
    Wait Until Element Is Visible  text:Default Organization Level Value
    Checkbox Status    Payment Allocations Enabled    Checked
    Checkbox Status    Default Allocations Enabled    Checked
    Click Button    Edit
    Choose Frame    Allocations Settings
    Set Checkbutton To    Default_Allocations_Enabled    unchecked
    Set Checkbutton To    Payment_Allocations_Enabled    unchecked
    Populate Field With Id    Default__c    null
    Click Button    Save      
    
Setup Test Data
    &{gau} =          API Create GAU  
    Set suite variable    &{gau}  
    ${date} =         Get Current Date    result_format=%Y-%m-%d
    Set suite variable    ${date}
    &{contact} =      API Create Contact
    Set suite variable    &{contact}
    Store Session Record    Account    &{contact}[AccountId]
    &{opportunity} =  API Create Opportunity   &{contact}[AccountId]    Donation  
    ...    StageName=Prospecting    
    ...    Amount=100    
    ...    CloseDate=${date}    
    ...    npe01__Do_Not_Automatically_Create_Payment__c=false    
    ...    Name=&{contact}[LastName] Test Donation
    @{records} =     Salesforce Query    npe01__OppPayment__c    
    ...    select=Id
    ...    npe01__Opportunity__c=&{opportunity}[Id]
    &{id} =     Get From List  ${records}  0
    &{payment} =     Salesforce Get  npe01__OppPayment__c  &{id}[Id]  
    Set suite variable    &{opportunity}
    Set suite variable    &{payment} 