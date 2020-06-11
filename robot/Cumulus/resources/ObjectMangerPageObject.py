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
	
	@capture_screenshot_on_error
	def open_fields_and_relationships(self, object_name):
		"""To go to object manager page for a specific object"""
		url_template = "{root}/lightning/setup/ObjectManager/{object}/FieldsAndRelationships/view"
		url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
		self.selenium.go_to(url)
		search_button = npsp_lex_locators['object_manager']['input'].format("globalQuickfind")
		self.salesforce.wait_until_loading_is_complete()
		self.selenium.wait_until_page_contains_element(search_button)
		
	def create_lookup_field(self,field_name, related):
		"""Creates a Lookpup field by taking in the inputs field_name and related field"""
		lookup_locator = npsp_lex_locators['object_manager']['input'].format("dtypeY")
		next_button = npsp_lex_locators['object_manager']['button'].format("Next")
		save_button = npsp_lex_locators['object_manager']['button'].format("Save")
		option = npsp_lex_locators['object_manager']['select_related_option'].format(related)
		field_label = npsp_lex_locators['object_manager']['input'].format("MasterLabel")
		self.selenium.wait_until_page_contains_element(lookup_locator,60)
		self.selenium.click_element(lookup_locator)
		time.sleep(1)
		self.selenium.click_element(next_button)
		related = npsp_lex_locators['object_manager']['select_related']
		self.selenium.wait_until_page_contains_element(related,60)
		self.selenium.scroll_element_into_view(related)
		self.selenium.get_webelement(related).click()
		self.selenium.click_element(option)
		time.sleep(2)
		self.selenium.click_element(next_button)
		self.salesforce.populate_field('Field Label', field_name)
		self.salesforce.populate_field('Description', "This is a custom field generated during automation")
		self.selenium.click_element(next_button)
		self.selenium.click_element(next_button)
		self.selenium.click_element(next_button)
		self.selenium.click_element(save_button)
		self.selenium.wait_until_location_contains("FieldsAndRelationships/view", timeout=90,
												   message="Detail page did not load in 1 min")
	
	@capture_screenshot_on_error
	def create_custom_field(self, type, field_name, related_to=None):
		"""Creates a custom field based on type paramenter and the field_name """
		search_button = npsp_lex_locators['object_manager']['input'].format("globalQuickfind")
		self.selenium.wait_until_page_contains_element(search_button,60)
		self.selenium.get_webelement(search_button).send_keys(field_name)
		self.selenium.get_webelement(search_button).send_keys(Keys.ENTER)
		time.sleep(1)
		self.salesforce.wait_until_loading_is_complete()
		search_results = npsp_lex_locators['object_manager']['search_result'].format(field_name)
		count = len(self.selenium.get_webelements(search_results))
		if count == 1:
			return
		else:
			locator = npsp_lex_locators['button-with-text'].format("New")
			self.selenium.wait_until_page_contains_element(locator,60)
			self.selenium.get_webelement(locator).click()
			self.salesforce.wait_until_loading_is_complete()
			self.npsp.wait_for_locator('frame_new', 'vfFrameId', 'vfFrameId')
			self.npsp.choose_frame('vfFrameId')
			if type == 'Lookup':
				self.create_lookup_field(field_name,related_to)
			elif type == 'Currency':
				self.create_currency_field(field_name)	

	def create_currency_field(self,field_name):
		"""Creates a currency field by taking in the field name"""
		currency_locator=npsp_lex_locators['object_manager']['input'].format("dtypeC")
		next_button=npsp_lex_locators['object_manager']['button'].format("Next")
		save_button=npsp_lex_locators['object_manager']['button'].format("Save")
		self.selenium.wait_until_page_contains_element(currency_locator,timeout=60)
		self.selenium.click_element(currency_locator)
		time.sleep(1)
		self.selenium.click_element(next_button)
		self.salesforce.populate_field('Field Label', field_name)
		self.salesforce.populate_field('Length', '16')
		self.salesforce.populate_field('Decimal Places', '2')
		self.salesforce.populate_field('Description', "This is a custom field generated during automation")
		self.selenium.click_element(next_button)
		self.selenium.click_element(next_button)
		self.selenium.click_element(save_button)
		self.selenium.wait_until_location_contains("FieldsAndRelationships/view", timeout=90, message="Fields And Relationships page did not load in 1 min")
		

