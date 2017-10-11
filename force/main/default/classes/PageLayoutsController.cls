public with sharing class PageLayoutsController
{
	@AuraEnabled
	public static PageLayoutService.Response updateLayout(String requestString)
	{
		PageLayoutService.Request request = (PageLayoutService.Request)JSON.deserialize(
			requestString,
			PageLayoutService.Request.class
		);
		
		return new PageLayoutService().updateLayout(request);
	}

	@AuraEnabled
	public static DescribeService.DisplayOption[] getObjectTypes()
	{
		return new DescribeService().getObjectTypes();
	}

	@AuraEnabled
	public static DescribeService.DisplayOption[] getFields(String objectType)
	{
		return new DescribeService().getFields(objectType);
	}
	
	@AuraEnabled
	public static String getObjectType(String recordId)
	{
		return new DescribeService().getObjectType(recordId);
	}
}