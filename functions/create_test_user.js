const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'motorsappdemo1'
});

const db = admin.firestore();

async function createTestUser() {
  try {
    // Create a test user document with garage role
    const userData = {
      email: 'testacc1@gmail.com',
      role: 'garage',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      displayName: 'Test Garage User'
    };

    // Add to users collection
    const userRef = await db.collection('users').add(userData);
    
    console.log(`Created test garage user with ID: ${userRef.id}`);
    console.log('User data:', userData);
    
    // Also create a user in Firebase Auth
    const authUser = await admin.auth().createUser({
      email: 'testacc1@gmail.com',
      password: 'testacc1',
      displayName: 'Test Garage User'
    });
    
    console.log(`Created Auth user with UID: ${authUser.uid}`);
    
    // Update the Firestore doc with the Auth UID
    await db.collection('users').doc(authUser.uid).set(userData);
    console.log(`Updated Firestore doc with Auth UID: ${authUser.uid}`);
    
  } catch (error) {
    console.error('Error creating test user:', error);
  }
}

createTestUser();
