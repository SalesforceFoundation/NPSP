*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${No_of_payments}     4
${intervel}    2
${frequency}    Month
${opp_name}

*** Test Cases ***

Create Donation from a Contact
    [tags]  unstable
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact}[AccountId]
    &{opportunity} =  API Create Opportunity    &{Contact}[AccountId]    Donation    Name=Sravani $1000 donation    Amount=1000    StageName=Pledged    npe01__Do_Not_Automatically_Create_Payment__c=false
    Set Suite Variable    &{opportunity}
    Go To Record Home  &{opportunity}[Id]
    Select Tab    Related
    ${opp_name}    Get Main Header 
    Set Global Variable      ${opp_name}
    Load Related List    Payments
    Click Special Related List Button  Payments    Schedule Payments
    Wait For Locator    frame    Create one or more Payments for this Opportunity
    Choose Frame    Create one or more Payments for this Opportunity
    ${date} =     Get Current Date    result_format=%-m/%-d/%Y
    ${loc}    Get NPSP Locator    id    inputX
    Input Text    ${loc}    ${date}
    Enter Payment Schedule    ${No_of_payments}    ${intervel}    ${frequency}
    ${xpath}    Get NPSP Locator    button    Calculate Payments
    Execute JavaScript    window.document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.scrollIntoView(true)
    Click Button With Value    Calculate Payments
    ${value}     Verify Payment Split   1000    ${No_of_payments}
    Should be equal as strings    ${value}    ${No_of_payments}
    Verify Date Split    ${date}    ${No_of_payments}    ${intervel}
    ${xpath}    Get NPSP Locator    button    Create Payments
    Execute JavaScript    window.document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.scrollIntoView(true)    
    Click Button with Value    Create Payments
    Current Page Should Be     Details    Opportunity
    Scroll Page To Location    0    0
    Validate Related Record Count         Payments       4
    Click ViewAll Related List    Payments
    ${flag}     Verify payment    
    should be equal as strings     ${flag}    pass
    
Verify values in Create one or more Payments for this Opportunity page
    [tags]  unstable
    Go To Page     Details    Opportunity    object_id=&{opportunity}[Id]
    Select Tab    Related
    Click First Matching Related Item Popup Link    Payments    Unpaid    Edit
    Wait Until Modal Is Open
    Set Checkbutton To    Written Off    checked
    ${pay_id}    Return Locator Value    payments.field-value    Payment Number
    Click Modal Button    Save
    Wait Until Modal Is Closed
    Click Special Related List Button  Payments    Schedule Payments
    Wait For Locator    frame    Create one or more Payments for this Opportunity
    Choose Frame    Create one or more Payments for this Opportunity
    Verify Field Values
    ...    Payment Writeoff Amount=$250.00
    ...    Remaining Balance=$750.00
    Click Button    Cancel
    Current Page Should Be     Details    Opportunity
    Select Tab    Related
    Click First Matching Related Item Popup Link    Payments    Unpaid    Edit
    Wait Until Modal Is Open
    Set Checkbutton To    Written Off    checked
    Set Checkbutton To    Paid           checked
    Click Modal Button    Save
    Page Should Contain    A Payment can't be both paid and written off. You must deselect one or both checkboxes.
    Click Modal Button    Cancel
    Current Page Should Be     Details    Opportunity
    Click ViewAll Related List    Payments
    Verify Details
    ...    Unpaid=3
    ...    Written Off=1
    
Verify values in Writeoff Remaining Balance Page
    [tags]  unstable
    Go To Page     Details    Opportunity    object_id=&{opportunity}[Id]
    Select Tab    Related
    Click First Matching Related Item Popup Link    Payments    Unpaid    Edit
    Wait Until Modal Is Open  
    Set Checkbutton To    Written Off    checked
    Populate Field    Payment Amount    200 
    Click Modal Button    Save
    Wait Until Modal Is Closed
    Click Related List Dd Button    Payments    Show one more action    Write Off Payments 
    Wait For Locator    frame    Write Off Remaining Balance
    Choose Frame    Write Off Remaining Balance 
    Wait Until Page Contains    You are preparing to write off 2 Payment(s)
    Verify Field Values
    ...    Payment Writeoff Amount=$450.00
    ...    Remaining Balance=$550.00  
    Page Should Contain    You are preparing to write off 2 Payment(s) totaling $550.00
    Choose Frame    Write Off Remaining Balance
    Click Button    Cancel
    Current Page Should Be     Details    Opportunity
    Select Tab    Related
    Load Related List    Payments
    Click ViewAll Related List    Payments
    Verify Details
    ...    Unpaid=2
    ...    Written Off=2