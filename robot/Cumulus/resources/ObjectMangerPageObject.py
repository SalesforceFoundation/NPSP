import time
from cumulusci.robotframework.utils import capture_screenshot_on_error
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from selenium.webdriver.common.keys import Keys
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception


@pageobject("Custom", "ObjectManager")
class ObjectManagerPage(BaseNPSPPage, BasePage):
	
	def open_fields_and_relationships(self, object_name):
		"""To go to object manager page for a specific object"""
		url_template = "{root}/lightning/setup/ObjectManager/{object}/FieldsAndRelationships/view"
		url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
		self.selenium.go_to(url)
		search_button = npsp_lex_locators['object_manager']['global_search']
		self.salesforce.wait_until_loading_is_complete()
		self.selenium.wait_until_page_contains_element(search_button)

	def is_custom_field_present(self, field_name):
		"""Verifies if the custom field is present already for the object specified and returns true or false"""
		search_button = npsp_lex_locators['object_manager']['global_search']
		self.selenium.wait_until_page_contains_element(search_button,60)
		self.selenium.get_webelement(search_button).send_keys(field_name)
		self.selenium.get_webelement(search_button).send_keys(Keys.ENTER)
		self.salesforce.wait_until_loading_is_complete()
		search_results = npsp_lex_locators['object_manager']['search_result'].format(field_name)
		list_ele = self.selenium.get_webelements(search_results)
		p_count=len(list_ele)
		#assert p_count == 1, "Expected custom field not present"
		if p_count == 0:
			return False
		else:
			return True
		
	def create_custom_field(self, type, field_name, related_to):
		# After confirming that the custom field is not present for the specified object, creates the custom field of the specified type
		value = self.is_custom_field_present(field_name)
		self.builtin.log_to_console(value)
		if value == True:
			return
		else:
			locator = npsp_lex_locators['button-with-text'].format("New")
			self.selenium.get_webelement(locator).click()
			self.salesforce.wait_until_loading_is_complete()
			self.npsp.wait_for_locator('frame_new', 'vfFrameId', 'vfFrameId')
			self.npsp.choose_frame('vfFrameId')
			if type == 'Lookup':
				locator = npsp_lex_locators['object_manager']['Lookup_option']
				next_button = npsp_lex_locators['object_manager']['button'].format("Next")
				save_button = npsp_lex_locators['object_manager']['button'].format("Save")
				option = npsp_lex_locators['object_manager']['select_related_option'].format(related_to)
				field_label = npsp_lex_locators['object_manager']['input_field_label']
				self.selenium.click_element(locator)
				self.selenium.click_element(next_button)
				related = npsp_lex_locators['object_manager']['select_related']
				self.selenium.scroll_element_into_view(related)
				self.selenium.get_webelement(related).click()
				self.selenium.click_element(option)
				time.sleep(2)
				self.selenium.click_element(next_button)
				field_label_input = self.selenium.find_element(field_label)
				self.salesforce.populate_field('Field Label', field_name)
				
				self.salesforce.populate_field('Description', "This is a custion field generated during automation")
				self.selenium.click_element(next_button)
				self.selenium.click_element(next_button)
				self.selenium.click_element(next_button)
				self.selenium.click_element(save_button)
				self.selenium.wait_until_location_contains("FieldsAndRelationships/view", timeout=90,
												   message="Detail page did not load in 1 min")
				assert self.is_custom_field_present(field_name) == True, "Expected custom field not created"
