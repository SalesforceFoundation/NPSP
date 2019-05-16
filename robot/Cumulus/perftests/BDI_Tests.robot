*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup       Run Task Class   tasks.generate_bdi_data.GenerateBDIData
...            num_records=2500  mapping_yaml=testdata/bdi_benchmark/mapping.yml

*** Test Cases ***

Import a data batch via the API
    Batch Data Import
