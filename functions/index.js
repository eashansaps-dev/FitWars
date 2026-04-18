const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");

initializeApp();
const db = getFirestore();

const DAILY_XP_CAP = 100;
const TOTAL_DAILY_CAP = 3 * DAILY_XP_CAP; // 300
const STAT_FIELDS = ["strength", "stamina", "speed"];
const MS_IN_24_HOURS = 24 * 60 * 60 * 1000;

/**
 * Cloud Function: validateStatUpdate
 *
 * Triggers on any write to stats/{userId}.
 * Validates that:
 *   - No single stat gained more than DAILY_XP_CAP (100) in 24 hours
 *   - Total XP gain across all stats does not exceed TOTAL_DAILY_CAP (300) in 24 hours
 *
 * On rejection the document is reverted to its previous values and the
 * violation is logged with the userId and attempted values.
 */
exports.validateStatUpdate = onDocumentWritten("stats/{userId}", async (event) => {
  const { userId } = event.params;

  // If the document was deleted there is nothing to validate.
  if (!event.data.after.exists) {
    return null;
  }

  const newData = event.data.after.data();
  const previousData = event.data.before.exists
    ? event.data.before.data()
    : null;

  // Default values for a brand-new document (no previous state).
  const defaults = { strength: 0, stamina: 0, speed: 0, totalXP: 0 };

  const prev = previousData || defaults;

  // Determine whether the previous write happened within the last 24 hours.
  // If the previous lastUpdated is older than 24 h the window has reset and
  // any gain is measured from zero.
  const now = Date.now();
  const prevTimestamp = prev.lastUpdated
    ? prev.lastUpdated.toMillis
      ? prev.lastUpdated.toMillis()
      : new Date(prev.lastUpdated).getTime()
    : 0;

  const withinWindow = now - prevTimestamp < MS_IN_24_HOURS;

  // When outside the 24-hour window we treat the baseline as the new values
  // themselves (delta = 0) so no cap is triggered.
  const baseline = withinWindow ? prev : newData;

  // Calculate per-stat deltas.
  let totalDelta = 0;
  let violated = false;
  const deltas = {};

  for (const field of STAT_FIELDS) {
    const newVal = newData[field] || 0;
    const oldVal = baseline[field] || 0;
    const delta = newVal - oldVal;
    deltas[field] = delta;
    totalDelta += delta;

    if (delta > DAILY_XP_CAP) {
      violated = true;
    }
  }

  // Check total cap.
  if (totalDelta > TOTAL_DAILY_CAP) {
    violated = true;
  }

  if (!violated) {
    return null; // Update is valid — nothing to do.
  }

  // --- Rejection path ---

  logger.warn("Stat validation failed", {
    userId,
    attemptedValues: newData,
    previousValues: prev,
    deltas,
    totalDelta,
  });

  // Revert the document to its previous values.
  const revertData = previousData || defaults;

  // Preserve the previous lastUpdated (or omit for new docs).
  const revertPayload = {};
  for (const field of STAT_FIELDS) {
    revertPayload[field] = revertData[field] || 0;
  }
  revertPayload.totalXP = revertData.totalXP || 0;
  if (revertData.lastUpdated) {
    revertPayload.lastUpdated = revertData.lastUpdated;
  }

  await db.collection("stats").doc(userId).set(revertPayload);

  logger.info("Reverted stat document for user", { userId, revertedTo: revertPayload });

  return null;
});
