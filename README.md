# COMP327 Assignment 2 - 98%

### Developing a “Coffee-Shops on Campus” App.

### Your Task

You will design and develop an application written in Swift 5 (or later) for iPhone 8. The application will enable you to locate
coffee-shops on campus relative to the user’s current location.

In order to do this, you will need to retrieve data from a web service regarding the location of, and information about,
coffee-shops on campus (note the underscore character that precedes the word “ajax” in the following URL).

https://dentistry.liverpool.ac.uk/_ajax/coffee/

This URL will return information about the full set of coffee-shops that are recorded in the database. To retrieve information
on a specific shop, use the URL below (supplying the appropriate value for the ID).

https://dentistry.liverpool.ac.uk/_ajax/coffee/info/?id=1

Note:
1. Use secure URLs, otherwise your app will not load the data or images.
2. Although the database structure will remain the same, the content will be updated soon to include URLs for images of the coffee-shops (at the moment, those image URLs are all null).

Your application is required to have the following basic features **(worth 70%):**
1. The user is initially presented with a map centred on their current location and at a reasonable level of zoom so that nearby roads etc. can be seen clearly. You may assume that the user is currently in the Ashton Building (a location file is available for Xcode to simulate the location of the Ashton Building). (latitude: 53.406566, longitude: -2.966531). **(worth 20%)**
2. Retrieve and decode the JSON data from the URLs, using the Codable protocol and JSONDecoder() (See lecture set 3, slides 19-22). **(worth 10%)**
3. The map contains a number of annotation marks indicating the location of nearby coffee-shops. **(worth 5%)**
4. In portrait view, a table below the map contains a list of coffee-shops (along with basic information), ordered by distance from the current location. **(worth 20%)**
5. Tapping on an annotation displays more detailed information about a specific coffee-shop, including an image (where available) and opening times, contact details, address etc. **(worth 15%)**

**25%** of the marks may be obtained by implementing useful features such as:
1. A search box allows the user to filter the items displayed in the table. **(worth 5%)**
2. Caching the coffee-shop information (in Core Data) on first run of the app. On subsequent runs, if no data connection is available, retrieve and display the information from Core Data. **(worth 10%)**
3. Implement an alternative layout in landscape view, e.g. the map displayed on the left and the table of coffee-shops displayed on the right. **(worth 10%)**
