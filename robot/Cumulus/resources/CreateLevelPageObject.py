from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception
import time

@pageobject("Custom", "CreateLevel")
class CreateLevelPage(BaseNPSPPage, BasePage):
    object_name = "npsp__Level__c"

    def _is_current_page(self):
        """ Verify we are on the Engagement Template view details page
            by verifying that the url contains '/view'
        """

        self.selenium.wait_until_location_contains("npsp__Level__c", timeout=60, message="Level Template create page did not open in 1 min")
        self.selenium.location_should_contain("npsp__Level__c",message="Current page is not a Level Template edit page")
        self.npsp.wait_for_locator("frame", "Levels")

    def populate_values(self, textvalues=None, dropdownvalues=None):

        #self.npsp.wait_for_locator("frame","LEVEL")
        #self.selenium.wait_for_locator("frame", "Levels")
        self.npsp.choose_frame("Levels")
        for field, value in textvalues.items():
            if field == "Level Name":
                id = "fldName"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.salesforce._populate_field(locator, value)
            elif field == "Minimum Amount":
                id = "fldMinAmount"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.salesforce._populate_field(locator, value)
            elif field == "Maximum Amount":
                id = "fldMaxAmount"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.salesforce._populate_field(locator, value)
        for name, value in dropdownvalues.items():
            """Enter values into corresponding fields in Levels page"""
            if name == "Target":
                id = "fldTarget"
                locator = npsp_lex_locators['levels']['select'].format(id)
                loc = self.selenium.get_webelement(locator)
                self.selenium.set_focus_to_element(locator)
                self.selenium.select_from_list_by_label(loc,value)
                time.sleep(2)
            elif name == "Source Field":
                id = "fldSourceField"
                locator = npsp_lex_locators['levels']['select'].format(id)
                loc = self.selenium.get_webelement(locator)
                self.selenium.set_focus_to_element(locator)
                self.selenium.select_from_list_by_label(loc,value)
                time.sleep(2)
            elif name == "Level Field":
                id = "fldLevel"
                locator = npsp_lex_locators['levels']['select'].format(id)
                loc = self.selenium.get_webelement(locator)
                self.selenium.set_focus_to_element(locator)
                self.selenium.select_from_list_by_label(loc,value)
                time.sleep(2)
            elif name == "Previous Level Field":
                id = "fldPreviousLevel"
                locator = npsp_lex_locators['levels']['select'].format(id)
                loc = self.selenium.get_webelement(locator)
                self.selenium.set_focus_to_element(locator)
                self.selenium.select_from_list_by_label(loc,value)

        self.selenium.click_button("Save")
        self.selenium.unselect_frame()
