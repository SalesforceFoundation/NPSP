*** Settings ***  
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

*** Variables ***
&{contact1_fields}         Email=test@example.com
&{contact2_fields}         Email=test@example.com
&{opportunity1_fields}     Type=Donation   Name=$0 opp with default allocations enabled     Amount=0    StageName=Prospecting    
&{opportunity2_fields}     Type=Donation   Name=$0 opp with default allocations disabled    Amount=0    StageName=Prospecting    

*** Test Cases ***
Allocations Behavior when $0 with Default Allocations Enabled
    [Documentation] 
    [tags]
    Enable Default Allocations
    Setupdata                   contact1            ${contact1_fields}     ${opportunity2_fields}
    Go To Page                  Detail
    ...                         Opportunity
    ...                         object_id=${data}[contact1_opportunity][Id]
    Select Tab                  Related
    Verify Allocations          GAU Allocations
    ...                         &{def_gau}[Name]=$0.00

Allocations Behavior when $0 with Default Allocations Disabled
    [Documentation]
    [tags]
    Disable Default Allocations
    Setupdata                   contact2            ${contact2_fields}     ${opportunity2_fields}
    &{allocation} =             API Create GAU Allocation   &{gau}[Id]     ${data}[contact2_opportunity][Id]    
    ...                         Percent__c=0.0 
    Go To Page                  Detail
    ...                         Opportunity
    ...                         object_id=${data}[contact2_opportunity][Id]
    Select Tab                  Related
    Verify Allocations          GAU Allocations
    ...                         &{gau}[Name]=0.000000%

***Keywords***
Enable Default Allocations
    &{def_gau} =  API Create GAU    Name=default gau
    Set suite variable              &{def_gau}
    API Modify Allocations Setting
    ...               Default_Allocations_Enabled__c=true
    ...               Default__c=&{def_gau}[Id]    
    
Disable Default Allocations
    API Modify Allocations Setting
    ...               Default_Allocations_Enabled__c=false    
    
Setup Test Data
    &{gau} =              API Create GAU  
    Set suite variable    &{gau}  
    