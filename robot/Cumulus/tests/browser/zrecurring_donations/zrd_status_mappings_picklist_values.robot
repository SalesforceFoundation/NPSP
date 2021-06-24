*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Custom Fields and data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser


*** Keywords ***
Setup Custom Fields and data
    ${Unique_Number}    Generate random string    4    0123456789
    # Ensuring that unique picklist values are added everytime the test is run
    ${value1}           Catenate    Pending     ${Unique_Number}
    ${value2}           Catenate    Canceled    ${Unique_Number}
    ${picklistvalues}=       Create List           ${value1}       ${value2}
    Set suite variable       @{picklistvalues}
    Set suite variable       ${value1}
    Set suite variable       ${value2}

    # Add Two new custom picklist values for the recurring donation's status field
    Add Custom Picklist Values To Field
    ...                                                    Object=Recurring Donation
    ...                                                    Field_Name=Status
    ...                                                    Values=@{picklistvalues}


*** Test Cases ***

Verify Status Mappings For Custom Status Picklist Values
    [Documentation]     This testcase is to ensure that the status mappings for the exiting values
    ...                 remain intact . The newly added status mapping values appear in the status
    ...                 mappinngs section and remain unmapped.

    [tags]                                       feature:RD                   unstable                 notonfeaturebranch

    Open NPSP Settings           Recurring Donations       Status to State Mapping
    Sleep                        1
    Verify Status To State Mappings
    ...                                                    Active=Active
    ...                                                    Lapsed=Lapsed
    ...                                                    Closed=Closed
    ...                                                    Paused=Active
    ...                                                    ${value1}=-- Unmapped --
    ...                                                    ${value2}=-- Unmapped --
