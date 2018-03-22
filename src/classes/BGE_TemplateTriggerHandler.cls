public with sharing class BGE_TemplateTriggerHandler {

	private BGE_TemplateNameHelper templateNameHelper;
    private static Boolean isRunningBefore = false;

    public BGE_TemplateTriggerHandler () {

    	templateNameHelper = new BGE_TemplateNameHelper(Trigger.new);
    }

    public void onBeforeInsert () {

    	 if (!isRunningBefore) {

    		 isRunningBefore = true;
    		 templateNameHelper.updateName();
    	     isRunningBefore = false;
    	 }
    }
}