from cumulusci.robotframework.pageobjects import HomePage
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators


@pageobject("Home", "Level__c")
class LevelListPage(BaseNPSPPage, HomePage):

    
    def _go_to_page(self, filter_name=None):
        """To go to NPSP Settings page"""
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
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Records list view did not load in 1 min")
        self.selenium.location_should_contain("Level__c",message="Current page is not a DataImport List view")
            
    
        

    
@pageobject("Details", "Level__c")
class LevelDetailPage(BaseNPSPPage, DetailPage): 
    
    
    def _is_current_page(self):
        """ Verify we are on the Level detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Detail view did not open in 1 min")
        self.selenium.location_should_contain("/lightning/r/",message="Current page is not Level record detail view")
    
        
        
    