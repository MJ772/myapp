const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {initializeApp} = require("firebase-admin/app");

// Initialize Firebase Admin SDK
initializeApp();

// Removed the global Stripe initialization here.
// The Stripe object will now be initialized inside each function.


// Define acceptBidAndProcessPayment function
const acceptBidAndProcessPaymentFunction = functions.https.onCall(
    async (data, context) => {
      // Validate authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Only authenticated users can accept bids",
        );
      }

      const {bidId, requestId, paymentMethodId} = data;

      // Basic validation
      if (!bidId || !requestId || !paymentMethodId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with \"bidId\", " +
            "\"requestId\", and \"paymentMethodId\".",
        );
      }

      try {
        // Initialize Stripe inside the function where it's needed
        const stripe = require("stripe")(functions.config().stripe.secret);

        const db = admin.firestore();
        const batch = db.batch();

        // Retrieve bid document
        const bidRef = db.collection("bids").doc(bidId);
        const bidDoc = await bidRef.get();

        if (!bidDoc.exists) {
          throw new functions.https.HttpsError(
              "not-found",
              `Bid with ID ${bidId} not found.`,
          );
        }

        const bidData = bidDoc.data();

        // Retrieve repair request document
        const requestRef = db.collection("repair_requests").doc(requestId);
        const requestDoc = await requestRef.get();

        if (!requestDoc.exists) {
          throw new functions.https.HttpsError(
              "not-found",
              `Repair request with ID ${requestId} not found.`,
          );
        }

        const requestData = requestDoc.data();
        const customerId = requestData.userId;
        const garageId = bidData.garageId;

        // Calculate amounts
        const bidPrice = bidData.price;
        const depositAmountCents = Math.round(bidPrice * 100 * 0.10); // 10% deposit
        const commissionPercentage = 0.05; // 5% platform commission
        const applicationFeeAmountCents = Math.round(
          depositAmountCents * commissionPercentage,
        );

        // Retrieve garage's Stripe account
        const garageUserDoc = await db.collection("users").doc(garageId).get();
        if (!garageUserDoc.exists) {
          throw new functions.https.HttpsError(
              "not-found",
              `Garage user with ID ${garageId} not found.`,
          );
        }

        const garageUserData = garageUserDoc.data();
        const connectedAccountId = garageUserData.stripeConnectedAccountId;

        if (!connectedAccountId) {
          throw new functions.https.HttpsError(
              "failed-precondition",
              `Stripe account ID not found for garage ${garageId}.`,
          );
        }

        // Create Payment Intent
        const paymentIntent = await stripe.paymentIntents.create({
          amount: depositAmountCents,
          currency: "usd",
          payment_method: paymentMethodId,
          confirm: true,
          customer: customerId,
          transfer_data: {
            destination: connectedAccountId,
            amount: depositAmountCents - applicationFeeAmountCents,
          },
          application_fee_amount: applicationFeeAmountCents,
          description: `Deposit for repair request ${requestId}`,
          metadata: {
            requestId,
            bidId,
            customerId,
            garageId,
            type: "deposit",
          },
        });

        // Update documents
        batch.update(bidRef, {
          status: "accepted",
          paymentIntentId: paymentIntent.id,
          depositAmount: depositAmountCents / 100,
          depositPaidAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        batch.update(requestRef, {
          status: "deposit_paid",
          acceptedBidId: bidId,
          acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await batch.commit();

        return {
          success: true,
          message: "Bid accepted and payment processed",
          paymentIntent: {
            id: paymentIntent.id,
            amount: paymentIntent.amount,
            status: paymentIntent.status,
          },
        };
      } catch (error) {
        console.error("Error accepting bid:", error);

        // Handle Stripe errors
        if (error.type === "StripeCardError") {
          throw new functions.https.HttpsError(
              "failed-precondition",
              error.message,
          );
        } else if (error.type) {
          throw new functions.https.HttpsError(
              "internal",
              `Stripe error: ${error.message}`,
          );
        }

        throw new functions.https.HttpsError(
            "internal",
            "Payment processing failed",
            error.message,
        );
      }
    },
);

// Define initiateStripeConnectOnboarding function
const initiateStripeConnectOnboardingFunction = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Authentication required",
        );
      }

      const userId = context.auth.uid;

      try {
        console.log(`[initiateStripeConnectOnboarding] Function started for user: ${userId}`);

        // Initialize Stripe inside the function where it's needed
        const stripe = require("stripe")(functions.config().stripe.secret);

        const db = admin.firestore();

        // Check user role
        const userDoc = await db.collection("users").doc(userId).get();
        const userData = userDoc.data();
        console.log(`[initiateStripeConnectOnboarding] Fetched user data. Role: ${userData?.role}`);

        if (!userDoc.exists || userData.role !== "garage") {
          throw new functions.https.HttpsError(
              "permission-denied",
              "Only garages can onboard",
          );
        }

        if (userData.stripeConnectedAccountId) {
          return {
            success: false,
            message: "Stripe account already connected",
          };
        }

        console.log(`[initiateStripeConnectOnboarding] Starting Stripe account creation/retrieval logic.`);

        // Account creation logic
        let accountId = userData.tempStripeAccountId;
        if (accountId) {
          try {
            // Use the initialized 'stripe' object
            await stripe.accounts.retrieve(accountId);
            console.log(`[initiateStripeConnectOnboarding] Retrieved existing Stripe account: ${accountId}`);
          } catch (e) {
            console.log("Creating new Stripe account");
            // Use the initialized 'stripe' object
            const account = await stripe.accounts.create({type: "express"});
            accountId = account.id;
            await db.collection("users").doc(userId).update({
              tempStripeAccountId: accountId,
            });
          }
        } else {
          // Use the initialized 'stripe' object
          const account = await stripe.accounts.create({type: "express"});
          accountId = account.id;
          console.log(`[initiateStripeConnectOnboarding] Created new Stripe account: ${accountId}`);
          await db.collection("users").doc(userId).update({
            tempStripeAccountId: accountId,
          });
        }

        console.log(`[initiateStripeConnectOnboarding] Creating Stripe account link for account: ${accountId}`);
        // Create onboarding link using the initialized stripe object
        const accountLink = await stripe.accountLinks.create({
          account: accountId,
          refresh_url: "MotorsApp://stripe-connect-redirect?status=refresh",
          return_url: "MotorsApp://stripe-connect-redirect?status=success",
          type: "account_onboarding",
          collect: "eventually_due",
        });

        return {
          success: true,
          url: accountLink.url,
          accountId,
        };
      } catch (error) {
        console.log(`[initiateStripeConnectOnboarding] Error caught in try block.`);
        console.error("Onboarding error:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Onboarding failed",
            error.message,
        );
      }
    },
);

// Export the functions
exports.acceptBidAndProcessPayment = acceptBidAndProcessPaymentFunction;
exports.initiateStripeConnectOnboarding = initiateStripeConnectOnboardingFunction;
