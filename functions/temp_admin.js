
const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * A temporary, callable function to grant the 'admin' custom claim
 * to a specific, hardcoded user email. This is for initial setup ONLY.
 *
 * **SECURITY WARNING:** This function should be deleted immediately after use.
 */
const makeFirstAdmin = functions.https.onCall(async (data, context) => {
  const targetEmail = "emjadulhoqu3@gmail.com";

  try {
    const userRecord = await admin.auth().getUserByEmail(targetEmail);
    const userUid = userRecord.uid;

    const listUsersResult = await admin.auth().listUsers(1000);
    const adminExists = listUsersResult.users.some(
        (user) => !!user.customClaims && !!user.customClaims.admin,
    );

    if (adminExists) {
      console.log(`Admin user already exists. Cannot make ${targetEmail} an admin.`);
      throw new functions.https.HttpsError("already-exists",
          "An admin user has already been configured.");
    }

    await admin.auth().setCustomUserClaims(userUid, {admin: true});

    console.log(`Successfully set admin claim on user ${targetEmail} ` +
    `(UID: ${userUid})`);

    return {
      status: "success",
      message: `Admin role has been successfully assigned to ${targetEmail}.`,
    };
  } catch (error) {
    console.error(`Error in makeFirstAdmin function: ${error.message}`);
    if (error.code === "auth/user-not-found") {
      throw new functions.https.HttpsError("not-found",
          `The user with email ${targetEmail} was not found. ` +
          "Please sign up with this email first.");
    }
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal",
        "An internal error occurred while setting the admin claim.");
  }
});

module.exports = {
  makeFirstAdmin,
};
