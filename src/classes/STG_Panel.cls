public with sharing virtual class STG_Panel {
	
	public STG_Panel() {
		system.debug('***** STG_Panel constructor');
		isEditMode = false;
	}
	
	public virtual string idPanel() { return null; }
	
	public boolean isEditMode { get; set; }
	
	public boolean isReadOnlyMode {
		get {
			return !isEditMode;
		}
	}
    
    static public STG_SettingsService stgService { 
        get {
            if (stgService == null)  { 
            	stgService = STG_SettingsService.stgService;
                system.debug('***** getting STG_SettingsService.stgService: ' + stgService);
            }
            return stgService;
        }
        private set;
    }

    public virtual PageReference saveSettings() { 
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
	        stgService.saveAll();
	        isEditMode = false;
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, null);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
        
    }

    public PageReference editSettings() { 
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        isEditMode = true;
        return null;
    }

    public PageReference cancelEdit() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        isEditMode = false;
        return null;
    }
       
    static public list<SelectOption> listSOAccountModels {
        get {
            if (listSOAccountModels == null) {
                listSOAccountModels = new list<SelectOption>();
                listSOAccountModels.add(new SelectOption('HH Account', 'HH Account'));
                listSOAccountModels.add(new SelectOption('One-to-One', 'One-to-One'));
                listSOAccountModels.add(new SelectOption('Individual', 'Individual'));
            }
            return listSOAccountModels;
        }
        private set;
    }

    static public list<SelectOption> listSOContactRoles {
        get {    
            if (listSOContactRoles == null) {
                listSOContactRoles = new list<SelectOption>();
                listSOContactRoles.add(new SelectOption('','- none -'));
                Schema.DescribeFieldResult F = Schema.sObjectType.OpportunityContactRole.fields.Role; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for (Schema.PicklistEntry pe : P) {
                    listSOContactRoles.add(new SelectOption(pe.getLabel(), pe.getLabel()));
                }
            }
            return listSOContactRoles;
        }
        private set;
    }

    static public list<SelectOption> listSOHHRules {
        get {
            if (listSOHHRules == null) {
                listSOHHRules = new list<SelectOption>();
                listSOHHRules.add(new SelectOption(HH_Households.ALL_PROCESSOR, HH_Households.ALL_PROCESSOR));
                listSOHHRules.add(new SelectOption(HH_Households.ALL_INDIVIDUALS_PROCESSOR, HH_Households.ALL_INDIVIDUALS_PROCESSOR));
                listSOHHRules.add(new SelectOption(HH_Households.NO_HOUSEHOLDS_PROCESSOR, HH_Households.NO_HOUSEHOLDS_PROCESSOR));
            }
            return listSOHHRules;
        }
        private set;
    }
    
    static public list<SelectOption> listSOContactRecTypes {
        get {
            if (listSOContactRecTypes == null) {
                listSOContactRecTypes = new list<SelectOption>();
                listSOContactRecTypes.add(new SelectOption('', '- none -'));
                listSOContactRecTypes.addAll(UTIL_RecordTypes.getStringRecordTypesForSelectList('Contact'));            
            }       
            return listSOContactRecTypes;
        }
        private set;
    }    
        
    static public list<SelectOption> listSOAccountRecTypeIds {
        get {
            if (listSOAccountRecTypeIds == null) {
                listSOAccountRecTypeIds = new list<SelectOption>();
                listSOAccountRecTypeIds.add(new SelectOption('', '- none -'));
                listSOAccountRecTypeIds.addAll(UTIL_RecordTypes.getRecordTypesForSelectList('Account'));            
            }       
            return listSOAccountRecTypeIds;
        }
        private set;
    }    

    static public list<SelectOption> listSOOppRecTypes {
        get {
            if (listSOOppRecTypes == null) {
                listSOOppRecTypes = new list<SelectOption>();
                listSOOppRecTypes.add(new SelectOption('', '- none -'));
                listSOOppRecTypes.addAll(UTIL_RecordTypes.getStringRecordTypesForSelectList('Opportunity'));            
            }       
            return listSOOppRecTypes;
        }
        private set;
    }    
        
    static public list<SelectOption> listSOOppRecTypesIds {
        get {
            if (listSOOppRecTypesIds == null) {
                listSOOppRecTypesIds = new list<SelectOption>();
                listSOOppRecTypesIds.add(new SelectOption('', '- none -'));
                listSOOppRecTypesIds.addAll(UTIL_RecordTypes.getRecordTypesForSelectList('Opportunity'));            
            }       
            return listSOOppRecTypesIds;
        }
        private set;
    }    

    static public list<SelectOption> listSOOppContactRoles {
        get {
            if (listSOOppContactRoles == null) {
                listSOOppContactRoles = new list<SelectOption>();
                listSOOppContactRoles.add(new SelectOption('','- none -'));
                Schema.DescribeFieldResult F = Schema.sObjectType.OpportunityContactRole.fields.Role; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for(Schema.PicklistEntry pe : P) {
                    listSOOppContactRoles.add(new SelectOption(pe.getLabel(), pe.getLabel()));
                }
            }
            return listSOOppContactRoles;
        }
        private set;
    }
    
    static public list<SelectOption> listSOOppTypes {
    	get {
	        if (listSOOppTypes == null) {
	            listSOOppTypes = new list<SelectOption>();
	            listSOOppTypes.add(new SelectOption('','- none -'));
	            Schema.DescribeFieldResult F = Schema.sObjectType.Opportunity.fields.Type; 
	            list<Schema.PicklistEntry> P = F.getPicklistValues();
	        
	            for (Schema.PicklistEntry plistentry: P) {
	                listSOOppTypes.add(new SelectOption(plistentry.getLabel(),plistentry.getLabel()));
	            }
	        }
	        return listSOOppTypes;
    	}
    	private set;
    }

     static public list<SelectOption> listSORelTypes {
        get {    
            if (listSORelTypes == null) {
                listSORelTypes = new list<SelectOption>();
                listSORelTypes.add(new SelectOption('','- none -'));
                Schema.DescribeFieldResult F = Schema.sObjectType.npe4__Relationship__c.fields.npe4__Type__c; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for (Schema.PicklistEntry pe : P) {
                    listSORelTypes.add(new SelectOption(pe.getLabel(), pe.getLabel()));
                }
            }
            return listSORelTypes;
        }
        private set;
    }

     static public list<SelectOption> listSOCampaignTypes {
        get {    
            if (listSOCampaignTypes == null) {
                listSOCampaignTypes = new list<SelectOption>();
                listSOCampaignTypes.add(new SelectOption('','- none -'));
                Schema.DescribeFieldResult F = Schema.sObjectType.Campaign.fields.Type; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                for (Schema.PicklistEntry pe : P) {
                    listSOCampaignTypes.add(new SelectOption(pe.getLabel(), pe.getLabel()));
                }
            }
            return listSOCampaignTypes;
        }
        private set;
    }

    static public list<SelectOption> listSOMailingReportIds {
        get {
            if (listSOMailingReportIds == null) {
                listSOMailingReportIds = new list<SelectOption>();
                listSOMailingReportIds.add(new SelectOption('','- none -'));
                for (Report rpt : [select Id, Name from Report where Name like '%mail%']) {
                    listSOMailingReportIds.add(new SelectOption(rpt.Id, rpt.Name));
                }
            }
            return listSOMailingReportIds;
        }
        private set;
    }

    static public string strHHAccountRecordTypeLabel {
    	get {
    		if (strHHAccountRecordTypeLabel == null) {
    			strHHAccountRecordTypeLabel = UTIL_RecordTypes.GetRecordTypeName('Account', stgService.stgCon.npe01__HH_Account_RecordTypeID__c);
    		}
    		return strHHAccountRecordTypeLabel;
    	}
    	private set;
    }
       
    static public string strOneToOneRecordTypeLabel {
        get {
            if (strOneToOneRecordTypeLabel == null) {
                strOneToOneRecordTypeLabel = UTIL_RecordTypes.GetRecordTypeName('Account', stgService.stgCon.npe01__One_to_One_RecordTypeID__c);
            }
            return strOneToOneRecordTypeLabel;
        }
        private set;
    }
      
}