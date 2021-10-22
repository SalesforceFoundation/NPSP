/**
 * File Name: fflib_MockSObjectUtil
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
@IsTest
public with sharing class fflib_MockSObjectUtil
{
	public static SObject addRelatedParentObject(SObject childObject, SObject parentObject, String relationshipField)
	{
		String original = JSON.serialize(childObject);
		return (SObject) JSON.deserialize(
				original.left(original.length() - 1) +
						',"' + relationshipField + '":' +
						JSON.serialize(parentObject) + '}',
				SObject.class);
	}
}