# ProxyBeggar

ProxyBeggar is a tool for crawling proxies from many free-proxy-providers. 

Here is some advantages for this tool:
1. It only stores valid proxies in redis, and keep testing and refreshing these proxies.
2. Once there are valid proxies, it will use these proxies to crawl provider's website, so you won't get
blocked by the website for your intensive and continuous requests.
3. You can easily get the valid proxies by a http request.

## Use
1. Bundle
2. Start crawling by executing bin/run
3. `rackup -p 3002` to start a web service. Now you can get valid proxies by request 127.0.0.1:3002. If you want to pretty 
print the response, just request 127.0.0.1:3002?pretty=true.

## Extend
If you want to crawl other providers' website, just create a class inherited ProxyBeggar::BaseCrawler in 
lib/proxy_beggar/crawlers，and make sure implements the abstract methods like other crawlers' class. The new file's name must
compliance the Rails' naming conventions, e.g. the file of `SevenyipCrawler` should be sevenyip_crawler. 


## Extra
Some provider's website may be very slow sometimes, you can modify the waiting time for the corresponding crawler in data/config.yml with
time_limit. You can execute bin/detect to check if the providers' website can be visited. If you are sure some website are
not work anymore, just delete the corresponding crawler file.  