*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Edit Level and Verify
    ${level_name}     Create Level
    Go To Object Home         npsp__Level__c
    Click Link    link=${level_name}
    Click Link    link=Edit
    Sleep    2
    Select Frame With Title    Levels
    Enter Level Dd Values    Source Field    Smallest Gift
    Enter Level Values
    ...            Minimum Amount=0.01
    ...            Maximum Amount=0.99
    
    Click Level Button    Save
    Go To Object Home         npsp__Level__c
    Click Link    link=${level_name}  
    Confirm Value    Minimum Amount (>=)    0.01    Y
    Confirm Value    Maximum Amount (<)     0.99    Y
    Sleep    2
    Confirm Value    Source Field    npo02__SmallestAmount__c    Y
        