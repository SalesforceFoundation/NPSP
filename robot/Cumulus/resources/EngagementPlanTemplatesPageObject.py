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
        url = self.cumulusci.org.lightning_base_url
        name = "Engagement_Plan_Template__c"
        object_name = "{}{}".format(self.cumulusci.get_namespace_prefix(), name)
        if action.lower() == "create":
            url = "{}/lightning/o/{}/new".format(url,object_name)
            self.selenium.go_to(url)
            self.salesforce.wait_until_loading_is_complete()
            self.selenium.wait_until_location_contains("/new",timeout=60, message="Page not loaded")
        if action.lower() == "edit":
            url = "{}/lightning/r/{}/{}/edit".format(url,object_name,engagementid)
            self.selenium.go_to(url)
            self.salesforce.wait_until_loading_is_complete()
            self.selenium.wait_until_location_contains("/edit",timeout=60, message="Page not loaded")

        self.npsp.wait_for_locator("frame","Manage Engagement Plan Template")

    def populate_values_and_save_template(self, action, dict):
        """ Based on the action sent, populates values to create or to edit """

        self.npsp.wait_for_locator("frame","Manage Engagement Plan Template")
        self.npsp.select_frame_and_click_element("Manage Engagement Plan Template", "id", "idName")

        if action == "Create":
            self.npsp.enter_eng_plan_values("idName", dict.get('Name'))
            self.npsp.enter_eng_plan_values("idDesc", "This plan is created via Automation")

        if 'task1' in dict and 'task2' in dict:
            self.selenium.click_button("Add Task")
            self.selenium.wait_until_page_contains("Task 1")
            self.npsp.enter_task_id_and_subject("Task 1", dict.get('task1'))
            self.selenium.click_button("Add Task")
            self.selenium.wait_until_page_contains("Task 2")
            self.npsp.enter_task_id_and_subject("Task 2", dict.get('task2'))

        self.npsp.page_scroll_to_locator("button", "Save")
        self.selenium.click_button("Save")
        self.selenium.wait_until_location_contains("/view")
            
    
@pageobject("Details", "Engagement_Plan_Template__c")
class EngagementPlanDetailPage(BaseNPSPPage, DetailPage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/view",timeout=60, message="Engagement plan detail view did not load in 1 min")
        self.selenium.location_should_contain("Engagement_Plan_Template__c",message="Current page is not an Engagement Plan record view")
                    
    