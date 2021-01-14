*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Run keywords
...             Disable Default And Payment Allocations
...             Capture Screenshot and Delete Records and Close Browser

*** Variables ***
&{contact1_fields}         Email=test@example.com
&{contact2_fields}         Email=test@example.com
&{opportunity1_fields}     Type=Donation   Name=$0 opp with default allocations enabled     Amount=0    StageName=Prospecting   npe01__Do_Not_Automatically_Create_Payment__c=false
&{opportunity2_fields}     Type=Donation   Name=$0 opp with default allocations disabled    Amount=0    StageName=Prospecting   npe01__Do_Not_Automatically_Create_Payment__c=false

*** Test Cases ***
Allocations Behavior when $0 with Default Allocations Enabled
    [Documentation]             Enable payment allocation and make sure default allocations are enabled
    ...                         Create a $0 opportunity.Default GAU allocation should still be created for opportunity.
    [tags]                      unstable     W-035595    feature:Payment Allocations
    Enable Default Allocations
    Setupdata                   contact1            ${contact1_fields}     ${opportunity1_fields}
    Go To Page                  Detail
    ...                         Opportunity
    ...                         object_id=${data}[contact1_opportunity][Id]
    Select Tab                  Related
    Verify Allocations          GAU Allocations
    ...                         ${def_gau}[Name]=$0.00

Allocations Behavior when $0 with Default Allocations Disabled
    [Documentation]             Enable payment allocation and make sure default allocations are DISABLED. Create a $0 opportunity
    ...                         Add a GAU with 100% and verify that GAU allocation is still there on Opportunity after save
    [tags]                      unstable    W-035647    feature:Payment Allocations
    Disable Default Allocations
    Setupdata                   contact2                    ${contact2_fields}     ${opportunity2_fields}
    &{allocation} =             API Create GAU Allocation   ${gau}[Id]             ${data}[contact2_opportunity][Id]
    ...                         ${ns}Percent__c=0.0
    Go To Page                  Detail
    ...                         Opportunity
    ...                         object_id=${data}[contact2_opportunity][Id]
    Select Tab                  Related
    Verify Allocations          GAU Allocations
    ...                         ${gau}[Name]=0.000000%

***Keywords***
Enable Default Allocations
    API Modify Allocations Setting
    ...               ${ns}Default_Allocations_Enabled__c=true
    ...               ${ns}Default__c=${def_gau}[Id]
    ...               ${ns}Payment_Allocations_Enabled__c=true

Disable Default Allocations
    API Modify Allocations Setting
    ...               ${ns}Default_Allocations_Enabled__c=false
    ...               ${ns}Default__c=${def_gau}[Id]
    ...               ${ns}Payment_Allocations_Enabled__c=true

Disable Default And Payment Allocations
    API Modify Allocations Setting
    ...               ${ns}Default_Allocations_Enabled__c=false
    ...               ${ns}Payment_Allocations_Enabled__c=false
    ...               ${ns}Default__c=None

Setup Test Data
    &{def_gau} =  API Create GAU    Name=default gau
    Set suite variable              &{def_gau}
    &{gau} =      API Create GAU
    Set suite variable              &{gau}
    ${ns} =       Get Npsp Namespace Prefix
    Set suite variable              ${ns}
    

