*** Variables ***

${count} =   9920       # use a multiple of 4
${database_url} =    
${field_mapping_method} =   Data Import Field Mapping

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup      Run Keywords    Clear DataImport Records   AND Generate Data

*** Keywords ***
Clear DataImport Records
    Run Task Class  cumulusci.tasks.bulkdata.DeleteData   objects=npsp__DataImport__c

Generate Data
    ${count} =	Convert To Integer	${count}	

    Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${count}
    ...                 database_url=${database_url} 
    ...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
    ...                 data_generation_task=tasks.generate_bdi_CO_data.GenerateBDIData_CO

*** Test Cases ***

Import a data batch via the API
    Batch Data Import   1000    ${field_mapping_method}

    ${count} =	Convert To Integer	${count}	

    @{result} =   Salesforce Query  npsp__DataImport__c  
    ...           select=COUNT(Id)
    ...           npsp__Status__c=Imported

    Should Be Equal     ${result}[0][expr0]     ${count}
