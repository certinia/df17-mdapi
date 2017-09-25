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
		
		if (this.request.AnchorType != PageLayoutService.ANCHOR_TYPE_END)
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

		Metadata.LayoutColumn finalColumn = findFinalColumn();
		if (finalColumn.layoutItems == null)
		{
			finalColumn.layoutItems = new Metadata.LayoutItem[]{};
		}

		finalColumn.layoutItems.add(this.request.asField());
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

	private Metadata.LayoutColumn findFinalColumn()
	{
		Integer lengthSections = this.layout.layoutSections.size();
		Metadata.LayoutSection finalSection = this.layout.layoutSections[lengthSections - 1];

		Integer lengthColumns = finalSection.layoutColumns.size();
		return finalSection.layoutColumns[lengthColumns - 1];
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
        	System.debug(result.success);
        }
	}
}
