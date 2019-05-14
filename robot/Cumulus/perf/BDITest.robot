*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot

*** Test Cases ***

Do a Batch Load via API
    Api Batchdata Load
