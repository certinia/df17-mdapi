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
		this.request = request;
		
		readLayout();
		modifyLayout();
		Id deploymentId = saveLayout();
		
		return new PageLayoutService.Response()
			.withSuccess(true)
			.withMessage('Enqueued deployment ' + deploymentId);
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
			for (Integer idxSection=0; idxSection<sizeSections; idxSection++)
			{
				Metadata.LayoutSection layoutSection = this.layout.layoutSections[idxSection];
				Integer sizeColumns = layoutSection.layoutColumns == null ? 0 : layoutSection.layoutColumns.size();
				for (Integer idxColumn=0; idxColumn<sizeColumns; idxColumn++)
				{
					Metadata.LayoutColumn layoutColumn = layoutSection.layoutColumns[idxColumn];
					Integer sizeItems = layoutColumn.layoutItems == null ? 0 : layoutColumn.layoutItems.size();
					
					if (this.request.AnchorType == PageLayoutService.ANCHOR_TYPE_START && idxSection == 0 && idxColumn == 0)
					{
						addAt(0, layoutColumn);
						return;
					}
					else if (this.request.AnchorType == PageLayoutService.ANCHOR_TYPE_END && idxSection >= sizeSections-1 && idxColumn >= sizeColumns-1)
					{
						addAt(sizeColumns-1, layoutColumn);
						return;
					}
					
					for (Integer idxItem=0; idxItem<sizeItems; idxItem++)
					{
						Metadata.LayoutItem anchorItem = layoutColumn.layoutItems[idxItem];
						if (anchorItem.field == this.request.AnchorField)
						{
							if (this.request.AnchorType == PageLayoutService.ANCHOR_TYPE_BEFORE)
							{
								addAt(idxItem, layoutColumn);
								return;
							}
							else if (this.request.AnchorType == PageLayoutService.ANCHOR_TYPE_AFTER)
							{
								addAt(idxItem + 1, layoutColumn);
								return;
							}
						}
					}
				}
			}

			// If we get this far, we couldn't find anywhere to add the field
			throw new PageLayoutService.PageLayoutException('Could not anchor ' + this.request.AnchorType + ' ' + this.request.AnchorField + ' in the layout ' + this.request.LayoutName);
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
					Integer sizeItems = layoutColumn.layoutItems == null ? 0 : layoutColumn.layoutItems.size();
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

			// If we get this far, we couldn't find the field to remove
			throw new PageLayoutService.PageLayoutException('Unable to remove field  ' + this.request.Field + ' because it was not in the layout ' + this.request.LayoutName);
		}
	}

	private void addAt(Integer idx, Metadata.LayoutColumn column)
	{
		Metadata.LayoutItem item = this.request.asField();

		if (column.layoutItems == null) {
			column.layoutItems = new Metadata.LayoutItem[]{ item };
			return;
		}

		if (idx >= column.layoutItems.size())
		{
			column.layoutItems.add(item);
			return;
		}

		column.layoutItems.add(idx, item);
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
