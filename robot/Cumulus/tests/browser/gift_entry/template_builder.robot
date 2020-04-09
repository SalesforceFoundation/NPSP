*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${template}       Robot Template
${new_template}   Robot Copy Template

*** Test Cases ***

Create a template and make changes
    [Documentation]                             
    [tags]                                    feature:GE                     
    #Create Template                             
    Go To Page                                Custom                        GE_Gift_Entry
    Wait Until Page Contains                  Default Gift Entry Template
    Click Gift Entry Button                   Create Template
    Wait Until Page Contains                  Gift Entry Template Information
    Enter Value In Field
    ...                                       Template Name=${template}
    ...                                       Description=This is created by automation script  
    Click Gift Entry Button                   Next: Form Fields
    Click Gift Entry Button                   Next: Batch Header
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Custom                        GE_Gift_Entry
    Page Should Contain                       ${template}
    
    #Clone Template
    Select Template Action                    ${template}                   Clone
    # Save Current Record ID For Deletion       Form_Template__c
    Click Gift Entry Button                   Save & Close
    Wait Until Page Contains                  This name has been used by another template. Please enter a unique name.
    Enter Value In Field                      Template Name=${new_template}
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Custom                        GE_Gift_Entry
    Page Should Contain                       ${new_template}
    
    #Delete Template
    Select Template Action                    ${new_template}               Delete
    Wait Until Page Does not Contain          ${new_template}
