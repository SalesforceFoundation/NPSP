*** Settings ***

Resource        tests/NPSP.robot
Library           DateTime
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

BGE Batch With Custom Values
    #Create a BGE batch with custom values (count/amount, new fields, new defaults, different settings)
    [tags]  unstable
    Set Window Size    1024    768
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
    Click Element With Locator    bge.duellist    Opportunity    Available Fields    Donation Name
    Click Element With Locator    bge.select-button    Opportunity    Move selection to Selected Fields
    Execute JavaScript    document.getElementsByClassName('wideListbox slds-form-element')[1].scrollIntoView()
    Click Element With Locator    bge.duellist    Payment    Selected Fields    Payment Check/Reference Number
    Click Element With Locator    bge.select-button    Payment    Move selection to Available Fields
    Click BGE Button        Next
    Click Element With Locator    bge.field-input    Donation Date
    Click Element With Locator    bge.month    Next Month
    Click Element With Locator    bge.date    20
    Select Value From BGE DD    Payment Method    Cash
    Fill BGE Form
    ...                       Donation Amount=10
    Click BGE Button        Next
    Select Value From BGE DD    Donation Matching Behavior    Single Match - Only import a record if it matches a single existing record.
    Click BGE Button    Show Advanced Options
    Fill BGE Form
    ...                       Batch Process Size=100
    ...                       Number of Days from Donation Date=2   
    ${xpath}    Get NPSP Locator    detail_page.section_header    Donation Matching
    Execute JavaScript    window.document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.scrollIntoView(true)
    Click Element With Locator    bge.field-duellist    Donation Matching Rule    Selected Fields    Donation Date
    Click Element With Locator    bge.field-select-button    Donation Matching Rule    Move selection to Available Fields
    Click BGE Button        Save
    Wait For Locator    bge.title    Batch Gift Entry
    ${batch_id}    Get Current Record Id
    Verify Title    Batch Gift Entry    ${batch}
    ${field}    Get NPSP Locator    bge.field-input    Donation Name
    Page Should Contain Element    ${field}
    ${field}    Get NPSP Locator    bge.field-input    Payment Check/Reference Number
    Page Should Not Contain Element    ${field}
    Store Session Record      ${ns}DataImportBatch__c  ${batch_id}
    Verify Expected Batch Values    ${batch_id}
    ...    Batch_Process_Size__c=100.0
    ...    Donation_Date_Range__c=2.0
    ...    Donation_Matching_Behavior__c=Single Match
    ...    Donation_Matching_Implementing_Class__c=None
    ...    Donation_Matching_Rule__c=${ns}donation_amount__c
    ...    Expected_Count_of_Gifts__c=2.0
    ...    Expected_Total_Batch_Amount__c=100.0
    ...    Post_Process_Implementing_Class__c=None
    ...    RequireTotalMatch__c=False
    ...    Run_Opportunity_Rollups_while_Processing__c=True