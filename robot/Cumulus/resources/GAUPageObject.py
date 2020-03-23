from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Listing", "General_Accounting_Unit__c")
class GAUListPage(BaseNPSPPage, ListingPage):

    
    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Records list view did not load in 1 min")
        self.selenium.location_should_contain("General_Accounting_Unit__c",message="Current page is not a GAU List view")
            
    
        

    
    
@pageobject("Custom", "ManageAllocations")
class GauAllocationPage(BaseNPSPPage, BasePage):
           
    def _wait_to_appear(self, timeout=None):
        """This function is called by the keyword 'wait for page object to appear'.
        used to verify that the page is visible and selects the iframe.
        """
        self.selenium.wait_until_location_contains("/one/one.app",timeout=60, message="Manage Allocations page did not load in 1 min")
        self.npsp.wait_for_locator('frame','Manage Allocations')
        self.npsp.choose_frame('Manage Allocations') 
        
    
    def add_gau_allocation(self,field, value):
        """Enter an allocation of sepecified 'value' in the given 'field'"""
        locator = npsp_lex_locators["gaus"]["input_field"].format(field)
        self.salesforce._populate_field(locator,value)      