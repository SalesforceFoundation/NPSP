---
title: Alternate IDEs
layout: default
---
# [Home](http://developer.salesforcefoundation.org/Cumulus/Contributor/) > Alternate IDEs

If you use an alternate IDE such as MavensMate, or are an old school vi user, you can still use the command line and a combination of ant build targets to do all your NPSP related development.

Unlike with the Force.com IDE, when using other IDEs you will keep your git repository and your IDE’s source repository separate. Alternatively, you can do your development directly in through your browser in Salesforce and not use an IDE at all.

# Initial setup

Once you have cloned your fork of the NPSP git repository in your local machine, create a file in your git directory called build.properties with the following information from your developer instance:

```
sf.serverurl=https://login.salesforce.com
sf.username=your_dev_environment@email.com
sf.password=your_dev_password_and_security_token
```

Make sure your developer instance is either new or that you don’t care about any of the metadata currently residing in it. The next step will clean your developer instance and install the unmanaged code for NPSP to allow you to do your dev work.

# Ant build scripts

Ant build scripts are predefined actions that are used by our continuous integration system to manage metadata and move it between salesforce environments. Those same tools can run manually from the command line, and can be used by developers to facilitate cleaning and preparing their developer environment, as well as tracking code and metadata changes through git and the command line.

Using these build targets in combination with command line git allows the use of any IDE for contributing code to NPSP.

### Install NPSP to your dev environment

From the command line in your git repository, run:

```sh
ant deployCI
```

Now you’re ready to [start coding](Do-the-Work.html)!
