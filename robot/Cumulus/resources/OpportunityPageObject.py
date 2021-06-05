from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.utils import capture_screenshot_on_error

from BaseObjects import BaseNPSPPage
import time
from NPSP import npsp_lex_locators

@pageobject("Details", "Opportunity")
class OpportunityPage(BaseNPSPPage, DetailPage):
    object_name = "Opportunity"

    def _is_current_page(self):
        """ Verify we are on the opportunity details page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/lightning/r/Opportunity/",timeout=60,message="Current page is not a Opportunity detail view")
        self.selenium.wait_until_page_contains("Donation Information")
        self.selenium.wait_until_page_contains("Delete")

    def ensure_opportunity_details_are_loaded(self,objectID, value):
        """ Navigate to the page with objectid mentioned
           Wait for the page to load and confirm atleast the opportunity name exists
        """
        self.pageobjects.go_to_page("Details", "Opportunity", objectID)
        self.npsp.navigate_to_and_validate_field_value("Opportunity Name", "contains", value)

    @capture_screenshot_on_error
    def navigate_to_matching_gifts_page(self):
        # if self.npsp.latest_api_version == 51.0:
        locator = npsp_lex_locators['manage_hh_page']['more_actions_btn']
        time.sleep(1)
        self.selenium.wait_until_element_is_visible(locator,60)
        self.selenium.click_element(locator)
        time.sleep(2)
        self.selenium.click_link('Find Matched Gifts')
        self.npsp.choose_frame("vfFrameId")
        # else:
        #     self.npsp.click_more_actions_button()
        #     time.sleep(2)
        #     self.selenium.click_link('Find Matched Gifts')
        #     self.npsp.choose_frame("vfFrameId")

    def navigate_to_writeoff_payments_page(self):
        if self.npsp.latest_api_version==51.0 or self.npsp.latest_api_version==52.0:
            self.npsp.click_related_list_dd_button('Payments', 'Show more actions', 'Writeoff_Payments')
        else:
            self.npsp.click_related_list_dd_button('Payments', 'Show one more action', 'Write Off Payments')
        self.npsp.wait_for_locator('frame','Write Off Remaining Balance')
        self.npsp.choose_frame("Write Off Remaining Balance")
        self.selenium.wait_until_page_contains("You are preparing to write off")

    def change_related_contact_role_settings(self,name,role=None,**kwargs):
        """Loads the related contact from opportunity, waits for the modal and updates the role and primary settings"""
        dropdown = npsp_lex_locators['related_drop_down'].format(name)
        edit = npsp_lex_locators['record']['dd_edit_option'].format("Edit")
        self.selenium.wait_until_page_contains_element(dropdown)
        self.salesforce._jsclick(dropdown)
        self.selenium.wait_until_element_is_visible(edit)
        self.selenium.click_element(edit)
        self.salesforce.wait_until_modal_is_open()
        self.npsp.select_value_from_dropdown ("Role",role)
        self.npsp.populate_modal_form(**kwargs)
        self.salesforce.click_modal_button("Save")

@pageobject("Listing", "Opportunity")
class OpportunityListingPage(BaseNPSPPage, ListingPage):
    object_name = "Opportunity"

    def _is_current_page(self):
        """ Verify we are on the opportunities listing page
            by verifying that the url contains '/list'
        """
        self.selenium.wait_until_location_contains("lightning/o/Opportunity/list",message="Current page is not a list page")

    def perform_delete_menu_operation_on(self,value,action):
        """ Identifies the value to delete from the List and chooses delete
            option from the menu. Confirms the delete action from the confirmation modal
        """
        locators = npsp_lex_locators['name']
        list_ele = self.selenium.get_webelements(locators)
        for index, element in enumerate(list_ele):
            if element.text == value:
                drop_down = npsp_lex_locators['opportunities_dropdown'].format(index + 1)
                self.selenium.set_focus_to_element(drop_down)
                self.selenium.wait_until_element_is_visible(drop_down)
                self.selenium.wait_until_element_is_enabled(drop_down)
                self.selenium.click_element(drop_down)
                self.selenium.wait_until_page_contains(action)
                self.selenium.click_link(action)

                # Wait for the delete button from the modal and confirm the delete action

                delete_btn=npsp_lex_locators["Delete_opportunity_modal_button"]
                self.selenium.wait_until_element_is_visible(delete_btn)
                self.selenium.click_button(delete_btn)
                self.selenium.wait_until_location_contains("/list")
                break




