*** Variables ***

${count} =   40       # use a multiple of 4
${database_url} =    
${field_mapping_method} =  

# tests won't work if there are records of these types in existence.
${core_objs_for_cleanup}    =  npsp__DataImport__c,npsp__CustomObject3__c
# you could also clean these up to have a cleaner test
${other_objs_for_cleanup}   =   Account,Contact,Opportunity,npe01__OppPayment__c, npsp__CustomObject1__c
${cleanup_first}    =   "core"   # could also be "all" for maximum cleanliness or "none" for fresh scratch orgs

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup      Run Keywords   Setup BDI
...                             AND  Clear DataImport Records   
...                             AND  Generate Data

*** Keywords ***
Clear DataImport Records
    ${all_objects}  =   Catenate    ${core_objs_for_cleanup}    ${other_objs_for_cleanup}
    ${cleanup_objects}  =   Set Variable If  
    ...             ${cleanup_first} == "core"  ${core_objs_for_cleanup}
    ...             ${cleanup_first} == "all"  ${all_objects}
    ...             ${cleanup_first} == "none"  ${None}     Error
    Should not be equal     ${cleanup_objects}      Error     
    ...                     Cleanup mode was not one of "core", "all" or "none"
    Run keyword if  ${cleanup_objects}
    ...    Run Task Class  cumulusci.tasks.bulkdata.DeleteData
    ...        objects=${cleanup_objects}

Generate Data
    ${count} =	Convert To Integer	${count}	

    Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${count}
    ...                 database_url=${database_url} 
    ...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
    ...                 data_generation_task=tasks.generate_bdi_CO_data.GenerateBDIData_CO

Setup BDI
    Configure BDI     ${field_mapping_method}

*** Test Cases ***

Import a data batch via the API
    Batch Data Import   1000    

    ${count} =	Convert To Integer	${count}	

    @{result} =   Salesforce Query  npsp__DataImport__c  
    ...           select=COUNT(Id)
    ...           npsp__Status__c=Imported

    Should Be Equal     ${result}[0][expr0]     ${count}

    @{result} =   Salesforce Query  npsp__CustomObject3__c  
    ...           select=COUNT(Id)

    Should Be Equal     ${result}[0][expr0]     ${count}
