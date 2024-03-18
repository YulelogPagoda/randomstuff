<H1> Watchlist for AS numbers </H1>
This is a little rundown of how to get a AS list and turn it into a way to look at all the AS numbers that your MDE machines are talking to.

There are many sources you can get the AS list from - ICANN being number one, but for the ease of getting a list I've got a list from IP2Location https://www.ip2location.com/ Signup is free and you can download the ASN file they have there for free.

Now, with that list we can create our watchlist of ASNs. First thing we need to know is that once we have the file which is about 40MB at current time of writing - that will be too big for the max local watchlist size. We can however use Azure storage to put a file into a blob store and then put that blob in for use as a Watchlist.

Here's the step by step...
1. First we'll need a Storage account to put our blob into and we'll likely want to build that in our Sentinel resource group
   ![My Image](images/my_image.png)
3. Then we need to get into Sentinel and go to the Watchlists
4. Use a name that will work for later queries to the Watchlist
   
5. ergea
