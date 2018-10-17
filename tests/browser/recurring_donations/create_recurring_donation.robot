*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Open Recurring Donation With Monthly Installment
    Sleep    5
    Open App Launcher
    Populate Address    Search apps or items...    NPSP Settings
    Select App Launcher Link  NPSP Settings
    Wait For Locator    frame    Nonprofit Success Pack Settings
    Select Frame With Title    Nonprofit Success Pack Settings
    Wait for Locator    npsp_settings.side_panal
    Click Link    link=Recurring Donations
    #Sleep    2
    Click Panal Sub Link    Recurring Donations
    #Sleep    2
    ${value}    Get NPSP Settings Value    Opportunity Forecast Months
    Log To Console    ${value}
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    Scroll Page To Location    0    500
    Click Related List Button  Recurring Donations    New
    Populate Form
    ...                       Recurring Donation Name= Robot Recurring Donation
    ...                       Amount=100 
    ...                       Installments=1 
    Click Dropdown    Date Established
    Change Month      Go to previous month
    Pick Date         10 
    Click Dropdown    Open Ended Status
    Click Link        link=Open
    Click Dropdown    Installment Period
    Click Link        link=Monthly
    Click Dropdown    Schedule Type
    Click Link        link=Multiply By
    Click Modal Button        Save
    Reload Page
    Sleep    3
    Scroll Page To Location    0    500
    # ${Rec_doc}    Get NPSP Locator    related_list_items
    # Page Should Contain Element    ${Rec_don}
    Click ViewAll Related List    Opportunities
    Reload Page
    ${return_value}    Verify Payment Details
    Should be equal as strings    ${return_value}    ${value}
    Verify Opportunities    ${value}
 
    