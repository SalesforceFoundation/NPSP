*** Variables ***
${database_url} =    
${persistent_org} = 

# tests won't work if there are records of these types in existence.
${core_objs_for_cleanup} =  DataImport__c,CustomObject3__c,CustomObject1__c
# you could also clean these up to have a cleaner test
${other_objs_for_cleanup} =   Opportunity,Account,Contact,CustomObject1__c,MaintenancePlan,General_Accounting_Unit__c,WorkOrder,npe01__OppPayment__c
${cleanup_first} =   core   # could also be "all" for maximum cleanliness or "none" for fresh scratch orgs
${data_generation_task} =     Set Variable If         "${field_mapping_method}"=="Help Text"  tasks.generate_bdi_data.generate_bdi_data         tasks.generate_bdi_CO_data.GenerateBDIData_CO

*** Settings ***

Resource  cumulusci/robotframework/CumulusCI.robot
Resource        robot/Cumulus/resources/NPSP.robot
Resource        robot/Cumulus/resources/Data.robot
Resource        robot/Cumulus/resources/BDI_API.robot
Suite Setup       Workaround Bug

*** Keywords ***
Clear Generated Records
    Python Display  Clearing Generated Records
    Delete     DataImport__c, CustomObject1__c, CustomObject2__c, CustomObject3__c
    Delete     Account_Soft_Credit__c     where=Account__r.BillingCountry\='Tuvalu'    hardDelete=True
    Delete     Allocation__c        where=Opportunity__r.Account.BillingCountry\='Tuvalu'
    Delete     npe01__OppPayment__c     where=npe01__Opportunity__r.Account.BillingCountry\='Tuvalu'    hardDelete=True
    Delete     Opportunity     where=Account.BillingCountry\='Tuvalu'    hardDelete=True
    Delete     Account     where=BillingCountry\='Tuvalu'    hardDelete=True
    Delete     Contact     where=Title\='HRH'    hardDelete=True

Generate Data
    [Arguments]    ${count}
    ${count} =  Convert To Integer	${count}

    Run Task Class   tasks.generate_and_load_data.GenerateAndLoadData
    ...                 num_records=${count}
#    ...                 database_url=sqlite:////tmp/temp_db.db  # turn this on to look at the DB for debugging
    ...                 mapping=datasets/bdi_benchmark/mapping-CO.yml
    ...                 data_generation_task=${data_generation_task}

Setup BDI
    [Arguments]     ${field_mapping_method}
    Configure BDI     ${field_mapping_method}

    Run Keyword If    '${field_mapping_method}'=='Data Import Field Mapping'
    ...               Ensure Custom Metadata Was Deployed

Report BDI
    @{result} =   Salesforce Query  DataImport__c  
    ...           select=COUNT(Id)
    ...           Status__c=Imported

    ${imported_records} =   Set Variable    ${result}[0][expr0]

    Python Display  DataImport__c imported    ${result}[0][expr0]

    @{result} =   Salesforce Query  CustomObject3__c  
    ...           select=COUNT(Id)

    Python Display  CustomObject3__c imported    ${result}[0][expr0]

    @{result} =   Salesforce Query  Account  
    ...           select=COUNT(Id)
    ...           BillingCountry=Tuvalu

    Python Display  Accounts imported    ${result}[0][expr0]

    @{result} =   Salesforce Query  Contact  
    ...           select=COUNT(Id)
    ...           Title=HRH

    Python Display  Contacts imported    ${result}[0][expr0]

Display Failures
    @{failures} =   Collect BDI Failures
    ${length} =  Get Length  ${failures}
    Run Keyword If  ${length} == 0  Log to Console  No failure records
    Return From Keyword If       ${length}==0        False

    Python Display      Failures   ${length}

    Python Display      Example Failure   Id: ${failures[0]['Id']}
    ...                                   Status__c: ${failures[0]['Status__c']}
    ...                                   PaymentImported__c: ${failures[0]['PaymentImported__c']}
    ...                                   PaymentImportStatus__c: ${failures[0]['PaymentImportStatus__c']}
    ...                                   FailureInformation__c: ${failures[0]['FailureInformation__c']}

Workaround Bug
    Return From Keyword If      ${persistent_org}   # persistent orgs don't have this bug
    Generate Data   4
    Setup BDI       Data Import Field Mapping
    Batch Data Import   1000

Validate Data
    [Arguments]     ${count}
    ${success} =    Assert Row Count    ${count}     DataImport__c       Status__c=Imported
    Run Keyword Unless   "${success}"=="Success"      Display Failures
    # double-check
    ${success} =    Assert Row Count    ${count}     CustomObject3__c
    Run Keyword Unless   "${success}"=="Success"      Display Failures

Reset Everything
    [Arguments]                 ${count}    ${bdi_mode}
    Clear Generated Records
    Setup BDI                   ${bdi_mode}
    Generate Data               ${count}

*** Test Cases ***
BGE/BDI Import - 20000 /250
    [Setup]     Reset Everything    20000    Data Import Field Mapping
    [Teardown]     Validate Data      20000
    Batch Data Import   250
