import time
from cumulusci.robotframework.utils import capture_screenshot_on_error
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.alert import Alert
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception


@pageobject("Custom", "ObjectManager")
class ObjectManagerPage(BaseNPSPPage, BasePage):

	@capture_screenshot_on_error
	def open_fields_and_relationships(self, object_name):
		"""To go to object manager page for a specific object"""
		url_template = "{root}/lightning/setup/ObjectManager/home"
		url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
		self.selenium.go_to(url)
		search_button = npsp_lex_locators['object_manager']['input'].format("globalQuickfind")
		self.salesforce.wait_until_loading_is_complete()
		self.selenium.wait_until_page_contains_element(search_button)
		self.selenium.get_webelement(search_button).send_keys(object_name)
		self.selenium.get_webelement(search_button).send_keys(Keys.ENTER)
		object = npsp_lex_locators['object_manager']['object_result'].format(object_name)
		leftnavoption = npsp_lex_locators['link-text'].format("Fields & Relationships")
		self.builtin.sleep(2,"Wait for the objects to load")
		self.selenium.wait_until_page_contains_element(object)
		self.selenium.click_element(object)
		self.selenium.wait_until_location_contains("Details/view", timeout=90)
		self.selenium.click_element(leftnavoption)

	@capture_screenshot_on_error
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

	@capture_screenshot_on_error
	def create_text_field(self,field_name):
		"""Creates a text field by taking in the field name"""
		text_locator=npsp_lex_locators['object_manager']['input'].format("dtypeS")
		next_button=npsp_lex_locators['object_manager']['button'].format("Next")
		save_button=npsp_lex_locators['object_manager']['button'].format("Save")
		self.selenium.wait_until_page_contains_element(text_locator,timeout=60)
		self.selenium.click_element(text_locator)
		time.sleep(1)
		self.selenium.click_element(next_button)
		self.salesforce.populate_field('Field Label', field_name)
		self.salesforce.populate_field('Length', '255')
		self.salesforce.populate_field('Description', "This is a custom field generated during automation")
		self.selenium.click_element(next_button)
		self.selenium.click_element(next_button)
		self.selenium.click_element(save_button)
		self.selenium.wait_until_location_contains("FieldsAndRelationships/view", timeout=90, message="Fields And Relationships page did not load in 1 min")

	@capture_screenshot_on_error
	def create_formula_field(self,field_name,formula):
		""" Creates a formula field by providing the field_name, formula and forumla fields"""
		formula_locator = npsp_lex_locators['object_manager']['input'].format("dtypeZ")
		next_button = npsp_lex_locators['object_manager']['button'].format("Next")
		save_button = npsp_lex_locators['object_manager']['button'].format("Save")
		checkbox_option = npsp_lex_locators['object_manager']['input'].format("fdtypeB")
		formula_txtarea = npsp_lex_locators['object_manager']['formula_txtarea'].format("CalculatedFormula")
		check_syntax = npsp_lex_locators['object_manager']['button'].format("Check Syntax")

		self.selenium.wait_until_page_contains_element(formula_locator,60)
		self.selenium.click_element(formula_locator)
		time.sleep(1)
		self.selenium.click_element(next_button)
		self.salesforce.populate_field('Field Label', field_name)
		self.selenium.wait_until_page_contains_element(checkbox_option,60)
		self.selenium.click_element(checkbox_option)
		self.selenium.click_element(next_button)
		self.selenium.wait_until_page_contains_element(formula_txtarea,60)
		self.selenium.get_webelement(formula_txtarea).send_keys(formula)
		self.selenium.click_element(check_syntax)
		self.selenium.click_element(next_button)
		self.selenium.click_element(next_button)
		self.selenium.click_element(save_button)
		self.selenium.wait_until_location_contains("FieldsAndRelationships/view", timeout=90,
												   message="Detail page did not load in 1 min")

	def create_lookup_field(self,field_name, related):
		"""Creates a Lookpup field by taking in the inputs field_name and related field"""
		lookup_locator = npsp_lex_locators['object_manager']['input'].format("dtypeY")
		next_button = npsp_lex_locators['object_manager']['button'].format("Next")
		save_button = npsp_lex_locators['object_manager']['button'].format("Save")
		option = npsp_lex_locators['object_manager']['select_related_option'].format(related)
		field_label = npsp_lex_locators['object_manager']['input'].format("MasterLabel")
		related = npsp_lex_locators['object_manager']['select_related'].format("DomainEnumOrId")
		self.selenium.wait_until_page_contains_element(lookup_locator,60)
		self.selenium.click_element(lookup_locator)
		time.sleep(1)
		self.selenium.click_element(next_button)
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
	def create_custom_field(self, **kwargs):
		"""Ensure that the custom field does not exist prior and Creates a custom field based on type paramenter and the field_name
		   IF the custom field exists it will not create the custom field and exits out of object manager
		   The Field_Type is the mandatory field to be present in the kwargs
		 """
		search_button = npsp_lex_locators['object_manager']['input'].format("globalQuickfind")
		self.selenium.wait_until_page_contains_element(search_button,60)
		self.selenium.get_webelement(search_button).send_keys(kwargs['Field_Name'])
		self.selenium.get_webelement(search_button).send_keys(Keys.ENTER)
		time.sleep(1)
		self.salesforce.wait_until_loading_is_complete()
		search_results = npsp_lex_locators['object_manager']['search_result'].format(kwargs['Field_Name'])
		count = len(self.selenium.get_webelements(search_results))
		if not count == 1:
			locator = npsp_lex_locators['button-with-text'].format("New")
			self.selenium.wait_until_page_contains_element(locator,60)
			self.selenium.get_webelement(locator).click()
			self.salesforce.wait_until_loading_is_complete()
			self.npsp.wait_for_locator('frame_new', 'vfFrameId', 'vfFrameId')
			self.npsp.choose_frame('vfFrameId')
			type = kwargs['Field_Type']
			if type.lower() == 'lookup':
				self.create_lookup_field(kwargs['Field_Name'],kwargs['Related_To'])
			elif type.lower() == 'currency':
				self.create_currency_field(kwargs['Field_Name'])
			elif type.lower() == 'formula':
				self.create_formula_field(kwargs['Field_Name'],kwargs['Formula'])
			elif type.lower() == 'text':
				self.create_text_field(kwargs['Field_Name'])


	@capture_screenshot_on_error
	def add_picklist_values(self, **kwargs):
		"""
		Searches for the specified field and if the field exits, Navigates throught the steps
		to add the picklist value(s)
		"""
		search_button = npsp_lex_locators['object_manager']['input'].format("globalQuickfind")
		self.selenium.wait_until_page_contains_element(search_button,60)
		self.selenium.get_webelement(search_button).send_keys(kwargs['Field_Name'])
		self.selenium.get_webelement(search_button).send_keys(Keys.ENTER)
		time.sleep(1)
		self.salesforce.wait_until_loading_is_complete()
		search_results = npsp_lex_locators['object_manager']['search_result'].format(kwargs['Field_Name'])
		count = len(self.selenium.get_webelements(search_results))
		if count >= 1:
			field = npsp_lex_locators['object_manager']['field_result'].format(kwargs['Field_Name'])
			new_picklst_btn = npsp_lex_locators['object_manager']['new_picklist_btn'].format('New Values')
			picklist_txtarea =  npsp_lex_locators['object_manager']['picklist_txtarea'].format('Status')
			picklist_save = npsp_lex_locators['object_manager']['button'].format('Save')
			self.selenium.wait_until_page_contains_element(field)
			self.selenium.click_element(field)
			self.npsp.wait_for_locator('frame_new', 'vfFrameId', 'vfFrameId')
			self.npsp.choose_frame('vfFrameId')
			self.selenium.wait_until_page_contains_element(new_picklst_btn)
			self.selenium.scroll_element_into_view(new_picklst_btn)
			self.selenium.click_element(new_picklst_btn)
			time.sleep(2)
			self.npsp.wait_for_locator('frame_new', 'vfFrameId', 'vfFrameId')
			self.npsp.choose_frame('vfFrameId')
			self.selenium.wait_until_page_contains_element(picklist_txtarea)
			for value in kwargs['Values']:
				self.selenium.get_webelement(picklist_txtarea).send_keys(value)
				self.selenium.get_webelement(picklist_txtarea).send_keys(Keys.ENTER)
			self.selenium.click_element(picklist_save)
		else:
			raise Exception(f"Field not found")

	def rename_object_field(self,object_name,field_name,new_name):
		"""Renames the field with new name if a field doesn't exist with that name"""
		save_button=npsp_lex_locators['object_manager']['button'].format("Save")
		self.open_fields_and_relationships(object_name)
		search_button = npsp_lex_locators['object_manager']['input'].format("globalQuickfind")
		self.selenium.wait_until_page_contains_element(search_button,60)
		self.selenium.get_webelement(search_button).send_keys(new_name)
		self.selenium.get_webelement(search_button).send_keys(Keys.ENTER)
		time.sleep(1)
		self.salesforce.wait_until_loading_is_complete()
		field_exists = self.selenium.get_webelements(npsp_lex_locators['object_manager']['search_result'].format(new_name))
		if not field_exists:
			self.selenium.clear_element_text(search_button)
			self.selenium.get_webelement(search_button).send_keys(field_name)
			self.selenium.get_webelement(search_button).send_keys(Keys.ENTER)
			time.sleep(1)
			self.salesforce.wait_until_loading_is_complete()
			search_result = npsp_lex_locators['object_manager']['search_result'].format(field_name)
			self.selenium.click_element(search_result)
			self.npsp.select_frame_and_click_element("Account Custom Field","object_manager.button","Edit")
			self.selenium.unselect_frame()
			self.npsp.wait_for_locator('frame_new', 'Edit Account Custom Field', 'Edit Account Custom Field')
			self.npsp.choose_frame('Edit Account Custom Field')
			self.selenium.wait_until_page_contains_element(save_button)
			locator = self.salesforce._get_input_field_locator('Field Label')
			element = self.selenium.get_webelement(locator)
			self.selenium.driver.execute_script("arguments[0].setAttribute(arguments[1], arguments[2]);", element, "onChange", "")
			self.salesforce.populate_field('Field Label', new_name)
			locator = self.salesforce._get_input_field_locator('Field Name')
			element = self.selenium.get_webelement(locator)
			self.selenium.driver.execute_script("arguments[0].setAttribute(arguments[1], arguments[2]);", element, "onChange", "")
			self.salesforce.populate_field('Field Name', new_name)
			self.selenium.click_element(save_button)

	def delete_object_field(self,object_name,field_name):
		"""Deletes the specified object field"""
		self.open_fields_and_relationships(object_name)
		search_button = npsp_lex_locators['object_manager']['input'].format("globalQuickfind")
		self.selenium.wait_until_page_contains_element(search_button,60)
		self.selenium.get_webelement(search_button).send_keys(field_name)
		self.selenium.get_webelement(search_button).send_keys(Keys.ENTER)
		time.sleep(1)
		self.salesforce.wait_until_loading_is_complete()
		search_result = npsp_lex_locators['object_manager']['field_dropdown'].format(field_name)
		self.selenium.click_element(search_result)
		delete_button=npsp_lex_locators["link-title"].format("Delete")
		self.selenium.wait_until_page_contains_element(delete_button)
		self.selenium.click_element(delete_button)
		self.salesforce.wait_until_modal_is_open()
		self.salesforce.click_modal_button("Delete")
		self.salesforce.wait_until_loading_is_complete()