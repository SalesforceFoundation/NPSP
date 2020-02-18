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
        self.npsp.choose_frame("Levels")


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

    def go_to_edit_level_page(self,levelid=None):
        """ Navigates to the edit view for the given level id """
        url = self.cumulusci.org.lightning_base_url
        name = "Level_c"
        object_name = "{}{}".format(self.cumulusci.get_namespace_prefix(), name)

        url = "{}/lightning/r/{}/{}/edit".format(url,object_name,levelid)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.npsp.wait_for_locator("frame","Levels")
        self.npsp.choose_frame("Levels")
        self.selenium.wait_until_location_contains("/edit",timeout=60, message="Page not loaded")
    
        
        
    