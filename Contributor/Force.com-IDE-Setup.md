# Setup the Project in the Force.com IDE

If you haven’t done so already, install your IDE of choice. Here are instructions on setting up the Force.com IDE up from scratch: https://developer.salesforce.com/page/Force.com_IDE_Installation

In the Force.com IDE, you want to uncheck ‘Build Automatically’ under ‘Project’.   We don’t want the IDE to start sending random pieces of metadata up to the cloud until we’ve configured everything properly. 

Setup a new project in Eclipse.  Right click in the project pane and go to ‘New’ and ‘Project’.  

Enter a new project name.  

![Eclipse New Project Dialog](img/eclipse-new-project.png)

If your Eclipse workspace is pointed at the same location as your local git repo, you’ll be good to go.  Otherwise you may need to add version control to your project.  Its under Team -> Share Project, then ‘git’, select an existing repository.  Once you’re ready to roll, it should look something like this:

![Setup Eclipse Project Example](img/eclipse-project.png)

Now that we’ve configured our DE org and source control repositories, lets get our IDE setup to do some actual coding work.  Back over in Eclipse, right click on the project name and select ‘Add Force.com Nature’. Now’s a good time to double-check that the ‘Build Automatically’ setting is disabled in your org. 

![Add Force.com Nature Example](img/eclipse-add-forcecom-nature.png)
![Properties for Cumulus Dialog](img/eclipse-properties-for-cumulus.png)

After entering the credentials for your DE org, click apply, but make sure that you click ‘No’ when asked if you want to fetch and overwrite anything.  While the code should be pretty much identical, there are enough subtle differences (think about white spacing, order of unordered elements, etc.) to cause git to see differences when there are in fact none.

![Eclipse Overwrite Components Dialog](img/eclipse-overwrite-components.png)

Now you can finally go back into your IDE and turn back on the Build Automatically setting.  Your Force.com IDE should now be fully configured to do some actual coding on the Nonprofit Starter Pack codebase!

### Optional: Set Force.com to run Ant targets
Click on Window > Show View > Other > Ant

![Selecting ANT in Eclipse](img/eclipse-select-ant.png)

From the Ant view in the IDE click on "Add build files" (the Ant with a plus sign on top icon) and select the build.xml from your project
From the Ant view select the task to run, for example "deployCI", and click the arrow with the green circle icon to execute it.

![Selecting ANT Targets in Eclipse](img/eclipse-ant-targets.png)

Note: The task in blue is the default one, which will be run by Ant if you do not specify any when running it.