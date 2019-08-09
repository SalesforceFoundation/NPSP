*** Variables ***

${count} =   12       # use a multiple of 4
${database_url} =    
${field_mapping_method} =  
${time_to_pause_after_changing_mode} =  0

# tests won't work if there are records of these types in existence.
${core_objs_for_cleanup} =  npsp__DataImport__c,npsp__CustomObject3__c,npe01__OppPayment__c
# you could also clean these up to have a cleaner test
${other_objs_for_cleanup} =   Opportunity,Account,Contact,npsp__CustomObject1__c,MaintenancePlan,npsp__General_Accounting_Unit__c
${cleanup_first} =   core   # could also be "all" for maximum cleanliness or "none" for fresh scratch orgs

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup      Run Keywords   Setup BDI
...                             AND  Workaround Bug
...                             AND  Clear DataImport Records   
...                             AND  Generate Data

*** Keywords ***
Clear DataImport Records
                                
    ${all_objects} =   Catenate    ${core_objs_for_cleanup}  ,   ${other_objs_for_cleanup}
    # changed below to disable the "none" option temporarily.
    ${cleanup_objects} =   Set Variable If  
    ...             "${cleanup_first}"=="core"  ${core_objs_for_cleanup}
    ...             "${cleanup_first}"=="all"  ${all_objects}
    ...             "${cleanup_first}"=="none"  ${core_objs_for_cleanup}     Error
    Should not be equal     ${cleanup_objects}      Error     
    ...                     Cleanup mode was not one of "core", "all" or "none"
    Run keyword if  "${cleanup_objects}"!="NONE"
    ...    Run Task Class  cumulusci.tasks.bulkdata.DeleteData
    ...        objects=${cleanup_objects}

Generate Data
    ${count} =	Convert To Integer	${count}	

    Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${count}
#    ...                 database_url=sqlite:////tmp/temp_db.db
    ...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
    ...                 data_generation_task=tasks.generate_bdi_CO_data.GenerateBDIData_CO

Setup BDI
    Configure BDI     ${field_mapping_method}

    Run Keyword If    ${time_to_pause_after_changing_mode}
    ...               Python Display    Pausing ${time_to_pause_after_changing_mode}    Seconds
    Run Keyword If    ${time_to_pause_after_changing_mode}
    ...               Sleep     ${time_to_pause_after_changing_mode}
    Ensure Custom Metadata Was Deployed


Ensure Custom Metadata Was Deployed
    ${Default_Object_Mapping_Set} =   Salesforce Query  npsp__Data_Import_Object_Mapping__mdt
    ...           select=Id
    ...           npsp__Data_Import_Object_Mapping_Set__r.DeveloperName=Default_Object_Mapping_Set
    ${Default_Object_Mapping_Set_Length} =  Get Length  ${Default_Object_Mapping_Set}

    ${Migrated_Custom_Object_Mapping_Set} =   Salesforce Query  npsp__Data_Import_Object_Mapping__mdt
    ...           select=Id
    ...           npsp__Data_Import_Object_Mapping_Set__r.DeveloperName=Migrated_Custom_Object_Mapping_Set
    ${Migrated_Custom_Object_Mapping_Set_Length} =  Get Length  ${Migrated_Custom_Object_Mapping_Set}

    Should Be Equal     ${Default_Object_Mapping_Set_Length}    ${Migrated_Custom_Object_Mapping_Set_Length}

    Python Display      Custom Metadata Deployed        ${Migrated_Custom_Object_Mapping_Set_Length}

Display Failures
    @{failures} =   Salesforce Query  npsp__DataImport__c
    ...           select=Id,npsp__Status__c,npsp__FailureInformation__c, npsp__PaymentImported__c, npsp__PaymentImportStatus__c
    ...           npsp__Status__c=Failed
    ${length} =  Get Length  ${failures}
    Run Keyword If  ${length} == 0  Log to Console  No failure records
    Run Keyword If  ${length} == 0  Return From Keyword    False

    Python Display      Failures   ${length}

    @{payments} =   Salesforce Query  npe01__OppPayment__c
    ...           select=COUNT(Id)

    Python Display      Number of payments created    ${payments}[0][expr0]

    Python Display      Example Failure   Id: ${failures[0]['Id']}
    ...                                   npsp__Status__c: ${failures[0]['npsp__Status__c']}
    ...                                   npsp__PaymentImported__c: ${failures[0]['npsp__PaymentImported__c']}
    ...                                   npsp__PaymentImportStatus__c: ${failures[0]['npsp__PaymentImportStatus__c']}
    ...                                   npsp__FailureInformation__c: ${failures[0]['npsp__FailureInformation__c']}

Workaround Bug
    Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${4}
    ...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
    ...                 data_generation_task=tasks.generate_bdi_CO_data.GenerateBDIData_CO

    Batch Data Import   1000


*** Test Cases ***

Import a data batch via the API - Complex Objects No ASCs

    Batch Data Import   500

    ${count} =	Convert To Integer	${count}	

    @{result} =   Salesforce Query  npsp__DataImport__c  
    ...           select=COUNT(Id)
    ...           npsp__Status__c=Imported

    ${imported_records} =   Set Variable    ${result}[0][expr0]

    Run Keyword If  ${imported_records}!=${count}
    ...    Display Failures

    Should Be Equal      ${imported_records}    ${count}

    @{result} =   Salesforce Query  npsp__CustomObject3__c  
    ...           select=COUNT(Id)

    Should Be Equal     ${result}[0][expr0]     ${count}

    @{result} =   Salesforce Query  npe01__OppPayment__c  
    ...           select=COUNT(Id)

    Should Be Equal     ${result}[0][expr0]     ${count}
