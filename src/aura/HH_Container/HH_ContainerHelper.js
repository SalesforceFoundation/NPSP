({
    /*******************************************************************************************************
    * @description called at onInit to load up the Household Object/Account, and its Contacts
    */
	loadObjects : function(component) {
        component.set("v.showSpinner", true);
        var hhId = component.get('v.hhId');
        component.set('v.hhTypePrefix', new String(hhId).substr(0, 3));
        
        // query for the Household account/object 
		var action = component.get("c.getHH");
        action.setParams({ hhId : hhId });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var hh = response.getReturnValue();
				component.set("v.hh", hh);

                // set our auto-naming checkbox states
                var strExclusions = hh.npo02__SYSTEM_CUSTOM_NAMING__c;
                component.set('v.isAutoName', strExclusions == null || !strExclusions.includes('Name'));
                component.set('v.isAutoFormalGreeting', strExclusions == null || !strExclusions.includes('Formal_Greeting__c'));
                component.set('v.isAutoInformalGreeting', strExclusions == null || !strExclusions.includes('Informal_Greeting__c'));
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);        

        // query for the Household Contacts 
		var action = component.get("c.getContacts");
        action.setParams({ hhId : hhId });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();            
			if (component.isValid() && state === "SUCCESS") {
                var listCon = response.getReturnValue();
				component.set("v.listCon", listCon);                
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
        });
		$A.enqueueAction(action);        

        // query for the Contact Salutations
		var action = component.get("c.getSalutations");
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var listSalutation = response.getReturnValue();
				component.set("v.listSalutation", listSalutation);                
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
        });
		$A.enqueueAction(action);        

        // query for the Addresses 
		var action = component.get("c.getAddresses");
        action.setParams({ hhId : hhId });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var listAddr = response.getReturnValue();
				component.set("v.listAddr", listAddr);                
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            

            // hide our initial startup spinner our visualforce container displays
            j$('.initialSpinner').hide();                                  
        });
		$A.enqueueAction(action);        
    },
    
    /*******************************************************************************************************
    * @description get updated names and greetings from server's custom naming code
    */
	updateHHNames : function(component) {
        var hh = component.get('v.hh');
        var listCon = component.get('v.listCon');     
        
        // update our auto-naming exclusion states
        this.updateNamingExclusions(component, hh);
        
        // get updated Names and Greetings 
		var action = component.get("c.getHHNamesGreetings");
        action.setParams({ hh : hh, listCon : listCon });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var hh = response.getReturnValue();
				component.set("v.hh", hh);
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);        
    },

    /*******************************************************************************************************
    * @description helper to display an errors that occur from a server method call
    */
    reportError : function(component, response) {
        var errors = response.getError();
        if (errors) {
            $A.log("Errors", errors);
            if (errors[0] && errors[0].message) {
                this.displayUIMessage(component, errors[0].message, "divUIMessageContainer");
            } else if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0].message) {
                this.displayUIMessage(component, errors[0].pageErrors[0].message, "divUIMessageContainer");
            } else {
                this.displayUIMessage(component, "Unknown error", "divUIMessageContainer");
            }
        } else {
            this.displayUIMessage(component, "Unknown error", "divUIMessageContainer");
        }        
    },

    /*******************************************************************************************************
    * @description creates a ui:message component for the given error string
    */
    displayUIMessage : function(component, strError, whichDiv) {
        $A.createComponents([
            ["ui:message",{
                "title" : "Error",
                "severity" : "error",
            }],
            ["ui:outputText",{
                "value" : strError
            }]
        ],
            function(components, status) {
                if (status === "SUCCESS") {
                    var message = components[0];
                    var outputText = components[1];
                    // set the body of the ui:message to be the ui:outputText
                    message.set("v.body", outputText);
                    var div = component.find(whichDiv);
                    // Replace div body with the dynamic component
                    div.set("v.body", message);
                }
       });
    },
    
    /*******************************************************************************************************
    * @description Saves all changes the container knows about (household object/account, contacts), and
    * if successful, then calls the visualforce page's save actionMethod, which will also close the page.
    */
    save : function(component) {
        component.set("v.showSpinner", true);
        
		// keep track of ourselves and whether both server updates succeed
        var self = this;
        var callbacksWaiting = 4;
        
        // first need to merge any households before we save contacts
        // so we avoid deleting a household if that contact was the last one in the hh.
        var listHHMerge = component.get('v.listHHMerge');
        var hh = component.get('v.hh');
        var action = component.get("c.mergeHouseholds");
        action.setParams({ hhWinner : hh, listHHMerge : listHHMerge });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                if (--callbacksWaiting == 0) {
                    saveAndCloseVisualforce();
                }
            }
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
        });
        $A.enqueueAction(action);
        
        // save the contacts
        var listCon = component.get("v.listCon");
		var action = component.get("c.upsertContacts");
        action.setParams({ listCon : listCon});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                if (--callbacksWaiting == 0) {
                    saveAndCloseVisualforce();
                }
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);

        // update our auto-naming exclusion states
        var hh = component.get("v.hh");
        this.updateNamingExclusions(component, hh);
        
        // save the Household
		var action = component.get("c.updateHousehold");
        action.setParams({ hh : hh});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                if (--callbacksWaiting == 0) {
                    saveAndCloseVisualforce();
                }
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);

        // delete any contacts
        var listConDelete = component.get("v.listConDelete");
		var action = component.get("c.deleteContacts");
        action.setParams({ listCon : listConDelete});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                if (--callbacksWaiting == 0) {
                    saveAndCloseVisualforce();
                }
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
		});
		$A.enqueueAction(action);
    },
    
    /*******************************************************************************************************
	* @description Update our auto-naming exclusion states based on our checkboxes.
    */
    updateNamingExclusions : function(component, hh) {
		var strExclusions = '';
        if (!component.get('v.isAutoName'))
            strExclusions += 'Household__c.Name;';
        if (!component.get('v.isAutoFormalGreeting'))
            strExclusions += 'Household__c.Formal_Greeting__c;';
        if (!component.get('v.isAutoInformalGreeting'))
            strExclusions += 'Household__c.Informal_Greeting__c;';
        hh.npo02__SYSTEM_CUSTOM_NAMING__c = strExclusions;   
    },

    /*******************************************************************************************************
	* @description Update our auto-naming exclusion states based on Name/Greeting Changes
    */
    updateAutoNaming : function(component, event) {
        var inputText = event.getSource();
        var idText = inputText.getLocalId();
        
        if (idText == 'txtHHName')
            component.set('v.isAutoName', false);
        else if (idText == 'txtFormalGreeting')
            component.set('v.isAutoFormalGreeting', false);
        else if (idText == 'txtInformalGreeting')
            component.set('v.isAutoInformalGreeting', false);
    },

    /*******************************************************************************************************
	* @description Ask the user if the Contact should be deleted, by displaying our delete contact popup.
    */
    promptDeleteContact : function(component, event) {
        var con = event.getParam("contact")
        component.set('v.showDeleteContactPopup', true);
        component.set('v.conDelete', con);
    },

    /*******************************************************************************************************
	* @description The user has decided not to delete the contact, so remove our delete contact popup.
    */
    cancelDeleteContact : function(component, event) {
        component.set('v.showDeleteContactPopup', false);
    },

    /*******************************************************************************************************
	* @description The user has confirmed the contact should be deleted.  
    * Remove our delete contact popup.
    * Add the contact to our list of contacts to delete.  
    * Remove the contact from our list of contacts in the household.  
    * Update all household names and greetings.
    */
    doDeleteContact : function(component, event) {
        component.set('v.showDeleteContactPopup', false);
        var con = component.get('v.conDelete');
        if (con != null) {
            var listConDelete = component.get('v.listConDelete');
            if (listConDelete == null)
                listConDelete = [];
            if (con.Id != null)
	            listConDelete.push(con);
            component.set('v.listConDelete', listConDelete);

            var listCon = component.get('v.listCon');
            var iconDel = listCon.indexOf(con);
            if (iconDel >= 0)
	            listCon.splice(iconDel, 1);
            component.set('v.listCon', listCon);
            this.updateHHNames(component);

            // we must tell the visualforce page, in case the primary contact lookup is to this contact.
            // ideally, the visualforce page would listen for a lightning event, but we haven't figured
            // out how to do that!
            contactRemoved(con);
        }
    },

    /*******************************************************************************************************
	* @description Close the page by redirecting back to the household
    */
    close : function(component) {
        // the correct way to handle navigation in Salesforce classic vs. LEX/mobile
        if (typeof sforce === "undefined") {
	    	window.top.location.replace('/' + component.get('v.hhId'));
        } else {
	    	sforce.one.navigateToSObject(component.get('v.hhId'));
        }
    },                           

    /*******************************************************************************************************
	* @description The default adddress has changed, so update our household and contacts
    */
    updateDefaultAddress : function(component, event) {
        var addr = event.getParam('addrDefault');
        var hh = component.get('v.hh');
        var isAccount = component.get('v.hhTypePrefix') == '001';
        
        // update the household
        if (isAccount) {
            hh.BillingStreet = addr.MailingStreet__c;
            if (addr.MailingStreet2__c != null) 
                hh.BillingStreet += '\n' + addr.MailingStreet2__c;
            hh.BillingCity = addr.MailingCity__c;
            hh.BillingState = addr.MailingState__c;
            hh.BillingPostalCode = addr.MailingPostalCode__c;
            hh.BillingCountry = addr.MailingCountry__c;
        } else {
            hh.npo02__MailingStreet__c = addr.MailingStreet__c;
            if (addr.MailingStreet2__c != null) 
                hh.npo02__MailingStreet__c += ',' + addr.MailingStreet2__c;
            hh.npo02__MailingCity__c = addr.MailingCity__c;
            hh.npo02__MailingState__c = addr.MailingState__c;
            hh.npo02__MailingPostalCode__c = addr.MailingPostalCode__c;
            hh.npo02__MailingCountry__c = addr.MailingCountry__c;            
        }
        component.set('v.hh', hh);
        
        // update the contacts
        var listCon = component.get('v.listCon');
        for (var i = 0; i < listCon.length; i++) {
            var con = listCon[i];
            if (!con.is_Address_Override__c) {
                this.copyAddrToContact(addr, con);
            }
        }
        component.set('v.listCon', listCon);
    },

    /*******************************************************************************************************
	* @description copy the address object to the appropriate contact fields
    */
    copyAddrToContact : function(addr, con) {
        con.MailingStreet = addr.MailingStreet__c;
        if (addr.MailingStreet2__c != null) 
            con.MailingStreet += '\n' + addr.MailingStreet2__c;
        con.MailingCity = addr.MailingCity__c;
        con.MailingState = addr.MailingState__c;
        con.MailingPostalCode = addr.MailingPostalCode__c;
        con.MailingCountry = addr.MailingCountry__c;
    },
    
    /*******************************************************************************************************
	* @description fixup custom labels exposed thru $Label, so the ones from the wrong namespace are null.
    */
    fixupCustomLabels : function(component) {
        // get access to the label global value provider which appears as an object, with a subobject
        // for each namespace, and property for each label.
        var lbl = $A.get('$Label');
        for (var nspace in lbl) {
            for (var str in lbl[nspace]) {
                // the labels that fail to get resolved appear as
                // "$Label.namespace.foo does not exist: Field $Label.namespace__foo does not exist. Check spelling."
                if (lbl[nspace][str] != null && lbl[nspace][str].startsWith('$Label'))
                    lbl[nspace][str] = null;
            }
        }
    },                           

    /*******************************************************************************************************
	* @description initialize a new Contact SObject
    */
    initNewContact : function(component) {
        var hhId = component.get('v.hhId');        
        var hhTypePrefix = component.get('v.hhTypePrefix');   
        var con = {'sobjectType': 'Contact'};
        if (hhTypePrefix == '001')
            con.AccountId = hhId;
        else
            con.npo02__Household__c = hhId;
        con.hhId = hhId;
        component.set('v.conNew', con);
    },                           

    /*******************************************************************************************************
	* @description add the new contact to the household, and update the household
    */
    createNewContact : function(component) {
        var listCon = component.get('v.listCon');
        var conNew = component.get('v.conNew');
        
        // perform field validation, which we don't get for free
        if (conNew.LastName == null) {
            this.displayUIMessage(component, $A.get("$Label.npo02.ContactLastNameRqd"), "divUIMessageNewContactPopup");
            return;
        }
        
		var addrDefault = component.find('addrMgr').get('v.addrDefault');
        if (addrDefault != null)
            this.copyAddrToContact(addrDefault, conNew);
        listCon.push(conNew);
        component.set('v.listCon', listCon);
        this.initNewContact(component);
        component.set('v.showNewContactPopup', false);

        // force our names to update since we have a new contact!
        this.updateHHNames(component);
    },                           

    /*******************************************************************************************************
	* @description the Salutation picklist has changed; update our contact.
    */
    onSalutationChange : function(component) {
        var conNew = component.get('v.conNew');
        conNew.Salutation = component.find('selSalutation').get('v.value');
        component.set('v.conNew', conNew);
    },
    
    /*******************************************************************************************************
    * @description merge the specified household and its contacts into the existing household
    */
	mergeHousehold : function(component, hhMerge) {
        component.set("v.showSpinner", true);
        var hhId = component.get('v.hhId');
        var hhTypePrefix = component.get('v.hhTypePrefix');        

        // query for the Household Contacts 
		var action = component.get("c.getContacts");
        action.setParams({ hhId : hhMerge.Id });
		var self = this;
		action.setCallback(this, function(response) {
			var state = response.getState();            
			if (component.isValid() && state === "SUCCESS") {
                var listConMerge = response.getReturnValue();
				var listCon = component.get("v.listCon");
                
				// move all contacts into our household
				var cExisting = listCon.length;
                for (var i in listConMerge) {
                    if (hhTypePrefix == '001')
                        listConMerge[i].AccountId = hhId;
                    else
                        listConMerge[i].npo02__Household__c = hhId;
                    listConMerge[i].npo02__Household_Naming_Order__c = i + cExisting;
                    listCon.push(listConMerge[i]);
                }               
                component.set('v.listCon', listCon);                
                
                // remember that we need to merge the hh at save time
                var listHHMerge = component.get('v.listHHMerge');
                if (listHHMerge == null)
                    listHHMerge = [];
                listHHMerge.push(hhMerge);

                // force our names to update since we have a new contact!
                this.updateHHNames(component);
			}
            else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }            
        });
		$A.enqueueAction(action);        

        // UNDONE: query for the Addresses from hhMerge?
        // UNDONE: update the merged contact's addresses to the hh default?
    },
    
})