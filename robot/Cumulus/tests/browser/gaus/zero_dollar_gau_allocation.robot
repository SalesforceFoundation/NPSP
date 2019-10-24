*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Variables
Suite Teardown  Delete Records and Close Browser

*** Keywords ***
API Create Zero Opportunity
    [Arguments]                         ${account_id}                              ${opp_type}              &{fields} 
    ${rt_id} =                          Get Record Type Id                         Opportunity              ${opp_type}
    ${close_date} =                     Get Current Date                           result_format=%Y-%m-%d
    ${opp_id} =                         Salesforce Insert                          Opportunity
    ...                                 AccountId=${account_id}
    ...                                 RecordTypeId=${rt_id}
    ...                                 StageName=Closed Won
    ...                                 CloseDate=${close_date}
    ...                                 Amount=0
    ...                                 Name=Test Donation
    ...                                 &{fields}
    &{opportunity} =                    Salesforce Get                             Opportunity              ${opp_id} 
    [return]                            &{opportunity}  

Setup Variables
    ${ns} =                             Get NPSP Namespace Prefix
    Set Suite Variable                  ${ns}

*** Test Cases ***

Assign GAU to $0 Opportunity
    &{gau} =                            API Create GAU

    @{gausettings} =                    Salesforce Query                           ${ns}Allocations_Settings__c
    ...                                 select=Id,${ns}Default__c,${ns}Default_Allocations_Enabled__c
    Salesforce Update                   ${ns}Allocations_Settings__c               ${gausettings}[0][Id]
    ...                                 ${ns}Default__c=&{gau}[Id]
    ...                                 ${ns}Default_Allocations_Enabled__c=true

    &{contact} =                        API Create Contact                         Email=jjoseph@robot.com
    Store Session Record                Account                                    &{contact}[AccountId]
    &{opportunity} =                    API Create Zero Opportunity                &{Contact}[AccountId]    Donation    Name=Test GAU donation
    Go To Record Home                   &{opportunity}[Id]

    @{gauallocations} =                 Salesforce Query                           ${ns}Allocation__c
    ...                                 select=${ns}General_Accounting_Unit__c
    ...                                 Opportunity__r.id=&{opportunity}[Id]                            
    
    Should Be Equal                     ${gauallocations}[0][${ns}General_Accounting_Unit__c]
    ...                                 &{gau}[Id]