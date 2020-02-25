from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from cumulusci.robotframework.utils import capture_screenshot_on_error
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "Level_c")
class CreateLevelPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Waits for the Levels iframe to load in the edit mode
        """
        self.npsp.wait_for_locator('frame','Levels')
        self.npsp.choose_frame('Levels')

    @capture_screenshot_on_error
    def enter_level_values(self, **kwargs):
        """Enter values into corresponding fields in Levels page"""
        for name, value in kwargs.items():
            if name == "Level Name":
                id = "fldName"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.salesforce._populate_field(locator, value)
            elif name == "Minimum Amount":
                id = "fldMinAmount"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.salesforce._populate_field(locator, value)
            elif name == "Maximum Amount":
                id = "fldMaxAmount"
                locator = npsp_lex_locators['levels']['id'].format(id)
                self.salesforce._populate_field(locator, value)

    @capture_screenshot_on_error
    def enter_level_dd_values(self, **kwargs):
        """Enter values into corresponding fields in Levels page"""
        spinner = npsp_lex_locators['dropdown_spinner']
        for name, value in kwargs.items():
            if name == "Target":
                id = "fldTarget"
                locator = npsp_lex_locators['levels']['select'].format(id)
                loc = self.selenium.get_webelement(locator)
                self.selenium.set_focus_to_element(locator)
                self.selenium.select_from_list_by_label(loc,value)
                self.selenium.wait_until_element_is_not_visible(spinner)
            elif name == "Source Field":
                id = "fldSourceField"
                locator = npsp_lex_locators['levels']['select'].format(id)
                loc = self.selenium.get_webelement(locator)
                self.selenium.set_focus_to_element(locator)
                self.selenium.select_from_list_by_label(loc,value)
                self.selenium.wait_until_element_is_not_visible(spinner)
            elif name == "Level Field":
                id = "fldLevel"
                locator = npsp_lex_locators['levels']['select'].format(id)
                loc = self.selenium.get_webelement(locator)
                self.selenium.set_focus_to_element(locator)
                self.selenium.select_from_list_by_label(loc,value)
                self.selenium.wait_until_element_is_not_visible(spinner)
            elif name == "Previous Level Field":
                id = "fldPreviousLevel"
                locator = npsp_lex_locators['levels']['select'].format(id)
                loc = self.selenium.get_webelement(locator)
                self.selenium.set_focus_to_element(locator)
                self.selenium.select_from_list_by_label(loc,value)
                self.selenium.wait_until_element_is_not_visible(spinner)