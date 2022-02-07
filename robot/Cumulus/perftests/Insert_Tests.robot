## @description: NPSP Performance Tests - Inserting Records
## @date 2022-02-07

*** Variables ***
${COUNTER} =      ${0}
${LOOP_COUNTER} =   50          ## 50x200 = 10,000 records

*** Settings ***
Documentation   Performance Testing of inserting records into an Org:
...             - Contacts (with and without addresses),
...             - Opportunties (with and without payments and allocation)
...             - Accounts and Contacts with NPSP Triggers disabled (simulating a vanilla org)
Library         DateTime
Resource        cumulusci/robotframework/Salesforce.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Test Setup

*** Keywords ***
## =============================================================================================
## Main Testing Keywords:
## =============================================================================================

Insert 200 Contacts
    [Arguments]     ${IncludeAddress}
    [Documentation]  Generate and Insert 200 Contacts (using NPSP)
    Set Suite Variable      ${COUNTER}   ${COUNTER + 1}
    @{objects}=     run keyword if    ${IncludeAddress}        Get 200 Contacts With Address
    ...                ELSE                     Get 200 Contacts Without Address
    Salesforce Collection Insert  ${objects}
    [return]    ${objects}

Insert 200 Opportunities
    [Arguments]     ${IncludePayment}
    [Documentation]  Generate and Insert 200 Opportunities

    @{accounts}=    Salesforce Query    Account
    ...           select=Id

    Set Suite Variable      ${COUNTER}   ${COUNTER + 1}
    @{objects}=     Get 200 Opportunities   ${accounts}     ${IncludePayment}
    Salesforce Collection Insert  ${objects}
    [return]    ${objects}

Insert 200 Non-NPSP Contacts
    [Documentation]     Generate and Insert 200 Accounts and Contacts with all NPSP triggers disabled.
    Set Suite Variable      ${COUNTER}   ${COUNTER + 1}

    ${random}=      Generate Random String     16
    ${timestamp} =	Get Current Date    result_format=epoch

    # Create Accounts
    @{records}=  Generate Test Data  Account  200
        ...  Name={{fake.name}} Household
        ...  Phone={{fake.phone_number}}
        ...  BillingStreet={{fake.street_address}}
        ...  BillingCity={{fake.city}}
        ...  BillingState={{fake.state}}
        ...  BillingPostalCode={{fake.postcode}}
        ...  Type=New Customer
    @{accounts}=    Salesforce Collection Insert    ${records}

    # Create Contacts and assign each contact to one account
    @{contacts}=     Get 200 Contacts With Address
    ${numcontacts}=  Get Length     ${contacts}
    FOR     ${index}   IN RANGE   ${numcontacts}
        ${object}=      Set Variable    ${contacts}[${index}]
        ${account}=     Set Variable    ${accounts}[${index}]
        ${account_id}=  Set Variable    ${account}[id]
        set to dictionary   ${object}   AccountId   ${account_id}
    END
    Salesforce Collection Insert    ${contacts}

    [return]    ${contacts}

## =============================================================================================
## Data Creation Keywords:
## =============================================================================================
Get 200 Opportunities
    [Arguments]     ${accounts}         ${IncludePayment}
    [Documentation]     Generate 200 Opportunity objects for the related Account/Contact
    ...                 and optionally dsiable creating a Payment record

    ${ExcludePayment}=  set variable if    ${IncludePayment}   ${False}     ${True}
    ${random}=      Generate Random String     16
    ${date}=        Get Current Date        result_format=%Y-%m-%d
    @{objects}=     Generate Test Data      Opportunity  200
        ...  Name=Performance Test Opportunity {{number}}
        ...  StageName=Closed Won
        ...  Amount={{100 + number}}
        ...  CloseDate=${date}
        ...  npe01__Do_Not_Automatically_Create_Payment__c=${ExcludePayment}

    ${numobjects}=  Get Length     ${objects}
    FOR     ${index}   IN RANGE   ${numobjects}
        ${object}=      Set Variable    ${objects}[${index}]
        ${account}=     Set Variable    ${accounts}[${index}]
        ${account_id}=  Set Variable    ${account}[Id]
        set to dictionary   ${object}   AccountId   ${account_id}
    END
    [return]    ${objects}

Get 200 Contacts With Address
    [Documentation]     Generate 200 Contact records with a Mailing Address

    ${random}=      Generate Random String     16
    ${timestamp} =	Get Current Date    result_format=epoch
    @{objects}=  Generate Test Data  Contact  200
        ...  FirstName={{fake.first_name}}
        ...  LastName={{fake.last_name}}
        ...  MailingStreet={{fake.street_address}}
        ...  MailingCity={{fake.city}}
        ...  MailingState={{fake.state}}
        ...  MailingPostalCode={{fake.postcode}}
        ...  Phone={{fake.phone_number}}
        ...  Title=${random}
        ...  Email=${timestamp}+{{number}}@${random}-{{number}}.com
    [return]    ${objects}

Get 200 Contacts Without Address
    [Documentation]     Generate 200 Contact records without a Mailing Address

    ${random}=      Generate Random String     16
    ${timestamp} =	Get Current Date    result_format=epoch
    @{objects}=  Generate Test Data  Contact  200
        ...  FirstName={{fake.first_name}}
        ...  LastName={{fake.last_name}}
        ...  Phone={{fake.phone_number}}
        ...  Title=${random}
        ...  Email=${timestamp}+{{number}}@${random}-{{number}}.com
    [return]    ${objects}

