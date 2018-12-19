*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

BGE Batch With Default Values
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
    Verify Title    Batch Gift Entry    ${batch}
    ${batch_id}    Get NPSP Record ID
    &{bge_batch} =     Salesforce Get  DataImportBatch__c  ${batch_id}
    Should Be Equal As Strings    &{bge_batch}[Batch_Process_Size__c]    50.0
    Should Be Equal As Strings    &{bge_batch}[Donation_Date_Range__c]    0.0
    Should Be Equal As Strings    &{bge_batch}[Donation_Matching_Behavior__c]    Single Match or Create
    Should Be Equal As Strings    &{bge_batch}[Donation_Matching_Implementing_Class__c]    None
    Should Be Equal As Strings    &{bge_batch}[Donation_Matching_Rule__c]    donation_amount__c;donation_date__c
    Should Be Equal As Strings    &{bge_batch}[Expected_Count_of_Gifts__c]    0.0
    Should Be Equal As Strings    &{bge_batch}[Expected_Total_Batch_Amount__c]    0.0
    Should Be Equal As Strings    &{bge_batch}[Post_Process_Implementing_Class__c]    None
    Should Be Equal As Strings    &{bge_batch}[Process_Using_Scheduled_Job__c]    False
    Should Be Equal As Strings    &{bge_batch}[RequireTotalMatch__c]    False
    Should Be Equal As Strings    &{bge_batch}[Run_Opportunity_Rollups_while_Processing__c]    False
