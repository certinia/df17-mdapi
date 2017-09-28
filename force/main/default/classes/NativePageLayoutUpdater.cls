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
		Integer sizeSections = this.layout.layoutSections.size();
			
		if (this.request.Operation == PageLayoutService.OPERATION_ADD)
		{
			Metadata.LayoutItem newItem = this.request.asField();
			
			for (Integer idxSection=0; idxSection<sizeSections; idxSection++)
			{
				Metadata.LayoutSection layoutSection = this.layout.layoutSections[idxSection];
				Integer sizeColumns = layoutSection.layoutColumns.size();
				for (Integer idxColumn=0; idxColumn < sizeColumns; idxColumn++)
				{
					Metadata.LayoutColumn layoutColumn = layoutSection.layoutColumns[idxColumn];
					Integer sizeItems = layoutColumn.layoutItems.size();
					
					if (this.request.AnchorType == PageLayoutService.ANCHOR_TYPE_START && idxSection == 0 && idxColumn == 0)
					{
						if (sizeItems == 0)
						{
							layoutColumn.layoutItems.add(newItem);
							return;
						}
						else
						{
							layoutColumn.layoutItems.add(0, newItem);
							return;
						}
					}
					else if (this.request.AnchorType == PageLayoutService.ANCHOR_TYPE_END && idxSection == sizeSections-1 && idxColumn == sizeItems-1)
					{
						layoutColumn.layoutItems.add(newItem);
						return;
					}
					
					
					for (Integer idxItem=0; idxItem < sizeItems; idxItem++)
					{
						Metadata.LayoutItem anchorItem = layoutColumn.layoutItems[idxItem];
						if (anchorItem.field == this.request.AnchorField)
						{
							if (this.request.AnchorType == PageLayoutService.ANCHOR_TYPE_BEFORE)
							{
								layoutColumn.layoutItems.add(idxItem, newItem);
								return;
							}
							else if (this.request.AnchorType == PageLayoutService.ANCHOR_TYPE_AFTER)
							{
								if (idxItem == sizeItems-1)
								{
									layoutColumn.layoutItems.add(newItem);
									return;
								}
								else
								{
									layoutColumn.layoutItems.add(idxItem+1, newItem);
									return;
								}
							}
						}
					}
				}
			}
		}
		else if (this.request.Operation == PageLayoutService.OPERATION_REMOVE)
		{
			for (Integer idxSection=0; idxSection<sizeSections; idxSection++)
			{
				Metadata.LayoutSection layoutSection = this.layout.layoutSections[idxSection];
				Integer sizeColumns = layoutSection.layoutColumns.size();
				for (Integer idxColumn=0; idxColumn < sizeColumns; idxColumn++)
				{
					Metadata.LayoutColumn layoutColumn = layoutSection.layoutColumns[idxColumn];
					Integer sizeItems = layoutColumn.layoutItems.size();
					for (Integer idxItem=0; idxItem < sizeItems; idxItem++)
					{
						Metadata.LayoutItem layoutItem = layoutColumn.layoutItems[idxItem];
						if (layoutItem.field == this.request.Field)
						{
							layoutColumn.layoutItems.remove(idxItem);
							return;
						}
					}
				}
			}
		}
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
