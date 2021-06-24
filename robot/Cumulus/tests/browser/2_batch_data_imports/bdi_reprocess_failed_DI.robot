*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/DataImportPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Variables
...             Enable Advanced Mapping
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${org_ns} =           Get Org Namespace Prefix
    Set suite variable    ${org_ns}
    ${date} =             Get Current Date    result_format=%Y-%m-%d
    Set suite variable    ${date}
    ${ns} =               Get NPSP Namespace Prefix
    Set suite variable    ${ns}
    &{gau} =  API Create GAU
    Set suite variable    &{gau}
    ${first_name} =      Generate Random String
    Set suite variable    ${first_name}
    ${last_name} =       Generate Random String
    Set suite variable    ${last_name}

Create Data Import Record
    ${account} =      Generate Random String
    &{data_import} =  API Create DataImport
    ...        ${ns}Account1_Name__c=${account}
    ...        ${ns}Donation_Amount__c=100
    ...        ${ns}Donation_Date__c=${date}
    ...        ${ns}Donation_Donor__c=Contact1
    ...        ${org_ns}CO2_currency__c=500
    [return]   &{data_import}

Create Data Import with GAU Details
    &{data_import} =  API Create DataImport
    ...        ${ns}Contact1_Firstname__c=${first_name}
    ...        ${ns}Contact1_Lastname__c=${last_name}
    ...        ${ns}Donation_Amount__c=100
    ...        ${ns}Donation_Date__c=${date}
    ...        ${ns}Donation_Donor__c=Contact1
    ...        ${ns}GAU_Allocation_1_Percent__c=50
    [return]   &{data_import}

*** Test Cases ***
Verify Donation Creation Fails on Incorrect Data and Reprocess
    [Documentation]
    ...                    Create a DI record with Account, CustomObject2 and Donation details but select Donation Donor as Contact.
    ...                    Verify that DI processing fails but account is created. Edit DI and change Donor to Account and reprocess DI record.
    ...                    DI completes and account matches to previous and Donation and Custom Object records are created
    [tags]                 W-035913    feature:BDI    unstable

    #Create DI record and process batch and verify failure messages
    &{data_import} =                 Create Data Import Record
    Process Data Import Batch        Errors
    &{data_import_upd} =             Salesforce Get  ${ns}DataImport__c  ${data_import}[Id]
    Open Data Import Record          ${data_import_upd}[Name]
    Current Page Should be           Details         DataImport__c
    Verify Failure Message           Failure Information        contains        Invalid Donation Donor
    Verify Failure Message           Donation Import Status     contains        Invalid Donation Donor

    # Verify Account Details
    Verify Expected Values                     nonns    Account            ${data_import_upd}[${ns}Account1Imported__c]
    ...    Name=${data_import}[${ns}Account1_Name__c]

    #Update DI record and reprocess batch and verify status messages
    Click Show More Actions Button   Edit
    Click Flexipage Dropdown         Donation Donor    Account1
    Click Special Button             Save
    Sleep                            2
    Process Data Import Batch        Completed
    &{data_import_upd} =             Salesforce Get  ${ns}DataImport__c  ${data_import}[Id]
    Open Data Import Record          ${data_import_upd}[Name]
    Current Page Should Be           Details          DataImport__c
    Verify Failure Message           Account1 Import Status    contains     Matched
    Verify Failure Message           Donation Import Status    contains     Created

    #Verify Opportunity is created as closed won with given date and amount
    Verify Expected Values                     nonns    Opportunity        ${data_import_upd}[${ns}DonationImported__c]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    ...    AccountId=${data_import_upd}[${ns}Account1Imported__c]

    #Verify Payment record is created and linked to opportunity with correct details
    Verify Expected Values                     nonns    npe01__OppPayment__c        ${data_import_upd}[${ns}PaymentImported__c]
    ...    npe01__Paid__c=True
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    ...    Payment_Status__c=Paid

    #Verify CustomObject2 record is created and linked to opportunity with correct details
    Verify Expected Values                     nonns       CustomObject2__c      ${data_import_upd}[${org_ns}CustomObject2Imported__c]
    ...    ${org_ns}C2_currency__c=500.0
    ...    ${org_ns}Account__c=${data_import_upd}[${ns}Account1Imported__c]

Verify GAU Allocation Fails on Incorrect Data and Reprocess
    [Documentation]
    ...                    Create a DI record with Contact, correct Donation details and GAU Allocation percent but without GAU ID.
    ...                    Verify that DI processing fails but Contact, Donation and Payment are created. Update DI with GAU ID and reprocess DI record.
    ...                    DI completes and Contact matches to previous and Donation and GAU allocation records are created
    [tags]                 W-035913    feature:BDI    unstable

    #Create DI record, process batch and confirm failure message
    &{data_import} =                 Create Data Import with GAU Details
    Process Data Import Batch        Errors
    &{data_import_upd} =             Salesforce Get  ${ns}DataImport__c  ${data_import}[Id]
    Log Many       &{data_import_upd}
    Open Data Import Record          ${data_import_upd}[Name]
    Current Page Should Be           Details          DataImport__c
    Verify Failure Message           Failure Information    contains       GAU Allocation 1: Import Status:\nError: record not created, missing required fields:${ns}GAU_Allocation_1_GAU__c

    # Verify Contact Details
    Verify Expected Values                     nonns    Contact            ${data_import_upd}[${ns}Contact1Imported__c]
    ...    FirstName=${first_name}
    ...    LastName=${last_name}

    #Verify Opportunity is created as closed won with given date and amount
    &{contact} =     Salesforce Get  Contact  ${data_import_upd}[${ns}Contact1Imported__c]
    Verify Expected Values                     nonns    Opportunity        ${data_import_upd}[${ns}DonationImported__c]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    ...    AccountId=${contact}[AccountId]

    #Verify Payment record is created and linked to opportunity with correct details
    Verify Expected Values                     nonns    npe01__OppPayment__c        ${data_import_upd}[${ns}PaymentImported__c]
    ...    npe01__Paid__c=True
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    ...    Payment_Status__c=Paid

    #Update DI record, reprocess batch and verify status messages and allocations
    Salesforce Update                ${ns}DataImport__c    ${data_import}[Id]
    ...                              ${ns}GAU_Allocation_1_GAU__c=${gau}[Id]
    Process Data Import Batch        Completed
    &{data_import_upd} =             Salesforce Get  ${ns}DataImport__c  ${data_import}[Id]
    Open Data Import Record          ${data_import_upd}[Name]
    Current Page Should Be           Details          DataImport__c
    Verify Failure Message           Contact1 Import Status    contains     Matched
    Verify Failure Message           Donation Import Status    contains     Created
    Go To Page                Detail        Opportunity     object_id=${data_import_upd}[${ns}DonationImported__c]
    Select Tab                Related
    Verify Allocations        GAU Allocations
    ...    ${gau}[Name]=50.000000%





