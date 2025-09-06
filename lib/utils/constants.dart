// lib/utils/constants.dart
const Set<String> kAdminEmails = {
  'emjadulhoqu3@gmail.com',
  'mandemmotorsltd@gmail.com',
};

const Set<String> kAdminUids = {
  // optional hard lock UID(s)
  // 'your-admin-uid',
};

// DEV toggles (true for MVP, set to false later)
const bool kBypassRoleApprovals = true; // UI bypass of pending screens
const bool kAutoApproveNonCustomer =
    true; // DB auto-approve for garage/chauffeur/courier
