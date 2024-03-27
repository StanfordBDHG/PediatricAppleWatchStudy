//
// This source file is part of the StudyApplication based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

const {onCall} = require("firebase-functions/v2/https");
const {logger, https} = require("firebase-functions/v2");
const {FieldValue} = require("firebase-admin/firestore");
const admin = require("firebase-admin");
const {beforeUserCreated} = require("firebase-functions/v2/identity");

admin.initializeApp();

exports.checkInvitationCode = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new https.HttpsError(
        "unauthenticated",
        "User is not properly authenticated.",
    );
  }

  const {invitationCode} = request.data;
  const userId = request.auth.uid;
  const firestore = admin.firestore();

  logger.debug(`User (${userId}) -> PAWS, InvitationCode ${invitationCode}`);

  try {
    // Based on https://github.com/StanfordSpezi/SpeziStudyApplication/blob/main/functions/index.js
    const invitationCodeRef = firestore.doc(`invitationCodes/${invitationCode}`);
    const invitationCodeDoc = await invitationCodeRef.get();

    if (!invitationCodeDoc.exists || invitationCodeDoc.data().used) {
      throw new https.HttpsError("not-found", "Invitation code not found or already used.");
    }

    const userStudyRef = firestore.doc(`users/${userId}`);
    const userStudyDoc = await userStudyRef.get();

    if (userStudyDoc.exists) {
      throw new https.HttpsError("already-exists", "User is already enrolled in the study.");
    }

    await firestore.runTransaction(async (transaction) => {
      transaction.set(userStudyRef, {
        invitationCode: invitationCode,
        dateOfEnrollment: FieldValue.serverTimestamp(),
      });

      transaction.update(invitationCodeRef, {
        used: true,
        usedBy: userId,
      });
    });

    logger.debug(`User (${userId}) successfully enrolled in study (PAWS) with invitation code: ${invitationCode}`);

    return {};
  } catch (error) {
    logger.error(`Error processing request: ${error.message}`);
    if (!error.code) {
      throw new https.HttpsError("internal", "Internal server error.");
    }
    throw error;
  }
});

// so the error was coming from here
// still need to assign email address, right
/*
exports.beforecreated = beforeUserCreated(async (event) => {
  const firestore = admin.firestore();

  try {
    // Check Firestore to confirm whether an invitation code has been associated with a user.
    const invitationQuerySnapshot = await firestore.collection("invitationCodes")
        .where("usedBy", "==", event.data.user.uid)
        .limit(1)
        .get();

    if (invitationQuerySnapshot.empty) {
      throw new https.HttpsError("not-found", "No valid invitation code found for this user.");
    }

    // const userDoc = await firestore.doc(`users/${event.data.user.uid}`).get();

    // // Check if the user document exists and contains the correct invitation code.
    // if (!userDoc.exists || userDoc.data()?.invitationCode !== invitationQuerySnapshot.docs[0]?.data().invitationCode) {
    //   throw new https.HttpsError("failed-precondition", "User document does not exist or contains incorrect invitation code.");
    // }
  } catch (error) {
    logger.error(`Error processing request: ${error.message}`);
    if (!error.code) {
      throw new https.HttpsError("internal", "Internal server error.");
    }
    throw error;
  }
});
*/
// what the user enters the code but then closes the app before signing up?
// hopefully that doesn't happen, but they could contact us and we'll just generate a new code
