from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Detail", "EngagementTemplate")
class EngagementTemplatePage(BaseNPSPPage, DetailPage):
    object_name = "npsp__Engagement_Plan_Template__c"

    def _is_current_page(self):
        """ Verify we are on the Engagement Template view details page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/lightning/r/npsp__Engagement_Plan_Template__c", timeout=60, message="Engagement Template detail view did not open in 1 min")
        self.selenium.location_should_contain("/lightning/r/npsp__Engagement_Plan_Template__c",message="Current page is not a Engagement Template detail view")



@pageobject("Listing", "EngagementTemplate")
class EngagementTemplatePage(BaseNPSPPage, ListingPage):
    object_name = "npsp__Engagement_Plan_Template__c"

    def _is_current_page(self):
        """ Verify we are on the Engagement Templates Lists page
            by verifying that the url contains '/list'
        """

        self.selenium.location_should_contain("/lightning/o/npsp__Engagement_Plan_Template__c/list",message="Current page is not Engagement Template Listings")


    def manage_engagement_template(self, action, plan_name, task1=None, sub_task=None, task2=None):

        if action == 'Create':
            self.npsp.click_special_object_button("New")
            self.npsp.wait_for_locator("frame","Manage Engagement Plan Template")
            self.npsp.select_frame_and_click_element("Manage Engagement Plan Template", "id", "idName")
            self.npsp.enter_eng_plan_values("idName", plan_name)
            self.npsp.enter_eng_plan_values("idDesc", "This plan is created via Automation")
            if task1 and task2 is not None:
                self.selenium.click_button("Add Task")
                self.selenium.wait_until_page_contains("Task 1")
                # self.npsp.click_task_button(1, "Add Dependent Task")
            #self.npsp.click_task_button(1, "Add Dependent Task")
                self.npsp.enter_task_id_and_subject("Task 1", task1)
                self.selenium.click_button("Add Task")



