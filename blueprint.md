1) Vision & Scope

Motors App is a multi-role automotive marketplace that connects customers with garages (vendors) for repair bids (reverse auction), enables vehicle rentals (self-drive & chauffeured), supports parts purchases with same-day couriers, and provides admin oversight and support staff operations.

Primary roles

Customer — requests repairs, books rentals, buys parts, chats with support.

Garage (Vendor) — bids on repair requests, lists rentals & parts, manages orders.

Chauffeur — sets availability, accepts chauffeured jobs, completes rides.

Courier — claims delivery jobs, completes pickups/drop-offs with live status.

Admin (Superuser) — full control: approvals, blacklists, data oversight, support.

Support Staff — manages tickets, chats, limited back-office visibility.

2) Delivery Plan & Timeline
Week-1 MVP (ship fast, then harden)

Auth & Roles

Split AuthScreen → LoginScreen and SignupScreen.

Role-aware router in main.dart (customer / garage / chauffeur / courier / support / admin).

Dev mode bypass of approvals (see §3).

Rentals (Core)

Customer: list → detail → checkout.

Checkout supports self-drive or chauffeured (choose driver).

Creates reservations (with chauffeur preference/assignment fields).

Chauffeur

Availability CRUD (users/{uid}/availability).

Inbox of offers (users/{uid}/chauffeur_jobs), accept/decline.

Vendor & Admin

Vendor dashboard stub + Stripe Connect gate (UI).

Admin approvals screen (Vendors/Chauffeurs/Couriers).

Support

Support queue stub reading support_tickets.

Phase A (Parts & Couriers)

Parts checkout → delivery_jobs creation; courier app flow; live tracking/ETA.

Customer & vendor tracking screens.

Phase B (Vehicles for Sale & Events)

Vehicle listings with filters & viewing reservations.

Events listing, vendor/admin curation.

Phase C (Payments & Compliance)

Stripe Connect (vendors/chauffeurs/couriers) + webhooks/payouts.

T&Cs/Privacy reviewed for UK/EU compliance.

Phase D (Ratings & Reviews)

Transaction-bound reviews across all roles; profile aggregates.

3) Dev Mode vs Production

Add toggles in lib/utils/constants.dart:

const Set<String> kAdminEmails = {'info@motorsapp.co.uk'};
const Set<String> kAdminUids = { /* optional hard lock UID(s) */ };

/// DEV ONLY (MVP): skip Pending screens in routing.
const bool kBypassRoleApprovals = true;

/// DEV ONLY (MVP): auto-approve non-customer roles at signup.
const bool kAutoApproveNonCustomer = true;


During MVP keep both = true for rapid testing.

Before enforcing approvals set both = false, verify Pending→Approved flows.

4) Current Status (Implemented)

Firebase integration: Auth + Firestore wired.

Roles: customer, garage, admin, chauffeur, courier, support.

Role routing: _AuthGate directs to dashboards; dev bypass active.

Approvals: Admin screen exists; bypassed in dev via toggles.

Customer: Rentals list/detail/checkout stubs in place (chauffeur option included).

Vendor: Dashboard scaffold + Stripe Connect gate (UI).

Admin: Approvals, blacklist, support tickets (views).

Support: Overview placeholder.

Chauffeur/Courier: Placeholders plus basic availability/inbox (chauffeur) and jobs list (courier).

5) Architecture
Tech stack

Flutter (Material 3; responsive, scalable widgets).

Firebase: Auth, Firestore, (Storage later), Functions (webhooks & automation), FCM (later).

High-level directory
lib/
  main.dart
  firebase_options.dart
  utils/
    constants.dart            // dev toggles, admin allowlists
    validators.dart           // (add)
    formatters.dart           // (add)
  models/
    user_model.dart           // roles, approvals, stripe status
    repair_request.dart
    bid.dart
    rental.dart
    vehicle.dart
    event.dart
    service.dart
    blacklist_entry.dart
  services/
    auth_service.dart
    repair_request_service.dart
    rental_service.dart
    vehicle_service.dart
    event_service.dart
    stripe_service.dart
    firestore_helpers.dart
  screens/
    auth/
      login_screen.dart
      signup_screen.dart
      pending_approval_screen.dart
      onboarding_screen.dart
    customer/
      customer_dashboard.dart          // (add)
      customer_submission_screen.dart
      rentals/
        rental_list_screen.dart
        rental_detail_screen.dart
        rental_checkout_screen.dart
      vehicles/
        vehicle_list_screen.dart
        vehicle_detail_screen.dart
      account/
        account_screen.dart            // (add)
        terms_screen.dart
        privacy_policy_screen.dart
        support_screen.dart
    vendor/
      garage_dashboard.dart
      stripe_connect_screen.dart       // (add)
      orders_bookings_screen.dart      // (add)
      blacklist_screen.dart            // (add)
    chauffeur/
      chauffeur_dashboard.dart
      availability_editor_screen.dart
      job_inbox_screen.dart
    courier/
      courier_dashboard.dart
      available_jobs_screen.dart
      active_delivery_screen.dart
    admin/
      admin_dashboard.dart
      vendor_approval_screen.dart
      support_overview_screen.dart
    support/
      support_home_screen.dart         // (add)
  widgets/
    common_widgets.dart
    cards/
      vehicle_card.dart
      rental_card.dart
      event_card.dart
    forms/
      repair_request_form.dart
      rental_form.dart
      vehicle_form.dart

