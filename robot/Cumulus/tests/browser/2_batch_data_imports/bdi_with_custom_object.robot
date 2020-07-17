*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/DataImportPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/AdvancedMappingPageObject.py
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
    
Create Data Import Record  
    ${first_name1} =      Generate Random String 
    ${last_name1} =       Generate Random String
    ${account} =          Generate Random String 
    ${check} =            Generate Random String
    &{data_import} =  API Create DataImport     
    ...        ${ns}Contact1_Firstname__c=${first_name1}
    ...        ${ns}Contact1_Lastname__c=${last_name1}
    ...        ${ns}Account1_Name__c=${account}
    ...        ${ns}Donation_Amount__c=100
    ...        ${ns}Donation_Date__c=${date}
    ...        ${ns}Donation_Donor__c=Contact1
    ...        ${ns}Payment_Method__c=Check
    ...        ${ns}Payment_Check_Reference_Number__c=${check}
    ...        ${ns}Opportunity_Contact_Role_1_Role__c=Honoree
    ...        ${org_ns}CO1_currency__c=500
    ...        ${org_ns}CO1_Date__c=${date}
    ...        ${org_ns}CO1_Number__c=9876543
    ...        ${org_ns}CO1_Phone__c=1002003000
    ...        ${org_ns}CO1_Picklist__c=Option1
    ...        ${org_ns}CO1_Text__c=Robot Automation
    ...        ${org_ns}CO1_textarea__c=This is custom object data created via Automation
    ...        ${org_ns}CO1_url__c=robot.#23@xyz.com 
    [return]   &{data_import}

    
*** Test Cases ***
1 Delete Mappings And Process Batch
    [Documentation]        
    ...                    Delete the Currency1 field mapping on object 'CustomObject1' 
    ...                    and create and process a DI record with a value in Currency1 field.
    ...                    Verify that Currency1 value is not mapped over to currency1 field on object 'CustomObject1' 
    ...                    and verify that all other records(Account, contact, Opportunity and payment) are created correctly 
    [tags]                 W-035915    feature:BDI    unstable
    Go To Page                                Custom          NPSP_Settings
    Open Main Menu                            System Tools
    Click Link With Text                      Advanced Mapping for Data Import & Gift Entry  
    Click Configure Advanced Mapping
    View Field Mappings Of The Object         CustomObject1
    Delete Field Mapping                            CO1 currency
    Reload Page
    
    &{data_import2} =                          Create Data Import Record
    Process Data Import Batch                  Completed
    &{data_import_upd} =                       Salesforce Get  ${ns}DataImport__c  ${data_import2}[Id]
    
    # Verify Account Details
    Verify Expected Values                     nonns    Account            ${data_import_upd}[${ns}Account1Imported__c]
    ...    Name=${data_import2}[${ns}Account1_Name__c]
    
    #Verify Contact Details
    Verify Expected Values                     nonns    Contact            ${data_import_upd}[${ns}Contact1Imported__c]
    ...    FirstName=${data_import2}[${ns}Contact1_Firstname__c]
    ...    LastName=${data_import2}[${ns}Contact1_Lastname__c]
    
    #Verify Opportunity is created as closed won with given date and amount
    Verify Expected Values                     nonns    Opportunity        ${data_import_upd}[${ns}DonationImported__c]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    
    #Verify CustomObject1 record is created and linked to opportunity with correct details
    Verify Expected Values                     nonns       CustomObject1__c      ${data_import_upd}[${org_ns}CustomObject1Imported__c]
    ...    ${org_ns}C1_currency2__c=None
    ...    ${org_ns}C1_currency__c=None
    ...    ${org_ns}C1_date__c=${date}
    ...    ${org_ns}C1_number__c=9876543.0
    ...    ${org_ns}C1_phone__c=1002003000
    ...    ${org_ns}C1_picklist__c=Option1
    ...    ${org_ns}C1_text__c=Robot Automation
    ...    ${org_ns}C1_textarea__c=This is custom object data created via Automation
    ...    ${org_ns}C1_url__c=robot.#23@xyz.com
    ...    ${org_ns}Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    
    #Verify Payment record is created and linked to opportunity with correct details
    Verify Expected Values                     nonns    npe01__OppPayment__c        ${data_import_upd}[${ns}PaymentImported__c]
    ...    npe01__Check_Reference_Number__c=${data_import2}[${ns}Payment_Check_Reference_Number__c]
    ...    npe01__Paid__c=True
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Payment_Method__c=Check
    ...    npe01__Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    ...    Payment_Status__c=Paid

