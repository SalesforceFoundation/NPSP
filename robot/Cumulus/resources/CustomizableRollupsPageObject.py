from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Custom", "CustomRollupSettings")
class CustomRollupSettingsPage(BaseNPSPPage, BasePage):
	
	def navigate_to_crlpsettings(self):
		""" Click on the Navigate CRLP Button and wait for the page to load
		"""
		locator = npsp_lex_locators['id'].format("navigateCRLPs")
		self.selenium.click_element(locator)
		self.selenium.wait_until_location_contains("/one/one.app", timeout=60,
												   message="custom rollup settings page did not load in 1 min")
		self.npsp.wait_for_locator('frame_new', 'vfFrameId', 'vfFrameId')
		self.npsp.choose_frame('vfFrameId')
		link=npsp_lex_locators['link-text'].format("Back to NPSP Settings")										   
		self.selenium.wait_until_page_contains_element(link,
											  error="Current page is not a customizable rollups setting view")

	@capture_screenshot_on_error
	def clone_rollup(self,rollup_name, **kwargs):
		""" Clone an existing rollup and edit required fields and save
		"""
		locator = npsp_lex_locators['crlps']['rollup_options'].format(rollup_name)
		select_locator = npsp_lex_locators['crlps']['select_locator'].format("Target Object")
		success_toast = npsp_lex_locators['crlps']['success_toast']
		self.selenium.scroll_element_into_view(locator)
		self.selenium.click_element(locator)
		self.selenium.wait_until_page_contains("Clone")
		self.selenium.click_link("Clone")
		self.selenium.wait_until_page_contains_element(select_locator)
		self.npsp.populate_modal_form(**kwargs)
		self.selenium.click_button("Save")
		self.selenium.wait_until_element_is_not_visible(success_toast)	
 
	def verify_rollup_exists(self,**kwargs):
		"""Using API verifies if the rollup with specified key,value pairs exist, if doesn't exist raises exception"""
		ns=self.npsp.get_npsp_namespace_prefix()
		object=ns+'Rollup__mdt'
		record=self.salesforce.salesforce_query(object,**kwargs)
		if len(record)>0:
			self.builtin.log("This rollup exists")
		else:
			raise Exception("Rollup does not exist")	