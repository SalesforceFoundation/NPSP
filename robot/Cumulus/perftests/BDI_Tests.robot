*** Variables ***

${count} =   ${120}       # use a multiple of 40

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup       Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
...                 num_records=${count}
...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
...                 data_generation_task=tasks.generate_bdi_CO_data.GenerateBDIData_CO

*** Test Cases ***

Import a data batch via the API
    Batch Data Import   1000    Data Import Field Mapping
    @{result} =   Salesforce Query  npsp__DataImport__c  select=COUNT(Id)
    Should Be Equal     ${result}[0][expr0]     ${count}
