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
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Detail page did not load in 1 min")
        self.selenium.location_should_contain("/lightning/r/Opportunity/",message="Current page is not a Opportunity detail view")


    def verify_payments_made(self, count):
        """
            Verify payments tally matches the count specified on the opportunity details page
        """

        self.npsp.select_tab("Related")
        self.salesforce.load_related_list("Payments")
        self.npsp.verify_occurrence("Payments", count)


    def validate_values_under_relatedlist_for(self, listname, **kwargs):
        """
        Navigate to one of the related list items specified and verify the values match the specified values as per the
        dictionary key value input.
        """
        self.npsp.wait_for_locator("record.related.check_occurrence","Contact Roles", 2)
        self.npsp.select_relatedlist(listname)
        self.npsp.verify_related_list_field_values(**kwargs)


@pageobject("Listing", "Opportunity")
class OpportunityListingPage(BaseNPSPPage, ListingPage):
    object_name = "Opportunity"

    def _is_current_page(self):
        """ Verify we are on the opportunities listing page
            by verifying that the url contains '/list'
        """
        self.selenium.wait_until_location_contains("/list", timeout=60, message="Opportunities listing page did not load in 1 min")
        self.selenium.location_should_contain("lightning/o/Opportunity/list",message="Current page is not a list page")

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


    
    
        