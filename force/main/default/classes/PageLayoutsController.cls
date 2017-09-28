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
}