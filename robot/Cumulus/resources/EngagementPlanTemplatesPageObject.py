from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Listing", "Engagement_Plan_Template__c")
class EngagementPlanListPage(BaseNPSPPage, ListingPage):

    
    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Records list view did not load in 1 min")
        self.selenium.location_should_contain("Engagement_Plan_Template__c",message="Current page is not an Engagement Plan List view")
            
    
@pageobject("Details", "Engagement_Plan_Template__c")
class EngagementPlanDetailPage(BaseNPSPPage, DetailPage):

    
    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/view",timeout=60, message="Records detail view did not load in 1 min")
        self.selenium.location_should_contain("Engagement_Plan_Template__c",message="Current page is not an Engagement Plan record view")
                    
    