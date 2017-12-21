/**
 * Created by randi.wilson on 12/20/17.
 */

public with sharing class STG_PanelCustomizableRollup_CTRL {

    public static void enableCRLP(){
        //method to enable CRLP
    }

    public PageReference navigate(){
        //this method only works correctly if the user has deliberately chosen Lightning OR Classic
        //getUITheme vs getUIThemeDisplayed may fix this?
        PageReference rollupGrid = new PageReference('/apex/CRLP_Setup');

        /**String theme = UserInfo.getUiThemeDisplayed();
        //If theme is within the Lightning app, redirect to components directly, else navigate to Visualforce context.
        if (theme == 'Theme4d' || theme == 'Theme4t'){
            Url base = System.URL.getSalesforceBaseUrl();
            rollupGrid = new PageReference(base + '#/n/CRLP');
        } else {
            rollupGrid = new PageReference('/apex/CRLP_Setup');
        }**/

        rollupGrid.setRedirect(true);
        return rollupGrid;
    }

}