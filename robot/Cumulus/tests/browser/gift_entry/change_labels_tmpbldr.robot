*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${TEMPLATE}       Labels Template
&{DATE}           Field Label=Closed Date
&{CAMPAIGN}       Field Label=Campaign
&{PAY}            Field Label=Check Number
&{RECORD_TYPE}    Field Label=Record Type


*** Test Cases ***

Verify Mapped Field Is Available For Batch Template
    # [Documentation]                         Create a custom field on opportunity and npsp data import objects. Create advanced mapping to these fields.
    # ...                                     Verify that the mapped field is available for selection while creating a new template and once selected, its avialble on newly created batch gift form
    # ...                                     Remove field from template, delete mapping and verify that the new field is not avaialable for selection while creating template.  
    [tags]                                  unstable      feature:GE                    W-042499   
    #Create new template with new field labels                            
    Go To Page                              Landing                         GE_Gift_Entry         
    Click Link                              Templates
    Click Gift Entry Button                 Create Template
    Current Page Should Be                  Template                        GE_Gift_Entry
    Enter Value In Field
    ...                                     Template Name=${TEMPLATE}
    ...                                     Description=This is created by automation script  
    Click Gift Entry Button                 Next: Form Fields
    Perform Action On Object Field          select                          Opportunity           Record Type ID
    Fill Template Form                      
    ...                                     Opportunity: Close Date=&{DATE}
    ...                                     Opportunity: Campaign ID=&{CAMPAIGN}
    ...                                     Payment: Check/Reference Number=&{PAY}
    ...                                     Opportunity: Record Type ID=&{RECORD_TYPE} 
    Click Gift Entry Button                 Next: Batch Settings
    Add Batch Table Columns                 Campaign                        Check Number          Record Type
    Click Gift Entry Button                 Save & Close
    Current Page Should Be                  Landing                         GE_Gift_Entry
    Click Link                              Templates
    Wait Until Page Contains                ${TEMPLATE}
    Store Template Record Id                ${TEMPLATE}
    #Verify new field labels are displayed on newly created batch with new template
    Click Gift Entry Button                 New Batch
    Wait Until Modal Is Open
    Select Template                         ${TEMPLATE}
    Load Page Object                        Form                            Gift Entry
    Fill Gift Entry Form
    ...                                     Batch Name=Field Labels Automation Batch
    ...                                     Batch Description=This is a test batch created via automation script
    Click Gift Entry Button                 Next
    Click Gift Entry Button                 Save
    Current Page Should Be                  Form                            Gift Entry            title=Gift Entry Form
    ${batch_id} =                           Save Current Record ID For Deletion     ${ns}DataImportBatch__c
    # Wait Until Page Contains                Test Mapping
    