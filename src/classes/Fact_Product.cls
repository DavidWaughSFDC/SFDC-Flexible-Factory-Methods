global class Fact_Product 
{
	public class ProductFactoryException extends Exception { }

	//component
	private static Fact_BaseComponent factoryBase = new Fact_BaseComponent('Product2');

	//define default constants
    public static final String DEFAULT_SKU = 'WIDG1000';  //widget
    public static final String DEFAULT_SERVICE_SKU = 'SERV3000';
    public static final String DEFAULT_TRAINING_SKU = 'CONS5000';

    public static final Set<String> DEFAULT_SKUS_SET = new Set<String> {DEFAULT_SKU, DEFAULT_SERVICE_SKU, DEFAULT_TRAINING_SKU};

    private static Map<String, Map<String, Object>> skuToRequiredFieldsToValuesNestedMap = new Map<String, Map<String, Object>>();

    /******** STATIC INITIALIZATION REGION ********/

    static 
    {
        for (String sku : DEFAULT_SKUS_SET)
    	{
        	skuToRequiredFieldsToValuesNestedMap.put(sku, populateRequiredFieldsToValuesMap(sku));
        }
    }

    /******** INIT HELPER REGION ********/
    
    private static Map<String, Object> populateRequiredFieldsToValuesMap(String sku)
    {
		Map<String, Object> requiredFieldsToValues = new Map<String, Object>();

        String productCode = null;
        String name = null;
        String description = null;
        String family = null;
        
        Boolean isActive = true;

        //Default Widget Sku:
    	if (sku == DEFAULT_SKU)
    	{
            productCode = sku;
        	name = 'Default Widget Offering';
			description = name;

	        family = 'Widget';
        }
        //Default Service Sku:
        else if (sku == DEFAULT_SERVICE_SKU)
        {
            productCode = sku;
        	name = 'Default Service Offering';
			description = name;

	        family = 'Service';
        }
        //Default Training Sku:
        else if (sku == DEFAULT_TRAINING_SKU)
        {
            productCode = sku;
        	name = 'Default Training Offering';
			description = name;

	        family = 'Widget';
        }
        else
        {
            throw new ProductFactoryException('Parameter sku not configured in Product Factory');
        }

        requiredFieldsToValues.put('ProductCode', sku);
        requiredFieldsToValues.put('Name', name);
        requiredFieldsToValues.put('Description', description);
        requiredFieldsToValues.put('Family', family);

        requiredFieldsToValues.put('IsActive', isActive);

    	return requiredFieldsToValues;
    }

    /******** METHODS REGION ********/

    //Core 'create' method
	global static Product2 createProduct(String sku)
	{	
		Product2 prod = new Product2();

		/*** START param validation ***/
		
		//if recordTypeName param's RecordType isn't available, throw config. error
        if (!skuToRequiredFieldsToValuesNestedMap.containsKey(sku))
        {
            throw new ProductFactoryException('Sku ' + sku + ' not configured in Product Factory');       
        }
        /*** END param validation ***/

        //RecordType assignment: SObject has no record types

        /*** START Dynamic field assignment ***/
        factoryBase.assignValuesToFieldsFromMap(prod, skuToRequiredFieldsToValuesNestedMap.get(sku) );
        /*** END Dynamic field assignment ***/

		return prod;
	}

	//Core 'insert' method
    global static List<Product2> insertProducts(List<String> skus)
    {
        //guard conditions:
        if (skus == null || skus.size() == 0)
        {
            throw new ProductFactoryException('Method cannot have null or empty list parameters');       
        }

        // query to determine if sku is already added 
        List<Product2> alreadyInsertedProductsList = [SELECT ProductCode
                                                    FROM Product2 WHERE Product2.ProductCode IN :skus];

        // create map of existing skus to products
        Map<String, Product2> alreadyInsertedSkuToProductMap = new Map<String, Product2>();

        Set<String> uninsertedSkuSet = new Set<String>(skus);

        if (alreadyInsertedProductsList.size() > 0)
        {
            // convert alreadyInsertedProductsList to map
            for (Product2 alreadyInsertedProduct : alreadyInsertedProductsList)
            {
                alreadyInsertedSkuToProductMap.put(alreadyInsertedProduct.ProductCode, alreadyInsertedProduct);
            }

            uninsertedSkuSet.removeAll(alreadyInsertedSkuToProductMap.keySet());
        }


        List<String> uninsertedSkuList = new List<String>(uninsertedSkuSet);

        Integer recordCount = uninsertedSkuList.size();

        //Factory records to generate and insert
        List<Product2> prods = new List<Product2>();

        //per-record creation
        for (Integer i = 0; i < recordCount; i++)
        {
            Product2 productToInsert = createProduct(uninsertedSkuList[i]);

            prods.add(productToInsert);
        }

	    //Note: no lookup assignments for this SObject

        insert prods;

        if (alreadyInsertedSkuToProductMap.size() > 0)
        {
            prods.addAll(alreadyInsertedSkuToProductMap.values());
        }

        return prods;
    }

    global static Product2 insertProduct(String sku)
	{
		List<String> skus = new List<String>();
        skus.add(sku);

        return insertProducts(skus)[0];
    }

	global static Product2 insertProduct()
	{
		List<String> skus = new List<String>();
        skus.add(DEFAULT_SKU);

        return insertProducts(skus)[0];
    }

}