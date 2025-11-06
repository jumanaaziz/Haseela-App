const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

// Configure region and concurrency as desired
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

if (!admin.apps.length) {
  admin.initializeApp();
}

// Trigger on task updates
exports.sendOnTaskApproval = onDocumentUpdated(
  'Parents/{parentId}/Children/{childId}/Tasks/{taskId}',
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    const prevStatus = String(before.status || '').toLowerCase();
    const newStatus = String(after.status || '').toLowerCase();

    // Only act when transitioning from 'pending' to 'done'
    // This ensures we only notify when parent approves a pending task
    const isPendingToDone = prevStatus === 'pending' && newStatus === 'done';
    
    if (!isPendingToDone) {
      console.log(`Skipping: status changed from '${prevStatus}' to '${newStatus}' (only notify on pending->done)`);
      return;
    }

    console.log(`✅ Task approved: transitioning from '${prevStatus}' to '${newStatus}'`);

    const { parentId, childId } = event.params;

    try {
      // Fetch child's FCM tokens
      const childRef = admin
        .firestore()
        .collection('Parents')
        .doc(parentId)
        .collection('Children')
        .doc(childId);

      const childSnap = await childRef.get();
      if (!childSnap.exists) {
        console.log(`❌ Child document not found: Parents/${parentId}/Children/${childId}`);
        return;
      }

      const childData = childSnap.data() || {};
      const tokens = Array.isArray(childData.fcmTokens)
        ? childData.fcmTokens.filter(Boolean)
        : [];

      console.log(`📱 Found ${tokens.length} FCM token(s) for child ${childId}`);

      const taskName = after.taskName || 'Your task';
      const allowance = typeof after.allowance === 'number' ? after.allowance : null;

      const title = 'Task approved! 🎉';
      const body = allowance != null
        ? `${taskName} approved • +${Math.round(allowance)} ﷼`
        : `${taskName} was approved`;

      const message = {
        notification: { title, body },
        data: {
          parentId,
          childId,
          taskId: event.params.taskId,
          status: newStatus,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              contentAvailable: true,
            },
          },
        },
      };

      if (tokens.length > 0) {
        // Send push to available tokens
        const response = await admin.messaging().sendEachForMulticast({
          tokens,
          ...message,
        });

        // Clean up invalid tokens
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const code = resp.error && resp.error.code ? resp.error.code : '';
            if (
              code.includes('messaging/invalid-registration-token') ||
              code.includes('messaging/registration-token-not-registered')
            ) {
              invalidTokens.push(tokens[idx]);
            }
          }
        });

        if (invalidTokens.length > 0) {
          await childRef.update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
          });
          console.log(`🧹 Cleaned up ${invalidTokens.length} invalid token(s)`);
        }

        console.log(`✅ Push notification sent successfully to ${response.successCount} device(s)`);
      } else {
        console.log(`⚠️ No FCM tokens found for child ${childId} - notification stored but not sent`);
      }

      // Store notification document under Parents/{parentId}/Children/{childId}/notifications
      const notificationDoc = {
        title,
        body,
        taskId: event.params.taskId,
        parentId,
        status: newStatus,
        type: 'task_approved',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      };

      const parentChildRef = admin
        .firestore()
        .collection('Parents')
        .doc(parentId)
        .collection('Children')
        .doc(childId)
        .collection('notifications');

      await parentChildRef.add(notificationDoc);
      console.log(`💾 Notification document stored in Parents/${parentId}/Children/${childId}/notifications`);
    } catch (err) {
      console.error('❌ sendOnTaskApproval error:', err);
    }
  }
);


