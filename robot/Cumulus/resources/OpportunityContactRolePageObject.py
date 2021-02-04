from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Custom", "OpportunityContactRole")
class OCRRelatedPage(BaseNPSPPage, BasePage):

    
#     def _is_current_page(self):
#         """
#         Waits for the current page to be a Data Import list view
#         """
#         self.selenium.wait_until_location_contains("/list",timeout=60, message="Records list view did not load in 1 min")
#         self.selenium.location_should_contain("DataImport__c",message="Current page is not a DataImport List view")
            
    def _wait_to_appear(self, timeout=None):
        """This function is called by the keyword 'wait for page object to appear'.
        Custom page objects can override this to verify that the object is visible.
        """
        self.selenium.wait_until_location_contains("OpportunityContactRoles/view",timeout=60, message="Related list view did not load in 1 min")

        
        
