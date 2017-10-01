/**
 * Copyright (c) 2017, FinancialForce.com, inc. All rights reserved.
 */
public class ClassicPageLayoutUpdater
{
	private static final String LOG_LINE_SEPARATOR = '\n';
	private static final Integer TIMEOUT_MILLIS = 120000;

	private PageLayoutService.Request request = null;
	private MetadataService.MetadataPort metadataPort = null;
	private MetadataService.Layout layout = null;
	private Boolean isDirty = false;

	public PageLayoutService.Response updateLayout(PageLayoutService.Request request)
	{
		this.request = request;
		
		initMetadataPort();
		readLayout();
		modifyLayout();
		saveLayout();
		
		return new PageLayoutService.Response()
			.withSuccess(true)
			.withMessage('Successfully updated page layout');
	}

	private void initMetadataPort()
	{
		metadataPort = new MetadataService.MetadataPort();
		metadataPort.timeout_x = TIMEOUT_MILLIS;
		metadataPort.SessionHeader = new MetadataService.SessionHeader_element();
		metadataPort.SessionHeader.sessionId = getSessionId();
	}

	private void readLayout()
	{
		MetadataService.Metadata[] records = metadataPort.readMetadata(
			Metadata.MetadataType.Layout.name(),
			new String[]{ this.request.LayoutName }
		).getRecords();

		if (records.isEmpty())
		{
			throw new PageLayoutService.PageLayoutException('No layouts for name ' + this.request.LayoutName);
		}

		this.layout = (MetadataService.Layout)records[0];
	}

	private void modifyLayout()
	{
		Integer sizeSections = this.layout.layoutSections.size();
			
		if (this.request.Operation == PageLayoutService.OPERATION_ADD)
		{
			for (Integer idxSection=0; idxSection<sizeSections; idxSection++)
			{
				MetadataService.LayoutSection layoutSection = this.layout.layoutSections[idxSection];
				Integer sizeColumns = layoutSection.layoutColumns == null ? 0 : layoutSection.layoutColumns.size();
				for (Integer idxColumn=0; idxColumn<sizeColumns; idxColumn++)
				{
					MetadataService.LayoutColumn layoutColumn = layoutSection.layoutColumns[idxColumn];
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
						MetadataService.LayoutItem anchorItem = layoutColumn.layoutItems[idxItem];
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
				MetadataService.LayoutSection layoutSection = this.layout.layoutSections[idxSection];
				Integer sizeColumns = layoutSection.layoutColumns.size();
				for (Integer idxColumn=0; idxColumn < sizeColumns; idxColumn++)
				{
					MetadataService.LayoutColumn layoutColumn = layoutSection.layoutColumns[idxColumn];
					Integer sizeItems = layoutColumn.layoutItems == null ? 0 : layoutColumn.layoutItems.size();
					for (Integer idxItem=0; idxItem < sizeItems; idxItem++)
					{
						MetadataService.LayoutItem layoutItem = layoutColumn.layoutItems[idxItem];
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

	private void addAt(Integer idx, MetadataService.LayoutColumn column)
	{
		MetadataService.LayoutItem item = this.request.asMetadataServiceField();

		if (column.layoutItems == null) {
			column.layoutItems = new MetadataService.LayoutItem[]{ item };
			return;
		}

		if (idx >= column.layoutItems.size())
		{
			column.layoutItems.add(item);
			return;
		}

		column.layoutItems.add(idx, item);
	}

	private void saveLayout()
	{
		MetadataService.SaveResult saveResult = metadataPort.updateMetadata(new MetadataService.Metadata[] { this.layout })[0];
		if (!saveResult.success)
		{
			String[] errors = new String[]{};
			for (MetadataService.Error error : saveResult.errors)
			{
				errors.add(error.message);
			}
			throw new PageLayoutService.PageLayoutException(String.join(errors, LOG_LINE_SEPARATOR));
		}
	}

	private static String getSessionId()
	{
		//Workaround because Lightning Component sessions are not API enabled
		//https://salesforce.stackexchange.com/questions/110515/getting-session-id-in-lightning
		return Test.isRunningTest() ? UserInfo.getSessionId() : Page.SessionId.getContent().toString();
	}
}
