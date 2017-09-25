/**
 * Copyright (c) 2017, FinancialForce.com, inc. All rights reserved.
 */
public class PageLayoutService
{
	public static final String STRATEGY_CLASSIC = 'Classic';
	public static final String STRATEGY_NATIVE = 'Native';
	
	public static final String OPERATION_ADD = 'Add';
	public static final String OPERATION_REMOVE = 'Remove';
	
	public static final String ANCHOR_TYPE_START = 'Start';
	public static final String ANCHOR_TYPE_BEFORE = 'Before';
	public static final String ANCHOR_TYPE_AFTER = 'After';
	public static final String ANCHOR_TYPE_END = 'End';

	public PageLayoutService.Response classicUpdateLayout(PageLayoutService.Request request)
	{
		return new NativePageLayoutUpdater().updateLayout(request);
	}

	public class Request
	{
		public String Strategy {get; set;}
		public String ObjectType {get; set;}
		public String LayoutName {get; set;}
		public String Operation {get; set;}
		public String Behavior {get; set;}
		public String Field {get; set;}
		public String AnchorType {get; set;}
		public String AnchorField {get; set;}

		public PageLayoutService.Request withStrategy(String value) { this.Strategy = value; return this; }
		public PageLayoutService.Request withObjectType(String value) { this.ObjectType = value; return this; }
		public PageLayoutService.Request withLayoutName(String value) { this.LayoutName = value; return this; }
		public PageLayoutService.Request withOperation(String value) { this.Operation = value; return this; }
		public PageLayoutService.Request withBehavior(String value) { this.Behavior = value; return this; }
		public PageLayoutService.Request withField(String value) { this.Field = value; return this; }
		public PageLayoutService.Request withAnchorType(String value) { this.AnchorType = value; return this; }
		public PageLayoutService.Request withAnchorField(String value) { this.AnchorField = value; return this; }

		public Metadata.LayoutItem asField()
		{
			Metadata.LayoutItem result = new Metadata.LayoutItem();
			result.field = this.Field;
			for (Metadata.UiBehavior uiBehavior : Metadata.UiBehavior.values())
			{
				if (uiBehavior.name() == this.Behavior)
				{
					result.behavior = uiBehavior;
					break;
				}
			}
			
			return result;
		}
	}

	public class Response
	{
		public Boolean Success {get; set;}
		public String Message {get; set;}

		public PageLayoutService.Response withSuccess(Boolean value) { this.Success = value; return this; }
		public PageLayoutService.Response withMessage(String value) { this.Message = value; return this; }
	}

	public class PageLayoutException extends Exception {}
}