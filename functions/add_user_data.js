const admin = require('firebase-admin');

// Initialize Firebase Admin SDK with emulator settings
// The project ID should match the one used by your emulators
admin.initializeApp({
  projectId: 'motorsappdemo1', // **Ensure this matches your project ID**
  // Other emulator settings are usually automatically picked up
  // if you are running this script from within the Firebase project directory
});

const firestore = admin.firestore();

// User UID that is causing the issue - CONFIRM THIS IS CORRECT FROM YOUR DEBUG LOGS
const userId = 'SoZZqsk5zEEwQu4L7ALn7LthIEcm';

// Data for the user document
const userData = {
  role: 'garage',
  createdAt: admin.firestore.FieldValue.serverTimestamp(), // Optional: add a timestamp
  // Add any other necessary user fields here if your app expects them
  // For example: displayName: 'Garage User', photoURL: '...', etc.
};

async function addUserDocument() {
  const userRef = firestore.collection('users').doc(userId);

  try {
    await userRef.set(userData, { merge: true }); // Use set with merge to avoid overwriting other fields if the document partially exists
    console.log(`Successfully added/updated document for user ${userId} in Firestore emulator.`);
  } catch (error) {
    console.error(`Error adding/updating document for user ${userId}:`, error);
  }
}

// Execute the function
addUserDocument();
