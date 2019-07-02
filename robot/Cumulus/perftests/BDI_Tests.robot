*** Variables ***

${count} =   ${10000}       # use a multiple of 20
                # half (called num_records below) will be "matching" import records
                # half (num_records) will be "not matching"
                #
                # learn more here:
                # https://salesforce.quip.com/gLfGAPtqVzUS

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup       Run Task Class   tasks.generate_bdi_data.GenerateBDIData
...            num_records=${count/2}  mapping_yaml=datasets/bdi_benchmark/mapping.yml

*** Test Cases ***

Import a data batch via the API
    Batch Data Import   1000
    @{result} =   Salesforce Query  npsp__DataImport__c  select=COUNT(Id)
    Should Be Equal     ${result}[0][expr0]     ${count}
