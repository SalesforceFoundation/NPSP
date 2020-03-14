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

    def navigate_to_matching_gifts_page(self):
        self.npsp.click_more_actions_button()
        self.selenium.click_link('Find Matched Gifts')
        self.npsp.choose_frame("vfFrameId")

    def navigate_to_writeoff_payments_page(self):
        self.npsp.click_related_list_dd_button('Payments', 'Show one more action', 'Write Off Payments')
        self.npsp.wait_for_locator('frame','Write Off Remaining Balance')
        self.npsp.choose_frame("Write Off Remaining Balance")
        self.selenium.wait_until_page_contains("You are preparing to write off")


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


    
    
        