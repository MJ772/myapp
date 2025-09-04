
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret);

admin.initializeApp();

const webhookSecret = functions.config().stripe.webhook;

exports.createStripeAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated", "The function must be called while authenticated.");
  }

  const uid = context.auth.uid;

  try {
    const account = await stripe.accounts.create({type: "express"});

    await admin.firestore().collection("users").doc(uid).update({
      stripeAccountId: account.id,
    });

    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `https://us-central1-${process.env.GCLOUD_PROJECT}` +
        ".cloudfunctions.net/createStripeAccount",
      return_url: "motorsapp://stripe-redirect?status=success",
      type: "account_onboarding",
    });

    return {accountLinkUrl: accountLink.url};
  } catch (error) {
    console.error("Error creating Stripe account:", error);
    throw new functions.https.HttpsError("internal",
        "An error occurred while creating the Stripe account.");
  }
});

exports.markRepairAsCompleted = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated", "The function must be called while authenticated.");
  }

  const {requestId} = data;

  if (!requestId) {
    throw new functions.https.HttpsError("invalid-argument",
        "The function must be called with a 'requestId'.");
  }

  try {
    await admin.firestore().collection("repair_requests").doc(requestId).update({
      status: "completed",
    });

    return {success: true};
  } catch (error) {
    console.error("Error marking repair as completed:", error);
    throw new functions.https.HttpsError("internal",
        "An error occurred while marking the repair as completed.");
  }
});

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated", "The function must be called while authenticated.");
  }

  const {requestId, bidId} = data;

  if (!requestId || !bidId) {
    throw new functions.https.HttpsError("invalid-argument",
        "The function must be called with a 'requestId' and 'bidId'.");
  }

  try {
    const bidDoc = await admin.firestore().collection("bids").doc(bidId).get();
    const repairRequestDoc = await admin.firestore()
        .collection("repair_requests").doc(requestId).get();

    if (!bidDoc.exists || !repairRequestDoc.exists) {
      throw new functions.https.HttpsError("not-found",
          "Bid or repair request not found.");
    }

    const bid = bidDoc.data();

    const garageStripeAccountId = "acct_1234567890";

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(bid.price * 100),
      currency: "usd",
      application_fee_amount: Math.round(bid.price * 10),
      transfer_data: {
        destination: garageStripeAccountId,
      },
      metadata: {
        requestId: requestId,
      },
    });

    return {clientSecret: paymentIntent.client_secret};
  } catch (error) {
    console.error("Error creating payment intent:", error);
    throw new functions.https.HttpsError("internal",
        "An error occurred while creating the payment intent.");
  }
});

exports.onPaymentSuccess = functions.https.onRequest(async (request, response) => {
  const signature = request.headers["stripe-signature"];

  let event;

  try {
    event = stripe.webhooks.constructEvent(request.rawBody, signature,
        webhookSecret);
  } catch (err) {
    console.error(`Webhook signature verification failed: ${err.message}`);
    response.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    const requestId = paymentIntent.metadata.requestId;

    if (!requestId) {
      console.error("Webhook received for payment_intent.succeeded but no " +
        "requestId was found in metadata.");
      response.status(400).send("No requestId found in metadata.");
      return;
    }

    try {
      await admin.firestore().collection("repair_requests").doc(requestId).update({
        status: "paid",
      });
      console.log(`Successfully updated repair request ${requestId} to 'paid'.`);
    } catch (error) {
      console.error(`Error updating repair request ${requestId} to 'paid':`,
          error);
      response.status(500).send("Internal server error.");
      return;
    }
  }

  response.status(200).send();
});