6) Data Model (MVP)

users/{uid}

role: 'customer'|'garage'|'chauffeur'|'courier'|'admin'|'support'

vendorApproved: bool, chauffeurApproved: bool, courierApproved: bool

displayName, photoUrl, stripeConnected: bool, createdAt

rentals/{rentalId}

vendorId, vehicle: {make, model, ...}, pricePerDay, type: 'selfDrive'|'chauffeured', createdAt

Subcollection reservations/{resId}:

customerId, startDate, endDate

agreedToTerms: bool, agreedToContract: bool

status: 'pending'|'confirmed'|'cancelled'

chauffeurPreference: uid|null

chauffeurAssignment: { driverId: uid|null, status: 'pending'|'accepted'|'declined'|'assigned' }

createdAt

users/{uid}/availability/{slotId}

start, end, source: 'manual'|'google'

users/{uid}/chauffeur_jobs/{jobId}

rentalReservationRef: <path>, status: 'offer'|'accepted'|'declined'|'assigned', createdAt

(Phase A) delivery_jobs/{deliveryId}

status: 'open'|'assigned'|'picked_up'|'enroute'|'delivered'

pickupAddress, dropoffAddress, size, weight, assignedCourierId

vendorId, customerId, createdAt, updatedAt

Support

support_tickets/{ticketId}: openedBy, targetType, status: 'open'|'assigned'|'closed', createdAt

conversations/{convId}/messages/{msgId} (later)

(Phase D) Reviews

reviews/{reviewId}:

targetType: 'customer'|'vendor'|'chauffeur'|'courier'|'support'

targetId, authorId, contextRef (transaction path), stars:1..5, text, createdAt

user_ratings/{uid}: avg: number, count: number

7) Firestore Security (summary)

Users cannot escalate privileges or set their own approval flags.

Non-customer reads/writes gated by role & approval flags (bypassed only in UI/DB via dev toggles).

Customers can create reservations; vendors can read their own orders; chauffeurs can read their own jobs; couriers can read jobs assigned to them.

Admin: full read/write.

Indexes (create):

rentals: createdAt desc

users: (role, vendorApproved), (role, chauffeurApproved), (role, courierApproved)

delivery_jobs: (status eq, createdAt desc)

support_tickets: createdAt desc

8) Feature Breakdown & Acceptance (MVP)
Auth & Routing

Done when:

Signup supports role selection; non-customer roles land in dashboards (dev bypass).

Admin allowlist routes to AdminDashboard.

Pending screen present; re-enabled when toggles = false.

Rentals

Done when:

Rentals visible; detail shows pricing/type.

Checkout collects date range, consents; chauffeured path shows ChauffeurPicker.

Reservation doc written with correct fields.

Chauffeur

Done when:

Availability slots add/remove.

Inbox shows offers; accept/decline updates job doc.

Vendor/Admin/Support

Vendor: Gate renders when stripeConnected:false; reservations/requests list visible (read-only OK).

Admin: Approvals tabs filter unapproved users; approve/reject actions work.

Support: Queue lists tickets; “Take” sets status:'assigned'.

9) Post-MVP High-Value Work

Parts & Couriers: end-to-end delivery flow, live location & ETA, customer/vendor tracking views.

Vehicles & Events: filters, viewing reservations, subscriptions.

Payments: Stripe Connect onboarding, server webhooks, payouts on completion; test refund paths.

Ratings & Reviews: transaction-bound reviews + profile aggregates; 1 review per context; admin moderation.

Calendar & Notifications: Chauffeur Google Calendar sync (OAuth); FCM role topics; job/approval/reservation notifications.

10) Non-Functional Requirements

Reliability: All writes idempotent; guard against duplicate bookings/accepts.

Security & Compliance: UK/EU privacy law aligned wording (no waiver of statutory rights).

Performance: Firestore queries indexed; list screens page/limit where needed.

Observability: Add simple print/log() for MVP; plan structured logging in Functions.

11) QA Checklist (MVP)

Auth

Sign up each role; login/logout cycles; admin allowlist verified.

Approvals

With toggles off, non-customer signup hits Pending; admin approves → dashboard access.

Rentals

Self-drive booking writes reservation; chauffeured booking includes chauffeur fields.

Chauffeur

Availability add/delete; inbox accept/decline reflected in Firestore.

Vendor/Admin/Support

Vendor gate appears; admin approve/reject works; support “Take” updates status.

12) Known Stubs / TODOs

Stripe Connect: UI gate in place; webhook + payouts pending.

Support chat: queue present; live conversation minimal (to expand).

Delivery live tracking: placeholder (Phase A).

Vehicles/events: placeholders (Phase B).

Legal copy: needs UK/EU vetted T&Cs/Privacy.

13) Change Control

All changes should include:

CHANGELOG.md: files added/modified, schema changes.

TEST_CHECKLIST.md: steps to validate success criteria.

NOTES.md: assumptions, found issues, required indexes & security updates.
