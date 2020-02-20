from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Details", "Opportunity")
class OpportunityPage(BaseNPSPPage, DetailPage):
    object_name = "Opportunity"

    def _is_current_page(self):
        """ Verify we are on the opportunity details page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/lightning/r/Opportunity/",message="Current page is not a Opportunity detail view")

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


    
    
        