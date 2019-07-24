*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library           DateTime
Suite Setup      Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Best Match Donation Matching Behaviour
    
    [tags]  stable
    Set Window Size    1024    768  
    Select App Launcher Tab   Batch Gift Entry
    # Click Link  &{batch}[Name]
    Click Link With Text    &{batch}[Name]
    Wait For Locator    bge.title    Batch Gift Entry
    Select Value From BGE DD    Donor Type    Account
    Populate Field By Placeholder    Search Accounts    &{account}[Name]
    Click Link    &{account}[Name]
    Click Link With Text    Review Donations
    Page Should Contain    &{opp_match}[Name]
    Page Should Contain    &{opp_dont_match}[Name]
    ${pay_no}    Get BGE Card Header    &{opp_match}[Name]
    Log To Console    ${pay_no}
    Click Button    title:Close this window
    Click Element With Locator    bge.field-input    Donation Amount
    Fill BGE Form
    ...                       Donation Amount=100
    Click Element With Locator    bge.field-input    Donation Date
    Click BGE Button    Today
    Click BGE Button       Save
    Verify Row Count    1
    Page Should Contain Link    ${pay_no}
    Scroll Page To Location    0    0
    Populate Field By Placeholder    Search Accounts    &{account}[Name]
    Click Element With Locator   bge.modal-link    &{account}[Name]
    Click Element With Locator    bge.field-input    Donation Amount
    Fill BGE Form
    ...                       Donation Amount=200
    Click Element With Locator    bge.field-input    Donation Date
    Click BGE Button    Today
    Click BGE Button       Save
    Sleep    2
    Verify Row Count    2
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Complete    data_imports.status    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    @{value}    Return List    bge.value    Donation
    #Click Link    ${value}
    Click Link With Text    @{value}[0]
    # Verify that a new payment and opportunity are created for the gift in closed won stage
    Select Window    @{value}[0] | Salesforce    7
    ${pay_id}    Get Current Record ID
    Store Session Record      npe01__OppPayment__c  ${pay_id}
    Verify Expected Values    nonns    npe01__OppPayment__c    ${pay_id}
    ...    npe01__Payment_Amount__c=200.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Paid__c=True
    ${opp_name}    Return Locator Value    check_field_spl    Opportunity
    Click Link    ${opp_name}
    ${opp_id} =           Get Current Record Id
    Store Session Record      Opportunity  ${opp_id}
    Confirm Value    Amount    $200.00    Y 
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Confirm Value    Close Date    ${opp_date}    Y 
    Confirm Value    Stage    Closed Won    Y
    # Verify that the gift matched to existing opportunity and updated it to closed won status and payment is paid
    Go To Record Home    &{opp_match}[Id]
    Confirm Value    Amount    $100.00    Y 
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Confirm Value    Close Date    ${opp_date}    Y 
    Confirm Value    Stage    Closed Won    Y 
    Select Tab    Related
    Load Related List    GAU Allocations
    Click Link    ${pay_no}
    ${pay}    Get Current Record ID
    Store Session Record      npe01__OppPayment__c  ${pay}
    Verify Expected Values    nonns    npe01__OppPayment__c    ${pay}
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Paid__c=True  
    # Verify that the opportunity that does not match is still in prospecting stage
    Go To Record Home    &{opp_dont_match}[Id]
    Confirm Value    Amount    $50.00    Y 
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Confirm Value    Close Date    ${opp_date}    Y 
    Confirm Value    Stage    Prospecting    Y  

***Keywords***
Setup Test Data
    ${ns} =  Get NPSP Namespace Prefix
    Set Suite Variable    ${ns}
    &{batch} =       API Create DataImportBatch    
    ...    ${ns}Batch_Process_Size__c=50    
    ...    ${ns}Batch_Description__c=Created via API    
    ...    ${ns}Donation_Matching_Behavior__c=Best Match or Create    
    ...    ${ns}Donation_Matching_Rule__c=${ns}donation_amount__c;${ns}donation_date__c    
    ...    ${ns}RequireTotalMatch__c=false    
    ...    ${ns}Run_Opportunity_Rollups_while_Processing__c=true   
    ...    ${ns}GiftBatch__c=true    
    ...    ${ns}Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}] 
    
    Set Suite Variable    &{batch}
    &{account} =     API Create Organization Account
    Set Suite Variable    &{account}
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    Set Suite Variable    ${date}
    &{opp_match} =     API Create Opportunity   &{account}[Id]    Donation  
    ...    StageName=Prospecting    
    ...    Amount=100    
    ...    CloseDate=${date}    
    ...    npe01__Do_Not_Automatically_Create_Payment__c=false    
    ...    Name=&{account}[Name] Test 100 Donation      
    Set Suite Variable    &{opp_match}
    &{opp_dont_match} =     API Create Opportunity   &{account}[Id]    Donation  
    ...    StageName=Prospecting    
    ...    Amount=50    
    ...    CloseDate=${date}    
    ...    npe01__Do_Not_Automatically_Create_Payment__c=false    
    ...    Name=&{account}[Name] Test 50 Donation      
    Set Suite Variable    &{opp_dont_match}