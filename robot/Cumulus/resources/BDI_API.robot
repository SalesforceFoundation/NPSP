*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Resource       robot/Cumulus/resources/Data.robot


*** Keywords ***
Collect BDI Failures
    @{failures} =   Salesforce Query  DataImport__c
    ...           select=Id,Status__c,FailureInformation__c, PaymentImported__c, PaymentImportStatus__c
    ...           Status__c=Failed
    Return From Keyword   @{failures}

Ensure Custom Metadata Was Deployed
    ${Default_Object_Mapping_Set} =   Salesforce Query  Data_Import_Object_Mapping__mdt
    ...           select=Id
    ...           Data_Import_Object_Mapping_Set__r.DeveloperName=Default_Object_Mapping_Set
    ${Default_Object_Mapping_Set_Length} =  Get Length  ${Default_Object_Mapping_Set}

    ${Migrated_Custom_Object_Mapping_Set} =   Salesforce Query  Data_Import_Object_Mapping__mdt
    ...           select=Id
    ...           Data_Import_Object_Mapping_Set__r.DeveloperName=Migrated_Custom_Object_Mapping_Set
    ${Migrated_Custom_Object_Mapping_Set_Length} =  Get Length  ${Migrated_Custom_Object_Mapping_Set}

    Should Be Equal     ${Default_Object_Mapping_Set_Length}    ${Migrated_Custom_Object_Mapping_Set_Length}

    Python Display      Custom Metadata Deployed        ${Migrated_Custom_Object_Mapping_Set_Length}
