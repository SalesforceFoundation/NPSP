from cumulusci.robotframework.pageobjects import HomePage
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception
import time


@pageobject("Home", "Level__c")
class LevelListPage(BaseNPSPPage, HomePage):

    def _go_to_page(self, filter_name=None):
        """To go to create level page"""
        url_template = "{root}/lightning/o/{object}/new"
        name = self._object_name
        object_name = "{}{}".format(self.cumulusci.get_namespace_prefix(), name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.npsp.wait_for_locator("frame","Levels")
        #elf.npsp.choose_frame("Levels")

    def populate_values_to_create_level(self, textvalues=None, dropdownvalues=None):
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


@pageobject("Listing", "Level__c")
class LevelListPage(BaseNPSPPage, ListingPage):

    def _is_current_page(self):
        """
        Waits for the current page to be level list view
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Records list view did not load in 1 min")
        self.selenium.location_should_contain("Level__c",message="Current page is not Level List view")


@pageobject("Details", "Level__c")
class LevelDetailPage(BaseNPSPPage, DetailPage): 

    def _is_current_page(self):
        """ Verify we are on the Level detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Detail view did not open in 1 min")
        self.selenium.location_should_contain("/lightning/r/",message="Current page is not Level record detail view")
    
        
        
    