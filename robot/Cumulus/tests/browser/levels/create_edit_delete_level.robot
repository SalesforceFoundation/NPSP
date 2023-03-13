*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/LevelsPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser


*** Variables ***
&{contact_fields}           Email=test@example.com
${min_amount}  0.10
${max_amount}  0.90
${minamount_to_edit}  0.01
${maxamount_to_edit}  0.99
${contact_smallestvalue}  0.75
${contact_smallestvalue_2}  2.0
${level_name}   AutomationLevel

*** Test Cases ***

Create and edit level to verify fields
    [Documentation]                      Create a level and verify the fields on the created level details page
    ...                                  Edit the level details and update the fields. Verify the updated fields
    ...                                  are persisted on the details page.
    [tags]                               feature:Levels     api     quadrant:q3

    Go To Page                                       Listing                            Level__c
    Navigate To Level Page                           create

    Enter Level Values
    ...                                                 Level Name=AutomationLevel
    ...                                                 Minimum Amount=${min_amount}
    ...                                                 Maximum Amount=${max_amount}
    Enter Level Dd Values
    ...                                                 Target=Contact
    ...                                                 Source Field=Smallest Gift
    ...                                                 Level Field=Level
    ...                                                 Previous Level Field=Previous Level
    Click Button                                        Save
    Current Page Should be                              Details    Level__c
    ${level_id} =                                       Save Current Record ID For Deletion  Level__c
    Set Global Variable                                 ${level_id}
    Go To Page                                          Details
        ...                                             Level__c
        ...                                             object_id=${level_id}

    Wait Until Loading Is Complete
    Navigate To And Validate Field Value                Minimum Amount (>\=)    contains    ${min_amount}
    Navigate To And Validate Field Value                Maximum Amount (<)      contains    ${max_amount}
    Go To Page                                          Listing                            Level__c
    Navigate To Level Page                              edit
    Enter Level Values
    ...                                                 Minimum Amount=${minamount_to_edit}
    ...                                                 Maximum Amount=${maxamount_to_edit}
    Enter Level Dd Values
    ...                                                 Source Field=Smallest Gift

    Click Button                                        Save
    Wait For Locator Is Not Visible                     frame                             Levels

    Go To Page                                          Details
    ...                                                 Level__c
    ...                                                 object_id=${level_id}

    Wait Until Loading Is Complete
    Navigate To And Validate Field Value    Minimum Amount (>\=)   contains       ${minamount_to_edit}
    Navigate To And Validate Field Value    Maximum Amount (<)     contains       ${maxamount_to_edit}
    Navigate To And Validate Field Value    Source Field           contains       npo02__SmallestAmount__c


2 Validate Level Assignment in Batch Job With SmallestAmount Value within level threshold limit and with a value above the threshold
    [Documentation]                      Create a contact, edit the smallgift field value to apply a valid
    ...                                  level that is within the limit values by running the batch process
    ...                                  Edit the smallestAmount value to a value greater than the limit threshold
    ...                                  Run the batch job and verify the correct levels are applied.

    [tags]                                  feature:Levels   api
    # --------------------------------
    # update the SmallestGift field value to allow the level to be applied
    # --------------------------------
    Setupdata                               contact                   contact_data=${contact_fields}
    Set Global Variable                     ${data}

    Salesforce Update                       Contact                   ${data}[contact][Id]  npo02__SmallestAmount__c=${contact_smallestvalue}
    Go To Page                              Details
    ...                                     Contact
    ...                                     object_id=${data}[contact][Id]

    Navigate To And Validate Field Value    Smallest Gift             contains    $${contact_smallestvalue}
    # --------------------------------
    # Open NPSP Settings and run the Levels batch job
    # --------------------------------
    Open NPSP Settings                      Bulk Data Processes         Level Assignment Batch
    Click Settings Button                   idPanelLvlAssignBatch       Run Batch
    Wait For Batch To Process               LVL_LevelAssign_BATCH       Completed
    # --------------------------------
    # Return to the Contact to validate the updated Level field
    # --------------------------------
    Go To Page                              Details
    ...                                     Contact
    ...                                     object_id=${data}[contact][Id]
    Navigate To And Validate Field Value    Level    contains          ${level_name}

    # --------------------------------
    # Update the contact's smallest Amount to a value greater than the level threshorld limit
    # --------------------------------

    Salesforce Update                       Contact                   ${data}[contact][Id]    npo02__SmallestAmount__c=${contact_smallestvalue_2}
    Go To Page                              Details
    ...                                     Contact
    ...                                     object_id=${data}[contact][Id]

    # --------------------------------
    # Open NPSP Settings and run the Levels batch job
    # --------------------------------
    Open NPSP Settings                      Bulk Data Processes         Level Assignment Batch
    Click Settings Button                   idPanelLvlAssignBatch       Run Batch
    Wait For Batch To Process               LVL_LevelAssign_BATCH       Completed



    Go To Page                              Details
    ...                                     Contact
    ...                                     object_id=${data}[contact][Id]

    Navigate To And Validate Field Value           Level      does not contain         ${level_name}    section=Donation Information
    Navigate To And Validate Field Value           Previous Level     contains         ${level_name}    section=Donation Information

3. Delete a Level
    [Documentation]                         Delete the Level from the levels listing page
    [tags]                                  feature:Levels   api

    Go To Page                              Details
    ...                                     Level__c
    ...                                     object_id=${level_id}
    Wait Until Loading Is Complete
    Current Page Should be                  Details    Level__c
    Click Show More Actions Button          Delete
    Wait Until Modal Is Open
    Click Modal Button                      Delete
    Wait Until Modal Is Closed
    Go To Page                              Details
    ...                                     Contact
    ...                                     object_id=${data}[contact][Id]
    Navigate To And Validate Field Value    Level      does not contain    ${level_name}    section=Donation Totals