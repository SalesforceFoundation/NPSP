*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Variables
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser


*** Keywords ***
API Create Zero Opportunity
    [Arguments]                         ${account_id}                       ${opp_type}              &{fields} 
    ${rt_id} =                          Get Record Type Id                  Opportunity              ${opp_type}
    ${close_date} =                     Get Current Date                    result_format=%Y-%m-%d
    ${opp_id} =                         Salesforce Insert                   Opportunity
    ...                                 AccountId=${account_id}
    ...                                 RecordTypeId=${rt_id}
    ...                                 StageName=Closed Won
    ...                                 CloseDate=${close_date}
    ...                                 Amount=0
    ...                                 Name=Test Donation
    ...                                 npe01__Do_Not_Automatically_Create_Payment__c=true 
    ...                                 &{fields}
    &{opportunity} =                    Salesforce Get                      Opportunity              ${opp_id} 
    [return]                            &{opportunity}  


Setup Variables
    ${ns} =                             Get NPSP Namespace Prefix
    Set Suite Variable                  ${ns}

Setup Test Data
    &{gau1} =                           API Create GAU
    &{contact} =                        API Create Contact                  Email=skristem@robot.com
    Store Session Record                Account                             &{contact}[AccountId]
    &{opportunity} =                    API Create Zero Opportunity         &{Contact}[AccountId]    Donation    Name=Test GAU donation



*** Test Cases ***

Assign GAU to $0 Opportunity
    [tags]  unstable

    Go To Record Home                    &{opportunity}[Id]
    Select Tab                           Related
    Click Special Related List Button    GAU Allocations                    Manage Allocations
    Wait For Locator                     frame                              Manage Allocations
    Choose Frame                         Manage Allocations
    Select Search                        General Accounting Unit 0          &{gau1}[Name]
    Add GAU Allocation                   Percent 0                          100
    Click Link                           Add Row
    Click Button                         Save
    Wait Until Page Does Not Contain     Add Row
    Select Window
    Page Scroll To Locator               record.related.check_occurrence    GAU Allocations
    Verify Occurrence                    GAU Allocations                    2
