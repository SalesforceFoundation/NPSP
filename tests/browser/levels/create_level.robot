*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Level and Verify
    ${level_name}     Create Level
    Go To Object Home         npsp__Level__c
    Click Link    link=${level_name}
    ${level_name1}    Get Main Header
    Should be Equal as Strings    ${level_name1}      ${level_name}  
    Confirm Value    Minimum Amount (>=)    0.10    Y
    Confirm Value    Maximum Amount (<)     0.90    Y
        