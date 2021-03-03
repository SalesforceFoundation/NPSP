*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
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
    ${ns} =  Get NPSP Namespace Prefix
    Set suite variable    ${NS}

    &{CONTACT}=  API Create Contact
    ...          FirstName=${faker.first_name()}
    ...          LastName=${faker.last_name()}
    Store Session Record     Contact     ${contact1}[Id]
    Set Suite Variable  &{CONTACT}

*** Test Cases ***

Verify Checkbox to Checkbox Field Mappings Are Successful
  [Documentation]
  [Tags]                                unstable        feature:GE      
  ${template} =                         Generate Random String
  Go to Page                            Landing     GE_Gift_Entry
  Click Link                            Templates
  Click Gift Entry Button               Create Template
  Current Page Should Be                Template                    GE_Gift_Entry
  Enter Value in Field
  ...                                   Template Name=${template}
  ...                                   Description=This is created by automation script 
  Click Gift Entry Button               Next: Form Fields
  Perform Action on Object Field        select   Contact 1  Checkbox To Checkbox
  #Page Should Not Contain               <checkbox required checkbox>
  Perform Action on Object Field        select   Contact 1  Checkbox To Picklist
  Click Gift Entry Button               Save & Close
  # deleting template
  Click Gift Entry Button               Save & Close
  Current Page Should Be                Landing                        GE_Gift_Entry
  Click Link                            Templates
  Wait Until Page Contains              ${template}
  Store Template Record Id              ${template}
  Create Gift Entry Batch               ${template}  ${template} Batch
  Current Page Should Be                Form       Gift Entry
  Fill Gift Entry Form
  ...                                   Donor Type=Contact1
  ...                                   Existing Donor Contact=&{CONTACT}
  ...                                   Donation Amount=1
  ...                                   Donation Date=Today
  Click Gift Entry Button               Save