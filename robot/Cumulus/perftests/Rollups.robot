*** Variables ***
${database_url} =    
${persistent_org} =     ${False}

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Resource        robot/Cumulus/resources/Data.robot

*** Keywords ***
Clear Generated Records
    Log  Clearing Generated Records
    # Organized in dependency order
    Bulk Delete     DataImport__c
    Bulk Delete     Account     where=Name Like '%BDITEST%'
    Bulk Delete     Contact     where=LastName Like '%BDITEST%'

Generate Data
    [Arguments]    ${count}
    ${count} =  Convert To Integer	${count}

    # Run Task   generate_and_load_from_yaml
    # ...                 num_records=${count}
    # ...                 num_records_tablename=DataImport__c
    # ...                 batch_size=${500000}
    # ...                 generator_yaml=datasets/bdi_benchmark/BDI.recipe.yml

Setup For Test
    [Arguments]                 ${count}
    Log      Preparing for ${TEST NAME}
    Clear Generated Records
    Generate Data               ${count}
    Log      Starting ${TEST NAME}

Run Rollup
    Log      Rollup code goes here.

Validate Data
    Log      Validation code goes here.


*** Test Cases ***
Rollup Test 
    [Setup]     Setup For Test      1000
    [Teardown]     Validate Data
    [Tags]    rollups
    Run Rollup
