from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "CreateEngagement")
class CreateEngagementPage(BaseNPSPPage, BasePage):
    object_name = "npsp__Engagement_Plan_Template__c"

    def _is_current_page(self):
        """ Verify we are on the Engagement Template view details page
            by verifying that the url contains '/view'
        """
        xpath = npsp_lex_locators["engagement_template"]
        self.selenium.wait_until_location_contains("npsp__Engagement_Plan_Template__c", timeout=60, message="Engagement Template create page did not open in 1 min")
        self.selenium.location_should_contain("npsp__Engagement_Plan_Template__c",message="Current page is not a Engagement Template edit page")
        self.selenium.page_should_contain_element(xpath)

    def populate_values_for_engagement_template(self, action, dict):

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