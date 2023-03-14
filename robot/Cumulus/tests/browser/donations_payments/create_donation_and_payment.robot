*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/SchedulePaymentPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***
# Sets test data contact and an opportunity for the contact
Setup Test Data
    Setupdata   contact   ${contact1_fields}     ${opportunity_fields}
    ${date} =   Get Current Date       result_format=%-m/%-d/%Y
    Set suite variable    ${date}

*** Variables ***
&{contact1_fields}       Email=test@example.com
&{opportunity_fields}    Type=Donation   Name=Auto Payment test $1000 Donation   Amount=1000  StageName=Closed Won     StageName=Pledged    npe01__Do_Not_Automatically_Create_Payment__c=false
${No_of_payments}     4
${intervel}           2
${frequency}          Month
${opp_name}           Auto Payment test $1000 Donation

*** Test Cases ***

Create Donation from a Contact
    [Documentation]                      Create a donation schedule payment from Ui and verify
    ...                                  The number of payment installments and interval splits

    [tags]                               feature:Donations and Payments   unstable   api
    Go To Page                           Details
    ...                                  Opportunity
    ...                                  object_id=${data}[contact_opportunity][Id]
    Wait Until Keyword Succeeds          1 minute
    ...                                  5 seconds
    ...                                  Ensure Opportunity Details Are Loaded        ${data}[contact_opportunity][Id]        ${data}[contact_opportunity][Name]
    Select Tab                           Related
    Load Related List                    Payments
    Wait Until Loading Is Complete
    Click Special Button                 Schedule Payments
    Current Page Should Be               Custom                 SchedulePayment

    Enter Text Field Value               ${date}
    Enter Payment Schedule               ${No_of_payments}      ${intervel}            ${frequency}
    scroll button into view and click using js                  Calculate Payments
    Verify Payment Split                 1000                   ${No_of_payments}
    Verify Date Split                    ${date}                ${No_of_payments}      ${intervel}
    scroll button into view and click using js                  Create Payments
    Wait until page contains             ${opp_name}
    Go To Page                           Listing                                       Opportunity
    Wait Until Loading Is Complete
    Wait Until Keyword Succeeds          1 minute
    ...                                  5 seconds
    ...                                  Ensure Opportunity Details Are Loaded        ${data}[contact_opportunity][Id]        ${data}[contact_opportunity][Name]

    Validate Related Record Count        Payments                 4

    Click ViewAll Related List           Payments
    Wait until page contains             Payments
    Sleep                                2
    Verify payment