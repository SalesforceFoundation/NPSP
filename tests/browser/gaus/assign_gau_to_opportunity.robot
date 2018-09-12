*** Settings ***

Resource        tests/NPSP.robot
Library    Builtin
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Assign GAU to Opportunity
    ${gau_name1}    Create GAU
    ${gau_name2}    Create GAU
    Go To Object Home    Opportunity
    Click On First Record
    Select Related Dropdown    GAU Allocations
    Click Link    link=Manage Allocations
    Sleep    2
    Select Frame With Title    Manage Allocations
    Select Search    0    ${gau_name1}
    Add GAU Allocation    percentage    0    50
    Click Task Button    Add Row    
    Select Search    1    ${gau_name2} 
    sleep    2   
    Add GAU Allocation    amount    1    20
    Click Save    GAU
    
   