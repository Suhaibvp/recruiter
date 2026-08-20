import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

export const onMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

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
      
      const chatData = chatDoc.data()!;
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
             jobTitle = jobDoc.data()?.roleName || "Job";
           }
         } catch(e) { }
      }

      if (isSenderRecruiter) {
        const recruiterDoc = await db.collection("recruiters").doc(senderId).get();
        if (recruiterDoc.exists) {
          senderName = recruiterDoc.data()?.fullName || "Recruiter";
          senderImageUrl = recruiterDoc.data()?.photoUrl || defaultIcon;
        }
      } else {
        const candidateDoc = await db.collection("candidates").doc(senderId).get();
        if (candidateDoc.exists) {
          senderName = candidateDoc.data()?.firstName 
            ? `${candidateDoc.data()?.firstName} ${candidateDoc.data()?.lastName}`.trim()
            : "Candidate";
          senderImageUrl = candidateDoc.data()?.photoUrl || defaultIcon;
        }
      }

      // 3. Get recipient FCM Token
      let fcmToken = null;
      if (isSenderRecruiter) {
        // Recipient is candidate
        const candidateDoc = await db.collection("candidates").doc(recipientId).get();
        fcmToken = candidateDoc.data()?.fcmToken;
      } else {
        // Recipient is recruiter
        const recruiterDoc = await db.collection("recruiters").doc(recipientId).get();
        fcmToken = recruiterDoc.data()?.fcmToken;
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
      } else {
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

    } catch (error) {
      console.error("Error processing notification:", error);
    }

    return null;
  });
