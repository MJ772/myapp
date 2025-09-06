# Motors App Blueprint

This document provides a comprehensive overview of the Motors App, a Flutter application designed to connect customers with various automotive services.

## 1. Project Overview

The Motors App is a multi-faceted platform that facilitates the following services:

- **Vehicle Rentals:** Customers can rent vehicles from various vendors.
- **Chauffeur Services:** Customers can hire chauffeurs for personal transportation.
- **Courier Services:** Customers can request courier services for package delivery.
- **Support:** A dedicated support system to assist all users.

## 2. Features

### 2.1. User Roles & Dashboards

The application implements a robust role-based access control system, with each role having a dedicated dashboard:

- **Admin:** (`AdminDashboard`) - Oversees the entire platform, with the ability to manage users, approve vendors, and monitor all activities.
- **Garage:** (`GarageDashboard`) - Manages vehicle rentals and related services.
- **Chauffeur:** (`ChauffeurDashboard`) - Manages their availability and accepts chauffeur requests.
- **Courier:** (`CourierDashboard`) - Manages their availability and accepts delivery requests.
- **Support:** (`SupportOverviewScreen`) - Manages and resolves support tickets.
- **Customer:** (`CustomerSubmissionScreen`) - Submits requests for rentals, chauffeurs, and couriers.

### 2.2. Authentication

- **Email & Password:** Users can sign up and log in using their email and password.
- **Role-Based Redirection:** Upon login, users are automatically redirected to their respective dashboards.
- **Pending Approval:** New non-customer users (garage, chauffeur, courier) are placed in a pending approval state until an admin approves their account. This is currently bypassed for development.

### 2.3. Development & Testing

- **Developer Toggles:** The application includes developer toggles for bypassing role approvals and auto-approving non-customer users to streamline development and testing.
- **Test Data Seeding:** A utility function is available to seed the Firestore database with test data for rentals, delivery jobs, and support tickets.
- **Test User Creation:** A utility function is available to create a full set of test users with different roles.

### 2.4. Support Ticket System

- **Ticket Creation:** Users can submit support tickets through a dedicated form (`CreateTicketScreen`).
- **Ticket Viewing:** The `SupportOverviewScreen` displays a real-time list of all support tickets from Firestore, ordered by creation date.
- **Status Indicators:** Tickets are visually marked as "Resolved" or "Pending".
- **User-Friendly Timestamps:** The `timeago` package is used to show when a ticket was created in a relative format (e.g., "5 minutes ago").

### 2.5. Garage Services Management

- **Live Data Dashboard:** The `GarageDashboard` displays a live count of "Open Rentals" by streaming data from Firestore.
- **Service Management:** Garage owners can navigate to a `ManageServicesScreen` to perform full CRUD (Create, Read, and Delete) operations on their service offerings.
- **Add Service:** A dialog allows for the easy addition of new services with a title, price, and duration.
- **View & Delete:** Services are listed clearly, and can be deleted with a single tap.

## 3. Styling and Design

- **Theme:** The app uses a Material 3 theme with a deep purple seed color.
- **Layout:** The application follows a standard mobile-first layout with a focus on clean and intuitive UI.

## 4. File Structure

```
lib
├── main.dart
├── firebase_options.dart
├── models
│   ├── service.dart
│   └── ticket.dart
├── screens
│   ├── admin
│   │   └── admin_dashboard.dart
│   ├── auth
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── pending_approval_screen.dart
│   ├── chauffeur
│   │   └── availability_editor_screen.dart
│   ├── placeholder
│   │   ├── chauffeur_dashboard.dart
│   │   ├── courier_dashboard.dart
│   │   └── customer_submission_screen.dart
│   ├── support
│   │   ├── support_overview_screen.dart
│   │   └── create_ticket_screen.dart
│   └── garage
│       ├── garage_dashboard_screen.dart
│       └── manage_services_screen.dart
├── services
│   └── auth_service.dart
└── utils
    ├── constants.dart
    ├── dev_utils.dart
    └── dev_user_creation.dart
```

## 5. Smoke Test Completion

- [x] **Admin:** `admin@test.com` -> `AdminDashboard`
- [x] **Garage:** `garage@test.com` -> `GarageDashboard`
- [x] **Chauffeur:** `chauffeur@test.com` -> `ChauffeurDashboard`
- [x] **Courier:** `courier@test.com` -> `CourierDashboard`
- [x] **Support:** `support@test.com` -> `SupportOverviewScreen`
- [x] **Customer:** `customer@test.com` -> `CustomerSubmissionScreen`
