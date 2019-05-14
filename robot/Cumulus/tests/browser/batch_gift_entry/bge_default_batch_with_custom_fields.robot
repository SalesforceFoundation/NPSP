*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${ns}
${camp_id}

*** Test Cases ***

Create BGE Batch With Custom Fields
    #Create a BGE batch with default values and selecting different types of custom fields for Donation and Payment
    [tags]  unstable
    Set Window Size    1024    768
    # --------------------------------
    # Create Batch With Custom Fields
    # --------------------------------
    ${batch} =           Generate Random String
    Select App Launcher Tab   Batch Gift Entry
    Click BGE Button       New Batch
    Fill BGE Form
    ...                       Name=${batch}
    ...                       Batch Description=This batch is created by Robot.
    Click BGE Button        Next
    Select Multiple Values From Duellist    bge.duellist    Opportunity    Available Fields    custom_campaign    custom_currency    custom_date    custom_number    custom_picklist    custom_text    custom_textarea    
    Click Duellist Button    Opportunity    Move selection to Selected Fields
    Execute JavaScript    document.getElementsByClassName('wideListbox slds-form-element')[1].scrollIntoView()
    Select Multiple Values From Duellist    bge.duellist    Payment    Available Fields    custom_email    custom_multipick    custom_phone    custom_url
    Click Duellist Button    Payment    Move selection to Selected Fields
    Click BGE Button        Next
    Click BGE Button        Next
    Click BGE Button        Save
    Wait For Locator    bge.title    Batch Gift Entry
    Verify Title    Batch Gift Entry    ${batch}
    ${batch_id}    Get Current Record Id
    ${ns} =  Get NPSP Namespace Prefix
    Set Global Variable     ${ns}       ${ns}
    Store Session Record      ${ns}DataImportBatch__c  ${batch_id}
    Verify Expected Batch Values    ${batch_id}
    ...    Batch_Process_Size__c=50.0
    ...    Donation_Date_Range__c=0.0
    ...    Donation_Matching_Behavior__c=Single Match or Create
    ...    Donation_Matching_Implementing_Class__c=None
    ...    Donation_Matching_Rule__c=${ns}donation_amount__c;${ns}donation_date__c
    ...    Expected_Count_of_Gifts__c=0.0
    ...    Expected_Total_Batch_Amount__c=0.0
    ...    Post_Process_Implementing_Class__c=None
    ...    RequireTotalMatch__c=False
    ...    Run_Opportunity_Rollups_while_Processing__c=True

Create New gift and process batch and validate
    [tags]  unstable
    &{contact} =     API Create Contact
    &{campaign} =    API Create Campaign
    Set Global Variable     ${camp_id}       &{campaign}[Id]
    Select Value From BGE DD    Donor Type    Contact
    Populate Field By Placeholder    Search Contacts    &{contact}[FirstName] &{contact}[LastName]
    Click Link    &{contact}[FirstName] &{contact}[LastName]
    Fill BGE Form
    ...    Donation Amount=100
    ...    custom_currency=20
    ...    custom_number=123
    ...    custom_text=Robot
    ...    custom_email=automation@robot.com
    ...    custom_phone=1234567890
    ...    custom_url=automation.com
    ...    custom_textarea=this is custom batch
    Populate Field By Placeholder    Search Campaigns    ${campaign}[Name]
    Click Field And Select Date    Donation Date    Today
    Click Field And Select Date    custom_date    Today
    Select Value From BGE DD    custom_picklist    2
    Select Multiple Values From Duellist    bge.duellist2    custom_multipick    Available    1    2    3
    Click Duellist Button    custom_multipick    Move selection to Chosen
    Click BGE Button       Save
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Locator    data_imports.status    Completed
    Click Button With Value   Close
    Verify Row Count    1
    
    
Verify Custom Fields on Payment and Donation
    [tags]  unstable 
    ${date} =     Get Current Date    result_format=%Y-%m-%d       
    ${value}    Return Locator Value    bge.value    Donation
    Click Link With Text    ${value}
    ${pay_id}    Get Current Record ID
    Store Session Record      npe01__OppPayment__c  ${pay_id}
    &{payment} =     Salesforce Get  npe01__OppPayment__c  ${pay_id}
    Verify Expected Values    nonns    npe01__OppPayment__c    ${pay_id}
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Paid__c=True
    ...    ${ns}custom_email__c=automation@robot.com
    ...    ${ns}custom_multipick__c=1;2;3
    ...    ${ns}custom_phone__c=1234567890
    ...    ${ns}custom_url__c=automation.com
    Verify Expected Values    nonns    Opportunity    &{payment}[npe01__Opportunity__c]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    ...    ${ns}custom_currency__c=20.0
    ...    ${ns}custom_date__c=${date}
    ...    ${ns}custom_lookup__c=${camp_id}
    ...    ${ns}custom_number__c=123.0
    ...    ${ns}custom_picklist__c=2
    ...    ${ns}custom_textarea__c=this is custom batch
    ...    ${ns}custom_text__c=Robot
    
         