## =============================================================================================
## Helper Keywords
## =============================================================================================

Test Setup
    Disable Duplicate Matching
    Delete Default Data

Disable Duplicate Matching
    [Documentation]  Disable Salesforce duplicate matching
    Run Task        set_duplicate_rule_status
        ...     active=${False}

Delete Default Data
    [Documentation]     Delete Entitlement & Associated Records (these are created by default in new scratch orgs)
    Log to Console      Deleting Entitlement Records
    Run Task            test_data_delete
        ...     objects=Entitlement,Contact,Account
        ...     ignore_row_errors=True

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

Enable Default GAU Allocation
    [Documentation]     Insert a single GAU record and set that as the default allocation in NPSP
    ${ns}=              Get NPSP Namespace Prefix
    &{default_gau}=     API Create GAU
    API Modify Allocations Setting
    ...        ${ns}Default_Allocations_Enabled__c=true
    ...        ${ns}Default__c=${default_gau}[Id]

Disable Default GAU Allocation
    [Documentation]     Disable the default GAU
    ${ns}=   Get NPSP Namespace Prefix
    API Modify Allocations Setting
    ...        ${ns}Default_Allocations_Enabled__c=false

Final Cleanup
    [Documentation]     Delete All Created Records and renable NPSP Triggers
    Log to Console      Deleting All Created Records
    Disable NPSP Triggers
    Delete Opportunities
    Delete Contacts
    Enable NPSP Triggers

Delete Contacts
    [Documentation]     Delete Account and Related Records Using the Bulk Api for performance
    Log to Console      Deleting Contact Records
    Run Task            test_data_delete
        ...     objects=npe01__OppPayment__c,Allocation__c,Address__c,Contact,Account

Delete Opportunities
    [Documentation]     Delete Opporutnity and Related Records Using the Bulk Api for performance
    Log to Console      Deleting Opportunity Records
    Run Task            test_data_delete
        ...     objects=npe01__OppPayment__c,Allocation__c,Opportunity

*** Test Cases ***
## =============================================================================================
## INDIVIDUAL TEST CASES
## =============================================================================================

Insert Contact Perf Test 10000
    [Documentation]     Insert 10K Contacts with an Address using NPSP's triggers - which automatically creates an Account
    ...                 and an Address__c record.
    [Tags]    long     insertions   contact
    FOR    ${index}    IN RANGE     ${LOOP_COUNTER}
        Insert 200 Contacts     ${True}
        Log To Console   Inserted batch ${index}/${LOOP_COUNTER} for Contacts with Addresses
    END
    [Teardown]    Delete Contacts

Insert Contact Perf Test 10000 No Address
    [Documentation]     Insert 10K Contacts without an Address using NPSP's triggers - which automatically creates an Account.
    ...                 Records are NOT deleted to allow use for the Opportunity Insert
    [Tags]    long     insertions   contact
    FOR    ${index}    IN RANGE     ${LOOP_COUNTER}
        Insert 200 Contacts     ${False}
        Log To Console   Inserted batch ${index}/${LOOP_COUNTER} for Contacts without Addresses
    END

Insert Opportunities Perf Test No Payment
    [Documentation]     Insert 10K Opportunies - No Payment or Allocation
    [Tags]    long     insertions   opportunity
    [Setup]     Disable Default GAU Allocation
    FOR    ${index}    IN RANGE     ${LOOP_COUNTER}
        Insert 200 Opportunities    ${False}
        Log To Console   Inserted batch ${index}/${LOOP_COUNTER} for Opportunities without a Payment
    END
    [Teardown]    Delete Opportunities

Insert Opportunities Perf Test With Payment
    [Documentation]     Insert 10K Opportunies - WITH a Payment record and No Allocation
    [Tags]    long     insertions   opportunity
    [Setup]     Disable Default GAU Allocation
    FOR    ${index}    IN RANGE     ${LOOP_COUNTER}
        Insert 200 Opportunities    ${True}
        Log To Console   Inserted batch ${index}/${LOOP_COUNTER} for Opportunities with a Payment
    END
    [Teardown]    Delete Opportunities

Insert Opportunities Perf Test Default Allocation
    [Documentation]     Insert 10K Opportunies - WITH the default Allocation and No Payment
    [Tags]    long     insertions   opportunity
    [Setup]     Enable Default GAU Allocation
    FOR    ${index}    IN RANGE     ${LOOP_COUNTER}
        Insert 200 Opportunities    ${False}
        Log To Console   Inserted batch ${index}/${LOOP_COUNTER} for Opportunities with an Allocation and no Payment
    END
    [Teardown]    Delete Opportunities

Insert Contact Perf Test 10000 Vanilla Org
    [Documentation]     Insert 10K Accounts and Contacts with all triggers disabled; effectively simulating
    ...                 a Vanilla Salesforce Org test
    [Setup]     Disable NPSP Triggers
    [Tags]    long     insertions   contact     vanilla

    FOR    ${index}    IN RANGE     ${LOOP_COUNTER}
        Insert 200 Non-NPSP Contacts
        Log To Console   Inserted batch ${index}/${LOOP_COUNTER} for Contacts and Accounts with all NPSP Triggers Disabled
    END
    [Teardown]  Enable NPSP Triggers