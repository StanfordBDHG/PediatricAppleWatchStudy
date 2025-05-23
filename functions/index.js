//
// This source file is part of the StudyApplication based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { logger, https } from "firebase-functions/v2";
import { beforeUserCreated } from "firebase-functions/v2/identity";

admin.initializeApp();

export const checkInvitationCode = https.onCall(
  {
    invoker: "public",
    serviceAccount: `cloudfunctionsserviceaccount@${process.env.GCLOUD_PROJECT}.iam.gserviceaccount.com`,
  },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError(
        "unauthenticated",
        "The function must be called with a valid authenticated request.",
      );
    }

    const invitationCode = request.data.invitationCode;
    const userId = request.auth.uid;

    const firestore = admin.firestore();
    logger.debug(`User (${userId}) -> PAWS, InvitationCode ${invitationCode}`);

    try {
      // Based on https://github.com/StanfordSpezi/SpeziStudyApplication/blob/main/functions/index.js'
      const invitationCodeRef = firestore.doc(
        `invitationCodes/${invitationCode}`,
      );
      const invitationCodeDoc = await invitationCodeRef.get();

      if (!invitationCodeDoc.exists || invitationCodeDoc.data().used) {
        throw new https.HttpsError(
          "not-found",
          "Invitation code not found or already used.",
        );
      }

      const userStudyRef = firestore.doc(`users/${userId}`);
      const userStudyDoc = await userStudyRef.get();

      if (userStudyDoc.exists) {
        throw new https.HttpsError(
          "already-exists",
          "User is already enrolled in the study.",
        );
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

      logger.debug(
        `User (${userId}) successfully enrolled in the PAWS study with invitation code: ${invitationCode}`,
      );

      return {};
    } catch (error) {
      logger.error(`Error processing request: ${error.message}`);
      if (!error.code) {
        throw new https.HttpsError("internal", "Internal server error.");
      }
      throw error;
    }
  },
);

export const beforecreated = beforeUserCreated(
  {
    serviceAccount: `cloudfunctionsserviceaccount@${process.env.GCLOUD_PROJECT}.iam.gserviceaccount.com`,
  },
  async (event) => {
    const firestore = admin.firestore();
    const userId = event.data.uid;

    try {
      // Check Firestore to confirm whether an invitation code has been associated with a user.
      const invitationQuerySnapshot = await firestore
        .collection("invitationCodes")
        .where("usedBy", "==", userId)
        .limit(1)
        .get();

      logger.info(
        `Invitation code query snapshot: ${invitationQuerySnapshot.size}`,
      );

      if (invitationQuerySnapshot.empty) {
        throw new https.HttpsError(
          "not-found",
          `No valid invitation code found for user ${userId}.`,
        );
      }

      const userDoc = await firestore.doc(`users/${userId}`).get();

      // Check if the user document exists and contains the correct invitation code.
      if (
        !userDoc.exists ||
        userDoc.data().invitationCode !== invitationQuerySnapshot.docs[0].id
      ) {
        throw new https.HttpsError(
          "failed-precondition",
          "User document does not exist or contains incorrect invitation code.",
        );
      }

      logger.info("User Creation Permitted");
    } catch (error) {
      logger.error(`Error processing request: ${error.message}`);
      if (!error.code) {
        throw new https.HttpsError("internal", "Internal server error.");
      }
      throw error;
    }
  },
);
