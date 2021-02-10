from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators


@pageobject("Listing", "Contact")
class ContactListingPage(BaseNPSPPage, ListingPage):
    object_name = "Contact"

    def click_delete_account_button(self):
        """Clicks on Delete Account button inside the iframe"""
        self.selenium.wait_until_location_contains("/delete", message="Account delete page did not load in 30 seconds")
        self.npsp.select_frame_and_click_element("vfFrameId","button","Delete Account")

@pageobject("Details", "Contact")
class ContactDetailPage(BaseNPSPPage, DetailPage):
    object_name = "Contact"

    def _is_current_page(self):
        """ Verify we are on the Contact detail page
            by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Detail page did not load in 1 min")
        self.selenium.location_should_contain("/lightning/r/Contact/",message="Current page is not a Contact record detail view")
        self.selenium.wait_until_page_contains("Contact Details")

    def update_field_value(self,field_name,old_value,new_value):
        """Delete the old value in specified field by clicking on delete icon and update with new value"""
        locator=npsp_lex_locators['delete_icon'].format(field_name,old_value)
        self.selenium.get_webelement(locator).click()
        self.salesforce.populate_lookup_field(field_name,new_value)

    def go_to_related_engagement_actionplans_page(self,customerid):

        """ Navigates to the related engagement plans listing page"""
        name = "Action_Plans__r"
        objectname = "{}{}".format(self.npsp.get_npsp_namespace_prefix(), name)
        values =  self.npsp.get_url_formatted_object_name(objectname)
        url = "{}/lightning/r/{}/related/{}/view".format(values['baseurl'],customerid,values['objectname'])
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.selenium.wait_until_location_contains("/view",timeout=60, message="Page not loaded")

    def perform_action_on_related_item(self,action):
        """ Identifies the value and performs the specified action requested
            Currently added logic for Delete. In the future can be extended for Edit
        """
        drop_down = npsp_lex_locators['opportunities_dropdown'].format(1)
        self.selenium.set_focus_to_element(drop_down)
        self.selenium.wait_until_element_is_visible(drop_down)
        self.selenium.click_element(drop_down)
        self.selenium.wait_until_page_contains(action)
        self.selenium.click_link(action)

        # Wait for the delete button from the modal and confirm the delete action
        if action.lower() == 'delete':
            delete_btn=npsp_lex_locators["Delete_opportunity_modal_button"]
            self.selenium.wait_until_element_is_visible(delete_btn)
            self.selenium.click_button(delete_btn)
            self.selenium.wait_until_location_contains("/view")

    def waitfor_actions_dropdown_and_click_option(self,option):
        """Wait for the Action dropdown menu to load from the contact details page
           Click on the desired option passed as a parameter
        """
        loc=npsp_lex_locators['contacts_actions_dropdown_menu']
        self.selenium.wait_until_element_is_visible(loc)
        self.selenium.click_link(option)

    def validate_relation_status_message(self, contact1, contact2, relation):
        """Obtains the status message displayed on the relationships section of contact details page
           Validates it against the expected status message
           Note: Pass contact1,contact2, relation in a desired pattern to format as contact1 is contact2's relation
        """
        expectedstatus = ("{} is {}'s {}".format(contact1,contact2,relation))
        id,actualstatus = self.npsp.check_status(contact1)
        self.builtin.should_be_equal_as_strings(actualstatus,expectedstatus)

    def verify_rollup_field_value(self,field_name,value,section=None):
        """Verifies if the given rollup field contains given value
        if it doesn't, then recalculates rollup and performs refresh"""
        try :
            self.npsp.navigate_to_and_validate_field_value(field_name,"contains",value,section)
            self.builtin.log("Found rollup value on the page on initial try")
        except Exception :
            self.npsp.click_more_actions_button()
            self.selenium.click_link("Recalculate Rollups")
            self.npsp.wait_for_locator("frame", "accessibility title")
            self.npsp.choose_frame("accessibility title")
            self.selenium.wait_until_page_contains("The rollups batch job is calculating and may take a few moments to complete. Go back to the Contact and refresh to see updated rollup values.",timeout=60)
            self.npsp.click_button_with_value("Back to Contact")
            self.pageobjects.current_page_should_be("Details","Contact")
            try :
                self.npsp.navigate_to_and_validate_field_value(field_name,"contains",value,section)
                self.builtin.log("Found rollup value on the page after recalculate")
            except Exception :
                self.selenium.reload_page()
                self.npsp.navigate_to_and_validate_field_value(field_name,"contains",value,section)

    def open_relationships_viewer(self):
        """Clicks on the Relationships Viewer link on the contact page"""
        locator=npsp_lex_locators['link-contains'].format("more actions")
        self.selenium.wait_until_element_is_visible(locator)
        self.selenium.click_element(locator)
        self.selenium.wait_until_page_contains("Relationships Viewer")
        link_locator=npsp_lex_locators['custom_objects']['actions-link'].format("Relationships_Viewer","Relationships_Viewer")
        self.selenium.click_link(link_locator)