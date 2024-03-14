/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { logger } = require("firebase-functions");
const { functions, auth } = require("firebase-functions");
const { onRequest, onCall} = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

// The Firebase Admin SDK to access Firestore.
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");

//params
const { defineString, defineSecret } = require('firebase-functions/params');
//const projectId = defineString("projectId");
//const storageBucket = defineString("storageBucket");
const geminiApiKey = defineSecret("geminiApiKey");



const admin = initializeApp();
const _firestore = getFirestore();
const _storage = getStorage();

// if( process.env.test ){
//     connectFirestoreEmulator(_firestore, '127.0.0.1', 8080);
//     connectStorageEmulator(_storage, "127.0.0.1", 9199);
//     connectFunctionsEmulator(_storage, "127.0.0.1", 5001);
// }
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


exports.health = onCall({
    enforceAppCheck: false, // Reject requests with missing or invalid App Check tokens.
},(request) => {
    logger.debug("Health Check Called");
    return "ok";
});

/**
 * User Clean Up if user is deleted
 */
exports.onUserDeleted = auth.user().onDelete(async (user) => {
    let firestore = _firestore();
    //delete user
    let userRef = firestore.doc('users/' + user.uid);
    await firestore.collection("users").doc(user.uid).delete();
    // delete users log
    let logRef = firestore.doc('food_logs/' + user.uid);
    await firestore.collection("food_logs").doc(user.uid).delete();
});

exports.onUserCreated = auth.user().onCreate(async (user) => {
    let firestore = _firestore();
    //delete user
    const doc = await firestore.collection("users").add(user.uid);
    await doc.add({
        'date_created': new Date()
    });
    // delete users log
    const foodDoc = await firestore.collection("food_logs").add(user.uid);
    foodDoc.add({
        'date_created': new Date()
    });
});




const foodTriggers = require("./triggers/foodImageTriggers.js");
foodTriggers.init(_firestore, _storage)
exports.onFoodActivityCreateHandler = foodTriggers.onFoodActivityCreateHandler;


const dexcomEndpoints = require("./endpoints/dexcom.js");
dexcomEndpoints.init(_firestore)
exports.getDexcomToken = dexcomEndpoints.getDexcomToken;
exports.getDexcomReadings = dexcomEndpoints.getDexcomReadings;

