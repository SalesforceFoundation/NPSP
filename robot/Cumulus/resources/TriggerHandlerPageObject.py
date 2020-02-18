from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators


@pageobject("Details", "Trigger_Handler__c")
class DataImportDetailPage(BaseNPSPPage, DetailPage): 
    
    
    def _is_current_page(self):
        """
        Waits for the current page to be a Trigger Handler record view
        """
        self.selenium.wait_until_location_contains("/view",timeout=60, message="Records list view did not load in 1 min")
        self.selenium.location_should_contain("Trigger_Handler__c",message="Current page is not a Trigger Handler record view")
