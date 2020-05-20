*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
Library         DateTime
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

BGE Batch With Custom Values
    #Create a BGE batch with custom values (count/amount, new fields, new defaults, different settings)
    [tags]  stable
    # --------------------------------
    # Create Custom Batch 
    # --------------------------------
    ${batch} =           Generate Random String
    ${ns} =  Get NPSP Namespace Prefix
    Go To Page                        Listing                      Batch_Gift_Entry
    Click BGE Button       New Batch
    Fill BGE Form
    ...                       Name=${batch}
    ...                       Batch Description=This custom batch is created by Robot
    ...                       Expected Count of Gifts=2
    ...                       Expected Total Batch Amount=100
    Click BGE Button        Next
    Select Multiple Values From Duellist    bge.duellist    Opportunity    Available Fields    Donation Name
    Click Duellist Button    Opportunity    Move selection to Selected Fields
    Execute JavaScript    document.getElementsByClassName('wideListbox slds-form-element')[1].scrollIntoView()
    Select Multiple Values From Duellist    bge.duellist    Payment    Selected Fields    Payment Check/Reference Number
    Click Duellist Button    Payment    Move selection to Available Fields
    Click BGE Button        Next
    Click Field And Select Date    Donation Date    Next Month    20
    Select Value From BGE DD    Payment Method    Cash
    Fill BGE Form
    ...                       Donation Amount=10
    Click BGE Button        Next
    Select Value From BGE DD    Donation Matching Behavior    Single Match - Only import a record if it matches a single existing record.
    Click BGE Button    Show Advanced Options
    ${xpath}    Get NPSP Locator    bge.field-input    Batch Process Size
    Execute JavaScript    window.document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.scrollIntoView(true)
    Fill BGE Form
    ...                       Batch Process Size=100 
    ...                       Number of Days from Donation Date=2 
    ${xpath}    Get NPSP Locator    detail_page.section_header    Donation Matching
    Execute JavaScript    window.document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.scrollIntoView(true)
    Select Multiple Values From Duellist    bge.field-duellist    Donation Matching Rule    Selected Fields    Donation Date
    Click Duellist Button   Donation Matching Rule    Move selection to Available Fields
    Click BGE Button        Save
    Wait For Locator    bge.title    Batch Gift Entry
    ${batch_id}    Get Current Record Id
    # --------------------------------
    # Verify Batch Values
    # --------------------------------
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

***Keywords***
Click Field And Select Date
    [Arguments]    ${field}    ${month}    ${date}
    Click Element With Locator    bge.field-input    ${field}
    Click Element With Locator    bge.month    ${month}
    Click Element With Locator    bge.date    ${date}

