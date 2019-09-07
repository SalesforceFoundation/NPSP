*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Library        Data.py


*** Keywords ***
Assert Row Count
    [Arguments]     ${count}        ${object_name}      &{kwargs}

    ${status}     ${result} =   Run Keyword And Ignore Error
    ...           Salesforce Query  ${object_name}  
    ...           select=COUNT(Id)
    ...           &{kwargs}

    Run Keyword if      '${status}' != 'PASS'
    ...           Python Display    
    ...           Salesforce query failed: probably timeout. ${object_name}    @{result}

    Return from keyword If    '${status}' != 'PASS'    ${status}

    ${matching_records} =   Set Variable    ${result}[0][expr0]
    Return from keyword If    ${matching_records}==${count}    PASS
    Should Be Equal         ${matching_records}     ${count}

Row Count
    [Arguments]     ${object_name}      &{kwargs}

    ${status}     @{result} =   Run Keyword And Ignore Error
    ...           Salesforce Query  ${object_name}  
    ...           select=COUNT(Id)
    ...           &{kwargs}

    Return From Keyword If    '${status}' != 'PASS'    ${status}

    ${matching_records} =   Set Variable    ${result}[0][expr0]

    Return From Keyword     ${matching_records}
