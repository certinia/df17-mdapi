public with sharing class PageLayoutsController
{
	@AuraEnabled
    public static PageLayoutService.Response updateLayouts(PageLayoutService.Request request)
	{
		return new PageLayoutService().updateLayout(request);
    }
}
