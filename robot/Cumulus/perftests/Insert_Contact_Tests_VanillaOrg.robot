## Performance Testing:
## - Object: Contact and parent Account
## - Org Configuration: Vanilla Salesforce (no NPSP)
## - Sizes: 1K, 10K, 100K, and 500K

Resource        cumulusci/robotframework/Salesforce.robot

*** Variables ***
${COUNTER} =      ${0}

*** Settings ***
Documentation   Test Inserting Contact & Parent Account records in a vanilla Salesforce org
Library         DateTime
Library         robot/Cumulus/perftests/GenerateData.py
Resource        cumulusci/robotframework/Salesforce.robot
Suite Setup     Disable Duplicate Matching

*** Keywords ***
Create Data File
    [Arguments]     ${count}
    Generate Data
    ...     recipe=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...     num_records_tablename=Contact
    ...     num_records=${count}
    ...     outfile=contacts.db

Load Dataset Rest
    Run Task    load_dataset
    ...         database_url=sqlite:///contacts.db
    ...         mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_Rest.yml

Load Dataset Bulk
    Run Task    load_dataset
    ...         database_url=sqlite:///contacts.db
    ...         mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_BulkApi.yml


Disable Duplicate Matching
    [Documentation]  Disable Salesforce duplicate matching
    Run Task        set_duplicate_rule_status
        ...         active=${False}

*** Test Cases ***

Insert Contact Perf Test 1K Rest
    [Setup]     Create Data File        1000
    [Tags]      1k_rest      insertions
    Load Dataset Rest


Insert Contact Perf Test 10K Rest
    [Setup]     Create Data File        10_000
    [Tags]      10k_rest      insertions
    Load Dataset Rest

Insert Contact Perf Test 10K Bulk
    [Setup]     Create Data File        10_000
    [Tags]      10k_bulk      insertions
    Load Dataset Bulk

Insert Contact Perf Test 100K Rest
    [Setup]     Create Data File        100_000
    [Tags]      100k_rest      insertions
    Load Dataset Rest

Insert Contact Perf Test 100K Bulk
    [Setup]     Create Data File        100_000
    [Tags]      100k_bulk      insertions
    Load Dataset Bulk

Insert Contact Perf Test 500K Bulk
    [Setup]     Create Data File        500_000
    [Tags]      500k_bulk      insertions
    Load Dataset Bulk

Insert Contact Perf Test 500K Rest
    [Setup]     Create Data File        500_000
    [Tags]      500k_rest      insertions
    Load Dataset Rest

Insert Contact Perf Test 1M Bulk
    [Setup]     Create Data File        1_000_000
    [Tags]      1M_bulk      insertions
    Load Dataset Bulk

