public with sharing class PageLayoutsController
{
	@AuraEnabled
    public static PageLayoutService.Response updateLayout(PageLayoutService.Request request)
	{
		return new PageLayoutService().updateLayout(request);
    }
}
