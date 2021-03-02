*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/DataImportPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Variables
...             Enable Advanced Mapping
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${first_name1} =      Generate Random String
    Set suite variable    ${first_name1}
    ${last_name1} =       Generate Random String
    Set suite variable    ${last_name1}
    ${account} =          Generate Random String 
    Set suite variable    ${account}
    ${org_ns} =           Get Org Namespace Prefix
    Set suite variable    ${org_ns}
    ${date} =             Get Current Date    result_format=%Y-%m-%d
    Set suite variable    ${date}
    ${ns} =               Get NPSP Namespace Prefix
    Set suite variable    ${ns}
    ${check} =            Generate Random String
    Set suite variable    ${check}
    
Setup Test Data
    &{gau} =  API Create GAU
    Set suite variable    &{gau}   
    &{data_import} =  API Create DataImport     
    ...        ${ns}Contact1_Firstname__c=${first_name1}
    ...        ${ns}Contact1_Lastname__c=${last_name1}
    ...        ${ns}Account1_Name__c=${account}
    ...        ${ns}Donation_Amount__c=200
    ...        ${ns}Donation_Date__c=${date}
    ...        ${ns}Donation_Donor__c=Contact1
    ...        ${ns}Payment_Method__c=Check
    ...        ${ns}Payment_Check_Reference_Number__c=${check}
    ...        ${org_ns}ASC_Amount__c=100
    ...        ${org_ns}ASC_Role__c=Influencer
    ...        ${ns}GAU_Allocation_1_GAU__c=${gau}[Id]
    ...        ${ns}GAU_Allocation_1_Amount__c=100
    ...        ${ns}Opportunity_Contact_Role_1_Role__c=Honoree
    Set Global Variable     &{data_import}       &{data_import} 

*** Test Cases ***

Create Data Import with Additional Objects via API and Verify Values 
    [Documentation]    Create a DI record with Contact, Account, Opportunity, Payment, Account Soft Credit 
    ...                and GAU details and verify that everything is saved as expected
    [tags]             unstable
    Process Data Import Batch    Completed
    &{data_import_upd} =      Salesforce Get  ${ns}DataImport__c  ${data_import}[Id]
    Verify Expected Values    nonns    Account            ${data_import_upd}[${ns}Account1Imported__c]
    ...    Name=${account}
    Verify Expected Values    nonns    Contact            ${data_import_upd}[${ns}Contact1Imported__c]
    ...    FirstName=${first_name1}
    ...    LastName=${last_name1}
    Verify Expected Values    nonns    Opportunity        ${data_import_upd}[${ns}DonationImported__c]
    ...    Amount=200.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    Verify Expected Values    ns       Account_Soft_Credit__c      ${data_import_upd}[${org_ns}AccountSoftCreditsImported__c]
    ...    ${ns}Amount__c=100.0
    ...    ${ns}Account__c=${data_import_upd}[${ns}Account1Imported__c]
    ...    ${ns}Role__c=Influencer
    ...    ${ns}Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    Verify Expected Values    nonns    npe01__OppPayment__c        ${data_import_upd}[${ns}PaymentImported__c]
    ...    npe01__Check_Reference_Number__c=${check}
    ...    npe01__Paid__c=True
    ...    npe01__Payment_Amount__c=200.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Payment_Method__c=Check
    ...    npe01__Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    ...    Payment_Status__c=Paid
    Go To Page                Detail        Opportunity     object_id=${data_import_upd}[${ns}DonationImported__c]
    Select Tab                Related
    Verify Allocations        Account Soft Credits
    ...    ${account}=$100.00
    Verify Allocations        GAU Allocations
    ...    ${gau}[Name]=$100.00
    Verify Related Object Field Values    Contact Roles
    ...    ${first_name1} ${last_name1}=Donor
    ...    ${first_name1} ${last_name1}=Honoree
   
      
    
    