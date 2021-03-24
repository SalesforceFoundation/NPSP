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
  ${NS} =  Get NPSP Namespace Prefix
  Set suite variable    ${NS}

Get Template Builder Field Names
  [Documentation]       Gets and stores the text values of template builder form field names in the BUILDER_FIELD_LABELS list.
  ...                   This list is compared to the FORM_FIELD_TITLES list to ensure the names and order of the sections match.
  @{builder_form_fields} =  Return Template Builder Titles  template_builder_fields
  ${BUILDER_FIELD_LABELS} =  Create List

  FOR  ${label}  IN  @{builder_form_fields}
      ${name} =  Get Text  ${label}
      Append to List  ${BUILDER_FIELD_LABELS}  ${name}
  END
  Set Suite Variable  ${BUILDER_FIELD_LABELS}

Get Template Builder Section Names
  [Documentation]       Gets and stores the text values of template builder section names in the BUILDER_S_TITLES list.
  ...                   This list is compared to the FORM_S_TITLES list to ensure the names and order of the sections match.
  @{builder_section_titles} =  Return Template Builder Titles  template_builder_sections
  ${BUILDER_S_TITLES} =  Create List

  FOR  ${label}  IN  @{builder_section_titles}
      ${name} =  Get Text  ${label}
      Append to List  ${BUILDER_S_TITLES}  ${name}
  END
  Set Suite Variable  ${BUILDER_S_TITLES}

Get Gift Entry Form Field Names
  [Documentation]       Gets and stores the text values of gift entry form field names in the FORM_FIELD_LABELS list.
  ...                   This list is compared to the BUILDER_FIELD_LABELS list to ensure the names and order of the sections match.
  @{gift_form_fields} =  Return Gift Form Titles  gift_entry_form_fields
  ${FORM_FIELD_LABELS} =  Create List

  FOR  ${label}  IN  @{gift_form_fields}
      ${name} =  Get Text  ${label}
      Append to List  ${FORM_FIELD_LABELS}  ${name}
  END
  Set Suite Variable  ${FORM_FIELD_LABELS}

Get Gift Entry Form Section Names
  [Documentation]       Gets and stores the text values of gift entry form section names in the FORM_S_TITLES list.
  ...                   This list is compared to the BUILDER_S_TITLES list to ensure the names and order of the sections match.
  @{form_section_titles} =  Return Gift Form Titles  gift_entry_form_sections
  ${FORM_S_TITLES} =  Create List

  FOR  ${label}  IN  @{form_section_titles}
      ${name} =  Get Text  ${label}
      Append to List  ${FORM_S_TITLES}  ${name}
  END
  Set Suite Variable  ${FORM_S_TITLES}

*** Test Cases ***

Reorder and Modify GE Template Fields
  [Documentation]                       Tests adding, deleting, and reordering form fields on the template builder,
  ...                                   and compares the order of the template form fields with the order of the 
  ...                                   gift form in a batch created from that template.
  [tags]                                feature:GE          W-039563
  ${template} =                         Generate Random String
  Go to Page                            Landing                     GE_Gift_Entry
  Click Link                            Templates
  Click Gift Entry Button               Create Template
  Current Page Should Be                Template                    GE_Gift_Entry
  Enter Value in Field
  ...                                   Template Name=${template}
  ...                                   Description=This is created by automation script 
  Click Gift Entry Button               Next: Form Fields
  Click Gift Entry Button               button Settings Gift Entry Form
  Enter Value in Field                  
  ...                                   Section Name=FormSection1
  Click Button                          Save
  Wait Until Element Is Not Visible     Save
  Click Button with Title               Add Section
  Perform Action On Object Field        select                     AccountSoftCredits  Role
  Perform Action On Object Field        select                     CustomObject1  CustomObject1Imported
  Click Gift Entry Button               button Settings New Section
  Enter Value in Field                  
  ...                                   Section Name=FormSection2
  Click Button                          Save
  Wait Until Element Is Not Visible     Save
  Click Gift Entry Button               button Up FormSection2
  Perform Action On Object Field        unselect                   Payment       Check/Reference Number
  Get Template Builder Field Names
  Get Template Builder Section Names
  Click Gift Entry Button               Save & Close
  Current Page Should Be                Landing         GE_Gift_Entry
  Click Link                            Templates
  Wait Until Page Contains              ${template}
  Store Template Record Id              ${template}
  Create Gift Entry Batch               ${template}  ${template} Batch
  Current Page Should Be                Form                        Gift Entry   title=FormSection1 
  Page Should Contain                   AccountSoftCredits: Role        
  Page Should Not Contain               Check/Reference Number
  Get Gift Entry Form Field Names
  Get Gift Entry Form Section Names
  Lists Should Be Equal                 ${BUILDER_FIELD_LABELS}  ${FORM_FIELD_LABELS}
  Lists Should Be Equal                 ${BUILDER_S_TITLES}  ${FORM_S_TITLES}                       
  ${batch_id} =                         Save Current Record ID For Deletion      ${NS}DataImportBatch__c