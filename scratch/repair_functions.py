
import os

file_path = r'd:\leastprice\functions\index.js'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

bad_part = """      );
      transaction.set(
    }"""

good_part = """      );
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
  });

exports.hybridMarketplaceSearch = functionsV1
  .region('us-central1')
  .runWith({
    timeoutSeconds: 120,
    memory: '1GB',
    maxInstances: 10,
  })
  .https.onRequest(async (request, response) => {
    applyCorsHeaders(request, response);

    if (request.method === 'OPTIONS') {
      response.status(204).send('');
      return;
    }"""

if bad_part in content:
    new_content = content.replace(bad_part, good_part)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Successfully repaired the file!")
else:
    print("Could not find the bad part. Trying fuzzy match...")
    # Try with different line endings or spaces if needed
    import re
    pattern = re.escape(bad_part).replace(r'\ ', r'\s*')
    if re.search(pattern, content):
        new_content = re.sub(pattern, good_part, content)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Successfully repaired the file using fuzzy match!")
    else:
        print("CRITICAL: Could not find the corrupted section even with fuzzy match.")
