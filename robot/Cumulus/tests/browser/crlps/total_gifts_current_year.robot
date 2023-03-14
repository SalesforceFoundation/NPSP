*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/CustomizableRollupsPageObject.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Customizable Rollups
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
# Create test data by creating a contact and associating three different opportunities to the same contact
Setup Test Data
    Setupdata   contact   ${contact1_fields}     ${opportunity1_fields}
    Setupdata   contact   opportunity_data=${opportunity2_fields}
    Setupdata   contact   opportunity_data=${opportunity3_fields}


*** Variables ***
&{contact1_fields}        Email=rollup@example.com
&{opportunity1_fields}    Type=Donation   Name=Auto Payment test $100 Donation1   Amount=100   StageName=Closed Won
&{opportunity2_fields}    Type=Donation   Name=Auto Payment test $100 Donation2   Amount=100   StageName=Closed Won
&{opportunity3_fields}    Type=Donation   Name=Auto Payment test $100 Donation3   Amount=100   StageName=Closed Won


*** Test Cases ***

Calculate CRLPs for Total Gifts On Multiple Opportunities
    [Documentation]             This test case is aimed at validating that the customizable rollup "Total Gifts" is active by default when the CRLP setting is turned
    ...                         And verifies that the rollup is actually happening
    [tags]                      feature:CRLP    unstable     api    quadrant:q3


    Load Page Object            Custom       CustomRollupSettings
    Navigate To Crlpsettings

    # Verify that the out of the box customizable rollup ( Account: Total Gifts ) exists and is active by default
    Verify Rollup exists        Account: Total Gifts

    # Navigate to the custom details page and verify that the rollup field "Total Gifts" shows up and displays the right amount
    Go To Page                              Details
    ...                                     Contact
    ...                                     object_id=${data}[contact][Id]
    Verify Rollup Field Value               Total Gifts         $300.00           Donation Totals