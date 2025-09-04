
# Motors App

This is a Flutter-based application that connects customers with car repair garages. Customers can submit repair requests, and garages can bid on those requests. The app also includes a settings screen for both customers and garages, as well as a dashboard for each role.

## Features

- **User Roles:** The app supports two user roles: `customer` and `garage`. Customers can submit repair requests, while garages can view and bid on them.
- **Repair Request Submission:** Customers can submit repair requests with a description, photos, and their current location.
- **Bidding:** Garages can view open repair requests and submit bids on them.
- **Dashboards:** The app provides a dashboard for both customers and garages. Customers can view their repair requests, while garages can view open requests and their own bids.
- **Settings:** Both customers and garages have access to a settings screen where they can manage their profile and other preferences.

## Running the Project

To run this project, you will need to have Flutter installed and configured on your machine. You will also need to have a Firebase project set up with the following services enabled:

- Firebase Authentication
- Firebase Firestore
- Firebase Storage

Once you have set up your Firebase project, you will need to add your Firebase configuration to the `lib/firebase_options.dart` file. You can then run the project using the following command:

```
flutter run
```
