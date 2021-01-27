Resource        cumulusci/robotframework/Salesforce.robot

*** Variables ***
${COUNTER} =      ${0}

*** Settings ***
Documentation   Tests of Inserting records
Library         DateTime
Resource        cumulusci/robotframework/Salesforce.robot

*** Keywords ***

Disable Duplicate Matching
    [Documentation]  Disable Salesforce duplicate matching
    Run Task        set_duplicate_rule_status
        ...     active=${False}

Insert 200 Contacts
    [Documentation]  Create 200 Contacts in CONTACTS suite variable
    Set Suite Variable      ${COUNTER}   ${COUNTER + 1}
    Log to Console             ${COUNTER}
    ${random}=     Generate Random String     16
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
    Salesforce Collection Insert  ${objects}
    [return]    ${objects}

*** Test Cases ***

Insert Contact Perf Test 10000
    [Setup]     Disable Duplicate Matching
    [Tags]    long     insertions
    FOR    ${index}    IN RANGE     50
        Insert 200 Contacts
        Log To Console   Inserted batch ${index}
    END