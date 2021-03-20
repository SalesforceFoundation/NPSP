*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${template}       Robot Template
${new_template}   Robot Copy Template

*** Test Cases ***

Create Clone and Delete Template
    [Documentation]                           Create a Template and verify template shows up in gift entry landing page. 
    ...                                       Clone the template and verify that template name has to be unique.
    ...                                       Delete Template and verify that template is not avaialable for selection while creating a batch.  
    [tags]                                    feature:GE                    W-039556                unstable           notonfeaturebranch
    #Create Template                             
    Go To Page                                Landing                        GE_Gift_Entry
    Click Link                                Templates
    Click Gift Entry Button                   Create Template
    Current Page Should Be                    Template                      GE_Gift_Entry
    Enter Value In Field
    ...                                       Template Name=${template}
    ...                                       Description=This is created by automation script  
    Click Gift Entry Button                   Next: Form Fields
    Click Gift Entry Button                   Next: Batch Settings
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing                        GE_Gift_Entry
    Click Link                                Templates
    Wait Until Page Contains                  ${template}
    Store Template Record Id                  ${template}
    
    #Clone Template
    Select Template Action                    ${template}                   Clone
    Click Gift Entry Button                   Save & Close
    Sleep                                     3
    Wait Until Page Contains                  This name has been used by another template. Please enter a unique name.
    Enter Value In Field                      Template Name=${new_template}
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing                        GE_Gift_Entry
    Click Link                                Templates
    Wait Until Page Contains                  ${new_template}
    
    #Delete Template
    Select Template Action                    ${new_template}               Delete
    Click Button                              New Batch
    Wait Until Modal Is Open
    Verify Template Is Not Available          ${new_template}

