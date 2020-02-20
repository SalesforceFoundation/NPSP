*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/LevelsPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${level_name}
${contact_id}

*** Test Cases ***

1 Create Level and Verify Fields
    [tags]  unstable
    ${level_name}=    Generate Random String
    Go To Page       Home        Level__c
    Enter Level Values
    ...            Level Name=${level_name}
    ...            Minimum Amount=0.1
    ...            Maximum Amount=0.9
    Enter Level Dd Values    Target    Contact
    Enter Level Dd Values    Source Field    Total Gifts
    Enter Level Dd Values    Level Field    Level
    Enter Level Dd Values    Previous Level Field    Previous Level
    Set Focus To Element   xpath: //input[@value='Save']
    Click Button  Save
    Current Page Should be    Details    Level__c
    ${level_id} =   Save Current Record ID For Deletion  Level__c
    Set Global Variable      ${level_name}
    Set Global Variable      ${level_id}
    Unselect Frame
    Navigate To And Validate Field Value    Minimum Amount (>\=)   contains    0.10
    Navigate To And Validate Field Value    Maximum Amount (<)    contains    0.90

2 Edit Level and Verify Fields
    # --------------------------------
    # Modify the Level Values and validate that they save correctly
    # --------------------------------
    [tags]  unstable
    Go To Page         Details         Level__c        object_id=${level_id}
    Click Show More Actions Button    Edit
    Wait Until Location Contains    /edit
    Wait For Locator    frame    Levels
    Choose Frame    Levels
    Enter Level Dd Values    Source Field    Smallest Gift
    Enter Level Values
    ...            Minimum Amount=0.01
    ...            Maximum Amount=0.99
    Set Focus To Element   xpath: //input[@value='Save']
    Click Button  Save
    #adding a workaround to go back to levels tab due to core issue
    Current Page Should Be     Details    Level__c
    Go To Page         Details         Level__c        object_id=${level_id}
    Navigate To And Validate Field Value   Minimum Amount (>\=)    contains    0.01
    Navigate To And Validate Field Value   Maximum Amount (<)     contains    0.99
    Navigate To And Validate Field Value    Source Field    contains    npo02__SmallestAmount__c

3 Validate Level Assignment in Batch Job
    [tags]  unstable
    # --------------------------------
    # Modify the SmallestGift field to allow the level to be applied
    # --------------------------------
    &{contact} =  API Create Contact
    Set Global Variable     ${contact_id}       &{contact}[Id]
    Go To Page    Details    Contact       object_id=${contact_id}
    Scroll Element Into View    text:Donation Totals
    Click Button       title:Edit Smallest Gift
    Wait For Locator  record.footer
    Populate Field          Smallest Gift     0.75
    Click Record Button     Save
    Wait Until Loading Is Complete
    Navigate To And Validate Field Value          Smallest Gift    contains    $0.75    section=Donation Totals
    # --------------------------------
    # Open NPSP Settings and run the Levels batch job
    # --------------------------------
    Open NPSP Settings      Bulk Data Processes         Level Assignment Batch
    Click Settings Button    idPanelLvlAssignBatch    Run Batch
    Wait For Batch To Process        LVL_LevelAssign_BATCH    Completed
    # --------------------------------
    # Return to the Contact to validate the updated Level field
    # --------------------------------
    Go To Page    Details    Contact       object_id=${contact_id}
    Navigate To And Validate Field Value          Level    contains    ${level_name}    section=Donation Totals

    # --------------------------------
    # Modify the SmallestGift field to change the applied level
    # --------------------------------
    Scroll Element Into View    text:Donation Totals
    Click Button       title:Edit Smallest Gift
    Wait For Locator  record.footer
    Populate Field          Smallest Gift     2.0
    Click Record Button     Save
    Wait Until Loading Is Complete
    Navigate To And Validate Field Value           Smallest Gift    contains    $2.00    section=Donation Totals
    # --------------------------------
    # Open NPSP Settings and run the Levels batch job
    # --------------------------------
    Open NPSP Settings      Bulk Data Processes         Level Assignment Batch
    Click Settings Button    idPanelLvlAssignBatch    Run Batch
    Wait For Batch To Process        LVL_LevelAssign_BATCH    Completed
    # --------------------------------
    # Return to the Contact to validate the updated Level field
    # --------------------------------
    Go To Page    Details    Contact       object_id=${contact_id}
    Navigate To And Validate Field Value           Level      does not contain         ${level_name}    section=Donation Totals
    Navigate To And Validate Field Value           Previous Level     contains         ${level_name}    section=Donation Totals


4 Delete Level and Validate Contact
    [tags]  unstable
    # --------------------------------
    # Delete the Level and validate that it was removed from the Contact
    # --------------------------------
    Go To Page               Details               Level__c                                object_id=${level_id}
    Click Show More Actions Button    Delete
    Click Modal Button    Delete
    Go To Page    Details    Contact       object_id=${contact_id}
    Navigate To And Validate Field Value    Level      does not contain    ${level_name}    section=Donation Totals
