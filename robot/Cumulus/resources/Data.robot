*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Library        Data.py


*** Keywords ***
Assert Query Count Equals
    [Arguments]     ${count}        ${object_name}      &{kwargs}

    @{result} =   Salesforce Query  ${object_name}  
    ...           select=COUNT(Id)
    ...           &{kwargs}

    ${matching_records} =   Set Variable    ${result}[0][expr0]
    Return from keyword If    ${matching_records}==${count}    Success
    Should Be Equal         ${matching_records}     ${count}
