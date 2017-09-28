/**
 * Copyright (c) 2017, FinancialForce.com, inc. All rights reserved.
 */
public class PageLayoutService
{
	public static final String STRATEGY_CLASSIC = 'Strategy_Classic';
	public static final String STRATEGY_NATIVE = 'Strategy_Native';
	
	public static final String OPERATION_ADD = 'Operation_Add';
	public static final String OPERATION_REMOVE = 'Operation_Remove';
	
	public static final String ANCHOR_TYPE_START = 'Anchor_Type_Start';
	public static final String ANCHOR_TYPE_BEFORE = 'Anchor_Type_Before';
	public static final String ANCHOR_TYPE_AFTER = 'Anchor_Type_After';
	public static final String ANCHOR_TYPE_END = 'Anchor_Type_End';

	public PageLayoutService.Response updateLayout(PageLayoutService.Request request)
	{
		if (request.Strategy == STRATEGY_CLASSIC)
		{
			return new NativePageLayoutUpdater().updateLayout(request);
		}
		
		if (request.Strategy == STRATEGY_NATIVE)
		{
			return new NativePageLayoutUpdater().updateLayout(request);
		}
		
		return new PageLayoutService.Response()
			.withSuccess(false)
			.withMessage('Unknown strategy: ' + request.Strategy);
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
