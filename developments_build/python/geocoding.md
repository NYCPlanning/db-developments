## About Geocoding
The current geocoding process uses geosupport desktop linux and python-geosupport binder to geocode addresses. 

### Important: 
* function ```1A```: the actual information
* function ```1E```: theoretical information
* function ```1B```: a combination of above two. 

### Current Approach: 
* We are calling function ```1B``` 
* First check if record exists in PAD (using mode ```regular```)
* If not, check if record exists in TPAD (using mode ```tpad```)
* if still doesn't exist, dump records into error file

### Issues: 
* ~~Theoretically, with ```regular+tpad``` switched on, we should expect more addresses to be geocoded, however, based on observation. when :~~ 
    ~~* using function ```1B```, there are fewer hits than using ```1B``` with mode ```regular```~~
    ~~* using function ```1A```, there are more hits than using ```1A``` with mode ```regular```(which follows expectation)~~
* switching on ```regular+tpad``` actually only yields ```tpad```, see github issue [here](https://github.com/ishiland/python-geosupport/issues/14)

* to further investigate the discrepencies between different modes and different functions, here are the few strange cases we encountered: 

* inconsistencies between geosupport and geoclient: 
    * for some cases, geosupport will not yield lat lon in the output but geoclient would, see explaination [here](https://github.com/CityOfNewYork/geoclient/issues/32)
    * basically if geoclient couldn't identify the lot centroid lat lon, it would yield the teoretical lat lon based on the street centerline. 
    * however, geosupport (under mode ```regular``` and ```tpad```) would only give you the actual lot centroid lat lon. 

* __same function call with different mode yielded different results__
```
>>> g['1A'](house_number='204-11', street_name='38 ave', borough_code='qn')['Longitude']
'-73.781607'
>>> g['1A'](house_number='204-11', street_name='38 ave', borough_code='qn', mode='regular+tpad')['Longitude']
''
```
### learned knowledge:
* ```1E``` does not return longitude and latitude information (when the mode is ```regular```)
* ```1E``` does not support TPAD switches
* ```1E``` does return longitude and latitude when the mode is ```extended```
