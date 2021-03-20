*** Settings ***
Documentation   Enable Default Allocations and add a Default GAU for Allocations as part of suite setup
...             Disable Default Allocations and remove the Default GAU as part of suite Teardown
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
...             robot/Cumulus/resources/GAUPageObject.py
...             robot/Cumulus/resources/CustomSettingsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Enable Payment Allocations
...             Setup Test Data
Suite Teardown  Run keywords
...             Disable Payment Allocations
...             Capture Screenshot and Delete Records and Close Browser

*** Variables ***
&{contact1_fields}         Email=test@example.com
&{contact2_fields}         Email=test@example.com
&{opportunity1_fields}     Type=Donation   Name=Opp Allocation Sync test Donation           Amount=100  StageName=Prospecting    npe01__Do_Not_Automatically_Create_Payment__c=false
&{opportunity2_fields}     Type=Donation   Name=Payment Allocation Sync test Donation       Amount=100  StageName=Prospecting    npe01__Do_Not_Automatically_Create_Payment__c=false

*** Test Cases ***
Create Payment Allocations and Verify Opportunity Allocations Sync
    [Documentation]                        Once Allocations are Enabled and a Default GAU is added, create an opportunity via API.
    ...                                    Open Opportunity and open payments from the related tab. Verify that total payment is assigned to Default GAU
    ...                                    Add a new Allocation to another GAU and verify that the Allocation is split between default and new GAUs.
    ...                                    Go to Opportunity and verify that same allocation is reflected under GAU allocations related list.
    [tags]                                 W-039821            feature:Payment Allocations            unstable          notonfeaturebranch
    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=${data}[contact1_opportunity][Id]
    Select Tab                             Related
    Load Related List                      GAU Allocations
    Click Span Button                      ${payment1}[Name]
    Select Window
    Current Page Should Be                 Details                    npe01__OppPayment__c
    Select Tab                             Related
    Verify Payment Allocations
    ...    ${def_gau}[Name]=$100.00
    Click Related List Button              Payment Allocations        New
    Wait For Modal                         New                        GAU Allocation
    Populate Lookup Field                  General Accounting Unit    ${gau}[Name]
    Populate Field                         Amount                     40
    Click Button                           Save
    Wait Until Modal Is Closed
    Verify Payment Allocations
    ...    ${def_gau}[Name]=$60.00
    ...    ${gau}[Name]=$40.00
    Go To Page                             Details
    ...                                    Opportunity
    ...                                    object_id=${data}[contact1_opportunity][Id]
    Current Page Should Be                 Details                    Opportunity
    Select Tab                             Related
    Verify Allocations                     GAU Allocations
    ...    ${def_gau}[Name]=$60.00
    ...    ${gau}[Name]=$40.00

Update GAU Allocations and Verify Payment Allocations Sync
    [Documentation]                        Once Allocations are Enabled and a Default GAU is added, create an opportunity via API.
    ...                                    Open Opportunity and Manage Allocations from GAU Allocations related list.
    ...                                    Add a new Allocation to another GAU and verify that the Allocation is split between default and new GAU.
    ...                                    Open Payments from related list and verify that same allocation is reflected under Payment Allocations related list.
    [tags]                                 W-039821                   feature:Payment Allocations               unstable           notonfeaturebranch
    Go To Page                             Detail
    ...                                    Opportunity
    ...                                    object_id=${data}[contact2_opportunity][Id]
    Select Tab                             Related
    Click Special Related List Button      GAU Allocations            Manage Allocations
    Current Page Should Be                 Custom                     ManageAllocations
    Set GAU Allocation
    ...                                    General Accounting Unit 0=${gau}[Name]
    ...                                    Percent 0=60
    Click Button                           Save
    Current Page Should Be                 Details                    Opportunity
    Verify Allocations                     GAU Allocations
    ...    ${def_gau}[Name]=$40.00
    ...    ${gau}[Name]=$60.00
    # As a workaround for lightning cache issue, going to the payment record directly as it would reload the record
    Go To Page                             Details                    npe01__OppPayment__c
    ...                                    object_id=${payment2}[Id]
    Select Tab                             Related
    Verify Payment Allocations
    ...    ${def_gau}[Name]=$40.00
    ...    ${gau}[Name]=$60.00

***Keywords***

Enable Payment Allocations
    &{def_gau} =  API Create GAU    Name=default gau
    Set suite variable              &{def_gau}
    Go To Page                      Custom                                  CustomSettings
    Select Settings Option          Allocations Settings                    Manage
    Verify Page And Select Frame    Allocations Settings
    Wait Until Element Is Visible   text:Default Organization Level Value
    Checkbox Status                 Payment Allocations Enabled             Not Checked
    Checkbox Status                 Default Allocations Enabled             Not Checked
    Click Button                    Edit
    Verify Page And Select Frame    Allocations Settings
    Set Checkbutton To              Default_Allocations_Enabled             checked
    Set Checkbutton To              Payment_Allocations_Enabled             checked
    Populate Field With Id          Default__c                              ${def_gau}[Id]
    Click Button                    Save

Disable Payment Allocations
    Go To Page                      Custom                                  CustomSettings
    Select Settings Option          Allocations Settings                    Manage
    Verify Page And Select Frame    Allocations Settings
    Wait Until Element Is Visible   text:Default Organization Level Value
    Checkbox Status                 Payment Allocations Enabled             Checked
    Checkbox Status                 Default Allocations Enabled             Checked
    Click Button                    Edit
    Verify Page And Select Frame    Allocations Settings
    Set Checkbutton To              Default_Allocations_Enabled             unchecked
    Set Checkbutton To              Payment_Allocations_Enabled             unchecked
    Populate Field With Id          Default__c                              null
    Click Button                    Save

Setup Test Data
    &{gau} =              API Create GAU
    Set suite variable    &{gau}
    ${date} =             Get Current Date    result_format=%Y-%m-%d
    Set suite variable    ${date}
    Setupdata             contact1            ${contact1_fields}     ${opportunity1_fields}
    Setupdata             contact2            ${contact2_fields}     ${opportunity2_fields}
    @{records} =          Salesforce Query    npe01__OppPayment__c
    ...    select=Id
    ...    npe01__Opportunity__c=${data}[contact1_opportunity][Id]
    &{id} =               Get From List  ${records}  0
    &{payment1} =         Salesforce Get  npe01__OppPayment__c  ${id}[Id]
    Set suite variable    &{payment1}
    @{records} =          Salesforce Query    npe01__OppPayment__c
    ...    select=Id
    ...    npe01__Opportunity__c=${data}[contact2_opportunity][Id]
    &{id} =               Get From List  ${records}  0
    &{payment2} =         Salesforce Get  npe01__OppPayment__c  ${id}[Id]
    Set suite variable    &{payment2}