---
title: Github
layout: post
---
# Github
The Nonprofit Starter Pack’s source code is hosted on Github, and you’ll need a github account to contribute to NPSP. If you don’t have an account, [create one first](https://github.com/join).

Next, we need to fork the latest NPSP code and create our own repository.  Login to Github and head to the [Cumulus github repository](https://github.com/SalesforceFoundation/Cumulus) In the upper right hand corner, you’ll see the ‘Fork’ button.  Click it.   Create your fork.  It should look something like this: 

![Forking the Cumulus Repository](/img/npsp-fork-example.png)

Since this is our own copy of the repository, we can modify this as much as we’d like without affecting anything else in the main repo. 

# Get the code onto your computer

Now, lets pull the repo down into a local repository on our machine using git clone.  At the command lane change into the directory where you want your code to live, then run:
```sh
git clone https://github.com/<user_name>/Cumulus.git
```
If you have trouble cloning the repository, you may need to setup github ssh access. Remember the directory where you have cloned the repository as we’ll be coming back here often throughout the process.

### Cloning…

![using git clone](/img/git-clone-example.png)

Congratulations, you are all set up in github! The next step is to choose an IDE. Any IDE will work, we provide instructions for setting up the [Force.com IDE](https://developer.salesforce.com/page/Force.com_IDE) as well as instructions for working with any IDE of your choice.
