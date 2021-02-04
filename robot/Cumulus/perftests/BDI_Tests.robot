*** Variables ***
${database_url} =    
${persistent_org} =     ${False}

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Resource        robot/Cumulus/resources/Data.robot
Resource        robot/Cumulus/resources/BDI_API.robot
Suite Setup       Workaround Bug

*** Keywords ***
Clear Generated Records
    Output  Clearing Generated Records
    # Organized in dependency order
    Bulk Delete     DataImport__c, CustomObject1__c, CustomObject2__c, CustomObject3__c      
    Bulk Delete     Account_Soft_Credit__c     where=Opportunity__r.Primary_Contact__r.LastName Like '%BDITEST%' OR Account__r.Name Like '%BDITEST%'
    Bulk Delete     Allocation__c        where=Opportunity__r.Primary_Contact__r.LastName Like '%BDITEST%' OR Opportunity__r.Account.Name Like '%BDITEST%'
    Bulk Delete     npe01__OppPayment__c     where=npe01__Opportunity__r.Primary_Contact__r.LastName Like '%BDITEST%' OR npe01__Opportunity__r.Account.Name Like '%BDITEST%'
    Bulk Delete     Opportunity     where=Primary_Contact__r.LastName Like '%BDITEST%' OR Account.Name Like '%BDITEST%'
    Bulk Delete     Account     where=Name Like '%BDITEST%'
    Bulk Delete     Contact     where=LastName Like '%BDITEST%'

Generate Data
    [Arguments]    ${count}
    ${count} =  Convert To Integer	${count}

    Run Task   generate_and_load_from_yaml
    ...                 num_records=${count}
    ...                 num_records_tablename=DataImport__c
    ...                 batch_size=${500000}
#    ...                 database_url=sqlite:////tmp/temp_db.db  # turn this on to look at the DB for debugging
    ...                 generator_yaml=datasets/bdi_benchmark/BDI.recipe.yml

Setup BDI
    [Arguments]     ${field_mapping_method}
    Configure BDI     ${field_mapping_method}

    Run Keyword If    '${field_mapping_method}'=='Data Import Field Mapping'
    ...               Ensure Custom Metadata Was Deployed

Report BDI
    ${result} =   Row Count      DataImport__c  
    ...           Status__c=Imported

    Output  DataImport__c imported    ${result}

    ${result} =   Row Count     CustomObject3__c  

    Output  CustomObject3__c imported    ${result}

    ${result} =   Row Count  Account  
    ...           BillingCountry=Tuvalu

    Output  Accounts imported    ${result}

    ${result} =   Row Count     Contact  
    ...           Name Like '%BDITEST%'

    Output  Contacts imported    ${result}

Workaround Bug
    [Documentation]   The first BDI import often fails. W-035180
    Return From Keyword If      ${persistent_org}   # persistent orgs don't have this bug
    Generate Data   4
    Setup BDI       Data Import Field Mapping
    Batch Data Import   1000

Validate Data
    [Arguments]     ${count}
    Output      Validating ${TEST NAME}
    ${result} =    Check Row Count    ${count}     DataImport__c       Status__c=Imported
    Run Keyword Unless   "${result}"=="PASS"      Display BDI Failures
    Should be Equal     ${result}      PASS

Setup For Test
    [Arguments]                 ${count}    ${bdi_mode}
    Output      Preparing for ${TEST NAME}
    Clear Generated Records
    Setup BDI                   ${bdi_mode}
    Generate Data               ${count}
    Output      Starting ${TEST NAME}

*** Test Cases ***
BGE/BDI Import - CO - 100 / 250 - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    100    Data Import Field Mapping
    [Teardown]     Validate Data      100
    [Tags]    ultra-short     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - HT - 100 / 250 - 3.5 Objs/DI - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con ,1Payment,1 Opp
    [Setup]     Setup For Test    100    Help Text
    [Teardown]     Validate Data      100
    [Tags]    ultra-short     help-text
    Batch Data Import   250

BGE/BDI Import - CO - 1000 / 250 - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    1000    Data Import Field Mapping
    [Teardown]     Validate Data      1000
    [Tags]    short     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - HT - 1000 / 250 - 3.5 Objs/DI - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con ,1Payment,1 Opp
    [Setup]     Setup For Test    1000    Help Text
    [Teardown]     Validate Data      1000
    [Tags]    short     help-text
    Batch Data Import   250

BGE/BDI Import - CO - 10000 / 250 - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    10000    Data Import Field Mapping
    [Teardown]     Validate Data      10000
    [Tags]    medium     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - HT - 10000 / 250 - 3.5 Objs/DI - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con ,1Payment,1 Opp
    [Setup]     Setup For Test    10000    Help Text
    [Teardown]     Validate Data      10000
    [Tags]    medium     help-text
    Batch Data Import   250

BGE/BDI Import - CO - 120000 / 250 - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    120000    Data Import Field Mapping
    [Teardown]     Validate Data      120000
    [Tags]    long     advanced-mapping
    Batch Data Import   250

BGE/BDI Import - HT - 120000 / 250 - 3.5 Objs/DI - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con ,1Payment,1 Opp
    [Setup]     Setup For Test    120000    Help Text
    [Teardown]     Validate Data      120000
    [Tags]    long     help-text
    Batch Data Import   250

BGE/BDI Import - CO - 1000000 / 250 - 7.5 Objs/DI - 0.75 New Acc 0.25 Mtchd Acc 0.25 New Con 0.25 Mtchd Con 1CO1 0.5CO2 1CO3 1Payment 1Allocation 0.5ASC 1 Opp
    [Setup]     Setup For Test    1000000    Data Import Field Mapping
    [Teardown]     Validate Data      1000000
    [Tags]    ultra-long     advanced-mapping
    Batch Data Import   250
