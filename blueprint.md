# Car Repair Reverse Auction App Blueprint

## Project Goal

Build a production-ready Flutter + Firebase reverse-auction app for car repairs with:
1. Customer photo/video uploads of vehicle issues
2. Real-time bidding by local garages
3. Fixed-price service catalog
4. Stripe payments & push notifications

## Technical Requirements

- **Flutter 3.19+** (iOS/Android)
- **Firebase**: Firestore, Storage, Auth, Cloud Functions
- **Stripe SDK** for payment holds
- **Firebase Extensions**:
    - `Storage Resize Images` (optimize uploaded photos)
    - `Firestore Send Email` (for bid notifications)
- **Dependencies**:
    - `firebase_core`
    - `cloud_firestore`
    - `firebase_auth`
    - `firebase_storage`
    - `image_picker`
    - `stripe_sdk`
    - `flutter_local_notifications`
    - `geolocator`

## Firestore Schema

```
plaintext
/repair_requests/{requestId}
- userId (string)
- photos: [string] (Firebase Storage URLs)
- description (string)
- status: "open"|"accepted"|"completed"
- createdAt (timestamp)
- location: {latitude: number, longitude: number}

/bids/{bidId}
- requestId (string)
- garageId (string)
- price (number)
- availability (string)
- status: "pending"|"accepted"

/services/{serviceId}
- garageId (string)
- title (string)
- price (number)
- duration (string)
```
## Cloud Functions Needed

1.  `onRepairRequestCreate`:
    - Resize images using Sharp.js
    - Notify nearby garages via FCM
2.  `onBidCreate`:
    - Validate bid price > garage's minimum
    - Update Firestore `repair_requests/bids` subcollection
3.  `onBidAccept`:
    - Charge 10% deposit via Stripe
    - Send confirmation SMS using Twilio

## Implemented Features (as of this blueprint update)

- Basic Firebase Initialization in `main.dart`
- Placeholder for Photo Uploader logic

## Implemented Features (as of this blueprint update)

- **Garage Dashboard:** Bid submission functionality implemented, including UI for entering bid price and availability and calling the `addBid` method.

## Plan for Next Steps

1.  **Implement `RepairRequestService`:** Create `lib/services/repair_request_service.dart` to handle CRUD operations for `repair_requests` and `bids` collections in Firestore. This will include methods to:
    - Create a new repair request
    - Fetch repair requests (all, by user, by status)
    - Add a bid to a repair request
    - Accept a bid
    - Fetch bids for a specific request
2.  **Build Customer Request Submission Screen:** Create `lib/screens/customer_submission_screen.dart`. This screen will include:
    - A mechanism for multi-image selection and upload to Firebase Storage.
    - A text field for the customer to describe the vehicle issue.
    - Integration with the `geolocator` package to get the customer's current location and store it with the repair request.
    - Logic to call `RepairRequestService` to submit the new repair request.
3.  **Develop Garage Dashboard:** Create `lib/screens/garage_dashboard.dart`. This screen will display open repair requests that are within a 10km radius of the garage's location (assuming garage location data is available elsewhere or will be added to the garage user profile). This will involve:
- **Repair Request Details Screen:** Create `lib/screens/repair_request_details_screen.dart`. This screen will fetch and display the details of a specific repair request and stream and display the bids associated with that request.

## Implemented Features (as of this blueprint update)

- **Garage Dashboard:** Displays open repair requests within a 10km radius of the garage's location.
    - Fetching the garage's location.
- Querying Firestore for `repair_requests` with status "open".
    - Calculating the distance between the garage and each repair request's location.
    - Displaying relevant details of the open requests within the radius.
4.  **Write Automated Test Cases for Bid Validation:** Create `test/bid_validation_test.dart`. This file will contain unit tests to verify the logic for bid validation, specifically ensuring that a bid price is greater than a simulated garage's minimum acceptable price.

## Future Enhancements

- Implement user authentication (customer and garage roles).
- Develop the real-time bidding UI for garages.
- Integrate Stripe for payment processing.
- Implement push notifications for relevant events (new bids, accepted bids, etc.).
- Create the fixed-price service catalog features.
- Implement the necessary Cloud Functions.
- Add comprehensive error handling and UI feedback.