/**
 * Copyright (c) 2017, FinancialForce.com, inc. All rights reserved.
 */
public class PageLayoutService
{
	public static final String STRATEGY_CLASSIC = 'Strategy_Classic';
	public static final String STRATEGY_NATIVE = 'Strategy_Native';
	
	public static final String OPERATION_ADD = 'Operation_Add';
	public static final String OPERATION_REMOVE = 'Operation_Remove';
	
	public static final String BEHAVIOUR_EDIT = 'Behaviour_Edit';
	public static final String BEHAVIOUR_REQUIRED = 'Behaviour_Required';
	public static final String BEHAVIOUR_READONLY = 'Behaviour_Readonly';
	
	public static final String ANCHOR_TYPE_START = 'Anchor_Type_Start';
	public static final String ANCHOR_TYPE_BEFORE = 'Anchor_Type_Before';
	public static final String ANCHOR_TYPE_AFTER = 'Anchor_Type_After';
	public static final String ANCHOR_TYPE_END = 'Anchor_Type_End';

	public PageLayoutService.Response updateLayout(PageLayoutService.Request request)
	{
		PageLayoutService.Response response;
		try
		{
			if (request.Strategy == STRATEGY_CLASSIC)
			{
				response = new ClassicPageLayoutUpdater().updateLayout(request);
			}
			else if (request.Strategy == STRATEGY_NATIVE)
			{
				response = new NativePageLayoutUpdater().updateLayout(request);
			}
			else
			{
				throw new PageLayoutException('Unknown strategy: ' + request.Strategy);
			}
		}
		catch (Exception e)
		{
			response = new PageLayoutService.Response()
				.withSuccess(false)
				.withMessage(e.getMessage());
		}
		
		return response;
	}

	public class Request
	{
		@AuraEnabled public String Strategy {get; set;}
		@AuraEnabled public String ObjectType {get; set;}
		@AuraEnabled public String LayoutName {get; set;}
		@AuraEnabled public String Operation {get; set;}
		@AuraEnabled public String Behavior {get; set;}
		@AuraEnabled public String Field {get; set;}
		@AuraEnabled public String AnchorType {get; set;}
		@AuraEnabled public String AnchorField {get; set;}

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
			
			if (this.Behavior == BEHAVIOUR_EDIT)
			{
				result.Behavior = Metadata.UiBehavior.EDIT;
			}
			else if (this.Behavior == BEHAVIOUR_REQUIRED)
			{
				result.Behavior = Metadata.UiBehavior.REQUIRED;
			}
			else if (this.Behavior == BEHAVIOUR_READONLY)
			{
				result.Behavior = Metadata.UiBehavior.READONLY;
			}
			
			return result;
		}

		public MetadataService.LayoutItem asMetadataServiceField()
		{
			MetadataService.LayoutItem result = new MetadataService.LayoutItem();
			result.field = this.Field;
			
			if (this.Behavior == BEHAVIOUR_EDIT)
			{
				result.Behavior = Metadata.UiBehavior.EDIT.name();
			}
			else if (this.Behavior == BEHAVIOUR_REQUIRED)
			{
				result.Behavior = Metadata.UiBehavior.REQUIRED.name();
			}
			else if (this.Behavior == BEHAVIOUR_READONLY)
			{
				result.Behavior = Metadata.UiBehavior.READONLY.name();
			}
			
			return result;
		}
	}

	public class Response
	{
		@AuraEnabled public Boolean Success {get; set;}
		@AuraEnabled public String Message {get; set;}

		public PageLayoutService.Response withSuccess(Boolean value) { this.Success = value; return this; }
		public PageLayoutService.Response withMessage(String value) { this.Message = value; return this; }
	}

	public class PageLayoutException extends Exception {}
}
