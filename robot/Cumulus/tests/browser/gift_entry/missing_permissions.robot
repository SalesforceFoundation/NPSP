*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Run Keywords
...             Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${NS} =            Get NPSP Namespace Prefix
${profile_name} =  SystemAdministrator2
${user_alias} =  Generate Random String

*** Keywords ***

Get Field ID
  [Arguments]             ${profile_name}       ${object_name}       ${field_name}
  &{result} =             Soql Query  SELECT Id, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE parentId IN ( SELECT id FROM permissionset WHERE PermissionSet.Profile.Name = '${profile_name}') AND SobjectType='${object_name}' AND Field='${field_name}'         
  ${Id} =                 Get From List  ${result}[records]  0
  Set Suite Variable  ${Id}


Setup Test Data

  &{PROFILE_DATA} =  API Query Record  ${ns}Profile  Name=System Administrator
  Set Suite Variable  &{PROFILE_DATA}

  ${CLONED_SYSADMIN_PROFILE} =  Salesforce Insert  ${ns}Profile  
  ...       Name=${profile_name} 
  ...       &{PROFILE_DATA}
  Set Suite Variable  ${CLONED_SYSADMIN_PROFILE}

  ${USER} =  Salesforce Insert  ${ns}User
  ...       FirstName=Test
  ...       LastName=User
  ...       ProfileId=${CLONED_SYSADMIN_PROFILE}
  ...       Alias=${user_alias}
  ...       #set license
  Set Suite Variable  ${USER}

  ${FORM_TEMPLATE_DESCRIPTION_ID} =  Get Field ID  ${profile_name}  Form_Template__c  Form_Template__c.Description__c
  Set Suite Variable  ${FORM_TEMPLATE_DESCRIPTION_ID}

  ${DI_BATCH_DESCRIPTION_ID} =  Get Field ID  ${profile_name}  Data_Import_Batch__c  Data_Import_Batch__c.Batch_Description__c
  Set Suite Variable  ${DI_BATCH_DESCRIPTION_ID}



*** Test Cases ***

# Verify Permissions Error When Missing NPSP DI Batch Object Access

#   # Salesforce Update  ${ns}Profile  ${CLONED_SYSADMIN_PROFILE}
#   # ...               #fields
#   Open Test Browser  useralias=${user_alias}
#   Go to Page   Landing    GE_Gift_Entry
#   Validate Error Message  #arg1  #arg2



# Verify Permissions Error When Missing Form Template Object Access


Verify Permissions Error When DI Batch Description is Revoked

  Salesforce Update         ${NS}FieldPermissions  ${Id}[Id]
  ...                       PermissionsRead=false
  ...                       PermissionsEdit=false
  Open Test Browser         useralias=${user_alias}
  Go to Page                Landing    GE_Gift_Entry
  # Validate Error Message    error
  # ...                   
  Salesforce Update         ${NS}FieldPermissions  ${DI_BATCH_DESCRIPTION_ID}
  ...                       PermissionsRead=true
  ...                       PermissionsEdit=true    


#Verify Permissions Error When Form Template Description is Revoked




