# Qjuin Dominic Salvador
# INF-231
# CTADMOBL Advance Mobile Programming

A new Flutter project that focuses on advance topics. Covering the Mobile to Web Transactions 

## Lab Activity Instance

Lab Activity 1: A stateless widget remains fixed and never changes its appearance once it is built, whereas a stateful widget can update and redraw itself dynamically. To trigger these local updates inside a single stateful widget, developers use setState for simple things like a temporary screen counter. However, when information needs to be shared across multiple different screens, Provider is the much better tool. Provider holds global information in one central place, completely avoiding the difficult process of passing data manually between widgets. 

Lab Activity 2: The model and UI work together by fetching product data from the service layer and rendering it in the screen layer, which keeps the app logic separated and easier to maintain. The search field filters the list on the client side by matching product titles and categories, while the detail screen shows the selected item’s full metadata. This setup makes the API data flow clear: service fetches data, model stores it, and screen displays it with user interaction. In this activity, the new design pattern is a simple MV-like flow where the screen listens to data and updates the view accordingly.