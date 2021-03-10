*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Run Keywords
...             Delete Session Records
...             Capture Screenshot and Delete Records and Close Browser

*** Variables ***


*** Keywords ***
Setup Test Data
    ${NS} =  Get NPSP Namespace Prefix
    Set suite variable    ${NS}

    &{CONTACT}=  API Create Contact
    ...          FirstName=${faker.first_name()}
    ...          LastName=${faker.last_name()}
    Store Session Record     Contact     ${CONTACT}[Id]
    Set Suite Variable  &{CONTACT}

*** Test Cases ***

Verify Checkbox to Checkbox Field Mappings Are Successful
  [Documentation]
  [Tags]                                W-8789974    unstable        feature:GE      
  ${template} =                         Generate Random String
  Go to Page                            Landing     GE_Gift_Entry
  Click Link                            Templates
  Click Gift Entry Button               Create Template
  Current Page Should Be                Template                    GE_Gift_Entry
  Enter Value in Field
  ...                                   Template Name=${template}
  ...                                   Description=This is created by automation script 
  Click Gift Entry Button               Next: Form Fields
  Perform Action on Object Field        select   Contact 1  Contact 1 Checkbox To Checkbox
  Perform Action on Object Field        select   Contact 1  Contact 1 Checkbox To Picklist
  Page Should Not Contain Element       //lightning-input[@data-qa-locator="checkbox Required Contact 1: Contact 1 Checkbox To Checkbox"]
  Click Gift Entry Button               Save & Close
  Current Page Should Be                Landing                        GE_Gift_Entry
  Click Link                            Templates
  Wait Until Page Contains              ${template}
  Store Template Record Id              ${template}
  Create Gift Entry Batch               ${template}  ${template} Batch
  Current Page Should Be                Form       Gift Entry   title=Gift Entry Form
  Save Current Record ID For Deletion   ${NS}DataImportBatch__c
  Fill Gift Entry Form
  ...                                   Data Import: Donation Donor=Contact1
  ...                                   Data Import: Contact1 Imported=${CONTACT}[Name]
  Verify Field Default Value             
  ...                                   Contact 1: Contact 1 Checkbox To Picklist=False
  ...                                   Contact 1: Contact 1 Checkbox To Checkbox=
  Fill Gift Entry Form
  ...                                   Contact 1: Contact 1 Checkbox To Picklist=True
  ...                                   Contact 1: Contact 1 Checkbox To Checkbox=true
  Sleep  10
  Click Gift Entry Button               Save & Enter New Gift
  Click Gift Entry Button               Process Batch
  Click Data Import Button              NPSP Data Import                button       Begin Data Import Process
  Wait For Batch To Process             BDI_DataImport_BATCH            Completed
  Go to Page                            Details    Contact    object_id=${CONTACT}[Id]
  Navigate To And Validate Field Value  Contact 1 Checkbox To Checkbox  contains  true
#   Navigate To And Validate Field Value  
#   Go to Page                          DI Batch        Validate Fields
#   Navigate to And Validate Field Value        #Field Info