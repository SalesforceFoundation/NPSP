*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/AdvancedMappingPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
  #Create fields to be mapped
  Create Customfield In Object Manager
  ...                                                    Object=Lead
  ...                                                    Field_Type=Lookup
  ...                                                    Related_To=Account
  ...                                                    Field_Name=Account Lookup

  Create Customfield In Object Manager
  ...                                                    Object=NPSP Data Import
  ...                                                    Field_Type=Text
  ...                                                    Field_Name=Lead Imported Status

  Create Customfield In Object Manager
  ...                                                    Object=NPSP Data Import
  ...                                                    Field_Type=Text
  ...                                                    Field_Name=Lead Company

  Create Customfield In Object Manager
  ...                                                    Object=NPSP Data Import
  ...                                                    Field_Type=Text
  ...                                                    Field_Name=Lead Last Name

  Create Customfield In Object Manager
  ...                                                    Object=NPSP Data Import
  ...                                                    Field_Type=Lookup
  ...                                                    Related_To=Lead
  ...                                                    Field_Name=Lead Lookup

  #Create lead record with first name, last name, and company name
  &{opp_lead} =                                         API Create Lead
  ...                                                     FirstName=${faker.first_name()}
  ...                                                     LastName=${faker.last_name()}
  ...                                                     Company=Generated Leads, Inc.


  ${template_name} =                                    Generate Random String
  Set suite variable                                    ${template_name}


*** Test Cases ***
Verify Fields Related to Lookups Populate on Batch Gift Entry Form
  [Documentation]                                       To be filled in
  ...                                                   at a later date.
  [tags]                                                unstable      feature:GE        W-043224
  #Create field mappings in Advanced Mapping
  Click Configure Advanced Mapping
  Create New Object Group                               Lead
  ...                                                   objectName=Lead (Lead)
  ...                                                   relationshipToPredecessor=Child
  ...                                                   ofThisMappingGroup=Account 1
  ...                                                   throughThisField=Account Lookup (Account_Lookup__c)
  ...                                                   importedRecordFieldName=Lead Lookup (Lead_Lookup__c)
  ...                                                   importedRecordStatusFieldName=Lead Imported Status (Lead_Imported_Status__c)
  View Field Mappings Of The Object                     Lead
  Create Mapping If Doesnt Exist                        Lead Company (Lead_Company__c)  Company ()
  Reload Page
  Create Mapping If Doesnt Exist                        Lead Last Name (Lead_Last_Name__c)  Last Name ()
  Go To Page                                            Landing                GE_Gift_Entry
  Click Link                                            Templates
  Click Gift Entry Button                               Create Template
  Current Page Should Be                                Template               GE_Gift_Entry
  Enter Value In Field
  ...                                                   Template Name=${template_name}
  ...                                                   Description=This template is created by an automation script.
  Click Gift Entry Button                               Next: Form Fields
  Perform Action on Object Field                        select  Lead           Lead Lookup
  Perform Action on Object Field                        select  Lead           Lead Company
  Perform Action on Object Field                        select  Lead           Lead Last Name