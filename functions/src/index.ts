
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const fcm = admin.messaging();

export const onNewBid = functions.firestore
    .document("repairRequests/{requestId}/bids/{bidId}")
    .onCreate(async (snapshot, context) => {
        const bidData = snapshot.data();
        const requestId = context.params.requestId;

        const requestDoc = await db.collection("repairRequests")
            .doc(requestId).get();
        const requestData = requestDoc.data();

        if (requestData) {
            const userId = requestData.userId;
            const userDoc = await db.collection("users").doc(userId).get();
            const userData = userDoc.data();

            if (userData && userData.fcmTokens) {
                const payload: admin.messaging.MessagingPayload = {
                    notification: {
                        title: "You have a new bid!",
                        body: `A garage has placed a bid of $${bidData.price} on ` +
                            "your repair request.",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    data: {
                        screen: "/repairRequestDetails",
                        requestId: requestId,
                    },
                };

                const tokens = userData.fcmTokens;
                await fcm.sendToDevice(tokens, payload);
            }
        }
    });

export const onBidAccepted = functions.firestore
    .document("repairRequests/{requestId}")
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();

        if (beforeData.status !== "in_progress" && 
            afterData.status === "in_progress") {
            const garageId = afterData.garageId;
            const userDoc = await db.collection("users").doc(garageId).get();
            const userData = userDoc.data();

            if (userData && userData.fcmTokens) {
                const payload: admin.messaging.MessagingPayload = {
                    notification: {
                        title: "Your bid was accepted!",
                        body: "Your bid on a repair request has been accepted. " +
                            "You can now begin the repair.",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    data: {
                        screen: "/repairRequestDetails",
                        requestId: context.params.requestId,
                    },
                };

                const tokens = userData.fcmTokens;
                await fcm.sendToDevice(tokens, payload);
            }
        }
    });

export const onNewChatMessage = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        functions.logger.log("onNewChatMessage context:", context);
        const messageData = snapshot.data();
        const recipientId = messageData.recipientId;

        const userDoc = await db.collection("users").doc(recipientId).get();
        const userData = userDoc.data();

        if (userData && userData.fcmTokens) {
            const payload: admin.messaging.MessagingPayload = {
                notification: {
                    title: "You have a new message!",
                    body: messageData.text,
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
                data: {
                    screen: "/chat",
                    repairRequestId: messageData.repairRequestId,
                    recipientId: messageData.senderId,
                },
            };

            const tokens = userData.fcmTokens;
            await fcm.sendToDevice(tokens, payload);
        }
    });
