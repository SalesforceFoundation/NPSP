*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/CustomizableRollupsPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Custom Fields and data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser


*** Keywords ***
Setup Custom Fields and data

    ${picklistvalues}=       Create List           Pending       Canceled
    Set suite variable       @{picklistvalues}


*** Test Cases ***

Verify Status Mappings For Custom Status Picklist Values
    [Documentation]     This testcase is to ensure that the status mappings for the exiting values
    ...                 remain intact . The newly added status mapping values appear in the status
    ...                 mappinngs section and remain unmapped.

    [tags]              unstable                           feature:RD

    # Add Two new custom picklist values for the recurring donation's status field
    Add Custom Picklist Values To Field
    ...                                                    Object=Recurring Donation
    ...                                                    Field_Name=Status
    ...                                                    Values=@{picklistvalues}

    Open NPSP Settings           Recurring Donations       Status to State Mapping
    Verify Status To State Mappings
    ...                                                    Active=Active
    ...                                                    Lapsed=Lapsed
    ...                                                    Closed=Closed
    ...                                                    Paused=Active
    ...                                                    Pending=-- Unmapped --
    ...                                                    Canceled=-- Unmapped --
