"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onMessageCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
exports.onMessageCreated = (0, firestore_1.onDocumentCreated)("chats/{chatId}/messages/{messageId}", async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    const snap = event.data;
    if (!snap)
        return;
    const defaultIcon = "https://cdn-icons-png.flaticon.com/512/149/149071.png";
    const newMessage = snap.data();
    const chatId = event.params.chatId;
    const senderId = newMessage.senderId;
    // content might be encrypted, but could be useful if decrypted later. Ignoring for now.
    // const content = newMessage.content;
    try {
        // 1. Get Chat details to find the recipient
        const chatDoc = await db.collection("chats").doc(chatId).get();
        if (!chatDoc.exists) {
            console.log("Chat document not found:", chatId);
            return null;
        }
        const chatData = chatDoc.data();
        // Assuming chat string stores both UIDs or has candidateId and recruiterId
        const candidateId = chatData.candidateId;
        const recruiterId = chatData.recruiterId;
        if (!candidateId || !recruiterId) {
            console.log("Missing participant IDs in chat");
            return null;
        }
        const isSenderRecruiter = senderId === recruiterId;
        const recipientId = isSenderRecruiter ? candidateId : recruiterId;
        // 2. Get sender profile for name and image
        let senderName = "User";
        let senderImageUrl = defaultIcon;
        let jobTitle = "Job";
        if (chatData.jobId) {
            try {
                const jobDoc = await db.collection("jobs").doc(chatData.jobId).get();
                if (jobDoc.exists) {
                    jobTitle = ((_a = jobDoc.data()) === null || _a === void 0 ? void 0 : _a.roleName) || "Job";
                }
            }
            catch (e) { }
        }
        if (isSenderRecruiter) {
            const recruiterDoc = await db.collection("recruiters").doc(senderId).get();
            if (recruiterDoc.exists) {
                senderName = ((_b = recruiterDoc.data()) === null || _b === void 0 ? void 0 : _b.fullName) || "Recruiter";
                senderImageUrl = ((_c = recruiterDoc.data()) === null || _c === void 0 ? void 0 : _c.photoUrl) || defaultIcon;
            }
        }
        else {
            const candidateDoc = await db.collection("candidates").doc(senderId).get();
            if (candidateDoc.exists) {
                senderName = ((_d = candidateDoc.data()) === null || _d === void 0 ? void 0 : _d.firstName)
                    ? `${(_e = candidateDoc.data()) === null || _e === void 0 ? void 0 : _e.firstName} ${(_f = candidateDoc.data()) === null || _f === void 0 ? void 0 : _f.lastName}`.trim()
                    : "Candidate";
                senderImageUrl = ((_g = candidateDoc.data()) === null || _g === void 0 ? void 0 : _g.photoUrl) || defaultIcon;
            }
        }
        // 3. Get recipient FCM Token
        let fcmToken = null;
        if (isSenderRecruiter) {
            // Recipient is candidate
            const candidateDoc = await db.collection("candidates").doc(recipientId).get();
            fcmToken = (_h = candidateDoc.data()) === null || _h === void 0 ? void 0 : _h.fcmToken;
        }
        else {
            // Recipient is recruiter
            const recruiterDoc = await db.collection("recruiters").doc(recipientId).get();
            fcmToken = (_j = recruiterDoc.data()) === null || _j === void 0 ? void 0 : _j.fcmToken;
        }
        // 4. Also write to notification_recruter / notification_candidate if needed
        // (The Flutter app is already listening to these collections)
        if (isSenderRecruiter) {
            // Create for candidate
            await db.collection("notification_candidate").add({
                userId: recipientId,
                type: 'message',
                title: `New Message from ${senderName}`,
                content: 'You have received a new message.',
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                payloadId: chatId,
                jobId: chatData.jobId,
                candidateId: candidateId,
                recruiterId: recruiterId,
            });
        }
        else {
            // Create for recruiter
            await db.collection("notification_recruter").add({
                recruiterId: recipientId,
                type: 'message',
                title: `New Message from ${senderName}`,
                content: 'You have received a new message.',
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                payloadId: chatId,
                jobId: chatData.jobId,
                candidateId: candidateId,
                candidateName: senderName,
                candidateImageUrl: senderImageUrl,
                jobTitle: jobTitle
            });
        }
        if (!fcmToken) {
            console.log(`No FCM token found for user ${recipientId}`);
            return null;
        }
        // 5. Send FCM Push Notification
        const payload = {
            notification: {
                title: `New Message from ${senderName}`,
                body: 'You have received a new message.',
                image: senderImageUrl,
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "chat",
                chatId: chatId,
                senderName: senderName,
                otherUserId: senderId,
            },
            token: fcmToken,
        };
        await admin.messaging().send(payload);
        console.log(`Successfully sent notification to ${recipientId}`);
    }
    catch (error) {
        console.error("Error processing notification:", error);
    }
    return null;
});
//# sourceMappingURL=index.js.map