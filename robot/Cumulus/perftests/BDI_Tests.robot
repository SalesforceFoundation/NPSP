*** Variables ***

${count} =   12       # use a multiple of 4
${database_url} =    
${field_mapping_method} =  
${persistent_org} = 

# tests won't work if there are records of these types in existence.
${core_objs_for_cleanup} =  DataImport__c,CustomObject3__c,CustomObject1__c
# you could also clean these up to have a cleaner test
${other_objs_for_cleanup} =   Opportunity,Account,Contact,CustomObject1__c,MaintenancePlan,General_Accounting_Unit__c,WorkOrder,npe01__OppPayment__c
${cleanup_first} =   core   # could also be "all" for maximum cleanliness or "none" for fresh scratch orgs
${data_generation_task} =     Set Variable If         "${field_mapping_method}"=="Help Text"  tasks.generate_bdi_data.generate_bdi_data         tasks.generate_bdi_CO_data.GenerateBDIData_CO

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Resource        robot/Cumulus/resources/Data.robot
Suite Setup      Run Keywords   Clear Generated Records
...                             AND  Setup BDI
...                             AND  Workaround Bug
...                             AND  Clear DataImport Records   
...                             AND  Generate Data  ${count}
Test Teardown      Run Keywords   Report BDI


*** Keywords ***
Clear DataImport Records
    ${persistent_org} =     Convert To Boolean      ${persistent_org}
    Run keyword if  ${persistent_org}    
    ...    Python Display     Persistent org     ${persistent_org}
    ...    ELSE         Transient org      
    Run keyword if  ${persistent_org}     Clear Generated Records

Clear Generated Records
    Python Display  Clearing
    Delete     Account_Soft_Credit__c     where=Account__r.BillingCountry\='Tuvalu'    hardDelete=True
    Delete     npe01__OppPayment__c     where=npe01__Opportunity__r.Account.BillingCountry\='Tuvalu'    hardDelete=True
    Delete     Opportunity     where=Account.BillingCountry\='Tuvalu'    hardDelete=True
    Delete     Account     where=BillingCountry\='Tuvalu'    hardDelete=True
    Delete     Contact     where=Title\='HRH'    hardDelete=True

Generate Data
    [Arguments]    ${count}
    ${count} =  Convert To Integer	${count}

    Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${count}
#    ...                 database_url=sqlite:////tmp/temp_db.db
    ...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
    ...                 data_generation_task=${data_generation_task}

Setup BDI
    Configure BDI     ${field_mapping_method}

    Run Keyword If    '${field_mapping_method}'=='Data Import Field Mapping'
    ...               Ensure Custom Metadata Was Deployed

Report BDI
    @{result} =   Salesforce Query  DataImport__c  
    ...           select=COUNT(Id)
    ...           Status__c=Imported

    ${imported_records} =   Set Variable    ${result}[0][expr0]

    Python Display  DataImport__c imported    ${result}[0][expr0]

    @{result} =   Salesforce Query  CustomObject3__c  
    ...           select=COUNT(Id)

    Python Display  CustomObject3__c imported    ${result}[0][expr0]

    # @{result} =   Salesforce Query  npe01__OppPayment__c  
    # ...           select=COUNT(Id)

    # Python Display  npe01__OppPayment__c imported    ${result}[0][expr0]

    @{result} =   Salesforce Query  Account  
    ...           select=COUNT(Id)
    ...           BillingCountry=Tuvalu

    Python Display  Accounts imported    ${result}[0][expr0]

    @{result} =   Salesforce Query  Contact  
    ...           select=COUNT(Id)
    ...           Title=HRH

    Python Display  Contacts imported    ${result}[0][expr0]

Ensure Custom Metadata Was Deployed
    ${Default_Object_Mapping_Set} =   Salesforce Query  Data_Import_Object_Mapping__mdt
    ...           select=Id
    ...           Data_Import_Object_Mapping_Set__r.DeveloperName=Default_Object_Mapping_Set
    ${Default_Object_Mapping_Set_Length} =  Get Length  ${Default_Object_Mapping_Set}

    ${Migrated_Custom_Object_Mapping_Set} =   Salesforce Query  Data_Import_Object_Mapping__mdt
    ...           select=Id
    ...           Data_Import_Object_Mapping_Set__r.DeveloperName=Migrated_Custom_Object_Mapping_Set
    ${Migrated_Custom_Object_Mapping_Set_Length} =  Get Length  ${Migrated_Custom_Object_Mapping_Set}

    Should Be Equal     ${Default_Object_Mapping_Set_Length}    ${Migrated_Custom_Object_Mapping_Set_Length}

    Python Display      Custom Metadata Deployed        ${Migrated_Custom_Object_Mapping_Set_Length}

Display Failures
    @{failures} =   Salesforce Query  DataImport__c
    ...           select=Id,Status__c,FailureInformation__c, PaymentImported__c, PaymentImportStatus__c
    ...           Status__c=Failed
    ${length} =  Get Length  ${failures}
    Run Keyword If  ${length} == 0  Log to Console  No failure records
    Run Keyword If  ${length} == 0  Return From Keyword    False

    Python Display      Failures   ${length}

    ## TODO: How to recognize my new payments?
    #
    # @{payments} =   Salesforce Query  npe01__OppPayment__c
    # ...           select=COUNT(Id)

    # Python Display      Number of payments created    ${payments}[0][expr0]

    Python Display      Example Failure   Id: ${failures[0]['Id']}
    ...                                   Status__c: ${failures[0]['Status__c']}
    ...                                   PaymentImported__c: ${failures[0]['PaymentImported__c']}
    ...                                   PaymentImportStatus__c: ${failures[0]['PaymentImportStatus__c']}
    ...                                   FailureInformation__c: ${failures[0]['FailureInformation__c']}

Workaround Bug
    Run Task Class      tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${4}
    ...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
    ...                 data_generation_task=tasks.generate_bdi_CO_data.GenerateBDIData_CO

    Batch Data Import   1000


*** Test Cases ***

Import a data batch via the API - COs - No ASCs - 12000 / 250

    Batch Data Import   250

    ${count} =	Convert To Integer	${count}	

    @{result} =   Salesforce Query  DataImport__c  
    ...           select=COUNT(Id)
    ...           Status__c=Imported

    ${imported_records} =   Set Variable    ${result}[0][expr0]

    Run Keyword If  ${imported_records}!=${count}
    ...    Display Failures

    Should Be Equal      ${imported_records}    ${count}

    @{result} =   Salesforce Query  CustomObject3__c  
    ...           select=COUNT(Id)

    Should Be Equal     ${result}[0][expr0]     ${count}

    ## TODO: How to recognize my newly created payments?
    # @{result} =   Salesforce Query  npe01__OppPayment__c  
    # ...           select=COUNT(Id)

    # Should Be Equal     ${result}[0][expr0]     ${count}
