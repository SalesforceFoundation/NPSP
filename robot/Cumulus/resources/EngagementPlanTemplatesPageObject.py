from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import HomePage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Home", "Engagement_Plan_Template__c")
class EngagementPlanHomePage(BaseNPSPPage, HomePage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Engagement Plan list view page
        """
        self.npsp.wait_for_locator('frame','accessibility title')
        self.npsp.choose_frame('accessibility title')

    def click_eng_plan_dropdown(self, title):
        locator = npsp_lex_locators['engagement_plan']['dropdown'].format(title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()

    def select_eng_plan_checkbox(self,title):
        """"""
        if title=="Skip Weekends":
            locator=npsp_lex_locators['engagement_plan']['checkbox'].format("span",title)
            self.selenium.get_webelement(locator).click()
        else:
            locator=npsp_lex_locators['engagement_plan']['checkbox'].format("label",title)
            self.selenium.get_webelement(locator).click()

    def enter_eng_plan_values(self, name, value):
        """Enter values into corresponding fields in Engagement Plan Templet page"""
        locator = npsp_lex_locators['id'].format(name)
        self.salesforce._populate_field(locator, value)

    def click_and_wait_for_task(self, taskname):
        self.selenium.click_button('Add Task')
        self.selenium.wait_until_page_contains(taskname)

    def enter_task_id_and_subject(self, id, value):
        """Enter values into corresponding task subject fields based on last 2 digits of id"""
        locator = npsp_lex_locators['engagement_plan']['input_box'].format(id, "Subject")
        self.selenium.wait_until_element_is_visible(locator, 60)
        self.salesforce.scroll_element_into_view(locator)
        self.selenium.get_webelement(locator).send_keys(value)

    def save_engagement_plan_template(self):
        self.npsp.page_scroll_to_locator('button', 'Save')
        self.selenium.click_button('Save')

    def click_task_button(self, name, task_id=None, type=None):
        """Click Task button based on Task id and button label"""
        if type == 'subtask':
            locator = npsp_lex_locators['engagement_plan']['button'].format(task_id, name)
            self.selenium.get_webelement(locator).click()
        else:
            self.selenium.click_button('Add Task')
            self.selenium.wait_until_page_contains(name)


@pageobject("Listing", "Engagement_Plan_Template__c")
class EngagementPlanListPage(BaseNPSPPage, ListingPage):

    def _go_to_page(self, filter_name=None):
        """Adding this go to page keyword as a workaround for namespace issue
        when running with 2GP orgs"""
        url_template = "{root}/lightning/o/{object}/list"
        name = self._object_name
        namespace= self.npsp.get_npsp_namespace_prefix()
        object_name = "{}{}".format(namespace, name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()

    def _is_current_page(self):
        """
        Waits for the current page to be a Engagement Plan list view page
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Engagement plan list view did not load in 1 min")
        self.selenium.location_should_contain("Engagement_Plan_Template__c",message="Current page is not an Engagement Plan List view")

    def go_to_engagement_plan_page(self,action,engagementid=None):
        """ Navigates to the specified mode of engagement plant template page """
        name = self._object_name
        objectname = "{}{}".format(self.npsp.get_npsp_namespace_prefix(), name)
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

        self.npsp.wait_for_locator("frame","accessibility title")


@pageobject("Details", "Engagement_Plan_Template__c")
class EngagementPlanDetailPage(BaseNPSPPage, DetailPage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/view",timeout=60, message="Engagement plan detail view did not load in 1 min")
        self.selenium.location_should_contain("Engagement_Plan_Template__c",message="Current page is not an Engagement Plan record view")

