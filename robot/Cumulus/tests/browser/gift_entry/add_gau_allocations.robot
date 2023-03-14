*** Settings ***
Documentation   These tests assumes that Default Gift Entry Template already has GAU widget included in the template
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Run keywords
...             API Modify Allocations Setting  ${NS}Default_Allocations_Enabled__c=false   ${NS}Default__c=None
...     AND     Query And Store Records To Delete    ${NS}DataImport__c   ${NS}Account1_Name__c=${ACCOUNT_NAME}
...     AND     Query And Store Records To Delete    ${NS}DataImport__c   ${NS}Contact1_Firstname__c=${FIRST_NAME}  ${NS}Contact1_Lastname__c=${LAST_NAME}
...     AND     Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${TEMPLATE}       GAU Widget Template
&{CONTACT}        Email=test@example.com

*** Keywords ***
Setup Test Data
    [Documentation]       Creates the GAU records and a first name, last name and company name
    ...                   needed to create contact and account
    &{DEFAULT_GAU} =      API Create GAU
    Set Suite Variable    &{DEFAULT_GAU}
    &{GAU1} =             API Create GAU
    Set Suite Variable    &{GAU1}
    &{GAU2} =             API Create GAU
    Set Suite Variable    &{GAU2}
    ${NS} =               Get NPSP Namespace Prefix
    Set Suite Variable    ${NS}
    ${FIRST_NAME} =       Get Fake Data  first_name
    Set Suite Variable    ${FIRST_NAME}
    ${LAST_NAME} =        Get Fake Data  last_name
    Set Suite Variable    ${LAST_NAME}
    ${ACCOUNT_NAME} =     Get Fake Data  company
    Set Suite Variable    ${ACCOUNT_NAME}


*** Test Cases ***

Test GAU Allocations with Default Allocations Disabled
    [Documentation]       Disable GAU allocations if enabled and navigate to Gift Entry page, click New Single Gift
    ...                   create a gift with contact info and add allocations more than donation amount and verify error message
    ...                   correct allocations to be less than donation amount(verifying remaining balance) and on saving opportunity
    ...                   and contact are created, GAU allocations are created for correct amounts specified on gift entry form
    [tags]                feature:GE    unstable    api     quadrant:q3
    API Modify Allocations Setting
    ...        ${NS}Default_Allocations_Enabled__c=false
    ...        ${NS}Default__c=None
    Go To Page                              Landing                        GE_Gift_Entry
    Click Link                              Templates
    Click Gift Entry Button                 New Single Gift
    Current Page Should Be                  Form                           Gift Entry
    Page Should Not Contain                 ${DEFAULT_GAU}[Name]
    Fill Gift Entry Form
    ...         Donor Type=Contact1
    ...         Contact First Name=${FIRST_NAME}
    ...         Contact Last Name=${LAST_NAME}
    ...         Donation Amount=100
    ...         Donation Date=Today
    Click Gift Entry Button                 Add New Allocation
    Fill Gift Entry Form
    ...         General Accounting Unit 0=${GAU1}[Name]
    ...         Percent 0=70
    Verify Allocation Remaining Balance     $30.00
    Validate Error Message                  warning
    ...         Allocation Error=Total amount doesn't match the Donation Amount
    Click Gift Entry Button                 Add New Allocation
    Fill Gift Entry Form
    ...         General Accounting Unit 1=${GAU2}[Name]
    ...         Amount 1=50
    Verify Allocation Remaining Balance     -$20.00
    Validate Error Message                  error
    ...         Allocation Error=Total amount doesn't match the Donation Amount
    Click Gift Entry Button                 Save
    Wait Until Page Contains Element        npsp:gift_entry.page_error
    Fill Gift Entry Form                    Amount 1=20
    Click Gift Entry Button                 Save
    ${date} =                               Get Current Date    result_format=%Y-%m-%d
    Current Page Should Be                  Details                         Opportunity
    &{account} =                            API Query Record                Account        Name=${LAST_NAME} Household
    Store Session Record                    Account                         ${account}[Id]
    ${newopp_id}                            Save Current Record ID For Deletion            Opportunity
    Verify Expected Values                  nonns                           Opportunity    ${newopp_id}
    ...         Amount=100.0
    ...         CloseDate=${date}
    ...         StageName=Closed Won
    ...         AccountId=${account}[Id]
    Select Tab                              Related
    Verify Allocations                      GAU Allocations
    ...         ${GAU1}[Name]=70.000000%
    ...         ${GAU2}[Name]=$20.00

Test GAU Allocations with Default Allocations Enabled
    [Documentation]       Enable GAU allocations and add a default if disabled and navigate to Gift Entry page, click New Single Gift
    ...                   create a gift with account info and verify default gau allocation equals donation amount, add new allocations
    ...                   with percent and amount. Verify default allocation changes to remaining amount after the two allocations
    ...                   and on saving opportunity and account are created, GAU allocations are created for all allocations correctly
    [tags]                feature:GE    unstable    api     quadrant:q3
    API Modify Allocations Setting
    ...        ${NS}Default_Allocations_Enabled__c=true
    ...        ${NS}Default__c=${DEFAULT_GAU}[Id]
    Go To Page                              Landing                       GE_Gift_Entry
    Click Link                              Templates
    Click Gift Entry Button                 New Single Gift
    Current Page Should Be                  Form                          Gift Entry
    Page Should Not Contain                 ${DEFAULT_GAU}[Name]
    Fill Gift Entry Form
    ...        Donor Type=Account1
    ...        Organization Account Name=${ACCOUNT_NAME}
    ...        Donation Amount=100
    ...        Donation Date=Today
    Verify Field Default Value
    ...        General Accounting Unit 0=${DEFAULT_GAU}[Name]
    ...        Amount 0=$100.00
    Click Gift Entry Button                 Add New Allocation
    Fill Gift Entry Form
    ...        General Accounting Unit 1=${GAU1}[Name]
    ...        Percent 1=60
    Verify Field Default Value
    ...        General Accounting Unit 0=${DEFAULT_GAU}[Name]
    ...        Amount 0=$40.00
    Click Gift Entry Button                 Add New Allocation
    Fill Gift Entry Form
    ...        General Accounting Unit 2=${GAU2}[Name]
    ...        Amount 2=30
    Verify Field Default Value
    ...        General Accounting Unit 0=${DEFAULT_GAU}[Name]
    ...        Amount 0=$10.00
    Click Gift Entry Button                 Save
    ${date} =                               Get Current Date                result_format=%Y-%m-%d
    Current Page Should Be                  Details                         Opportunity
    &{account} =                            API Query Record                Account      Name=${ACCOUNT_NAME}
    Store Session Record                    Account                         ${account}[Id]
    ${newopp_id}                            Save Current Record ID For Deletion          Opportunity
    Verify Expected Values                  nonns                           Opportunity  ${newopp_id}
    ...        Amount=100.0
    ...        CloseDate=${date}
    ...        StageName=Closed Won
    ...        AccountId=${account}[Id]
    Select Tab                              Related
    Verify Allocations                      GAU Allocations
    ...        ${GAU1}[Name]=60.000000%
    ...        ${GAU2}[Name]=$30.00
    ...        ${DEFAULT_GAU}[Name]=$10.00