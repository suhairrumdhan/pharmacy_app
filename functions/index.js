const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onNotificationCreated = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notification = snapshot.data();
    const userId = event.params.userId;

    try {
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

      const userData = userDoc.data();
      const token = userData?.fcmToken;

      if (!token) {
        console.log("No token for user:", userId);
        return;
      }

      const message = {
        token,
        notification: {
          title: notification.title,
          body: notification.message,
        },
        data: {
          type: notification.type || "general",
          orderId: notification.orderId || "",
        },
      };

      await admin.messaging().send(message);

      console.log("✅ Push sent for user:", userId);
    } catch (error) {
      console.error("❌ Push failed:", error);
    }
  }
);