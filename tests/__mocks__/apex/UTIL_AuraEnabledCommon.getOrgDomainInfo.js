const orgDomainInfo = require('./data/orgDomainInfo.json');

const mockedOrgDomainInfo = jest.fn().mockResolvedValue(orgDomainInfo);

export default mockedOrgDomainInfo;