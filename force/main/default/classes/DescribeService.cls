public class DescribeService
{
	public DisplayOption[] getObjectTypes()
	{
		DisplayOption[] result = new DisplayOption[]{};
		
		for (Schema.SObjectType objectType : Schema.getGlobalDescribe().values())
		{
			DescribeSObjectResult describe = objectType.getDescribe();
			String developerName = describe.getName();
			String label = describe.getLabel();
			String displayName = String.format('{0} ({1})', new String[]{
				label,
				developerName
			});

			result.add(new DescribeService.DisplayOption()
				.withValue(developerName)
				.withLabel(displayName));
		}

		result.sort();
		return result;
	}
	
	public DisplayOption[] getFields(String objectType)
	{
		DisplayOption[] result = new DisplayOption[]{};
		
		Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectType);
		if (sObjectType != null)
		{
			DescribeSObjectResult describe = sObjectType.getDescribe();
			for (Schema.SObjectField field : describe.fields.getMap().values())
			{
				Schema.DescribeFieldResult dfr = field.getDescribe();
				String developerName = dfr.getName();
				String label = dfr.getLabel();
				String displayName = String.format('{0} ({1})', new String[]{
					label,
					developerName
				});

				result.add(new DescribeService.DisplayOption()
					.withValue(developerName)
					.withLabel(displayName));
			}
		}

		result.sort();
		return result;
	}

	public String getObjectType(String recordId)
	{
		String result = '';
		try
		{
			Schema.SObjectType objectType = Id.valueOf(recordId).getSObjectType();
			result = objectType.getDescribe().getName();
		}
		catch (Exception e)
		{}

		return result;
	}

	public class DisplayOption implements Comparable
	{
		@AuraEnabled public String value {get; set;}
		@AuraEnabled public String label {get; set;}

		public DisplayOption withValue(String value) { this.Value = value; return this; }
		public DisplayOption withLabel(String value) { this.Label = value; return this; }

		public Integer compareTo(Object o)
		{
			if (o instanceof DescribeService.DisplayOption)
			{
				DescribeService.DisplayOption that = (DescribeService.DisplayOption)o;

				String thisLabel = this.label == null ? '' : this.label;
				return thisLabel.compareTo(that.label);
			}

			return 0;
		}
	}
}
