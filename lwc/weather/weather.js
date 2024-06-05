import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import weatherCallout from '@salesforce/apex/WeatherServiceCallout.weatherCallout';
import CITY_FIELD from '@salesforce/schema/Account.BillingCity';
import COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';
import STATE_FIELD from '@salesforce/schema/Account.BillingState';
import STREET_FIELD from '@salesforce/schema/Account.BillingStreet';
import LWC_Not_Used from '@salesforce/label/c.LWC_Not_Used';
import Address_Not from '@salesforce/label/c.Address_Not';

const FIELDS = [CITY_FIELD, COUNTRY_FIELD, STATE_FIELD, STREET_FIELD];

export default class AccountWeatherDisplay extends LightningElement {
    @api recordId;
    accountData;
    currentAccountCity;
    currentAccountCityState;
    currentAccountCityCountryCode;
    currentAccountAddress;
    isLoading = true;
    error = false;
    errorMessage;
    weatherTemp;
    weatherDesc;
    weatherImg;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (error) {
            this.error = true;
            this.errorMessage = LWC_Not_Used;
            this.isLoading = false;
        } else if (data) {
            this.accountData = data;
            if (data.fields.BillingCity.value === null 
                && data.fields.BillingState.value === null
                && data.fields.BillingCountry.value === null) {
                    this.error = true;
                    this.errorMessage = Address_Not;
                    this.isLoading = false;
            } else {
                this.currentAccountCity = data.fields.BillingCity.value !== null ? data.fields.BillingCountry.value : '';
                this.currentAccountCityState = data.fields.BillingState.value !== null ? data.fields.BillingState.value : '';
                this.currentAccountCityCountryCode = data.fields.BillingCountry.value !== null ? data.fields.BillingCountry.value : '';
                this.currentAccountAddress = this.currentAccountCityState !== '' ? this.currentAccountCityState : this.currentAccountCity !== '' ? this.currentAccountCity:this.currentAccountCityCountryCode !== '' ? this.currentAccountCityCountryCode: '';
                weatherCallout({ cityName: data.fields.BillingCity.value, cityState : this.currentAccountCityState, cityCountryCode: this.currentAccountCityCountryCode, accountId: this.recordId})
                .then(data => {
                    if (data) {
                        if (data.error === "404") {
                            this.error = true;
                            this.errorMessage = data.weatherdescription;
                            this.isLoading = false;
                            return;
                        } else {
                            this.weatherImg = "https://openweathermap.org/img/wn/" + data.weatherIcon + "@2x.png";
                            this.weatherTemp = data.weatherTemp + '°С';
                            this.weatherDesc = data.weatherdescription;
                        }
                    }
                }).catch(err => console.log(err))
                .finally(() => {
                    this.isLoading = false;
                });
            }
        }
    }
}