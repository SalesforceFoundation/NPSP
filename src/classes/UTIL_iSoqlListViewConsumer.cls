public interface UTIL_iSoqlListViewConsumer {
    
    void setComponentController(UTIL_SoqlListView_CTRL compController);
    
    string getStrSoql();
    
    list<string> getstrFields(); 
    
    string getstrNameField();
    
    string getstrObjectType();

    PageReference NewItem();
    
    PageReference EditItem(ID idItem);
}