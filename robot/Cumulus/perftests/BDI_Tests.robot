## @description: NPSP BDI Performance Tests
##               Two Separate BDI Jobs, each with 10K DI records. One is 100% match to existing Contacts, and the other has 0 matches.
## @date 2021-08-23

*** Variables ***
${persistent_org} =         ${False}
${AdvMappingConfigValue} =  Data Import Field Mapping
${DataImportBatchSize} =    250
${DataImportRecordCount} =  10000
${RecipeWithNoMatches} =    datasets/bdi_benchmark/BDI-without-matching.recipe.yml
${RecipeWithMatches} =      datasets/bdi_benchmark/BDI-with-matching.recipe.yml

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Resource        robot/Cumulus/resources/Data.robot
Resource        robot/Cumulus/resources/BDI_API.robot
Suite Setup     Configure Org

*** Keywords ***
## =============================================================================================
## Main Testing Keywords:
## =============================================================================================

Setup For Test
    [Arguments]             ${BdiMatchingMode}
    Output      \n
    Output      Preparing Data for Test
    Clear Test Data
    Generate Data           ${BdiMatchingMode}
    Output      Executing Data Import Batch Job

Configure Org
    Disable Duplicate Matching
    Delete Default Data
    Configure BDI       ${AdvMappingConfigValue}
    Ensure Custom Metadata Was Deployed

## =============================================================================================
## Data Creation Keywords:
## =============================================================================================
Generate Data
    [Arguments]    ${BdiMatchingMode}
    ${count} =  Convert To Integer      ${DataImportRecordCount}

    ${recipe} =     Set Variable if    '${BdiMatchingMode}'=='FullMatch'
    ...             ${RecipeWithMatches}
    ...             ${RecipeWithNoMatches}

    Output      Generating ${count} Records for '${BdiMatchingMode}' Test Using '${recipe}'

    Run Task   generate_and_load_from_yaml
    ...                 num_records=${count}
    ...                 num_records_tablename=DataImport__c
    ...                 batch_size=${500000}
    ...                 generator_yaml=${recipe}
#    ...                 database_url=sqlite:////tmp/temp_db.db  # turn this on to look at the DB for debugging

Clear Test Data
    Output  Clear Pre-Existing Test Data
    Disable NPSP Triggers
    Bulk Delete     DataImport__c,DataImportBatch__c
    Bulk Delete     Account_Soft_Credit__c, Allocation__c, npe01__OppPayment__c, Opportunity
    Bulk Delete     Account                    where=Name Like '%BDITEST%'
    Bulk Delete     Contact                    where=LastName Like '%BDITEST%'
    Bulk Delete     General_Accounting_Unit__c
    Enable NPSP Triggers

## =============================================================================================
## Helper Keywords
## =============================================================================================

Disable Duplicate Matching
    [Documentation]  Disable Salesforce duplicate matching
    Run Task        set_duplicate_rule_status
        ...     active=${False}

Delete Default Data
    [Documentation]     Delete Entitlement & Associated Records (these are created by default in new scratch orgs)
    Log to Console      Deleting Entitlement Records
    Run keyword and ignore error        Run Task            test_data_delete
        ...     objects=Entitlement,Account

Disable NPSP Triggers
    [Documentation]  Disable all NPSP Triggers
    Log to Console   Disable NPSP Triggers
    Run Task         disable_triggers
        ...     active=${False}
        ...     restore=${False}

Enable NPSP Triggers
    [Documentation]  Enable all NPSP Triggers
    Log to Console   Enable NPSP Triggers
    Run Task         restore_triggers
        ...     active=${True}
        ...     restore=${False}

Report BDI
    ${result} =   Row Count      DataImport__c
    ...           Status__c=Imported

    Output  DataImport__c imported    ${result}

    ${result} =   Row Count  Account
    ...           BillingCountry=Tuvalu

    Output  Accounts imported    ${result}

    ${result} =   Row Count     Contact
    ...           Name Like '%BDITEST%'

    Output  Contacts imported    ${result}

#Workaround Bug
#    [Documentation]   The first BDI import often fails. W-035180
#    Return From Keyword If      ${persistent_org}   # persistent orgs don't have this bug
#    Generate Data   4
#    Setup BDI       Data Import Field Mapping
#    Batch Data Import   1000

Validate Data
    Output      Validating Test Results

    ${result} =    Check Row Count    ${DataImportRecordCount}     DataImport__c       Status__c=Imported
    Run Keyword Unless   "${result}"=="PASS"      Display BDI Failures
    Should be Equal     ${result}      PASS

    ${result} =    Check Row Count    ${DataImportRecordCount}     Account
    Run Keyword Unless   "${result}"=="PASS"      Log to Console  Account Record Count is not ${DataImportRecordCount}
    Should be Equal     ${result}      PASS

    ${result} =    Check Row Count    ${DataImportRecordCount}     Opportunity
    Run Keyword Unless   "${result}"=="PASS"      Log to Console  Opportunity Record Count is not ${DataImportRecordCount}
    Should be Equal     ${result}      PASS

*** Test Cases ***
## =============================================================================================
## INDIVIDUAL TEST CASES
## =============================================================================================

BDI - Advanced Mapping with Full Match to Existing Contact 10K
    [Setup]        Setup For Test    FullMatch
    [Teardown]     Validate Data
    [Tags]         bdi   medium     advanced-mapping     full-contact-match
    Batch Data Import   ${DataImportBatchSize}

BDI - Advanced Mapping with No Match to Existing Contact 10K
    [Setup]        Setup For Test    NoMatch
    [Teardown]     Validate Data
    [Tags]         bdi   medium     advanced-mapping     no-contact-match
    Batch Data Import   ${DataImportBatchSize}
