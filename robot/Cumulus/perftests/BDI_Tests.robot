*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup       Run Task Class   tasks.generate_bdi_data.GenerateBDIData
...            num_records=5000  mapping_yaml=datasets/bdi_benchmark/mapping.yml

*** Test Cases ***

Import a data batch via the API
    Batch Data Import   1000
