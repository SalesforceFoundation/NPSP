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
Resource        cumulusci/robotframework/Salesforce.robot

*** Keywords ***

Disable Duplicate Matching
    [Documentation]  Disable Salesforce duplicate matching
    Run Task        set_duplicate_rule_status
        ...         active=${False}

Insert 1M Contacts With CCI (Bulk)
    [Documentation]  Create 1M Contacts and parent Accounts using SnowFakery via Bulk API
    Run Task    generate_and_load_from_yaml
    ...                 num_records=1000000
    ...                 num_records_tablename=Contact
    ...                 generator_yaml=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...                 mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_BulkApi.yml

Insert 500K Contacts With CCI (Rest)
    [Documentation]  Create 500K Contacts and parent Accounts using SnowFakery via Rest API
    Run Task    generate_and_load_from_yaml
    ...                 num_records=500000
    ...                 num_records_tablename=Contact
    ...                 generator_yaml=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...                 mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_Rest.yml

Insert 500K Contacts With CCI (Bulk)
    [Documentation]  Create 500K Contacts and parent Accounts using SnowFakery via Bulk API
    Run Task    generate_and_load_from_yaml
    ...                 num_records=500000
    ...                 num_records_tablename=Contact
    ...                 generator_yaml=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...                 mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_BulkApi.yml

Insert 100K Contacts With CCI (Rest)
    [Documentation]  Create 100K Contacts and parent Accounts using SnowFakery via Rest API
    Run Task    generate_and_load_from_yaml
    ...                 num_records=100000
    ...                 num_records_tablename=Contact
    ...                 generator_yaml=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...                 mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_Rest.yml

Insert 100K Contacts With CCI (Bulk)
    [Documentation]  Create 100K Contacts and parent Accounts using SnowFakery via Bulk API
    Run Task    generate_and_load_from_yaml
    ...                 num_records=100000
    ...                 num_records_tablename=Contact
    ...                 generator_yaml=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...                 mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_BulkApi.yml

Insert 10K Contacts With CCI (Rest)
    [Documentation]  Create 10K Contacts and parent Accounts using SnowFakery via Rest API
    Run Task    generate_and_load_from_yaml
    ...                 num_records=10000
    ...                 num_records_tablename=Contact
    ...                 generator_yaml=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...                 mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_Rest.yml

Insert 10K Contacts With CCI (Bulk)
    [Documentation]  Create 10K Contacts and parent Accounts using SnowFakery via Bulk API
    Run Task    generate_and_load_from_yaml
    ...                 num_records=10000
    ...                 num_records_tablename=Contact
    ...                 generator_yaml=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...                 mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_BulkApi.yml

Insert 1K Contacts With CCI (Rest)
    [Documentation]  Create 1K Contacts and parent Accounts using SnowFakery via Rest API
    Run Task    generate_and_load_from_yaml
    ...                 num_records=1000
    ...                 num_records_tablename=Contact
    ...                 generator_yaml=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Recipe.yml
    ...                 mapping=robot/Cumulus/perftests/Insert_Contacts_Vanilla_Mapping_Rest.yml

*** Test Cases ***

Insert Contact Perf Test 1K Rest
    [Setup]     Disable Duplicate Matching
    [Tags]      1k_rest      insertions
    Insert 1K Contacts With CCI (Rest)

Insert Contact Perf Test 10K Rest
    # [Setup]     Disable Duplicate Matching
    [Tags]      10k_rest      insertions
    Insert 10K Contacts With CCI (Rest)

Insert Contact Perf Test 10K Bulk
    # [Setup]     Disable Duplicate Matching
    [Tags]      10k_bulk      insertions
    Insert 10K Contacts With CCI (Bulk)

Insert Contact Perf Test 100K Rest
    # [Setup]     Disable Duplicate Matching
    [Tags]      100k_rest      insertions
    Insert 100K Contacts With CCI (Rest)

Insert Contact Perf Test 100K Bulk
    # [Setup]     Disable Duplicate Matching
    [Tags]      100k_bulk      insertions
    Insert 100K Contacts With CCI (Bulk)

Insert Contact Perf Test 500K Bulk
    # [Setup]     Disable Duplicate Matching
    [Tags]      500k_bulk      insertions
    Insert 500K Contacts With CCI (Bulk)

Insert Contact Perf Test 500K Rest
    # [Setup]     Disable Duplicate Matching
    [Tags]      500k_rest      insertions
    Insert 500K Contacts With CCI (Rest)

Insert Contact Perf Test 1M Bulk
    # [Setup]     Disable Duplicate Matching
    [Tags]      1M_bulk      insertions
    Insert 1M Contacts With CCI (Bulk)

