/**
 * Copyright (c) 2017, FinancialForce.com, inc. All rights reserved.
 */
public class NativePageLayoutUpdater
{
	private PageLayoutService.Request request = null;
	private Metadata.Layout layout = null;
	private Boolean isDirty = false;

	public PageLayoutService.Response updateLayout(PageLayoutService.Request request)
	{
		try
		{
			this.request = request;
			validate();
			
			readLayout();
			modifyLayout();
			Id deploymentId = saveLayout();
			
			return new PageLayoutService.Response()
				.withSuccess(true)
				.withMessage('Enqueued deployment ' + deploymentId + ' - ' + DateTime.now().format());
		}
		catch (PageLayoutService.PageLayoutException e)
		{
			return new PageLayoutService.Response()
				.withSuccess(false)
				.withMessage(e.getMessage());
		}
	}

	private void validate()
	{
		if (this.request.Strategy != PageLayoutService.STRATEGY_CLASSIC)
		{
			throw new PageLayoutService.PageLayoutException('Unsupported Strategy: ' + this.request.Strategy);
		}
		
		if (this.request.Operation != PageLayoutService.OPERATION_ADD)
		{
			throw new PageLayoutService.PageLayoutException('Unsupported Operation: ' + this.request.Operation);
		}
		
		if (this.request.AnchorType != PageLayoutService.ANCHOR_TYPE_START)
		{
			throw new PageLayoutService.PageLayoutException('Unsupported AnchorType: ' + this.request.AnchorType);
		}
	}

	private void readLayout()
	{
		Metadata.Metadata[] records = Metadata.Operations.retrieve(
			Metadata.MetadataType.Layout,
			new String[]{ this.request.LayoutName }
		);

		if (records.isEmpty())
		{
			throw new PageLayoutService.PageLayoutException('No layouts for name ' + this.request.LayoutName);
		}

		this.layout = (Metadata.Layout)records[0];
	}

	private void modifyLayout()
	{
		Metadata.LayoutItem existingField = findFieldFromLayout();
		if (existingField != null)
		{
			throw new PageLayoutService.PageLayoutException('Field ' + this.request.Field + 'already present in layout ' + this.request.LayoutName);
		}

		Metadata.LayoutColumn firstColumn = findFirstColumn();
		if (firstColumn.layoutItems == null)
		{
			firstColumn.layoutItems = new Metadata.LayoutItem[]{};
		}

		firstColumn.layoutItems.add(0, this.request.asField());
	}

	private Metadata.LayoutItem findFieldFromLayout()
	{
		for (Metadata.LayoutSection layoutSection : this.layout.layoutSections)
		{
			for (Metadata.LayoutColumn layoutColumn : layoutSection.layoutColumns)
			{
				if (layoutColumn.layoutItems != null)
				{
					for (Metadata.LayoutItem layoutItem : layoutColumn.layoutItems)
					{
						if (layoutItem.field == this.request.Field)
						{
							return layoutItem;
						}
					}
				}
			}
		}

		return null;
	}

	private Metadata.LayoutColumn findFirstColumn()
	{
		Metadata.LayoutSection firstSection = this.layout.layoutSections[0];
		return firstSection.layoutColumns[0];
	}

	private Id saveLayout()
	{
		Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
		mdContainer.addMetadata(this.layout);

		return Metadata.Operations.enqueueDeployment(mdContainer, new DeployCallback());
	}

	private class DeployCallback implements Metadata.DeployCallback
	{
		public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context)
		{
        	System.debug('Status: ' + result.status + '. ErrorCode: ' + result.errorStatusCode + '. Errors: ' + result.errorMessage);
        }
	}
}