2 Create Data Import with Custom Object via API and Verify Values 
    [Documentation]        
    ...                    Create the Currency1 field mapping on object 'CustomObject1' 
    ...                    and Create and process DI record with Contact, Account, Opportunity, Payment and CustomObject1 details
    ...                    and verify that all records are created as expected along with currency1 
    ...                    on DI mapped to currency1 on object 'CustomObject1'
    [tags]                 W-035915    feature:BDI    unstable
    Go To Page                                Custom          NPSP_Settings
    Open Main Menu                            System Tools
    Click Link With Text                      Advanced Mapping for Data Import & Gift Entry  
    Click Configure Advanced Mapping
    View Field Mappings Of The Object         CustomObject1
    Create New Field Mapping                  CO1 currency (CO1_currency__c)    C1_currency (C1_currency__c)
    Reload Page
    
    &{data_import} =                          Create Data Import Record
    Process Data Import Batch                 Completed
    &{data_import_upd} =                      Salesforce Get  ${ns}DataImport__c  ${data_import}[Id]
    
    # Verify Account Details
    Verify Expected Values                    nonns    Account            ${data_import_upd}[${ns}Account1Imported__c]
    ...    Name=${data_import}[${ns}Account1_Name__c]
    
    #Verify Contact Details
    Verify Expected Values                    nonns    Contact            ${data_import_upd}[${ns}Contact1Imported__c]
    ...    FirstName=${data_import}[${ns}Contact1_Firstname__c]
    ...    LastName=${data_import}[${ns}Contact1_Lastname__c]
    
    #Verify Opportunity is created as closed won with given date and amount
    Verify Expected Values                    nonns    Opportunity        ${data_import_upd}[${ns}DonationImported__c]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    
    #Verify CustomObject1 record is created and linked to opportunity with correct details
    Verify Expected Values                    nonns       CustomObject1__c      ${data_import_upd}[${org_ns}CustomObject1Imported__c]
    ...    ${org_ns}C1_currency__c=500.0
    ...    ${org_ns}C1_date__c=${date}
    ...    ${org_ns}C1_number__c=9876543.0
    ...    ${org_ns}C1_phone__c=1002003000
    ...    ${org_ns}C1_picklist__c=Option1
    ...    ${org_ns}C1_text__c=Robot Automation
    ...    ${org_ns}C1_textarea__c=This is custom object data created via Automation
    ...    ${org_ns}C1_url__c=robot.#23@xyz.com
    ...    ${org_ns}Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    
    #Verify Payment record is created and linked to opportunity with correct details
    Verify Expected Values                    nonns    npe01__OppPayment__c        ${data_import_upd}[${ns}PaymentImported__c]
    ...    npe01__Check_Reference_Number__c=${data_import}[${ns}Payment_Check_Reference_Number__c]
    ...    npe01__Paid__c=True
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Payment_Method__c=Check
    ...    npe01__Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    ...    Payment_Status__c=Paid
       
3 Update Mappings and Process Batch 
    [Documentation]        
    ...                    Delete the Currency2 field mapping on object 'CustomObject1' if it exists 
    ...                    and map currency1 on DI to currency2 on object 'CustomObject1'
    ...                    Create and process DI record with Contact, Account, Opportunity, Payment and CustomObject1 details 
    ...                    and verify that all records are created as expected along with 
    ...                    currency1 on DI mapped to currency2 on object 'CustomObject1'   
    [tags]                 W-035915    feature:BDI    unstable
    Go To Page                                Custom          NPSP_Settings
    Open Main Menu                            System Tools
    Click Link With Text                      Advanced Mapping for Data Import & Gift Entry  
    Click Configure Advanced Mapping
    View Field Mappings Of The Object         CustomObject1  
    Delete Mapping If Mapping Exists          CO1 Currency2
    Edit Field Mappings                       CO1 currency    C1_currency2 (C1_currency2__c)
    Reload Page
    
    &{data_import1} =                          Create Data Import Record
    Process Data Import Batch                  Completed
    &{data_import_upd} =                       Salesforce Get  ${ns}DataImport__c  ${data_import1}[Id]
    
    # Verify Account Details
    Verify Expected Values                     nonns    Account            ${data_import_upd}[${ns}Account1Imported__c]
    ...    Name=${data_import1}[${ns}Account1_Name__c]
    
    #Verify Contact Details
    Verify Expected Values                     nonns    Contact            ${data_import_upd}[${ns}Contact1Imported__c]
    ...    FirstName=${data_import1}[${ns}Contact1_Firstname__c]
    ...    LastName=${data_import1}[${ns}Contact1_Lastname__c]
    
    #Verify Opportunity is created as closed won with given date and amount
    Verify Expected Values                     nonns    Opportunity        ${data_import_upd}[${ns}DonationImported__c]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    
    #Verify CustomObject1 record is created and linked to opportunity with correct details
    Verify Expected Values                     nonns       CustomObject1__c      ${data_import_upd}[${org_ns}CustomObject1Imported__c]
    ...    ${org_ns}C1_currency2__c=500.0
    ...    ${org_ns}C1_currency__c=None
    ...    ${org_ns}C1_date__c=${date}
    ...    ${org_ns}C1_number__c=9876543.0
    ...    ${org_ns}C1_phone__c=1002003000
    ...    ${org_ns}C1_picklist__c=Option1
    ...    ${org_ns}C1_text__c=Robot Automation
    ...    ${org_ns}C1_textarea__c=This is custom object data created via Automation
    ...    ${org_ns}C1_url__c=robot.#23@xyz.com
    ...    ${org_ns}Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    
    #Verify Payment record is created and linked to opportunity with correct details
    Verify Expected Values                     nonns    npe01__OppPayment__c        ${data_import_upd}[${ns}PaymentImported__c]
    ...    npe01__Check_Reference_Number__c=${data_import1}[${ns}Payment_Check_Reference_Number__c]
    ...    npe01__Paid__c=True
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Payment_Method__c=Check
    ...    npe01__Opportunity__c=${data_import_upd}[${ns}DonationImported__c]
    ...    Payment_Status__c=Paid

        