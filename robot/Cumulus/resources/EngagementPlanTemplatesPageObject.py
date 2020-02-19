from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Listing", "Engagement_Plan_Template__c")
class EngagementPlanListPage(BaseNPSPPage, ListingPage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Engagement Plan list view page
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Engagement plan list view did not load in 1 min")
        self.selenium.location_should_contain("Engagement_Plan_Template__c",message="Current page is not an Engagement Plan List view")

    def go_to_engagement_plan_page(self,action,engagementid=None):
        """ Navigates to the specified mode of engagement plant template page """

        objectname = "Engagement_Plan_Template__c"
        values =  self.npsp.get_url_formatted_object_name(objectname)
        if action.lower() == "create":
            url = "{}/lightning/o/{}/new".format(values['baseurl'],values['objectname'])
            self.selenium.go_to(url)
            self.salesforce.wait_until_loading_is_complete()
            self.selenium.wait_until_location_contains("/new",timeout=60, message="Page not loaded")
        if action.lower() == "edit":
            url = "{}/lightning/r/{}/{}/edit".format(values['baseurl'],values['objectname'],engagementid)
            self.selenium.go_to(url)
            self.salesforce.wait_until_loading_is_complete()
            self.selenium.wait_until_location_contains("/edit",timeout=60, message="Page not loaded")

        self.npsp.wait_for_locator("frame","Manage Engagement Plan Template")

    
@pageobject("Details", "Engagement_Plan_Template__c")
class EngagementPlanDetailPage(BaseNPSPPage, DetailPage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/view",timeout=60, message="Engagement plan detail view did not load in 1 min")
        self.selenium.location_should_contain("Engagement_Plan_Template__c",message="Current page is not an Engagement Plan record view")
                    
    