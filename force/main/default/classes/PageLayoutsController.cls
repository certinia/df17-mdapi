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
	public static PageLayoutService.DisplayOption[] getObjectTypes()
	{
		return new PageLayoutService().getObjectTypes();
	}

	@AuraEnabled
	public static PageLayoutService.DisplayOption[] getFields(String objectType)
	{
		return new PageLayoutService().getFields(objectType);
	}
}