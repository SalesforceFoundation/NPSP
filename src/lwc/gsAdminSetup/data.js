import gsChecklistExploreNPSPTitle from '@salesforce/label/c.gsChecklistExploreNPSPTitle';
import gsChecklistExploreNPSPDesc from '@salesforce/label/c.gsChecklistExploreNPSPDesc';

import gsChecklistMakeItYourDesc from '@salesforce/label/c.gsChecklistMakeItYourDesc';
import gsChecklistMakeItYourTitle from '@salesforce/label/c.gsChecklistMakeItYourTitle';

import gsChecklistOnboardUsersTitle from '@salesforce/label/c.gsChecklistOnboardUsersTitle';
import gsChecklistOnboardUsersDesc from '@salesforce/label/c.gsChecklistOnboardUsersDesc';

const exploreNPSP = {
    title: gsChecklistExploreNPSPTitle,
    desc: gsChecklistExploreNPSPDesc,
}

const makeItYours = {
    title: gsChecklistMakeItYourTitle,
    desc: gsChecklistMakeItYourDesc,
}

const onboardUsers = {   
    title: gsChecklistOnboardUsersTitle,
    desc: gsChecklistOnboardUsersDesc
}

export default [
    { id: 1, ...exploreNPSP },
    { id: 2, ...makeItYours },
    { id: 3, ...onboardUsers },
];
