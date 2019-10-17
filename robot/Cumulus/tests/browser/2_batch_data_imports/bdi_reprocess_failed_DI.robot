*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/DataImportPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/AdvancedMappingPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Variables
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${org_ns} =           Get Org Namespace Prefix
    Set suite variable    ${org_ns}
    ${date} =             Get Current Date    result_format=%Y-%m-%d
    Set suite variable    ${date}
    ${ns} =               Get NPSP Namespace Prefix
    Set suite variable    ${ns}
    
Create Data Import Record  
    ${first_name1} =      Generate Random String 
    ${last_name1} =       Generate Random String
    ${gau} =          Generate Random String 
    ${check} =            Generate Random String
    &{gau} =  API Create GAU
    &{data_import} =  API Create DataImport     
    ...        ${ns}Contact1_Firstname__c=${first_name1}
    ...        ${ns}Contact1_Lastname__c=${last_name1}
    ...        ${ns}Donation_Amount__c=100
    ...        ${ns}Donation_Date__c=${date}
    ...        ${ns}Donation_Donor__c=Account1
    ...        ${ns}GAU_Allocation_1_GAU__c=&{gau}[Id]
    ...        ${ns}GAU_Allocation_1_percent__c=50
    [return]   &{data_import}

    
*** Test Cases ***
Verify Donation Creation Fails on Incorrect Data and Reprocess
    [Documentation]        
    ...                    Delete the Currency1 field mapping on object 'CustomObject1' 
    ...                    and create and process a DI record with a value in Currency1 field.
    ...                    Verify that Currency1 value is not mapped over to currency1 field on object 'CustomObject1' 
    ...                    and verify that all other records(Account, contact, Opportunity and payment) are created correctly 
    [tags]                 W-035913    feature:BDI
    &{data_import} =                 Create Data Import Record
    Process Data Import Batch        Errors
    &{data_import_upd} =             Salesforce Get  ${ns}DataImport__c  &{data_import}[Id]
    Open Data Import Record          &{data_import_upd}[Name]    
    #Verify Contact Details
    Verify Expected Values                     nonns    Contact            &{data_import_upd}[${ns}Contact1Imported__c]
    ...    FirstName=&{data_import}[${ns}Contact1_Firstname__c]
    ...    LastName=&{data_import}[${ns}Contact1_Lastname__c]
    
    #Verify Opportunity is created as closed won with given date and amount
    Verify Expected Values                     nonns    Opportunity        &{data_import_upd}[${ns}DonationImported__c]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    
   
    
    #Verify Payment record is created and linked to opportunity with correct details
    Verify Expected Values                     nonns    npe01__OppPayment__c        &{data_import_upd}[${ns}PaymentImported__c]
    ...    npe01__Check_Reference_Number__c=&{data_import2}[${ns}Payment_Check_Reference_Number__c]
    ...    npe01__Paid__c=True
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Payment_Method__c=Check
    ...    npe01__Opportunity__c=&{data_import_upd}[${ns}DonationImported__c]
    ...    Payment_Status__c=Paid

    