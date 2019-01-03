*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${level_name}
${contact_id}

*** Test Cases ***

1 Create Level and Verify Fields
    ${level_id}  ${level_name}     Create Level
    Set Global Variable      ${level_name}
    Go To Record Home        ${level_id}
    Confirm Value    Minimum Amount (>=)    0.10    Y
    Confirm Value    Maximum Amount (<)     0.9    Y

2 Edit Level and Verify Fields
    # --------------------------------
    # Modify the Level Values and validate that they save correctly
    # --------------------------------
    Click Link    link=Show more actions
    Click Link    link=Edit
    Wait For Locator    frame    Levels
    Select Frame With Title    Levels
    Enter Level Dd Values    Source Field    Smallest Gift
    Enter Level Values
    ...            Minimum Amount=0.01
    ...            Maximum Amount=0.99
    Set Focus To Element   xpath: //input[@value='Save']
    Click Button  Save
    Unselect Frame
    Wait For Locator  breadcrumb  Level
    Reload Page
    Wait Until Loading Is Complete
    Confirm Value    Minimum Amount (>=)    0.01    Y
    Confirm Value    Maximum Amount (<)     0.99    Y
    Confirm Value    Source Field    npo02__SmallestAmount__c    Y

3 Validate Level Assignment in Batch Job
    [tags]  unstable
    # --------------------------------
    # Modify the SmallestGift field to allow the level to be applied
    # --------------------------------
    &{contact} =  API Create Contact
    Set Global Variable     ${contact_id}       &{contact}[Id]
    Go To Record Home       ${contact_id}
    Scroll Element Into View    text:Donation Totals
    Click Button       title:Edit Smallest Gift
    Wait For Locator  record.edit_form
    Populate Field          Smallest Gift     0.75
    Click Record Button     Save
    Wait Until Loading Is Complete
    Scroll Element Into View    text:Donation Totals
    Confirm Value           Smallest Gift    $0.75    Y
    # --------------------------------
    # Open NPSP Settings and run the Levels batch job
    # --------------------------------
    Open NPSP Settings      Bulk Data Processes         Level Assignment Batch
    Click Element           //input[contains(@class, 'stg-run-level-batch')]
    Wait for Locator        npsp_settings.completed
    # --------------------------------
    # Return to the Contact to validate the updated Level field
    # --------------------------------
    Go To Record Home       ${contact_id}
    Verify Field Value      Level    ${level_name}    Y
    # --------------------------------
    # Modify the SmallestGift field to change the applied level
    # --------------------------------
    Scroll Element Into View    text:Donation Totals
    Click Button       title:Edit Smallest Gift
    Wait For Locator  record.edit_form
    Populate Field          Smallest Gift     2.0
    Click Record Button     Save
    Wait Until Loading Is Complete
    Scroll Element Into View    text:Donation Totals
    Confirm Value           Smallest Gift    $2.00    Y
    # --------------------------------
    # Open NPSP Settings and run the Levels batch job
    # --------------------------------
    Open NPSP Settings      Bulk Data Processes         Level Assignment Batch
    Click Element           //input[contains(@class, 'stg-run-level-batch')]
    Wait for Locator        npsp_settings.completed
    # --------------------------------
    # Return to the Contact to validate the updated Level field
    # --------------------------------
    Go To Record Home       ${contact_id}
    Confirm Value           Level               ${level_name}    N
    Verify Field Value      Previous Level      ${level_name}    Y

4 Delete Level and Validate Contact
    [tags]  unstable
    # --------------------------------
    # Delete the Level and validate that it was removed from the Contact
    # --------------------------------
    Click Link    link=${level_name}
    Click Link    link=Show more actions
    Click Link    link=Delete
    Click Modal Button    Delete
    Go To Record Home           ${contact_id}
    Confirm Value    Level      ${level_name}    N
