*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Analyze account object home page
    Inject Axe Core Library
    Go To Object Home    Account
    Inject Axe Core Library
    &{acc_results}    Get Axe Analysis Results
    Log Summary Of Results    ${acc_results}
    Warn On Incomplete Rules    ${acc_results}
    Go To Object Home    Opportunity
    Inject Axe Core Library
    &{results}    Get Axe Analysis Results
    Log Summary Of Results    ${results}
    Warn On Incomplete Rules    ${results}
    Fail If There Are Violations    ${results}
    
    
