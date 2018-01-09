/**
 * Created by randi.wilson on 12/20/17.
 */

public with sharing class STG_PanelCustomizableRollup_CTRL {

    public static void enableCRLP(){
        //method to enable CRLP
    }

    public PageReference navigate(){

        //TODO: check this will work with upcoming URL changes
        PageReference rollupGrid = new PageReference('/apex/CRLP_RollupSetup');
        rollupGrid.setRedirect(true);
        return rollupGrid;
    }

}