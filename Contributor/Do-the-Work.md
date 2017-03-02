---
title: NPSP Code Contributor's Guide: Do the Work
layout: default
---
# [Home](http://developer.salesforcefoundation.org/Cumulus/Contributor/) > Do the Work!

### I've got my IDE. Great ... What should I do?

Phew! You are now all set up to contribute code to NPSP. The first thing to do is make sure you've read the general [Contributing to the Nonprofit Success Pack](http://www.salesforce.org/help/contribute-nonprofit-success-pack/) page. 

If you’re not sure what you want to build but are looking for a way to contribute, it’s actually pretty easy to find something to work on.

First, head back over to the [NPSP github issues](github.com/SalesforceFoundation/Cumulus/issues) and use the big ‘Labels’ tab at the top to select a set of labels to filter the issue list by. The 'community-ready' label is the ideal place to start - these are issues that have been reviewed by Salesforce.org engineers and flagged as good candidates for community contributions. You can also take a look at the ‘bug’, 'feature-request’ and ‘enhancement' labels.

We recommend always posting on the issue to see if it makes sense to pick it up, just in case somebody else is already working what you’ve selected! Also feel free to ask questions about the issue or discuss proposed solutions directly in the github issue.

You may have your own ideas for features or feature enhancements that you want to create and make available to the world. That’s great! The first step is to read this [list of considerations](http://www.salesforce.org/help/contribute-nonprofit-success-pack/#developer) to make sure that your idea is appropriate. If your idea meets those criteria, the best next step is to [create an Idea in the Hub](https://powerofus.force.com/hub-ideas) that describes what you want to build. You can also post to the [Power of Us Hub’s Nonprofit Success Pack Contributors group](https://powerofus.force.com/0F980000000CtL2) to discuss ideas or find inspiration from the community. Ideas for features that have support from others in the community and meet all the contribution criteria are the most likely to be accepted and incorporated into the Nonprofit Success Pack.

# Git branching

When you clone your fork of the Cumulus repository onto your local computer, you'll be in the 'dev' branch. For each new feature or issue that you work on, you'll want to create a new branch. You can create and "checkout" (ie, start to work on) a new branch like so:

```git checkout -b feature/123-person-accts-rule```

Your branch name should start with 'feature/'. If you're working on a specific GitHub issue, put that next. Your branch name shouldn't have spaces or special characters. Then put a 2-3 word summary of what you're working on - abbreviations are fine. 

Commit all your changes to this branch 

# NPSP Apex Documentation

We've put together a handy site that's an invaluable tool in understanding the NPSP code base: [ApexDocs](http://developer.salesforcefoundation.org/Cumulus/). Now all that's left to do is to do the coding!

# Add To The Cumulus Unmanaged Package

If you've added any metadata that needs to be part of NPSP as part of your feature, it needs to be added to the Cumulus unmanaged package. Examples include a new class, trigger, or page, or really anything else like a new field, custom setting, page layout, etc.

1. Navigate to Setup > Create > Packages
2. Click on the Cumulus package name
3. Click Add
4. Select the correct Component Type
5. Check the box next to your component
6. Click Add To Package

Next up, learn how to push your changes to github, and [submit them to the Salesforce Foundation for review](Submit-Your-Feature.html).
