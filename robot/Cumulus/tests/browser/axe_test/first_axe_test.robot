*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Analyze account object home page
    Go To Object Home    Account
    Click Object Button  New
    Select Record Type                     Organization
    Wait until modal is open
    # run axe analysis for the modal on page
    Inject Axe Core Library
    &{acc_results}    Get Axe Analysis Results  cssSelector=div.actionBody > div
    Log Summary Of Results    ${acc_results}
    Warn On Incomplete Rules    ${acc_results}
    Warn On Violations Rules    ${acc_results}
    Go To Object Home    Opportunity
    # run axe analysis for the whole page
    Inject Axe Core Library
    &{results}    Get Axe Analysis Results
    Log Summary Of Results    ${results}
    Warn On Incomplete Rules    ${results}
    Warn On Violations Rules    ${results}
    
    
