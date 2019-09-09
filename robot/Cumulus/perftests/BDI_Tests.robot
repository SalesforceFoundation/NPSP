*** Variables ***
${database_url} =    
${persistent_org} =     ${False}

${data_generation_task} =       tasks.generate_bdi_CO_data.GenerateBDIData_CO

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Resource        robot/Cumulus/resources/Data.robot
Resource        robot/Cumulus/resources/BDI_API.robot
Suite Setup       Workaround Bug

*** Keywords ***
Clear Generated Records
    Python Display  Clearing Generated Records
    # Organized in dependency order
    Delete     DataImport__c, CustomObject1__c, CustomObject2__c, CustomObject3__c      
    Delete     Account_Soft_Credit__c     where=Opportunity__r.Primary_Contact__r.LastName Like '%BDITEST%' OR Account__r.Name Like '%BDITEST%'
    Delete     Allocation__c        where=Opportunity__r.Primary_Contact__r.LastName Like '%BDITEST%' OR Opportunity__r.Account.Name Like '%BDITEST%'
    Delete     npe01__OppPayment__c     where=npe01__Opportunity__r.Primary_Contact__r.LastName Like '%BDITEST%' OR npe01__Opportunity__r.Account.Name Like '%BDITEST%'
    Delete     Opportunity     where=Primary_Contact__r.LastName Like '%BDITEST%' OR Account.Name Like '%BDITEST%'
    Delete     Account     where=Name Like '%BDITEST%'
    Delete     Contact     where=LastName Like '%BDITEST%'

Generate Data
    [Arguments]    ${count}
    ${count} =  Convert To Integer	${count}
    # ${data_generation_task} =     Set Variable If         "${field_mapping_method}"=="Help Text"  tasks.generate_bdi_data.generate_bdi_data         tasks.generate_bdi_CO_data.GenerateBDIData_CO

    Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${count}
#    ...                 database_url=sqlite:////tmp/temp_db.db  # turn this on to look at the DB for debugging
    ...                 mapping=datasets/bdi_benchmark/mapping.yml
    ...                 data_generation_task=${data_generation_task}

Setup BDI
    [Arguments]     ${field_mapping_method}
    Configure BDI     ${field_mapping_method}

    Run Keyword If    '${field_mapping_method}'=='Data Import Field Mapping'
    ...               Ensure Custom Metadata Was Deployed

Report BDI
    ${result} =   Row Count      DataImport__c  
    ...           Status__c=Imported

    Python Display  DataImport__c imported    ${result}

    ${result} =   Row Count     CustomObject3__c  

    Python Display  CustomObject3__c imported    ${result}

    ${result} =   Row Count  Account  
    ...           BillingCountry=Tuvalu

    Python Display  Accounts imported    ${result}

    ${result} =   Row Count     Contact  
    ...           Name Like '%BDITEST%'

    Python Display  Contacts imported    ${result}

Workaround Bug
    Return From Keyword If      ${persistent_org}   # persistent orgs don't have this bug
    Generate Data   4
    Setup BDI       Data Import Field Mapping
    Batch Data Import   1000

Validate Data
    [Arguments]     ${count}
    ${result} =    Check Row Count    ${count}     DataImport__c       Status__c=Imported
    Run Keyword Unless   "${result}"=="PASS"      Display BDI Failures
    Should be Equal     ${result}      PASS

Setup For Test
    [Arguments]                 ${count}    ${bdi_mode}
    Clear Generated Records
    Setup BDI                   ${bdi_mode}
    Generate Data               ${count}

*** Test Cases ***
BGE/BDI Import - CO - 100 / 250 - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    100    Data Import Field Mapping
    [Teardown]     Validate Data      100
    [Tags]    ultra-short     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - HT - 100 / 250 - 3.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con ,1Payment,1 Opp
    [Setup]     Setup For Test    100    Help Text
    [Teardown]     Validate Data      100
    [Tags]    ultra-short     help-text
    Batch Data Import   250

BGE/BDI Import - CO - 1000 / 250 - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    1000    Data Import Field Mapping
    [Teardown]     Validate Data      1000
    [Tags]    short     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - HT - 1000 / 250 - 3.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con ,1Payment,1 Opp
    [Setup]     Setup For Test    10000    Help Text
    [Teardown]     Validate Data      10000
    [Tags]    short     help-text
    Batch Data Import   250

BGE/BDI Import - CO - 10000 / 250 - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    10000    Data Import Field Mapping
    [Teardown]     Validate Data      10000
    [Tags]    medium     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - HT - 10000 / 250 - 3.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con ,1Payment,1 Opp
    [Setup]     Setup For Test    10000    Help Text
    [Teardown]     Validate Data      10000
    [Tags]    medium     help-text
    Batch Data Import   250

BGE/BDI Import - CO - 120000 / 250 - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    10000    Data Import Field Mapping
    [Teardown]     Validate Data      10000
    [Tags]    long     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - HT - 120000 / 250 - 3.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con ,1Payment,1 Opp
    [Setup]     Setup For Test    120000    Help Text
    [Teardown]     Validate Data      120000
    [Tags]    long     help-text
    Batch Data Import   250

BGE/BDI Import - CO - 120000 / 250 - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    120000    Data Import Field Mapping
    [Teardown]     Validate Data      120000
    [Tags]    long     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - CO - 1000000 / 250 - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    1000000    Data Import Field Mapping
    [Teardown]     Validate Data      1000000
    [Tags]    ultra-long     advanced-mapping
    Batch Data Import   250
