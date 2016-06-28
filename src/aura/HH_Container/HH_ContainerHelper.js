({
    /*******************************************************************************************************
     * @description called at onInit to load up the Household Object/Account, and its Contacts
     */
    loadObjects: function(component) {
        component.set("v.showSpinner", true);
        var hhId = component.get('v.hhId');
        component.set('v.hhTypePrefix', String(hhId).substr(0, 3));
        var namespacePrefix = component.get('v.namespacePrefix');

        // query for the Household account/object
        var action = component.get("c.getHH");
        action.setParams({
            hhId: hhId
        });
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var hh = response.getReturnValue();
                // now we need to fixup namespacing of fields
                hh = this.removePrefixFromObjectFields(namespacePrefix, hh);
                component.set("v.hh", hh);

                // set our auto-naming checkbox states
                var strExclusions = hh.npo02__SYSTEM_CUSTOM_NAMING__c;
                component.set('v.isAutoName', !strExclusions || !strExclusions.includes('Name'));
                component.set('v.isAutoFormalGreeting', !strExclusions || !strExclusions.includes('Formal_Greeting__c'));
                component.set('v.isAutoInformalGreeting', !strExclusions || !strExclusions.includes('Informal_Greeting__c'));
            } else if (component.isValid() && state === "ERROR") {
                component.set('v.isSaveDisabled', true);
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);

        // query for the Household Contacts
        action = component.get("c.getContacts");
        action.setParams({
            hhId: hhId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var listCon = response.getReturnValue();
                // now we need to fixup namespacing of fields
                listCon = this.removePrefixFromListObjectFields(namespacePrefix, listCon);
                component.set("v.listCon", listCon);
            } else if (component.isValid() && state === "ERROR") {
                component.set('v.isSaveDisabled', true);
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);

        // query for the Contact Salutations
        action = component.get("c.getSalutations");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var listSalutation = response.getReturnValue();
                component.set("v.listSalutation", listSalutation);
            } else if (component.isValid() && state === "ERROR") {
                component.set('v.isSaveDisabled', true);
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);

        // query for Contact Delete permissions
        action = component.get("c.isDeletable");
        action.setParams({
            strSObject: 'Contact'
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.allowContactDelete", response.getReturnValue());
            } else if (component.isValid() && state === "ERROR") {
                component.set('v.isSaveDisabled', true);
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);

        // query for Household Delete permissions for merge usage
        var strSObject = 'Account';
        if (component.get('v.hhTypePrefix') !== '001') {
            strSObject = 'npo02__Household__c';
        }
        action = component.get("c.isDeletable");
        action.setParams({
            strSObject: strSObject
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.allowHouseholdMerge", response.getReturnValue());
            } else if (component.isValid() && state === "ERROR") {
                component.set('v.isSaveDisabled', true);
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);

        // query for the Addresses
        action = component.get("c.getAddresses");
        action.setParams({
            hhId: hhId,
            listAddrExisting: null
        });
        action.setCallback(this, function(response) {

            // tell our visualforce page we are done loading
            var event = $A.get("e.c:HH_ContainerLoadedEvent");
            event.fire();

            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var listAddr = response.getReturnValue();
                // now we need to fixup namespacing of fields
                listAddr = this.removePrefixFromListObjectFields(namespacePrefix, listAddr);
                component.set("v.listAddr", listAddr);
            } else if (component.isValid() && state === "ERROR") {
                component.set('v.isSaveDisabled', true);
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);
    },

    /*******************************************************************************************************
     * @description get updated names and greetings from server's custom naming code
     */
    updateHHNames: function(component) {
        var hh = component.get('v.hh');
        var listCon = component.get('v.listCon');

        // update our auto-naming exclusion states
        this.updateNamingExclusions(component, hh);

        // get updated Names and Greetings
        var action = component.get("c.getHHNamesGreetings");
        // now we need to fixup namespacing of fields
        var namespacePrefix = component.get('v.namespacePrefix');
        hh = this.addPrefixToObjectFields(namespacePrefix, hh);
        listCon = this.addPrefixToListObjectFields(namespacePrefix, listCon);
        action.setParams({
            hh: hh,
            listCon: listCon
        });
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                hh = response.getReturnValue();
                hh = this.removePrefixFromObjectFields(namespacePrefix, hh);
                component.set("v.hh", hh);
            } else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);
    },

    /*******************************************************************************************************
     * @description helper to display an errors that occur from a server method call
     */
    reportError: function(component, response) {
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
    displayUIMessage: function(component, strError, whichDiv) {
        $A.createComponents([
                ["ui:message", {
                    "title": "Error",
                    "severity": "error"
                }],
                ["ui:outputText", {
                    "value": strError
                }]
            ],
            function(components, status) {
                if (status === "SUCCESS") {
                    var message = components[0];
                    var outputText = components[1];
                    // set the body of the ui:message to be the ui:outputText
                    message.set("v.body", outputText);
                    var div = component.find(whichDiv);
                    if (div) {
                        // append div body with the dynamic component
                        var curMsg = div.get('v.body');
                        curMsg.push(message);
                        div.set("v.body", curMsg);
                    }
                }
            });
    },

    /*******************************************************************************************************
     * @description Saves all changes the container knows about (household object/account, contacts), and
     * if successful, then calls the visualforce page's save actionMethod, which will also close the page.
     */
    save: function(component) {
        component.set("v.showSpinner", true);

        // keep track of ourselves and whether both server updates succeed
        var self = this;
        var callbacksWaiting = 4;
        var action;

        // create our shared callback code
        var callback = function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                if (--callbacksWaiting === 0) {
                    // tell our visualforce page we are done saving, so it should save
                    // its data and close the page.
                    var event = $A.get("e.c:HH_HouseholdSavedEvent");
                    event.fire();
                }
            } else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }
        };

        // first need to merge any households (Accounts only) before we save contacts
        // so we avoid deleting a household if that contact was the last one in the hh.
        var listHHMerge = component.get('v.listHHMerge');
        var hh = component.get('v.hh');
        var namespacePrefix = component.get('v.namespacePrefix');
        hh = this.addPrefixToObjectFields(namespacePrefix, hh);
        if (listHHMerge && listHHMerge.length > 0) {
            listHHMerge = this.addPrefixToListObjectFields(namespacePrefix, listHHMerge);
            action = component.get("c.mergeHouseholds");
            action.setParams({
                hhWinner: hh,
                listHHMerge: listHHMerge
            });
            action.setCallback(this, callback);
            $A.enqueueAction(action);
        } else {
            callbacksWaiting--;
        }

        // save the contacts
        var listCon = component.get("v.listCon");
        listCon = this.addPrefixToListObjectFields(namespacePrefix, listCon);
        action = component.get("c.upsertContacts");
        action.setParams({
            listCon: listCon
        });
        action.setCallback(this, callback);
        $A.enqueueAction(action);

        // update our auto-naming exclusion states
        this.updateNamingExclusions(component, hh);

        // save the Household
        action = component.get("c.updateHousehold");
        action.setParams({
            hh: hh
        });
        action.setCallback(this, callback);
        $A.enqueueAction(action);

        // delete any contacts
        var listConDelete = component.get("v.listConDelete");
        listConDelete = this.addPrefixToListObjectFields(namespacePrefix, listConDelete);
        action = component.get("c.deleteContacts");
        action.setParams({
            listCon: listConDelete
        });
        action.setCallback(this, callback);
        $A.enqueueAction(action);
    },

    /*******************************************************************************************************
     * @description Update our auto-naming exclusion states based on our checkboxes.
     */
    updateNamingExclusions: function(component, hh) {
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
    updateAutoNaming: function(component, event) {
        var inputText = event.getSource();
        var idText = inputText.getLocalId();

        if (idText === 'txtHHName')
            component.set('v.isAutoName', false);
        else if (idText === 'txtFormalGreeting')
            component.set('v.isAutoFormalGreeting', false);
        else if (idText === 'txtInformalGreeting')
            component.set('v.isAutoInformalGreeting', false);
    },

    /*******************************************************************************************************
     * @description Ask the user if the Contact should be deleted, by displaying our delete contact popup.
     */
    promptDeleteContact: function(component, event) {
        var con = event.getParam("contact");
        component.set('v.showDeleteContactPopup', true);
        component.set('v.conDelete', con);
    },

    /*******************************************************************************************************
     * @description The user has decided not to delete the contact, so remove our delete contact popup.
     */
    cancelDeleteContact: function(component /* , event */ ) {
        component.set('v.showDeleteContactPopup', false);
    },

    /*******************************************************************************************************
     * @description The user has confirmed the contact should be deleted.
     * Remove our delete contact popup.
     * Add the contact to our list of contacts to delete.
     * Remove the contact from our list of contacts in the household.
     * Update all household names and greetings.
     */
    doDeleteContact: function(component, event) {
        component.set('v.showDeleteContactPopup', false);
        var con = component.get('v.conDelete');
        if (con) {
            var listConDelete = component.get('v.listConDelete');
            if (!listConDelete)
                listConDelete = [];
            if (con.Id)
                listConDelete.push(con);
            component.set('v.listConDelete', listConDelete);

            var listCon = component.get('v.listCon');
            var iconDel = this.findContact(listCon, con);
            if (iconDel >= 0)
                listCon.splice(iconDel, 1);
            component.set('v.listCon', listCon);
            this.updateHHNames(component);

            // we must tell the visualforce page, in case the primary contact lookup is to this contact.
            event = $A.get("e.c:HH_ContactAfterDeleteEvent");
            event.setParams({
                "contact": con
            });
            event.fire();
        }
    },

    /*******************************************************************************************************
     * @description find the contact in the list
     * @param listCon the list of Contacts
     * @param con the contact to find
     * @return iCon the index to the found contact, or -1 if not found.
     */
    findContact: function(listCon, con) {
        var iCon;
        for (iCon = 0; iCon < listCon.length; iCon++) {
            var con2 = listCon[iCon];
            if (con.Id && con.Id === con2.Id)
                return iCon;
            if (!con.Id && !con2.Id && con.dtNewContact === con2.dtNewContact)
                return iCon;
        }
        return -1;
    },

    /*******************************************************************************************************
     * @description Close the page by redirecting back to the household
     */
    close: function(component) {
        // the correct way to handle navigation in Salesforce classic vs. LEX/mobile
        /*global sforce */
        if (typeof sforce === "undefined") {
            window.location.replace('/' + component.get('v.hhId'));
        } else {
            sforce.one.navigateToSObject(component.get('v.hhId'));
        }
    },

    /*******************************************************************************************************
     * @description The default adddress has changed, so update our household and contacts
     */
    updateDefaultAddress: function(component, addr) {
        var hh = component.get('v.hh');
        var isAccount = component.get('v.hhTypePrefix') === '001';

        // update the household
        if (isAccount) {
            hh.BillingStreet = addr.MailingStreet__c;
            if (addr.MailingStreet2__c)
                hh.BillingStreet += '\n' + addr.MailingStreet2__c;
            hh.BillingCity = addr.MailingCity__c;
            hh.BillingState = addr.MailingState__c;
            hh.BillingPostalCode = addr.MailingPostalCode__c;
            hh.BillingCountry = addr.MailingCountry__c;
        } else {
            hh.npo02__MailingStreet__c = addr.MailingStreet__c;
            if (addr.MailingStreet2__c)
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
    copyAddrToContact: function(addr, con) {
        con.MailingStreet = addr.MailingStreet__c;
        if (addr.MailingStreet2__c)
            con.MailingStreet += '\n' + addr.MailingStreet2__c;
        con.MailingCity = addr.MailingCity__c;
        con.MailingState = addr.MailingState__c;
        con.MailingPostalCode = addr.MailingPostalCode__c;
        con.MailingCountry = addr.MailingCountry__c;
    },

    /*******************************************************************************************************
     * @description fixup custom labels exposed thru $Label, so the ones from our namespace work for 'c'
     */
    fixupCustomLabels: function(component) {
        var namespacePrefix = component.get('v.namespacePrefix');

        if (namespacePrefix && namespacePrefix.length > 0) {
            var nspace = namespacePrefix.replace('__', '');

            // get access to the label global value provider which appears as an object, with a subobject
            // for each namespace, and property for each label.
            var lbl = $A.get('$Label');

            for (var str in lbl['c']) {
                // the labels that fail to get resolved appear as
                // "$Label namespace.foo does not exist: Field $Label namespace__foo does not exist. Check spelling."
                if (lbl['c'][str] && lbl['c'][str].startsWith('$Label'))
                    lbl['c'][str] = lbl[nspace][str];
            }
        }
        return;
        
        // force the following label references, or these won't be available to $Label.
        try {
            $A.get("$Label.npsp.lblAddressOverride");
            $A.get("$Label.npsp.lblCCardExcludeFrom");
            $A.get("$Label.npsp.lblHouseholdName");
            $A.get("$Label.npsp.lblFormalGreeting");
            $A.get("$Label.npsp.lblInformalGreeting");
            $A.get("$Label.npsp.lblHousehold");
            $A.get("$Label.npsp.lblDeleteContact");
            $A.get("$Label.npsp.lblDeleteContactPrompt");
            $A.get("$Label.npsp.lblStreet");
            $A.get("$Label.npsp.lblCity");
            $A.get("$Label.npsp.lblState");
            $A.get("$Label.npsp.lblPostalCode");
            $A.get("$Label.npsp.lblCountry");
            $A.get("$Label.npsp.lblSalutation");
            $A.get("$Label.npsp.lblFirstName");
            $A.get("$Label.npsp.lblLastName");
            $A.get("$Label.npsp.stgBtnCancel");
            $A.get("$Label.npsp.stgBtnSave");
            $A.get("$Label.npsp.bdiBtnClose");
            $A.get("$Label.npsp.lblMergeHHTitle");
            $A.get("$Label.npsp.lblMergeHHPrompt");
            $A.get("$Label.npsp.lblBtnAddContact");
            $A.get("$Label.npsp.lblBtnAddAllHHMembers");
            $A.get("$Label.npsp.lblFindOrAddContact");
            $A.get("$Label.npsp.lblFindInContacts");
            $A.get("$Label.npsp.lblNoHHMergePermissions");
        } catch(e) {
        }
        
    },

    /*******************************************************************************************************
     * @description show the New Contact Popup in response to the ContactNewEvent
     */
    showNewContactPopup: function(component, event) {
        var con = event.getParam('contact');
        var conNew = component.get('v.conNew');
        conNew.FirstName = con.FirstName;
        conNew.LastName = con.LastName;
        component.set('v.conNew', conNew);
        component.set('v.showNewContactPopup', true);
    },

    /*******************************************************************************************************
     * @description initialize a new Contact SObject
     */
    initNewContact: function(component) {
        var hhId = component.get('v.hhId');
        var hhTypePrefix = component.get('v.hhTypePrefix');
        var con = {
            'sobjectType': 'Contact'
        };
        if (hhTypePrefix === '001')
            con.AccountId = hhId;
        else
            con.npo02__Household__c = hhId;
        con.hhId = hhId;
        // tag each new contact with a timestamp, so we can identify it if we need to delete it.
        con.dtNewContact = Date.now();
        component.set('v.conNew', con);
    },

    /*******************************************************************************************************
     * @description add the new contact to the household, and update the household
     */
    createNewContact: function(component) {
        var listCon = component.get('v.listCon');
        var conNew = component.get('v.conNew');

        // perform field validation, which we don't get for free
        if (!conNew.LastName) {
            this.displayUIMessage(component, $A.get("$Label.npo02.ContactLastNameRqd"), "divUIMessageNewContactPopup");
            return;
        }

        var addrDefault = component.find('addrMgr').get('v.addrDefault');
        if (addrDefault)
            this.copyAddrToContact(addrDefault, conNew);
        conNew.npo02__Household_Naming_Order__c = listCon.length;
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
    onSalutationChange: function(component) {
        var conNew = component.get('v.conNew');
        conNew.Salutation = component.find('selSalutation').get('v.value');
        component.set('v.conNew', conNew);
    },

    /*******************************************************************************************************
     * @description sees if the contact is NOT the lone member of a household, in which case it will bring up
     * our Merge Household popup.  if they are the lone member, it will just proceed with the HH merge.
     */
    addOrMergeContact: function(component, event) {
        var namespacePrefix = component.get('v.namespacePrefix');
        var conAdd = event.getParam('value');
        conAdd = this.removePrefixFromObjectFields(namespacePrefix, conAdd);

        var cMembers = 0;
        var hhId = conAdd.HHId__c;

        if (hhId && String(hhId).substr(0, 3) === '001') {
            var acc = conAdd.Account;
            cMembers = acc.Number_of_Household_Members__c;
        } else if (conAdd.npo02__Household__c) {
            cMembers = conAdd.npo02__Household__r.Number_of_Household_Members__c;
        }
        var hhMerge = {
            'Id': hhId
        };
        hhMerge.Number_of_Household_Members__c = cMembers;
        component.set('v.hhMerge', hhMerge);
        component.set('v.conAdd', conAdd);

        // if we can't merge households (due to permissions), we only support moving a contact
        // from one household to another if there will still be remaining household members.
        // otherwise the household would need to get deleted which we can't allow.
        if (!component.get('v.allowHouseholdMerge')) {
            if (cMembers > 1) {
                this.addContact(component, conAdd);
                return;
            } else {
                this.displayUIMessage(component, $A.get("$Label.c.lblNoHHMergePermissions"), "divUIMessageContainer");
                return;
            }
        }

        // handle contacts not in a household account, and having no household object.
        if (!hhId) {
            this.addContact(component, conAdd);
            // if only one contact in household, merge the households
        } else if (cMembers === 1) {
            this.mergeHousehold(component, hhMerge);
            // more contacts in household, prompt for add vs merge.
        } else {
            component.set('v.showMergeHHPopup', true);
        }
    },

    /*******************************************************************************************************
     * @description add the Contact to the existing household
     */
    addContact: function(component, conAdd) {
        component.set("v.showSpinner", true);
        var hhId = component.get('v.hhId');
        var hhTypePrefix = component.get('v.hhTypePrefix');
        var listCon = component.get("v.listCon");

        if (hhTypePrefix === '001')
            conAdd.AccountId = hhId;
        else
            conAdd.npo02__Household__c = hhId;
        // put them at the end of our naming list
        conAdd.npo02__Household_Naming_Order__c = listCon.length;
        listCon.push(conAdd);
        component.set('v.listCon', listCon);

        // update the contact's addresses to the hh default (if they have no override)
        var addrDefault = component.find('addrMgr').get('v.addrDefault');
        if (addrDefault)
            this.updateDefaultAddress(component, addrDefault);

        // UNDONE: need to add the contact's address to our address mgr (if not override)

        // force our names to update since we have new contacts!
        this.updateHHNames(component);

        // add the Contact's address to our list
        var action = component.get("c.addContactAddresses");
        var listAddr = component.get('v.listAddr');
        var namespacePrefix = component.get('v.namespacePrefix');
        // because our address objects aren't real, we need to
        // tell the system what type of sobject they are
        for (var i in listAddr)
            listAddr[i].sobjectType = namespacePrefix + 'Address__c';
        listCon = [conAdd];
        listCon = this.addPrefixToListObjectFields(namespacePrefix, listCon);
        listAddr = this.addPrefixToListObjectFields(namespacePrefix, listAddr);
        action.setParams({
            listCon: listCon,
            listAddrExisting: listAddr
        });
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                listAddr = response.getReturnValue();
                listAddr = this.removePrefixFromListObjectFields(namespacePrefix, listAddr);
                component.set("v.listAddr", listAddr);
            } else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);

    },

    /*******************************************************************************************************
     * @description merge the specified household and its contacts into the existing household
     */
    mergeHousehold: function(component, hhMerge) {
        component.set("v.showSpinner", true);
        var hhId = component.get('v.hhId');
        var hhTypePrefix = component.get('v.hhTypePrefix');
        var namespacePrefix = component.get('v.namespacePrefix');

        // query for the Household Contacts
        var action = component.get("c.getContacts");
        action.setParams({
            hhId: hhMerge.Id
        });
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var listConMerge = response.getReturnValue();
                listConMerge = this.removePrefixFromListObjectFields(namespacePrefix, listConMerge);
                var listCon = component.get("v.listCon");

                // move all contacts into our household
                var cExisting = listCon.length;
                for (var i in listConMerge) {
                    if (hhTypePrefix === '001')
                        listConMerge[i].AccountId = hhId;
                    else
                        listConMerge[i].npo02__Household__c = hhId;
                    // put them at the end of our naming list
                    listConMerge[i].npo02__Household_Naming_Order__c = i + cExisting;
                    listCon.push(listConMerge[i]);
                }
                component.set('v.listCon', listCon);

                // update the merged contact's addresses to the hh default (if they have no override)
                var addrDefault = component.find('addrMgr').get('v.addrDefault');
                if (addrDefault)
                    this.updateDefaultAddress(component, addrDefault);

                // remember that we need to merge the hh at save time (HH Accounts only!)
                if (hhTypePrefix === '001') {
                    var listHHMerge = component.get('v.listHHMerge');
                    if (!listHHMerge)
                        listHHMerge = [];
                    listHHMerge.push(hhMerge);
                }

                // force our names to update since we have new contacts!
                this.updateHHNames(component);
            } else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);

        // query for the new Addresses
        action = component.get("c.getAddresses");
        var listAddr = component.get('v.listAddr');
        // because our address objects aren't real, we need to
        // tell the system what type of sobject they are
        for (var i in listAddr)
            listAddr[i].sobjectType = namespacePrefix + 'Address__c';
        listAddr = this.addPrefixToListObjectFields(namespacePrefix, listAddr);
        action.setParams({
            hhId: hhMerge.Id,
            listAddrExisting: listAddr
        });
        self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                listAddr = response.getReturnValue();
                listAddr = this.removePrefixFromListObjectFields(namespacePrefix, listAddr);
                component.set("v.listAddr", listAddr);
            } else if (component.isValid() && state === "ERROR") {
                self.reportError(component, response);
            }
        });
        $A.enqueueAction(action);

    },

    /*******************************************************************************************************
     * @description add the namespace prefix to any object custom fields that have no prefix
     */
    addPrefixToObjectFields: function(namespacePrefix, object) {
        return this.processPrefixObjectFields(namespacePrefix, object, true);
    },

    /*******************************************************************************************************
     * @description remove the namespace prefix from any object custom fields that have it
     */
    removePrefixFromObjectFields: function(namespacePrefix, object) {
        return this.processPrefixObjectFields(namespacePrefix, object, false);
    },

    /*******************************************************************************************************
     * @description add the namespace prefix to a list of objects with custom fields that have no prefix
     */
    addPrefixToListObjectFields: function(namespacePrefix, listObject) {
        if (namespacePrefix && namespacePrefix.length > 0) {
            var listObj = [];
            for (var object in listObject) {
                var obj = this.processPrefixObjectFields(namespacePrefix, listObject[object], true);
                listObj.push(obj);
            }
            return listObj;
        } else {
            return listObject;
        }
    },

    /*******************************************************************************************************
     * @description remove the namespace prefix to a list of objects with custom fields that have the prefix
     */
    removePrefixFromListObjectFields: function(namespacePrefix, listObject) {
        if (namespacePrefix && namespacePrefix.length > 0) {
            var listObj = [];
            for (var object in listObject) {
                var obj = this.processPrefixObjectFields(namespacePrefix, listObject[object], false);
                listObj.push(obj);
            }
            return listObj;
        } else {
            return listObject;
        }
    },

    /*******************************************************************************************************
     * @description adds or removes namespace prefix from the object's custom fields
     */
    processPrefixObjectFields: function(namespacePrefix, object, isAdd) {
        if (namespacePrefix && namespacePrefix.length > 0) {

            var obj = {}; //create object

            // process namespace prefix from each custom field
            for (var fld in object) {
                if (isAdd) {
                    // see if custom field has no namespace prefix
                    if (fld.endsWith('__c') && fld.indexOf('__') === fld.lastIndexOf('__')) {
                        var fld2 = namespacePrefix + fld;
                        obj[fld2] = object[fld];
                    } else {
                        obj[fld] = object[fld];
                    }
                } else {
                    // see if custom field starts with our namespace prefix
                    if (fld.endsWith('__c') && fld.startsWith(namespacePrefix)) {
                        var fld2 = fld.replace(namespacePrefix, '');
                        obj[fld2] = object[fld];
                    } else {
                        obj[fld] = object[fld];
                    }
                }
            }
            return obj;
        } else {
            return object;
        }
    },


})