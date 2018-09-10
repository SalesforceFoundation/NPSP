*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Library        OperatingSystem
Library        XML

*** Keywords ***

API Create Household
    [Arguments]      &{fields}
    ${name} =        Generate Random String
    ${rt_id} =       Get Record Type Id  Account  HH_Account
    ${account_id} =  Salesforce Insert  Account
    ...                  Name=${name}
    ...                  RecordTypeId=${rt_id}
    ...                  &{fields}
    &{account} =     Salesforce Get  Account  ${account_id}
    [return]         &{account}

API Create Household Address
    [Arguments]      ${account_id}  &{fields}
    # Addresses will be deleted if they don't have a country, set a default if none provided
    Run Keyword If   'MailingCountry__c' not in &{fields}
    ...                Set To Dictionary  ${fields}  MailingCountry__c=Test Country
    ${address_id} =  Salesforce Insert  Address__c
    ...                  Household_Account__c=${account_id}
    ...                  &{fields}
    &{address} =     Salesforce Get  Address__c  ${address_id}
    [return]         &{address}

API Create Contact
    [Arguments]      &{fields}
    ${first_name} =  Generate Random String
    ${last_name} =   Generate Random String
    ${contact_id} =  Salesforce Insert  Contact
    ...                  FirstName=${first_name}
    ...                  LastName=${last_name}
    ...                  &{fields}
    &{contact} =     Salesforce Get  Contact  ${contact_id}
    [return]         &{contact}