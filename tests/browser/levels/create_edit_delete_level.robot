*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${level_name}

*** Test Cases ***

Create Level and Verify
    ${level_id}  ${level_name}     Create Level
    Set Global Variable      ${level_name}
    Go To Record Home         ${level_id}
    Confirm Value    Minimum Amount (>=)    0.10    Y
    Confirm Value    Maximum Amount (<)     0.90    Y

Edit Level and Verify
    Click Link    link=Show more actions
    Click Link    link=Edit
    Select Frame With Title    Levels
    Enter Level Dd Values    Source Field    Smallest Gift
    Enter Level Values
    ...            Minimum Amount=0.01
    ...            Maximum Amount=0.99
    Set Focus To Element   xpath: //input[@value='Save']
    Click Button  Save
    Unselect Frame
    Wait For Locator  breadcrumb  Level
    Reload Page
    Wait Until Loading Is Complete
    Confirm Value    Minimum Amount (>=)    0.01    Y
    Confirm Value    Maximum Amount (<)     0.99    Y
    Confirm Value    Source Field    npo02__SmallestAmount__c    Y

Validate Level Batch Job 1
    &{contact} =  API Create Contact
    Go To Record Home       &{contact}[Id]
    Select Tab              Details
    # Scroll down so elements aren't hidden behind the footer
    Scroll Page To Location    0    1000
    Click Edit Button    Edit Smallest Gift
    Populate Form
    ...                    Smallest Gift=0.75
    Click Record Button    Save
    Wait Until Loading Is Complete
    Run Task    execute_anon
    ...         apex=LVL_LevelAssign_SCHED sched = new LVL_LevelAssign_SCHED(); sched.runBatch();
    Run Task    batch_apex_wait
    ...         class_name=LVL_LevelAssign_BATCH
    Go To Record Home       &{contact}[Id]
    Select Tab    Details
    Verify Field Value    Level    ${level_name}    Y
    ## Validate Level Batch Job 2
    Scroll Page To Location    0    1000
    Click Edit Button    Edit Smallest Gift
    Populate Form
    ...                    Smallest Gift=2.0
    Click Record Button    Save
    Wait Until Loading Is Complete
    Run Task    execute_anon
    ...         apex=LVL_LevelAssign_SCHED sched = new LVL_LevelAssign_SCHED(); sched.runBatch();
    Run Task    batch_apex_wait
    ...         class_name=LVL_LevelAssign_BATCH
    Go To Record Home       &{contact}[Id]
    Select Tab    Details
    Confirm Value    Level             ${level_name}    N
    Verify Field Value    Previous Level    ${level_name}    Y
    Click Link    link=${level_name}
    Click Link    link=Show more actions
    Click Link    link=Delete
    Click Modal Button    Delete
    Go To Record Home       &{contact}[Id]
    Select Tab    Details
    Confirm Value    Level    ${level_name}    N
