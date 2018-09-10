*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Custom Suite Setup
Suite Teardown  Custom Suite Teardown

*** Keywords ***
Custom Suite Setup
    ${layout} =  Parse XML  src/layouts/Account-Household Layout.layout
    Add Element  ${layout}
    ...            <layoutItems><behavior>Readonly</behavior><field>County__c</field></layoutItems>
    ...            xpath=.//layoutSections[1]/layoutColumns[2]
    Save Xml     ${layout}  
    ...            ${CURDIR}/address_workflow_copycounty/layouts/Account-Household Layout.layout
    Run Task     update_package_xml  
    ...            path=${CURDIR}/address_workflow_copycounty
    ...            package_name=""
    Run Task     deploy
    ...            path=${CURDIR}/address_workflow_copycounty
    Run Task     update_admin_profile
    Open Test Browser
   
Custom Suite Teardown 
    Delete Records and Close Browser
    Remove File     tests/integration/address_workflow_copycounty/layouts/Account-Household Layout.layout
    Run Task Class  cumulusci.tasks.salesforce.UninstallLocal
    ...               path=tests/integration/address_workflow_copycounty

*** Test Cases ***

Insert Default via API
    ${county} =        Set Variable  Test County
    &{account} =       API Create Household
    &{fields}          Create Dictionary
    ...                  County_Name__c=${county}
    ...                  Default_Address__c=true
    &{address} =       API Create Household Address  &{account}[Id]  &{fields}
    &{account} =       Salesforce Get  Account  &{account}[Id]

    Should Be Equal    &{account}[County__c]  ${county}

Insert Not Default via API
    ${county} =        Set Variable  Test County
    &{account} =       API Create Household
    &{fields}          Create Dictionary
    ...                  County_Name__c=${county}
    &{address} =       API Create Household Address  &{account}[Id]  &{fields}
    &{account} =       Salesforce Get  Account  &{account}[Id]

    Should Be Equal    &{account}[County__c]  ${null}

Insert New Default via API
    ${county} =        Set Variable  Test County
    &{account} =       API Create Household
    &{fields}          Create Dictionary
    ...                  County_Name__c=Test Original County
    ...                  Default_Address__c=true
    &{address} =       API Create Household Address  &{account}[Id]  &{fields}
    Set To Dictionary  ${fields}  County_Name__c=${county}
    &{address} =       API Create Household Address  &{account}[Id]  &{fields}
    &{account} =       Salesforce Get  Account  &{account}[Id]

    Should Be Equal    &{account}[County__c]  ${county}

Update County On Default via API
    ${county} =        Set Variable  Test County
    &{account} =       API Create Household
    &{fields}          Create Dictionary
    ...                  County_Name__c=Test Original County
    ...                  Default_Address__c=true
    &{address} =       API Create Household Address  &{account}[Id]  &{fields}
    Salesforce Update  Address__c  &{address}[Id]
    ...                  County_Name__c=${county}
    &{account} =       Salesforce Get  Account  &{account}[Id]

    Should Be Equal    &{account}[County__c]  ${county}