*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***

Setup Test Data
    [Documentation]     Setsup namespace prefix
    ${ns} =  Get NPSP Namespace Prefix
    Set suite variable    ${ns}

Get Template Builder Field Names
  @{BUILDER_FORM_FIELDS} =  Return Template Builder Titles  template_builder_fields
  ${BUILDER_FIELD_LABELS} =  Create List

  FOR  ${LABEL}  IN  @{BUILDER_FORM_FIELDS}
      ${NAME} =  Get Text  ${LABEL}
      Append to List  ${BUILDER_FIELD_LABELS}  ${name}
  END
  Set Suite Variable  ${BUILDER_FIELD_LABELS}

Get Template Builder Section Names
  @{BUILDER_SECTION_TITLES} =  Return Template Builder Titles  template_builder_sections
  ${BUILDER_S_TITLES} =  Create List

  FOR  ${LABEL}  IN  @{BUILDER_SECTION_TITLES}
      ${NAME} =  Get Text  ${LABEL}
      Append to List  ${BUILDER_S_TITLES}  ${NAME}
  END
  Set Suite Variable  ${BUILDER_S_TITLES}

Get Gift Entry Form Field Names
  @{GIFT_FORM_FIELDS} =  Return Gift Form Titles  gift_entry_form_fields
  ${FORM_FIELD_LABELS} =  Create List

  FOR  ${LABEL}  IN  @{GIFT_FORM_FIELDS}
      ${NAME} =  Get Text  ${LABEL}
      Append to List  ${FORM_FIELD_LABELS}  ${NAME}
  END
  Set Suite Variable  ${FORM_FIELD_LABELS}

Get Gift Entry Form Section Names
  @{FORM_SECTION_TITLES} =  Return Gift Form Titles  gift_entry_form_sections
  ${FORM_S_TITLES} =  Create List

  FOR  ${LABEL}  IN  @{FORM_SECTION_TITLES}
      ${NAME} =  Get Text  ${LABEL}
      Append to List  ${FORM_S_TITLES}  ${NAME}
  END
  Set Suite Variable  ${FORM_S_TITLES}

*** Test Cases ***

Reorder and Modify GE Template Fields
  [Documentation]                       Tests adding, deleting, and reordering form fields on the template builder,
  ...                                   and compares the order of the template form fields with the order of the 
  ...                                   gift form in a batch created from that template.
  [tags]                                unstable                    feature:GE          W-039563
  ${TEMPLATE} =                         Generate Random String
  Go to Page                            Landing                     GE_Gift_Entry
  Click Link                            Templates
  Click Gift Entry Button               Create Template
  Current Page Should Be                Template                    GE_Gift_Entry
  Enter Value in Field
  ...                                   Template Name=${TEMPLATE}
  ...                                   Description=This is created by automation script 
  Click Gift Entry Button               Next: Form Fields
  Click Gift Entry Button               button Settings Gift Entry Form
  Enter Value in Field                  
  ...                                   Section Name=FormSection1
  Click Button                          Save
  Wait Until Element Is Not Visible     Save
  Click Button with Title                          Add Section
  Perform Action On Object Field        select                     AccountSoftCredits  Role
  Perform Action On Object Field        select                     CustomObject1  CustomObject1Imported
  Click Gift Entry Button               button Settings New Section
  Enter Value in Field                  
  ...                                   Section Name=FormSection2
  Click Button                          Save
  Wait Until Element Is Not Visible     Save
  # Scroll Page To Location               0  900
  Click Gift Entry Button               button Up FormSection2
  Perform Action On Object Field        unselect                   Payment       Check/Reference Number
  #Gets names of template builder sections and fields and stores them in a list
  Get Template Builder Field Names
  Get Template Builder Section Names
  Click Gift Entry Button               Save & Close
  Current Page Should Be       Landing         GE_Gift_Entry
  Click Link                   Templates
  Wait Until Page Contains     ${TEMPLATE}
  Store Template Record Id     ${TEMPLATE}
  Create Gift Entry Batch               ${TEMPLATE}  ${TEMPLATE} Batch
  Current Page Should Be                Form                        Gift Entry   title=FormSection1 
  Page Should Contain                   AccountSoftCredits: Role        
  Page Should Not Contain               Check/Reference Number
  #Gets names of form sections and fields, stores them in a list, and compares the order to the template builder page's list
  Get Gift Entry Form Field Names
  Get Gift Entry Form Section Names
  Lists Should Be Equal                 ${BUILDER_FIELD_LABELS}  ${FORM_FIELD_LABELS}
  Lists Should Be Equal                 ${BUILDER_S_TITLES}  ${FORM_S_TITLES}                       
  ${BATCH_ID} =                         Save Current Record ID For Deletion      ${ns}DataImportBatch__c