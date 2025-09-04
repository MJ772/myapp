const admin = require("firebase-admin");

admin.initializeApp({
  projectId: "motorsappdemo1",
});

const firestore = admin.firestore();

const userId = "SoZZqsk5zEEwQu4L7ALn7LthIEcm";

const userData = {
  role: "garage",
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
};

/**
 * Adds or updates a user document in Firestore
 * @return {Promise<void>} A promise that resolves when the operation is complete
 */
async function addUserDocument() {
  const userRef = firestore.collection("users").doc(userId);

  try {
    await userRef.set(userData, {merge: true});
    console.log(`Successfully added/updated document for user ${userId} ` +
    "in Firestore emulator.");
  } catch (error) {
    console.error(`Error adding/updating document for user ${userId}:`, error);
  }
}

addUserDocument();

