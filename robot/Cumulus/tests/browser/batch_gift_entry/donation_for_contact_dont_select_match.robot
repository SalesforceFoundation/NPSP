*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library           DateTime
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Dont select match for contact new donation with grid changes
    #Enter a donation for a contact that has an exact opp match, don't select the match, make grid changes, and process batch
    [tags]  stable
    Set Window Size    1024    768
    ${ns} =  Get NPSP Namespace Prefix
    &{batch} =       API Create DataImportBatch    
    ...    ${ns}Batch_Process_Size__c=50    
    ...    ${ns}Batch_Description__c=Created via API    
    ...    ${ns}Donation_Matching_Behavior__c=Single Match or Create    
    ...    ${ns}Donation_Matching_Rule__c=${ns}donation_amount__c;${ns}donation_date__c    
    ...    ${ns}RequireTotalMatch__c=false    
    ...    ${ns}Run_Opportunity_Rollups_while_Processing__c=true   
    ...    ${ns}GiftBatch__c=true    
    ...    ${ns}Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}] 
    &{contact} =     API Create Contact
    Store Session Record      Account    &{contact}[AccountId]
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    &{opportunity} =     API Create Opportunity   &{contact}[AccountId]    Donation  StageName=Prospecting    Amount=100    CloseDate=${date}      
    Select App Launcher Tab   Batch Gift Entry
    # Click Link  &{batch}[Name]
    Click Link With Text    &{batch}[Name]
    Wait For Locator    bge.title    Batch Gift Entry
    Select Value From BGE DD    Donor Type    Contact
    Populate Field By Placeholder    Search Contacts    &{contact}[FirstName] &{contact}[LastName]
    Click Link    &{contact}[FirstName] &{contact}[LastName]
    Page Should Contain Link    Review Donations
    Click Element With Locator    bge.field-input    Donation Amount
    Fill BGE Form
    ...                       Donation Amount=100
    Click Field And Select Date    Donation Date    Today
    Click BGE Button       Save
    Sleep    2
    Verify Row Count    1
    Page Should Contain Link    &{opportunity}[Name]
    Wait For Locator    bge.edit_button    Donation Amount
    Click BGE Edit Button    Donation Amount 
    Wait For Locator    bge.edit_field  
    Populate BGE Edit Field    Donation Amount    20
    Click Element With Locator    span    Donation Date
    Wait Until Element Is Not Visible    //span[contains(@class,'toastMessage')]
    Page Should Not Contain Link    &{opportunity}[Name]
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Complete    data_imports.status    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    Verify Expected Values    nonns    Opportunity    &{opportunity}[Id]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Prospecting
    ${value}    Return Locator Value    bge.value    Donation
    # Click Link    ${value}
    Click Link With Text    ${value}
    Select Window    ${value} | Salesforce    7
    ${opp_name}    Return Locator Value    check_field_spl    Opportunity
    Click Link    ${opp_name}
    ${newopp_id}    Get Current Record ID
    Store Session Record      Opportunity    ${newopp_id}
    Verify Expected Values    nonns    Opportunity    ${newopp_id}
    ...    Amount=20.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    Go To Record Home    &{contact}[Id]
    Select Tab    Related
    Load Related List    Opportunities
    Verify Occurrence    Opportunities    2
    
   
