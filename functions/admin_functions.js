const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * Sets a user as an admin by setting a custom claim.
 * Must be called by an existing admin.
 */
exports.setAdmin = functions.https.onCall(async (data, context) => {
  // 1. Verify the caller is already an admin.
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only an admin can set other admins.",
    );
  }

  // 2. Get user and set custom claim (admin).
  const email = data.email;
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, {admin: true});
    console.log(`Successfully made ${email} an admin.`);
    return {message: `Success! ${email} is now an admin.`};
  } catch (error) {
    console.error("Error setting admin custom claim:", error);
    throw new functions.https.HttpsError("internal", "Error setting admin.");
  }
});

