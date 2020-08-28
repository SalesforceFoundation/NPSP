*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***


*** Keywords ***

Setup Test Data
    ${NS} =              Get NPSP Namespace Prefix
    Set suite variable   ${NS}

*** Test Cases ***

Reorder and Modify GE Template Fields
  [Documentation]                       This tests reordering, adding, and deleting sections
  ...                                   from a newly created GE template.

  [tags]                                unstable                    feature:GE          W-039563
  ${template} =                         Generate Random String
  Go to Page                            Landing                     npsp__GE_Gift_Entry
  Click Link                            Templates
  Click Gift Entry Button               Create Template
  Current Page Should Be                Template                    GE_Gift_Entry
  Enter Value in Field
  ...                                   Template Name=${template}
  ...                                   Description=This is created by automation script 
  Click Gift Entry Button               Next: Form Fields

  #Adds 'Role' form field from the AccountSoftCredits section
  Perform Action On Object Field        select                     AccountSoftCredits  Role

  Perform Action On Object Field        select                     CustomObject1  CustomObject1Imported

  #Moves the CustomObject1Imported field up in the field order
  Click Gift Entry Button               button Up Data Import: CustomObject1Imported

  #Deletes the Payment: Check/Reference Number field from the template
  Perform Action On Object Field        unselect                   Payment       Check/Reference Number
  Verify Template Builder               contains                   AccountSoftCredits: Role
  Verify Template Builder               does not contain           Payment: Check/Reference Number
  Click Gift Entry Button               Save & Close
  Current Page Should Be                Landing                    npsp__GE_Gift_Entry
  Click Gift Entry Button               New Batch
  Select Template                       ${template}
  Load Page Object                      Form                       Gift Entry
  Click Button                          Next
  Fill Gift Entry Form
  ...                                   Batch Name=${template}
  ...                                   Batch Description=This is a test batch created via automation script
  Click Gift Entry Button               Next
  Click Gift Entry Button               Save
  Current Page Should Be                Form                        Gift Entry   title=Gift Entry Form 
  # Confirms fields added are present, and deleted fields are not present
  Page Should Contain                   AccountSoftCredits: Role        
  Page Should Not Contain               Check/Reference Number
  ${batch_id} =                         Save Current Record ID For Deletion      ${NS}DataImportBatch__c



 
