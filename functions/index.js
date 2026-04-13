const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');

if (!admin.apps.length) {
  admin.initializeApp();
}

setGlobalOptions({
  region: 'us-central1',
  maxInstances: 10,
});

const db = admin.firestore();
const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;
const increment = admin.firestore.FieldValue.increment;

exports.applyReferralRewardOnUserCreate = onDocumentCreated(
  {
    document: 'users/{userId}',
    retry: true,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn('User create trigger fired without snapshot payload.');
      return;
    }

    const userRef = snapshot.ref;

    await db.runTransaction(async (transaction) => {
      const freshUserSnapshot = await transaction.get(userRef);
      if (!freshUserSnapshot.exists) {
        logger.warn('User document no longer exists before referral processing.', {
          userId: userRef.id,
        });
        return;
      }

      const userData = freshUserSnapshot.data() || {};
      const referralRewardApplied = userData.referralRewardApplied === true;
      if (referralRewardApplied) {
        logger.info('Referral reward already applied, skipping duplicate work.', {
          userId: userRef.id,
        });
        return;
      }

      const invitedBy = String(userData.invitedBy || '').trim().toUpperCase();
      if (!invitedBy) {
        transaction.set(
          userRef,
          {
            referralStatus: 'no_invite_code',
            referralProcessedAt: serverTimestamp(),
          },
          { merge: true },
        );
        return;
      }

      const referrerQuery = db
        .collection('users')
        .where('referralCode', '==', invitedBy)
        .limit(1);
      const referrerQuerySnapshot = await transaction.get(referrerQuery);
      if (referrerQuerySnapshot.empty) {
        transaction.set(
          userRef,
          {
            referralStatus: 'referrer_not_found',
            referralProcessedAt: serverTimestamp(),
          },
          { merge: true },
        );
        logger.warn('Invite code did not match any referrer.', {
          userId: userRef.id,
          invitedBy,
        });
        return;
      }

      const referrerSnapshot = referrerQuerySnapshot.docs[0];
      if (referrerSnapshot.id === userRef.id) {
        transaction.set(
          userRef,
          {
            invitedBy: '',
            referralStatus: 'self_referral_blocked',
            referralProcessedAt: serverTimestamp(),
          },
          { merge: true },
        );
        logger.warn('Blocked self-referral attempt.', {
          userId: userRef.id,
        });
        return;
      }

      transaction.set(
        referrerSnapshot.ref,
        {
          invitedCount: increment(1),
          updatedAt: serverTimestamp(),
        },
        { merge: true },
      );
      transaction.set(
        userRef,
        {
          referralRewardApplied: true,
          referralStatus: 'reward_applied',
          referralProcessedAt: serverTimestamp(),
          referrerUserId: referrerSnapshot.id,
        },
        { merge: true },
      );

      logger.info('Referral reward applied successfully.', {
        userId: userRef.id,
        referrerUserId: referrerSnapshot.id,
        invitedBy,
      });
    });
  },
);
