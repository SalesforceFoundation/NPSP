*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/DataImportPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Variables
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/DataImportPageObject.py
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${first_name1} =           Generate Random String
    Set suite variable    ${first_name1}
    ${last_name1} =            Generate Random String
    Set suite variable    ${last_name1}
    ${acc1}=                   Generate Random String
    Set suite variable    ${acc1}
    ${first_name2} =           Generate Random String
    Set suite variable    ${first_name2}
    ${last_name2} =            Generate Random String
    Set suite variable    ${last_name2}
    ${acc2}=                   Generate Random String
    Set suite variable    ${acc2}
    ${org_ns} =  Get Org Namespace Prefix
    Set suite variable    ${org_ns}
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    Set suite variable    ${date}
    ${ns} =  Get NPSP Namespace Prefix
    Set suite variable    ${ns}

*** Test Cases ***

Create Data Import Via API
    [tags]      quadrant:q3
    &{data_import} =  API Create DataImport
    ...        ${ns}Account1_Name__c=${acc1}
    ...        ${ns}Account2_Name__c=${acc2}
    ...        ${ns}Contact1_Firstname__c=${first_name1}
    ...        ${ns}Contact1_Lastname__c=${last_name1}
    ...        ${ns}Contact2_Firstname__c=${first_name2}
    ...        ${ns}Contact2_Lastname__c=${last_name2}
    ...        ${ns}Home_Street__c=123 automation street
    ...        ${ns}Home_City__c=Toledo
    ...        ${ns}Home_State_Province__c=Ohio
    ...        ${ns}Home_Zip_Postal_Code__c=94326
    ...        ${org_ns}custom_acc_text__c=automation
    ...        ${org_ns}Custom_add_date__c=${date}
    ...        ${org_ns}custom_cont_num__c=9876543210
    Set Global Variable     &{data_import}       &{data_import}
    # Navigating to the NPSP Settings page as a workaround for the DML error.
    # will remove below line once this W-8119513 in GUS is fixed
    Go To Page        Custom        NPSP_Settings
    Go To Page        Listing       DataImport__c
    Change View To    To Be Imported
    Page Should Contain Link    ${data_import}[Name]
    Click Special Object Button       Start Data Import
    Wait For Locator    frame    NPSP Data Import
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value   Close

Verify Custom Fields on Account Contact and Address Objects
    [tags]      quadrant:q3
    &{data_import_new} =     Salesforce Get  ${ns}DataImport__c  ${data_import}[Id]
    Verify Expected Values    nonns    Account    ${data_import_new}[${ns}Account1Imported__c]
    ...    Name=${acc1}
    ...    ${org_ns}custom_acc_text__c=automation
    Verify Expected Values    nonns    Account    ${data_import_new}[${ns}Account2Imported__c]
    ...    Name=${acc2}
    ...    ${org_ns}custom_acc_text__c=None
    Verify Expected Values    nonns    Contact    ${data_import_new}[${ns}Contact1Imported__c]
    ...    FirstName=${first_name1}
    ...    LastName=${last_name1}
    ...    ${org_ns}custom_cont_num__c=None
    Verify Expected Values    nonns    Contact    ${data_import_new}[${ns}Contact2Imported__c]
    ...    FirstName=${first_name2}
    ...    LastName=${last_name2}
    ...    ${org_ns}custom_cont_num__c=9876543210.0
    Verify Expected Values    nonns    ${ns}Address__c    ${data_import_new}[${ns}HomeAddressImported__c]
    ...        ${org_ns}Custom_add_date__c=${date}
    ...        ${ns}MailingStreet__c=123 automation street
    ...        ${ns}MailingCity__c=Toledo
    ...        ${ns}MailingState__c=Ohio
    ...        ${ns}MailingPostalCode__c=94326