# Mandem Blueprint

## Overview

This document outlines the architecture, features, and design of the Mandem app, a comprehensive vehicle rental and service platform. The app connects customers with vehicle rentals (with optional chauffeurs), parts delivery, and garage services.

## Architecture

The application follows a standard Flutter layered architecture, separating UI (presentation), business logic (domain), and data persistence (data). State management is handled by `provider` for app-wide state and `ValueNotifier` for local widget state.

*   **Data Layer**: Cloud Firestore is the primary database, with data models defined in `lib/models`. Firebase Storage is used for user-uploaded images and other assets.
*   **Domain Layer**: Business logic is encapsulated in services and providers, ensuring a clear separation of concerns.
*   **Presentation Layer**: The UI is built with Flutter's Material Design library, with custom themes and widgets for a consistent user experience.

## Features

### User Roles

*   **Customer**: Can browse and rent vehicles, book services, and request parts delivery.
*   **Garage (Vendor)**: Can list vehicles for rent, manage services, and fulfill parts orders.
*   **Chauffeur**: Can be hired to drive rental vehicles.
*   **Courier**: Can deliver parts to customers.
*   **Admin/Support**: Can manage users, approve vendors, and handle support tickets.

### Core Functionality

*   **Authentication**: Users can sign up and sign in with email and password, with role selection at registration.
*   **Vehicle Rentals**: Garages can list vehicles with details like make, model, year, price, and availability. Customers can browse, filter, and book rentals.
*   **Chauffeur Services**: Customers can opt to hire a chauffeur for their rental.
*   **Parts Delivery**: Garages can list parts for sale, and customers can order them for same-day delivery.
*   **Garage Services**: Garages can list their services (e.g., oil change, tire rotation), and customers can book appointments.
*   **Support System**: Users can create support tickets to get help from the admin/support team.

## Design

The app uses a modern, clean design with a consistent color scheme and typography. The UI is designed to be intuitive and easy to navigate for all user roles.

*   **Theming**: A centralized theme is defined in `lib/theme/theme.dart`, with light and dark modes.
*   **Widgets**: Reusable widgets are used throughout the app to maintain a consistent look and feel.
*   **Navigation**: `go_router` is used for declarative navigation, providing a robust and scalable routing solution.

## Current Plan

### Task: Refactor and Enhance Firestore Rules & Models

**Objective**: To improve the security, consistency, and functionality of the Firestore database by refactoring security rules, updating data models, and adding a new feature for garage services.

**Steps**:

1.  **Refactor Screens**: Relocate `garage_dashboard_screen.dart` and `manage_services_screen.dart` from `lib/screens/garage/` to `lib/screens/vendor/` to better reflect the user role.

2.  **Update Firestore Rules (`firestore.rules`)**:
    *   Add a rule to allow specific admin emails (`emjadulhoqu3@gmail.com`, `mandemmotorsltd@gmail.com`) to have admin privileges.
    *   Refine the `reservations` update rule to prevent users from changing the `vendorId`.
    *   Add a rule for `support_tickets` to ensure that the `openedBy` field is set to the user's UID upon creation.
    *   Implement rules for a new `services` collection to allow approved vendors to manage their services.

3.  **Update Firestore Indexes (`firestore.indexes.json`)**:
    *   Add a composite index for `reservations` to support querying by `vendorId`, `status`, and `createdAt`.
    *   Add an index for the new `services` collection to allow querying by `garageId`.

4.  **Update `Ticket` Model (`lib/models/ticket.dart`)**:
    *   Standardize the `userId` field to `openedBy` for consistency with the new security rules.
    *   Add a `serverTime` parameter to the `toMap` method to use `FieldValue.serverTimestamp()` for accurate creation timestamps.

5.  **Update `CreateTicketScreen` (`lib/screens/support/create_ticket_screen.dart`)**:
    *   Modify the ticket creation logic to use the `openedBy` field and set the `createdAt` timestamp using the server time.

6.  **Update `Reservation` Model (`lib/models/reservation.dart`)**:
    *   Ensure the `vendorId` is included in the `toMap` method so it is correctly saved to Firestore.

## Next Milestones (MVP Close-Out)

### N1 — Vendor Reservation Detail & Confirmation
**Goal:** Allow vendors to confirm/decline pending reservations and assign a chauffeur.
**Deliverables:**
- `lib/screens/vendor/reservation_detail_screen.dart`
- Vendor list of pending reservations (query `collectionGroup('reservations')` by `vendorId == uid`, `status == 'pending'`).
- Actions: Confirm → `status:'confirmed'`; Decline → `status:'cancelled'`; Assign chauffeur → set `chauffeurAssignment.driverId`.
**Acceptance:**
- Vendor updates are reflected immediately for the customer.
- Firestore rules prevent changing `customerId/startDate/endDate/vendorId`.

### N2 — Chauffeur Offer & Assignment
**Goal:** Turn confirmed chauffeured bookings into actionable jobs.
**Deliverables:**
- On vendor confirm (chauffeured): create `users/{driverId}/chauffeur_jobs/{jobId}` with `status:'offer'`.
- Chauffeur Inbox → Accept/Decline; vendor marks reservation as `assigned` when accepted.
**Acceptance:**
- Chauffeur state changes propagate to reservation fields; rules allow only assignment status updates for the chauffeur.

### N3 — Support Ticket Detail & Resolve
**Goal:** Operational support tooling.
**Deliverables:**
- `lib/screens/support/ticket_detail_screen.dart` with resolve toggle (support/admin only).
- SupportOverview shows all tickets for support/admin; “My Tickets” for non-support users.
**Acceptance:**
- Changing `isResolved` updates list state without errors.

### N4 — Admin Approvals (Staging Flip)
**Goal:** Prove production approval gates.
**Steps:**
- Set `kBypassRoleApprovals=false`, `kAutoApproveNonCustomer=false` (staging).
- Test new signups for Garage/Chauffeur/Courier → Pending → Approve → Dashboard.
**Acceptance:**
- All three roles require admin approval before dashboard access; no rule violations.

### N5 — Garage Services (Customer-Side)
**Goal:** Make Services discoverable and bookable.
**Deliverables:**
- `services_list_screen.dart`, `service_detail_screen.dart`, `service_booking_screen.dart`
- Collection: `service_bookings` with `{vendorId, customerId, serviceId, startDate, status, createdAt}`
- Rules: mirror reservations constraints (vendor/customer/admin scopes).
**Acceptance:**
- Customer can create a service booking; vendor can view their bookings.

### N6 — Profile & Settings
**Goal:** Basic user self-service.
**Deliverables:**
- `account/profile_screen.dart` to update displayName/photo.
- Storage write for avatar (optional), secure rules: users can only edit safe fields.
**Acceptance:**
- Profile updates persist; no role/approval edits possible by users.

### Notes on Architecture Alignment
- **Router:** For MVP, we keep `Navigator` + `_AuthGate`. Post-MVP we may migrate to `go_router` for declarative routes.
- **Naming:** Consolidate to `lib/screens/vendor/*` (replace any lingering `garage/*` imports as we touch files).
