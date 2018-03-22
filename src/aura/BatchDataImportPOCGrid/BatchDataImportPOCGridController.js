({
 doInit : function(component, event, helper)
    {
        var pageSize = component.get("v.pageSize");
        
        var action = component.get("c.getGifts");
        action.setCallback(this, function(response) 
  {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") 
            {
                console.log(response.getReturnValue());
                component.set('v.giftsList', response.getReturnValue());
                
                component.set("v.totalSize", component.get("v.giftsList").length);
                component.set("v.start",0);
                component.set("v.end",pageSize-1);
                
                var paginationList = [];
                for(var i=0; i< pageSize; i++)
                {
                 paginationList.push(response.getReturnValue()[i]);    
    }
                
                component.set('v.paginationList', paginationList);
            }
        });
        $A.enqueueAction(action);
    },
    next : function(component, event, helper) 
    {
     var accountList = component.get("v.giftsList");
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
        
        var counter = 0;
        for(var i=end+1; i<end+pageSize+1; i++)
        {
         if(accountList.length > end)
            {
          paginationList.push(accountList[i]);
                counter ++ ;
         }
        }
        start = start + counter;
        end = end + counter;
        
        component.set("v.start",start);
        component.set("v.end",end);
        
        component.set('v.paginationList', paginationList);
 },
    previous : function(component, event, helper) 
    {
     var accountList = component.get("v.giftsList");
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
         
        var counter = 0;
        for(var i= start-pageSize; i < start ; i++)
        {
         if(i > -1)
            {
             paginationList.push(accountList[i]);
                counter ++;
         }
            else
            {
                start++;
            }
        }
        start = start - counter;
        end = end - counter;
        
        component.set("v.start",start);
        component.set("v.end",end);
        
        component.set('v.paginationList', paginationList);
 }
})