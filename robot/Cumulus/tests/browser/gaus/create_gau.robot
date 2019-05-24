*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create GAU and Verify
    ${gau_name}    Create GAU
    ${gau_name1}    Get Main Header
    Should be Equal as Strings    ${gau_name1}      ${gau_name} 
