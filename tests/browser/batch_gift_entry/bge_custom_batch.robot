*** Settings ***

Resource        tests/NPSP.robot
Library           DateTime
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

BGE Batch With Custom Values
    #Create a BGE batch with custom values (count/amount, new fields, new defaults, different settings)
    [tags]  unstable
    ${batch} =           Generate Random String
    ${ns} =  Get NPSP Namespace Prefix
    Select App Launcher Tab   Batch Gift Entry
    Click BGE Button       New Batch
    Fill BGE Form
    ...                       Name=${batch}
    ...                       Batch Description=This custom batch is created by Robot
    ...                       Expected Count of Gifts=2
    ...                       Expected Total Batch Amount=100
    Click BGE Button        Next
    Select Duellist Values    Opportunity    Available Fields    Donation Name
    Click Duellist Button    Opportunity    Move selection to Selected Fields
    ${xpath}    Get NPSP Locator    bge.duellist    Payment    Selected Fields    Check/Reference Number
    Execute JavaScript    window.document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.scrollIntoView(true)
    Select Duellist Values    Payment    Selected Fields    Check/Reference Number
    Click Duellist Button    Payment    Move selection to Available Fields
    Click BGE Button        Next
    Select BGE Date Picker    Donation Date: Default Value
    Change BGE month    Next Month
    Pick BGE Date    20
    Select Value From BGE DD    Method    Cash
    Fill BGE Form
    ...                       Donation Amount: Default Value=10
    Click BGE Button        Next
    Select Value From BGE DD    Donation Matching Behavior    Single Match - Only import a record if it matches a single existing record.
    Click BGE Button    Show Advanced Options
    Fill BGE Form
    ...                       Batch Process Size=100
    ...                       Number of Days from Donation Date=2   
    ${xpath}    Get NPSP Locator    detail_page.section_header    Donation Matching
    Execute JavaScript    window.document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.scrollIntoView(true)
    Select Duellist Values    Donation Matching Rule    Selected Fields    Donation Date
    Click Duellist Button    Donation Matching Rule    Move selection to Available Fields
    Click BGE Button        Save
    Wait For Locator    bge.title    Batch Gift Entry
    Verify Title    Batch Gift Entry    ${batch}
    ${field}    Get NPSP Locator    bge.field-input    Donation Name
    Page Should Contain Element    ${field}
    ${field}    Get NPSP Locator    bge.field-input    Payment Check/Reference Number
    Page Should Not Contain Element    ${field}
    ${batch_id}    Get Current Record Id
    Store Session Record      ${ns}DataImportBatch__c  ${batch_id}
    &{bge_batch} =     Salesforce Get  ${ns}DataImportBatch__c  ${batch_id}
    Should Be Equal As Strings    &{bge_batch}[${ns}Batch_Process_Size__c]    100.0
    Should Be Equal As Strings    &{bge_batch}[${ns}Donation_Date_Range__c]    2.0
    Should Be Equal As Strings    &{bge_batch}[${ns}Donation_Matching_Behavior__c]    Single Match
    Should Be Equal As Strings    &{bge_batch}[${ns}Donation_Matching_Implementing_Class__c]    None
    Should Be Equal As Strings    &{bge_batch}[${ns}Donation_Matching_Rule__c]    ${ns}donation_amount__c
    Should Be Equal As Strings    &{bge_batch}[${ns}Expected_Count_of_Gifts__c]    2.0
    Should Be Equal As Strings    &{bge_batch}[${ns}Expected_Total_Batch_Amount__c]    100.0
    Should Be Equal As Strings    &{bge_batch}[${ns}Post_Process_Implementing_Class__c]    None
    Should Be Equal As Strings    &{bge_batch}[${ns}RequireTotalMatch__c]    False
    Should Be Equal As Strings    &{bge_batch}[${ns}Run_Opportunity_Rollups_while_Processing__c]    True