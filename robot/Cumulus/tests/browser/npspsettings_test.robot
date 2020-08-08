*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser
 
*** Test Cases ***    
Go To NPSP Settings And Run Batch

    ${endvalue}    Set Variable    12    #    End Value

    FOR    ${i}    IN RANGE    ${endvalue}
        Run Donations Batch Process 
    END
    

