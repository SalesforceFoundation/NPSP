*** Variables ***

${count} =   8       # use a multiple of 4
${database_url} =    
${field_mapping_method} =  

# tests won't work if there are records of these types in existence.
${core_objs_for_cleanup} =  npsp__DataImport__c,npsp__CustomObject3__c
# you could also clean these up to have a cleaner test
${other_objs_for_cleanup} =   Opportunity,npe01__OppPayment__c,Account,Contact,npsp__CustomObject1__c,MaintenancePlan,npsp__General_Accounting_Unit__c
${cleanup_first} =   "core"   # could also be "all" for maximum cleanliness or "none" for fresh scratch orgs

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup      Run Keywords   Setup BDI
...                             AND  Clear DataImport Records   
...                             AND  Generate Data

*** Keywords ***
Clear DataImport Records
    ${all_objects} =   Catenate    ${core_objs_for_cleanup}  ,   ${other_objs_for_cleanup}
    ${cleanup_objects} =   Set Variable If  
    ...             "${cleanup_first}"=="core"  ${core_objs_for_cleanup}
    ...             "${cleanup_first}"=="all"  ${all_objects}
    ...             "${cleanup_first}"=="none"  NONE     Error
    Should not be equal     ${cleanup_objects}      Error     
    ...                     Cleanup mode was not one of "core", "all" or "none"
    Run keyword if  "${cleanup_objects}"!="NONE"
    ...    Run Task Class  cumulusci.tasks.bulkdata.DeleteData
    ...        objects=${cleanup_objects}

Generate Data
    ${count} =	Convert To Integer	${count}	

    Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${count}
#    ...                 database_url=sqlite:////tmp/debug_backup.db
    ...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
    ...                 data_generation_task=tasks.generate_bdi_CO_data.GenerateBDIData_CO

Setup BDI
    Configure BDI     ${field_mapping_method}

Display Failures
    @{result} =   Salesforce Query  npsp__DataImport__c
    ...           select=Id,npsp__Status__c,npsp__FailureInformation__c
    ...           npsp__Status__c=Failed
    ${length} =  Get Length  ${result}
    Run Keyword If  ${length} == 0  Log to Console  No failure records
    Run Keyword If  ${length} == 0  Return From Keyword    False

    ${first_failure} =   Set Variable   ${result}[0][npsp__FailureInformation__c]

   Python Display      Failures   ${first_failure}


*** Test Cases ***

Import a data batch via the API - Test 4
    Batch Data Import   2

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

    @{result} =   Salesforce Query  npsp__CustomObject3__c  
    ...           select=COUNT(Id)

    Should Be Equal     ${result}[0][expr0]     ${count}
