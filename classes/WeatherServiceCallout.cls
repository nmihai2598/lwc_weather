public with sharing class WeatherServiceCallout {

    private static final String SERVICE_URL = 'callout:WeatherAPI';
    private static ApiKey__c apikey = ApiKey__c.getInstance();


    @AuraEnabled
    public static WeatherData weatherCallout(String cityName, String cityState, String cityCountryCode, Id accountId) {
        WeatherData weather = new WeatherData();
        String cond = cityName.replace(' ', '%20') + ',' + cityState.replace(' ', '%20') + ',' + cityCountryCode.replace(' ', '%20');
        Map<String, String> params = new Map<String, String> {
            'units' => 'metric',
             'q' => cond
        };
        
        HTTPResponse res = requestWeather(params); 
        Map<String, Object> mapResp = (Map<String, Object>) JSON.deserializeUntyped(res.getBody().toString());
        if (mapResp.get('cod') == '404') {
            weather.error = mapResp.get('cod').toString();
            weather.weatherdescription = (String) mapResp.get('message').toString();
            System.debug(weather);
            return weather;
        }
        for (Object obj: (List<Object>)mapResp.get('list')) {
            Map<String, Object> objMap = (Map<String, Object>) obj;
            System.debug(Date.valueOf(objMap.get('dt_txt').toString()) );
            System.debug(Date.today().addDays(+1));
            if (Date.valueOf(objMap.get('dt_txt').toString()) == Date.today().addDays(+1)){
                Map<String, Object> mapResponse =(Map<String, Object>) ((List<Object>)objMap.get('weather')).get(0);
                System.debug(mapResponse.get('description').toString());
                weather.weatherdescription = (String) mapResponse.get('description').toString();
                weather.weatherIcon = (String) mapResponse.get('icon').toString();
                weather.weatherTemp = Integer.valueof(((Map<String, Object>)objMap.get('main')).get('temp'));
        		weather.weatherAccount = updateAccount(accountId, weather.weatherdescription);
                break;
            }
        }
        return weather;
    }
    
    private static HTTPResponse requestWeather(Map<String, String> params) {
        String weatherApi = SERVICE_URL + '?appid=' + apikey.Key__c;
		
        for (String key: params.keySet()) {
            weatherApi += '&' + key + '=' + params.get(key);
        }
        HttpRequest weatherRequest = new HttpRequest();
        weatherRequest.setEndpoint(weatherApi);
        weatherRequest.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(weatherRequest);
        return res;
    }
    
    private static Account updateAccount(Id accountId, String weatherdescription) {
        try {
            Account acc = new Account();
            acc.Id = accountId;
            acc.Weather_description__c = weatherdescription;
            update acc;
            return acc;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class WeatherData {
        @AuraEnabled public Account weatherAccount;
        @AuraEnabled public String weatherdescription;
        @AuraEnabled public String weatherIcon;
        @AuraEnabled public Decimal weatherTemp;
        @AuraEnabled public String error;
    }
}