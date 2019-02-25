*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

BGE Batch With Default Values
    #Create a BGE batch with default values
    [tags]  unstable
    ${batch} =           Generate Random String
    Select App Launcher Tab   Batch Gift Entry
    Click BGE Button       New Batch
    Fill BGE Form
    ...                       Name=${batch}
    ...                       Batch Description=This batch is created by Robot
    Click BGE Button        Next
    Click BGE Button        Next
    Click BGE Button        Next
    Click BGE Button        Save
    Wait For Locator    bge.title    Batch Gift Entry
    Verify Title    Batch Gift Entry    ${batch}
    ${batch_id}    Get NPSP Record ID
    ${ns} =  Get NPSP Namespace Prefix
    Store Session Record      ${ns}DataImportBatch__c  ${batch_id}
    &{bge_batch} =     Salesforce Get  ${ns}DataImportBatch__c  ${batch_id}
    Log Many   &{bge_batch}
    Should Be Equal As Strings    &{bge_batch}[${ns}Batch_Process_Size__c]    50.0
    Should Be Equal As Strings    &{bge_batch}[${ns}Donation_Date_Range__c]    0.0
    Should Be Equal As Strings    &{bge_batch}[${ns}Donation_Matching_Behavior__c]    Single Match or Create
    Should Be Equal As Strings    &{bge_batch}[${ns}Donation_Matching_Implementing_Class__c]    None
    Should Be Equal As Strings    &{bge_batch}[${ns}Donation_Matching_Rule__c]    ${ns}donation_amount__c;${ns}donation_date__c
    Should Be Equal As Strings    &{bge_batch}[${ns}Expected_Count_of_Gifts__c]    0.0
    Should Be Equal As Strings    &{bge_batch}[${ns}Expected_Total_Batch_Amount__c]    0.0
    Should Be Equal As Strings    &{bge_batch}[${ns}Post_Process_Implementing_Class__c]    None
    Should Be Equal As Strings    &{bge_batch}[${ns}RequireTotalMatch__c]    False
    Should Be Equal As Strings    &{bge_batch}[${ns}Run_Opportunity_Rollups_while_Processing__c]    True
