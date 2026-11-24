// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SplitSure';

  @override
  String get tagline => 'Protect your music.\nPromote your sound.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get signIn => 'Sign In';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get onboarding1Title => 'Protect Your Collaboration';

  @override
  String get onboarding1TitleAccent => 'Protect';

  @override
  String get onboarding1Subtitle =>
      'Create secure agreements: define collaboration terms, ownership percentages and each contributor\'s responsibilities.';

  @override
  String get onboarding2Title => 'Promote Your Music';

  @override
  String get onboarding2TitleAccent => 'Promote';

  @override
  String get onboarding2Subtitle =>
      'Create promotional videos, captions and content for your releases, ready to share on TikTok, Instagram, Facebook and YouTube.';

  @override
  String get onboarding3Title => 'Manage Your Projects';

  @override
  String get onboarding3TitleAccent => 'Manage';

  @override
  String get onboarding3Subtitle =>
      'Keep all your collaborations and music projects organised in one place.';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get username => 'Username (optional)';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get country => 'Country';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get register => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Sign In';

  @override
  String get termsAccept =>
      'I agree to the Terms of Service and Privacy Policy';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get mustAcceptTerms => 'You must accept the terms to continue';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get myProjects => 'My Projects';

  @override
  String get protect => 'Protect';

  @override
  String get reach => 'Reach';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Settings';

  @override
  String get welcome => 'Welcome back';

  @override
  String get createProject => 'Create Music Project';

  @override
  String get recentProjects => 'Recent Projects';

  @override
  String get pendingAgreements => 'Pending Agreements';

  @override
  String get subscriptionStatus => 'Subscription';

  @override
  String get freePlan => 'Basic Plan';

  @override
  String get monthlyPlan => 'Monthly Plan';

  @override
  String get quarterlyPlan => '3-Month Plan';

  @override
  String get annualPlan => 'Annual Plan';

  @override
  String get logout => 'Log Out';

  @override
  String get profile => 'Profile';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get changePassword => 'Change Password';

  @override
  String get notificationPreferences => 'Notification Preferences';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get selectLanguage => 'Select your language';

  @override
  String get navHome => 'Home';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get onboarding1TitleRest => ' Your\nCollaboration';

  @override
  String get onboarding2TitleRest => ' Your\nMusic';

  @override
  String get onboarding3TitleRest => ' Your\nProjects';

  @override
  String get chooseLanguageBilingual =>
      'Choose your language / Choisissez votre langue';

  @override
  String get welcomeFooter =>
      'Join a growing community of artists and creators';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordSubtitle =>
      'Enter your email and we will send you a reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetEmailSent => 'Password reset email sent! Check your inbox.';

  @override
  String get cancel => 'Cancel';

  @override
  String errorWithDetails(String details) {
    return 'Error: $details';
  }

  @override
  String get accountCreatedCheckEmail =>
      'Account created! Please check your email to confirm.';

  @override
  String get countryCameroon => 'Cameroon';

  @override
  String get countryNigeria => 'Nigeria';

  @override
  String get countryGhana => 'Ghana';

  @override
  String get countrySouthAfrica => 'South Africa';

  @override
  String get countryKenya => 'Kenya';

  @override
  String get countryFrance => 'France';

  @override
  String get countryUnitedStates => 'United States';

  @override
  String get countryUnitedKingdom => 'United Kingdom';

  @override
  String get countryOther => 'Other';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPending => 'Pending acceptance';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusChangesRequested => 'Changes requested';

  @override
  String get statusDeclined => 'Declined';

  @override
  String get statusContentGenerated => 'Content generated';

  @override
  String get statusReadyToShare => 'Ready to share';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get roleArtist => 'Artist';

  @override
  String get roleProducer => 'Producer';

  @override
  String get roleSongwriter => 'Songwriter';

  @override
  String get roleBeatmaker => 'Beatmaker';

  @override
  String get roleFeaturedArtist => 'Featured artist';

  @override
  String get roleComposer => 'Composer';

  @override
  String get roleSoundEngineer => 'Sound engineer';

  @override
  String get roleMusicManager => 'Music manager';

  @override
  String get roleOther => 'Other';

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithComma(String greeting) {
    return '$greeting,';
  }

  @override
  String get defaultArtistName => 'Artist';

  @override
  String get agreementsLabel => 'Agreements';

  @override
  String get campaignsLabel => 'Campaigns';

  @override
  String agreementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agreements',
      one: '1 agreement',
      zero: 'No agreements',
    );
    return '$_temp0';
  }

  @override
  String campaignCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campaigns',
      one: '1 campaign',
      zero: 'No campaigns',
    );
    return '$_temp0';
  }

  @override
  String get modules => 'Modules';

  @override
  String get protectModuleTitle => 'SplitSure Protect';

  @override
  String get protectModuleSubtitle =>
      'Secure your collaborations with split agreements.';

  @override
  String get reachModuleTitle => 'SplitSure Reach';

  @override
  String get reachModuleSubtitle =>
      'Create promotional content for your releases.';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String activityAgreement(String status) {
    return 'Agreement · $status';
  }

  @override
  String activityCampaign(String status) {
    return 'Campaign · $status';
  }

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get newAgreement => 'New Agreement';

  @override
  String get newCampaign => 'New Campaign';

  @override
  String get fullAccessActive => 'Full access active';

  @override
  String get upgradeForFullAccess => 'Upgrade to unlock all features';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get active => 'Active';

  @override
  String get collaborationAgreements => 'Collaboration agreements';

  @override
  String get newShort => 'New';

  @override
  String get filterAll => 'All';

  @override
  String get noAgreementsYet => 'No agreements yet';

  @override
  String get noAgreementsHint =>
      'Protect your music collaborations by creating split agreements.';

  @override
  String get splitsMustTotal100 => 'Split percentages must total 100%';

  @override
  String get createAgreement => 'Create Agreement';

  @override
  String get songInformation => 'Song Information';

  @override
  String stepOf3(String step) {
    return 'Step $step of 3';
  }

  @override
  String get step3Optional => 'Step 3 of 3 (Optional)';

  @override
  String get songTitleRequired => 'Song Title *';

  @override
  String get fieldRequired => 'Required';

  @override
  String get musicGenre => 'Music Genre';

  @override
  String get musicGenreHint => 'e.g. Afrobeats, Hip-Hop';

  @override
  String get songDescription => 'Song Description';

  @override
  String get scopeOfRights => 'Scope of Rights';

  @override
  String get scopeOfRightsHint =>
      'e.g. Master recording, composition, lyrics...';

  @override
  String get additionalTermsOptional => 'Additional Terms (optional)';

  @override
  String get recordingDate => 'Recording Date';

  @override
  String get expectedReleaseDate => 'Expected Release Date';

  @override
  String get effectiveDate => 'Effective Date';

  @override
  String get uploadCoverArtOptional => 'Upload Cover Art (optional)';

  @override
  String get legalInfoNotice =>
      'This agreement is for informational purposes. Obtain independent legal advice for binding contracts.';

  @override
  String get collaboratorsAndSplits => 'Collaborators & Splits';

  @override
  String get collaborators => 'Collaborators';

  @override
  String splitTotalRemaining(String total, String remaining) {
    return 'Total: $total% · Remaining: $remaining%';
  }

  @override
  String get addCollaborator => 'Add Collaborator';

  @override
  String get noCollaboratorsHint =>
      'You can create the agreement without collaborators and add them later.';

  @override
  String get witnessLegalRep => 'Witness / Legal Representative';

  @override
  String get addWitness => 'Add Witness';

  @override
  String get addWitnessSubtitle =>
      'Optional — a person who witnesses the agreement';

  @override
  String get addLegalRep => 'Add Legal Representative';

  @override
  String get addLegalRepSubtitle => 'Optional — a lawyer or legal advisor';

  @override
  String get witnessLawyerDisclaimer =>
      'Disclaimer: Adding a witness or lawyer here does not constitute their legal approval. SplitSure does not replace qualified legal counsel. Parties should seek independent legal advice.';

  @override
  String get witnessFullNameRequired => 'Witness Full Name *';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get roleRelationshipOptional => 'Role / Relationship (optional)';

  @override
  String get lawyerFullNameRequired => 'Lawyer Full Name *';

  @override
  String get lawFirmOptional => 'Law Firm (optional)';

  @override
  String get professionalRegistrationOptional =>
      'Professional Registration (optional)';

  @override
  String collaboratorNumber(String number) {
    return 'Collaborator $number';
  }

  @override
  String get nameRequired => 'Name *';

  @override
  String get percentRequired => '% *';

  @override
  String get requiredShort => 'Req.';

  @override
  String get invalid => 'Invalid';

  @override
  String get collaboratorRoleRequired => 'Role (e.g. Producer, Vocalist) *';

  @override
  String get contributionDescriptionOptional =>
      'Contribution description (optional)';

  @override
  String responseRecorded(String response) {
    return 'Response recorded: $response';
  }

  @override
  String statusUpdatedTo(String status) {
    return 'Status updated to $status';
  }

  @override
  String pdfError(String details) {
    return 'PDF error: $details';
  }

  @override
  String get agreementActions => 'Agreement Actions';

  @override
  String get sendForReview => 'Send for Review';

  @override
  String get markAccepted => 'Mark Accepted';

  @override
  String get respondToAgreement => 'Respond to Agreement';

  @override
  String get accept => 'Accept';

  @override
  String get requestChanges => 'Request Changes';

  @override
  String get decline => 'Decline';

  @override
  String get songDetails => 'Song Details';

  @override
  String get description => 'Description';

  @override
  String get additionalTerms => 'Additional Terms';

  @override
  String get created => 'Created';

  @override
  String get witness => 'Witness';

  @override
  String get name => 'Name';

  @override
  String get emailShort => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get role => 'Role';

  @override
  String get legalRepresentative => 'Legal Representative';

  @override
  String get firm => 'Firm';

  @override
  String get registration => 'Registration';

  @override
  String get exportAndShare => 'Export & Share';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get downloadPdfSubtitle => 'Generate a PDF copy of this agreement';

  @override
  String get copyAgreementId => 'Copy Agreement ID';

  @override
  String get agreementIdCopied => 'Agreement ID copied';

  @override
  String get recordKeepingDisclaimer =>
      'Disclaimer: This agreement is for record-keeping purposes. SplitSure does not provide legal advice. Consult a qualified legal professional for binding agreements.';

  @override
  String get songProjectInformation => 'Song / Project Information';

  @override
  String get songTitle => 'Song Title';

  @override
  String get genre => 'Genre';

  @override
  String get releaseDate => 'Release Date';

  @override
  String get agreementStatus => 'Agreement Status';

  @override
  String get collaboratorsRevenueShares => 'Collaborators & Revenue Shares';

  @override
  String get roleRelationship => 'Role / Relationship';

  @override
  String get lawFirm => 'Law Firm';

  @override
  String get pdfTaglineOneLine => 'Protect your music. Promote your sound.';

  @override
  String get collaborationAgreementCaps => 'COLLABORATION AGREEMENT';

  @override
  String get contribution => 'Contribution';

  @override
  String get sharePercent => 'Share %';

  @override
  String get acceptanceSignatures => 'Acceptance & Signatures';

  @override
  String get pdfAcceptanceIntro =>
      'The acceptance status of each party is recorded below.';

  @override
  String get signatureLabel => 'Signature:';

  @override
  String get dateBlank => 'Date: ___________';

  @override
  String pdfReference(String ref) {
    return 'Ref: $ref';
  }

  @override
  String pdfPageOf(String page, String total) {
    return 'Page $page of $total';
  }

  @override
  String pdfTotal(String total) {
    return 'Total: $total%';
  }

  @override
  String pdfPartyStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get pdfAwaitingResponse => 'Awaiting response';

  @override
  String pdfAcceptedOn(String date) {
    return 'Accepted: $date';
  }

  @override
  String get pdfDisclaimer =>
      'DISCLAIMER: This document is generated by SplitSure for record-keeping purposes only. It does not constitute legal advice. The parties are encouraged to seek independent legal counsel before relying on this agreement as a binding contract. SplitSure does not guarantee the legal enforceability of this document in any jurisdiction.';

  @override
  String get promotionCampaigns => 'Promotion campaigns';

  @override
  String get noCampaignsYet => 'No campaigns yet';

  @override
  String get noCampaignsHint =>
      'Create your first campaign to turn a release into promotional content.';

  @override
  String get contentGeneratedLabel => 'Content generated';

  @override
  String uploadError(String details) {
    return 'Upload error: $details';
  }

  @override
  String get editCampaign => 'Edit Campaign';

  @override
  String get campaignInfo => 'Campaign Info';

  @override
  String get campaignNameOptional => 'Campaign Name (optional)';

  @override
  String get musicDescription => 'Music Description';

  @override
  String get promotionalMessage => 'Promotional Message';

  @override
  String get promotionalMessageHint => 'e.g. My new single is out now!';

  @override
  String get streamingLinkOptional => 'Streaming Link (optional)';

  @override
  String get mediaAssets => 'Media Assets';

  @override
  String get coverArt => 'Cover Art';

  @override
  String get musicFileFormats => 'Music File (MP3 / WAV)';

  @override
  String get audienceAndBudget => 'Audience & Budget';

  @override
  String get targetAudienceOptional => 'Target Audience (optional)';

  @override
  String get targetAudienceHint => 'e.g. Afrobeats fans, 18-35';

  @override
  String get budgetFcfa => 'Budget (FCFA)';

  @override
  String releaseOn(String date) {
    return 'Release: $date';
  }

  @override
  String get releaseDateOptional => 'Release Date (optional)';

  @override
  String get platforms => 'Platforms';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get createCampaign => 'Create Campaign';

  @override
  String get uploading => 'Uploading...';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get tapToUpload => 'Tap to upload';

  @override
  String get snippetSaved => 'Snippet saved!';

  @override
  String get contentGeneratedSnack => 'Content generated!';

  @override
  String copiedLabel(String label) {
    return '$label copied!';
  }

  @override
  String get campaignDetails => 'Campaign Details';

  @override
  String get audience => 'Audience';

  @override
  String get streamingLink => 'Streaming Link';

  @override
  String get budget => 'Budget';

  @override
  String amountFcfa(String amount) {
    return '$amount FCFA';
  }

  @override
  String get songSnippet => 'Song Snippet';

  @override
  String get loadingAudio => 'Loading audio...';

  @override
  String get generatePromoContent => 'Generate Promotional Content';

  @override
  String get generatePromoContentHint =>
      'Generate captions, hashtags and a promotional announcement for your campaign.';

  @override
  String get generating => 'Generating...';

  @override
  String get generateContent => 'Generate Content';

  @override
  String get generatedCaption => 'Generated Caption';

  @override
  String get caption => 'Caption';

  @override
  String get hashtags => 'Hashtags';

  @override
  String get promotionalVideo => 'Promotional Video';

  @override
  String get videoBackendNotice =>
      'Video generation requires a backend service. Download your cover art and use a tool like CapCut or Canva to create a 9:16 promo video with your snippet.';

  @override
  String get coverArtUrl => 'Cover art URL';

  @override
  String get copyCoverArtUrl => 'Copy Cover Art URL';

  @override
  String get shareOn => 'Share On';

  @override
  String get shareManuallyHint =>
      'Download your content and share manually on these platforms.';

  @override
  String get markReadyToShare => 'Mark as Ready to Share';

  @override
  String get selectSnippet => 'Select Snippet';

  @override
  String secondsShort(String seconds) {
    return '${seconds}s';
  }

  @override
  String snippetStart(String time) {
    return 'Start: $time';
  }

  @override
  String snippetEnd(String time) {
    return 'End: $time';
  }

  @override
  String get snippetRecommendation =>
      'Recommended: 15–30 seconds for social media.';

  @override
  String get saveSnippetTimes => 'Save Snippet Times';

  @override
  String captionOutNow(String title) {
    return '🎵 \"$title\" is out now!';
  }

  @override
  String get defaultPromoMessage => 'New music out now!';

  @override
  String get streamItNow => 'Stream it now';

  @override
  String streamItNowAt(String link) {
    return 'Stream it now: $link';
  }

  @override
  String get manageYourAccount => 'Manage your account';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get notificationsAndSubscription => 'Notifications & Subscription';

  @override
  String get legal => 'Legal';

  @override
  String get privacyPolicyBody =>
      'SplitSure collects only the data necessary to provide its services. Your data is stored securely on Supabase and is never sold to third parties.';

  @override
  String get termsBody =>
      'By using SplitSure, you agree to use the platform responsibly. Agreements created on SplitSure are for record-keeping purposes. Seek independent legal advice for binding contracts.';

  @override
  String get helpBody =>
      'For support, contact us at support@splitsure.app. We aim to respond within 24 hours.';

  @override
  String get session => 'Session';

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get close => 'Close';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get passwordUpdated => 'Password updated!';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotificationsHint =>
      'You\'ll be notified about agreements and campaigns here.';

  @override
  String get chooseAPlan => 'Choose a Plan';

  @override
  String get unlockFullAccess => 'Unlock full access to SplitSure';

  @override
  String get durationForever => 'Forever';

  @override
  String get durationPerMonth => 'per month';

  @override
  String get durationThreeMonths => '3 months';

  @override
  String get durationPerYear => 'per year';

  @override
  String saveVsMonthly(String amount) {
    return 'Save $amount FCFA vs monthly';
  }

  @override
  String get featureUpTo2Agreements => 'Create up to 2 agreements';

  @override
  String get featureUpTo2Campaigns => 'Create up to 2 campaigns';

  @override
  String get featureBasicContent => 'Basic content generation';

  @override
  String get featureCommunitySupport => 'Community support';

  @override
  String get featureUnlimitedAgreements => 'Unlimited agreements';

  @override
  String get featureUnlimitedCampaigns => 'Unlimited campaigns';

  @override
  String get featureFullContent => 'Full content generation';

  @override
  String get featurePdfExport => 'PDF agreement export';

  @override
  String get featurePrioritySupport => 'Priority support';

  @override
  String get featureEverythingMonthly => 'Everything in Monthly';

  @override
  String get featureSave17 => 'Save 17% vs monthly';

  @override
  String get featureEarlyAccess => 'Early access to new features';

  @override
  String get featureSave58 => 'Save 58% vs monthly';

  @override
  String get featurePriorityRequests => 'Priority feature requests';

  @override
  String get featureDedicatedSupport => 'Dedicated support';

  @override
  String get mobileMoneyNotice =>
      'Payment integration with Mobile Money (MTN, Orange) will be available in the full release. Use the demo flow for testing.';

  @override
  String demoSubscriptionActivated(String plan) {
    return 'Demo subscription activated: $plan';
  }

  @override
  String currentPlan(String plan) {
    return 'Current: $plan';
  }

  @override
  String expiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String get noExpiry => 'No expiry';

  @override
  String get expired => 'Expired';

  @override
  String get popular => 'Popular';

  @override
  String get current => 'Current';

  @override
  String subscribeFor(String price) {
    return 'Subscribe – $price';
  }

  @override
  String get demoModeNotice =>
      'DEMO MODE — No real payment is processed. This simulates a subscription for testing.';

  @override
  String get plan => 'Plan';

  @override
  String get amount => 'Amount';

  @override
  String get confirmDemoSubscription => 'Confirm Demo Subscription';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get bio => 'Bio';

  @override
  String get city => 'City';

  @override
  String get connectedAccounts => 'Connected Accounts';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get preferences => 'Preferences';

  @override
  String get about => 'About';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get aboutSplitSure => 'About SplitSure';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get aboutDescription =>
      'SplitSure helps independent artists, producers and songwriters manage collaboration agreements and promote their music releases.';

  @override
  String get aboutCommunity =>
      'Built for the music community in Cameroon and beyond.';

  @override
  String get inactive => 'Inactive';

  @override
  String get noSocialAccounts => 'No social accounts connected.';

  @override
  String get noTransactionsYet => 'No transactions yet.';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String get save => 'Save';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get firstNameRequiredLabel => 'First Name *';

  @override
  String get lastNameRequiredLabel => 'Last Name *';

  @override
  String get musicRoles => 'Music Roles';

  @override
  String get socialMediaLinks => 'Social Media Links';

  @override
  String get whatsappUrl => 'WhatsApp Number or Link';

  @override
  String get tiktokUrl => 'TikTok URL';

  @override
  String get youtubeUrl => 'YouTube URL';

  @override
  String get facebookUrl => 'Facebook URL';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get signInSubtitle => 'Welcome back! Sign in to continue.';

  @override
  String get registerSubtitle => 'Join SplitSure in less than a minute.';

  @override
  String get rememberMe => 'Remember me';

  @override
  String welcomeBackName(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String welcomeNewName(String name) {
    return 'Welcome to SplitSure, $name!';
  }

  @override
  String get welcomeBackSubtitle =>
      'Good to see you again. Your music is in safe hands.';

  @override
  String get welcomeNewSubtitle =>
      'Your account is ready. Let\'s protect and promote your music.';

  @override
  String get accountCreatedTitle => 'Account created!';

  @override
  String get continueToSignIn => 'Continue to sign in';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
      zero: 'All caught up',
    );
    return '$_temp0';
  }

  @override
  String get acceptConfirm =>
      'By accepting, you confirm you have read this agreement and agree to your share and role. Your acceptance will be recorded with the date and your account.';

  @override
  String get acceptedExplain =>
      'Every required party has accepted this version. It is now locked and kept in the history.';

  @override
  String get acceptedLocked =>
      'Accepted agreements cannot be edited. Create a new agreement for any further changes.';

  @override
  String acceptedOfTotal(int accepted, int total) {
    return '$accepted/$total accepted';
  }

  @override
  String get addAtLeastOneCollaborator => 'Add at least one collaborator.';

  @override
  String get additionalTermsHint =>
      'e.g. deductions, credits, how disputes are handled…';

  @override
  String get agreementReference => 'Agreement reference';

  @override
  String get agreementSavedDraft =>
      'Agreement saved as a draft. Review it, then send it to your collaborators.';

  @override
  String agreementTitleFor(String song) {
    return 'Music Collaboration Agreement – “$song”';
  }

  @override
  String get artistNameLabel => 'Artist name *';

  @override
  String get awaitingResponse => 'Awaiting response';

  @override
  String get changeNoteOptional => 'What changed? (optional)';

  @override
  String get changeRequests => 'Changes requested';

  @override
  String get changeRequestsHint =>
      'Edit the agreement to address these requests; a new version will be sent to everyone.';

  @override
  String get changesRequestedExplain =>
      'A collaborator asked for changes. The creator can edit the agreement and send a new version.';

  @override
  String get changesSaved => 'Changes saved.';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmRights =>
      'I confirm I own this content or have permission to use it.';

  @override
  String get confirmRightsRequired =>
      'Please confirm you own or have permission to use the uploaded content.';

  @override
  String get copyInviteLink => 'Copy invite link';

  @override
  String get declineReasonOptional => 'Reason (optional)';

  @override
  String get declinedExplain =>
      'A collaborator declined. The creator can revise the agreement and send a new version, or delete it.';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAgreementConfirm =>
      'Delete this agreement? This cannot be undone.';

  @override
  String get deleteProjectConfirm =>
      'Delete this project? Its agreements and campaigns are kept but no longer linked to it.';

  @override
  String get describeChanges => 'Describe the changes you need';

  @override
  String get draftExplain =>
      'Only you can see this draft. When the shares total 100%, send it to your collaborators for review.';

  @override
  String get edit => 'Edit';

  @override
  String get editAgreement => 'Edit agreement';

  @override
  String get editAndResend => 'Edit & send new version';

  @override
  String get editProject => 'Edit project';

  @override
  String get emailForInvite => 'Email (to invite)';

  @override
  String get featureNotInPlan =>
      'This feature is not included in your current plan.';

  @override
  String get finalizedOn => 'Accepted by all on';

  @override
  String get inviteExplain =>
      'Collaborators with an email receive the agreement in their SplitSure account (registered or not yet). You can also copy a secure invite link for each person once the agreement is saved.';

  @override
  String inviteLinkCopied(String name) {
    return 'Invite link for $name copied. Share it privately.';
  }

  @override
  String get inviteOpening => 'Linking this invitation to your account…';

  @override
  String get inviteSignInPrompt =>
      'You\'ve been invited to review a music collaboration agreement. Create a free account or sign in to view it.';

  @override
  String get inviteTitle => 'You\'re invited to collaborate';

  @override
  String get musicProjectOptional => 'Music project (optional)';

  @override
  String get newVersionExplain =>
      'Your edits will be sent as a new version. Previous answers are kept in the history and everyone will be asked to review again.';

  @override
  String get newVersionSent => 'New version sent to your collaborators.';

  @override
  String get newVersionTitle => 'Send a new version?';

  @override
  String get noProject => 'No project';

  @override
  String get noProjectsHint =>
      'Group a song\'s agreements and campaigns in one place.';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get noResponsesYet => 'No responses yet';

  @override
  String get notNow => 'Not now';

  @override
  String get openAgreement => 'Open agreement';

  @override
  String get paymentTerms => 'Payment / revenue-sharing terms';

  @override
  String get paymentTermsHint =>
      'e.g. how and when income is shared, who collects, reporting…';

  @override
  String pendingExplain(int accepted, int total) {
    return 'Waiting for collaborators: $accepted of $total have accepted.';
  }

  @override
  String planLimitReachedBody(int max) {
    return 'Your current plan allows up to $max. Upgrade to create more.';
  }

  @override
  String get planLimitReachedTitle => 'Plan limit reached';

  @override
  String projectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects',
      one: '1 project',
      zero: 'No projects',
    );
    return '$_temp0';
  }

  @override
  String get projectSaved => 'Project saved.';

  @override
  String get projectStatus => 'Project status';

  @override
  String get projectStatusIdea => 'Idea';

  @override
  String get projectStatusInProgress => 'In progress';

  @override
  String get projectStatusRecorded => 'Recorded';

  @override
  String get projectStatusReleased => 'Released';

  @override
  String get responseSentAccepted => 'You accepted the agreement.';

  @override
  String get responseSentChanges => 'Your change request was sent.';

  @override
  String get responseSentDeclined => 'You declined the agreement.';

  @override
  String get saveAsDraft => 'Save as draft';

  @override
  String get saveProject => 'Save project';

  @override
  String get scopeAndTerms => 'Scope & terms';

  @override
  String get scopeComposition => 'Musical composition';

  @override
  String get scopeDetails => 'Scope details (optional)';

  @override
  String get scopeHelp =>
      'The percentages do not automatically apply to every right or income. Select what this agreement covers.';

  @override
  String get scopeLyrics => 'Lyrics';

  @override
  String get scopeMaster => 'Sound recording / master';

  @override
  String get scopeOther => 'Other rights or revenue';

  @override
  String get scopeProduction => 'Production contribution';

  @override
  String get scopeQuestion => 'What does this agreement cover?';

  @override
  String get seeAll => 'See all';

  @override
  String get seePlans => 'See plans';

  @override
  String get send => 'Send';

  @override
  String get sendForReviewConfirm =>
      'Send this agreement to all collaborators for review? They will be able to accept, request changes or decline.';

  @override
  String get sendNewVersion => 'Send new version';

  @override
  String get sentForReview => 'Agreement sent for review.';

  @override
  String get splitsExceed100 => 'The total cannot exceed 100%.';

  @override
  String get splitsMustReach100 =>
      'Shares must total exactly 100% before the agreement can be sent.';

  @override
  String get splitsReady => 'Shares total 100%.';

  @override
  String stepOfN(String step, String total) {
    return 'Step $step of $total';
  }

  @override
  String get totalLabel => 'Total';

  @override
  String get versionHistory => 'Version history';

  @override
  String get versionLabel => 'Version';

  @override
  String versionSentOn(int version, String date) {
    return 'Version $version · $date';
  }

  @override
  String versionShort(int version) {
    return 'v$version';
  }

  @override
  String get witnessOptionalIntro =>
      'Both sections are optional. A witness or lawyer listed here has not approved the agreement unless they review it themselves.';

  @override
  String get yourResponse => 'Your response';

  @override
  String get yourResponseNeeded => 'Your response is needed';

  @override
  String yourShareIs(String percent, String role) {
    return 'Your share: $percent as $role';
  }

  @override
  String updatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String get sharedWithYou => 'Shared with you';

  @override
  String get deleteCampaignConfirm =>
      'Delete this campaign and its generated content?';

  @override
  String get downloadVideo => 'Download video';

  @override
  String durationDays(int days) {
    return '$days days';
  }

  @override
  String get enablePush => 'Enable push notifications on this device';

  @override
  String expiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expires in $days days',
      one: 'Expires tomorrow',
      zero: 'Expires today',
    );
    return '$_temp0';
  }

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get featureCollaboratorInvites =>
      'Collaborator invitations & acceptance tracking';

  @override
  String get featurePromoVideo => '9:16 promotional videos';

  @override
  String get featureUnlimitedProjects => 'Unlimited music projects';

  @override
  String featureUpToAgreements(int count) {
    return 'Up to $count agreements';
  }

  @override
  String featureUpToCampaigns(int count) {
    return 'Up to $count campaigns';
  }

  @override
  String featureUpToProjects(int count) {
    return 'Up to $count music projects';
  }

  @override
  String get freePlanExplain =>
      'You\'re on the Basic plan. Upgrade any time for unlimited agreements, campaigns and projects.';

  @override
  String get generateVideo => 'Generate promo video';

  @override
  String get markCompleted => 'Mark completed';

  @override
  String notifAcceptedBody(String name, String song) {
    return '$name accepted “$song”.';
  }

  @override
  String get notifAcceptedTitle => 'Agreement accepted';

  @override
  String notifCampaignBody(String campaign) {
    return '“$campaign” is complete.';
  }

  @override
  String get notifCampaignTitle => 'Campaign completed';

  @override
  String get notifCatAgreements => 'Agreements';

  @override
  String get notifCatAgreementsHint =>
      'Invitations, responses and new versions';

  @override
  String get notifCatCampaigns => 'Campaigns';

  @override
  String get notifCatCampaignsHint => 'When a campaign is completed';

  @override
  String get notifCatSubscription => 'Subscription';

  @override
  String get notifCatSubscriptionHint => 'Expiry reminders';

  @override
  String notifChangesBody(String name, String song) {
    return '$name requested changes to “$song”.';
  }

  @override
  String get notifChangesTitle => 'Changes requested';

  @override
  String notifDeclinedBody(String name, String song) {
    return '$name declined “$song”.';
  }

  @override
  String get notifDeclinedTitle => 'Agreement declined';

  @override
  String get notifExpiredBody => 'Renew to keep full access to SplitSure.';

  @override
  String get notifExpiredTitle => 'Subscription expired';

  @override
  String notifExpiringBody(String date) {
    return 'Your plan expires on $date.';
  }

  @override
  String get notifExpiringTitle => 'Subscription expiring soon';

  @override
  String notifFinalBody(String song) {
    return 'All parties accepted “$song”.';
  }

  @override
  String get notifFinalTitle => 'Agreement finalised';

  @override
  String notifInvitedBody(String song) {
    return 'You\'ve been invited to review “$song”.';
  }

  @override
  String get notifInvitedTitle => 'New collaboration agreement';

  @override
  String notifNewVersionBody(String version, String song) {
    return 'Version $version of “$song” is ready for review.';
  }

  @override
  String get notifNewVersionTitle => 'Agreement updated';

  @override
  String get outNowBadge => 'OUT NOW';

  @override
  String get paymentDemo => 'Demo (not paid)';

  @override
  String get paymentFailed => 'Failed';

  @override
  String get paymentPaid => 'Paid';

  @override
  String get paymentPending => 'Pending';

  @override
  String get paymentRefunded => 'Refunded';

  @override
  String get paymentStatus => 'Payment status';

  @override
  String get pushEnabled => 'Push notifications enabled on this device.';

  @override
  String get pushExplain =>
      'Allow notifications in your browser to be alerted about agreements even when SplitSure is closed.';

  @override
  String get pushUnavailable =>
      'Push notifications are not available in this browser or were blocked.';

  @override
  String get regenerateVideo => 'Generate a new video';

  @override
  String get renewExtends =>
      'Renewing adds the new period after your current expiry date.';

  @override
  String renewPlan(String price) {
    return 'Renew – $price';
  }

  @override
  String get startDate => 'Start date';

  @override
  String get subscriptionHistory => 'Subscription history';

  @override
  String get templatePulse => 'Cover pulse';

  @override
  String get templatePulseHint => 'Artwork that moves with the beat';

  @override
  String get templateWaveform => 'Waveform teaser';

  @override
  String get templateWaveformHint => 'Live sound bars + progress';

  @override
  String videoFailed(String details) {
    return 'Video could not be created: $details';
  }

  @override
  String get videoIntro =>
      'Creates a real vertical 9:16 video with your artwork, title, artist name, message and the selected snippet. It records in real time, so keep this tab open.';

  @override
  String get videoNeedsMusic => 'Upload a music file to the campaign first.';

  @override
  String get videoReady => 'Your promo video is ready!';

  @override
  String videoRendering(int percent) {
    return 'Recording your video… $percent%';
  }

  @override
  String get videoUnsupported =>
      'This browser cannot record video. Use a recent Chrome, Edge or Safari.';

  @override
  String get videoWebmNote =>
      'Your browser saved this video as WebM. For an MP4 file, generate it in Chrome, Edge or Safari.';

  @override
  String get noRolesYet => 'No music roles added yet.';

  @override
  String get proPlan => 'Pro';

  @override
  String get choosePlanTitle => 'Choose your plan';

  @override
  String get choosePlanSubtitle =>
      'Start free and upgrade whenever you\'re ready.';

  @override
  String get continueWithFree => 'Continue with Basic';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String upgradeForAmount(String amount) {
    return 'Upgrade for $amount';
  }

  @override
  String get oneTimePayment => 'One-time payment';

  @override
  String get freeForever => 'Free forever';

  @override
  String get recommended => 'Recommended';

  @override
  String get proActive => 'Pro active';

  @override
  String proActiveSince(String date) {
    return 'Pro since $date';
  }

  @override
  String get youAreOnFree => 'You\'re on the Free plan';

  @override
  String get youAreOnPro => 'You\'re on Pro';

  @override
  String get proUnlocksBody =>
      'Unlimited opportunity posts, unlimited final agreements, Reach promotion tools and more.';

  @override
  String get freeFeatureProtectDrafts => '1 free agreement document';

  @override
  String freeFeatureAgreementFee(String amount) {
    return 'Each extra agreement: $amount to preview & download';
  }

  @override
  String get freeFeatureOnePost => '1 opportunity post';

  @override
  String get freeFeaturePassport => 'Music Passport & applications';

  @override
  String freeFeatureProjects(int count) {
    return 'Up to $count projects';
  }

  @override
  String get proFeatureUnlimitedPosts => 'Unlimited opportunity posts';

  @override
  String get proFeatureUnlimitedAgreements => 'Unlimited agreements';

  @override
  String get proFeatureReach => 'Reach: campaigns, captions & promo videos';

  @override
  String get proFeatureUnlimitedProjects => 'Unlimited projects';

  @override
  String get proFeaturePriority => 'Priority visibility in the Opportunity Hub';

  @override
  String get paymentHistory => 'Payment history';

  @override
  String get noPayments => 'No payments yet.';

  @override
  String get paymentTypePro => 'Pro upgrade';

  @override
  String get paymentTypeAgreement => 'Final agreement';

  @override
  String get paymentSuccess => 'Successful';

  @override
  String get paymentCancelled => 'Cancelled';

  @override
  String get payWithMobileMoney => 'Pay with Mobile Money';

  @override
  String get mtnMomo => 'MTN Mobile Money';

  @override
  String get orangeMoney => 'Orange Money';

  @override
  String get mobileMoneyNumber => 'Mobile Money number';

  @override
  String get mobileMoneyNumberHint => '6XX XXX XXX';

  @override
  String get invalidCameroonPhone =>
      'Enter a valid Cameroon number (9 digits starting with 6).';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get waitingForApproval => 'Waiting for your approval';

  @override
  String approveOnPhone(String amount) {
    return 'Check your phone and approve the $amount payment with your PIN.';
  }

  @override
  String get dialToApprove =>
      'No prompt? Dial *126# (MTN) or #150*50# (Orange) to approve pending payments.';

  @override
  String get checkingPayment => 'Checking payment…';

  @override
  String get paymentConfirmed => 'Payment confirmed';

  @override
  String get paymentNotCompleted => 'Payment not completed';

  @override
  String get paymentFailedBody =>
      'The payment was declined or cancelled. Nothing was charged. You can try again.';

  @override
  String get paymentStillPending =>
      'We haven\'t received confirmation yet. If you approved it, it will be applied automatically – check again in a moment.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get tryAgain => 'Try again';

  @override
  String get paymentsUnavailable =>
      'Payments are temporarily unavailable. Please try again later.';

  @override
  String get alreadyPro => 'You already have Pro.';

  @override
  String get proWelcomeTitle => 'Welcome to Pro!';

  @override
  String get proWelcomeBody =>
      'Everything is unlocked. Enjoy unlimited posts, agreements and Reach.';

  @override
  String get securePaymentNote =>
      'Payments are processed securely by MeSomb. SplitSure never sees your PIN.';

  @override
  String get planBadgeFree => 'FREE';

  @override
  String get planBadgePro => 'PRO';

  @override
  String get reference => 'Reference';

  @override
  String get continueLabel => 'Continue';

  @override
  String get musicPassport => 'Music Passport';

  @override
  String get passportTagline => 'Your professional music identity';

  @override
  String get createPassport => 'Create my Music Passport';

  @override
  String get createPassportIntro =>
      'One professional profile used across SplitSure: showcase your roles, skills and work, apply to opportunities and get discovered.';

  @override
  String get editPassport => 'Edit passport';

  @override
  String get passportStepIdentity => 'Identity';

  @override
  String get passportStepProfessional => 'Professional';

  @override
  String get passportStepPortfolio => 'Portfolio';

  @override
  String get passportStepReview => 'Review';

  @override
  String get stageName => 'Professional / stage name';

  @override
  String get fullName => 'Full name';

  @override
  String get primaryRole => 'Primary role';

  @override
  String get secondaryRoles => 'Secondary roles (optional)';

  @override
  String get professionalBio => 'Short professional biography';

  @override
  String get contactEmail => 'Contact email';

  @override
  String get contactPhone => 'Contact phone';

  @override
  String get preferredContact => 'Preferred contact method';

  @override
  String get contactEmailMethod => 'Email';

  @override
  String get contactPhoneMethod => 'Phone call';

  @override
  String get contactWhatsapp => 'WhatsApp';

  @override
  String get contactInApp => 'Through SplitSure';

  @override
  String get skillsSpecialisations => 'Skills & specialisations';

  @override
  String get yearsExperience => 'Years of experience';

  @override
  String get genres => 'Genres';

  @override
  String get instruments => 'Instruments played';

  @override
  String get languages => 'Languages';

  @override
  String get availability => 'Availability for collaboration';

  @override
  String get availabilityAvailable => 'Available';

  @override
  String get availabilityLimited => 'Limited availability';

  @override
  String get availabilityUnavailable => 'Not available';

  @override
  String get preferredArrangements => 'Preferred collaboration arrangements';

  @override
  String get operatingLocation => 'Location of operation';

  @override
  String get operatingLocationHint => 'e.g. Douala, Yaoundé, remote';

  @override
  String get typeAndEnter => 'Type and press Enter';

  @override
  String get externalLinks => 'Links';

  @override
  String get personalWebsite => 'Website';

  @override
  String get portfolioItems => 'Portfolio & experience';

  @override
  String get addPortfolioItem => 'Add to portfolio';

  @override
  String get editPortfolioItem => 'Edit portfolio item';

  @override
  String get noPortfolioItems =>
      'Add your projects, releases, credits, videos and awards.';

  @override
  String get portfolioKind => 'Type';

  @override
  String get kindProject => 'Project';

  @override
  String get kindRelease => 'Released song';

  @override
  String get kindAlbum => 'Album / EP';

  @override
  String get kindProductionCredit => 'Production credit';

  @override
  String get kindWritingCredit => 'Writing credit';

  @override
  String get kindCollaboration => 'Collaboration';

  @override
  String get kindVideo => 'Music video';

  @override
  String get kindAward => 'Achievement / award';

  @override
  String get kindExperience => 'Professional experience';

  @override
  String get itemTitle => 'Title';

  @override
  String get itemRoleOptional => 'Your role (optional)';

  @override
  String get itemYear => 'Year';

  @override
  String get itemLink => 'Link (Spotify, YouTube…)';

  @override
  String get itemDescription => 'Description';

  @override
  String get addImage => 'Add image';

  @override
  String get showOnPublicPassport => 'Show on my public passport';

  @override
  String get visibilitySettings => 'Public visibility';

  @override
  String get visibilityHint =>
      'Choose what visitors of your public passport can see.';

  @override
  String get visibilityContact => 'Contact details';

  @override
  String get visibilityLocation => 'Location';

  @override
  String get visibilityPortfolio => 'Portfolio';

  @override
  String get visibilityLinks => 'Links';

  @override
  String get visibilityExperience => 'Years of experience';

  @override
  String get passportUrl => 'Public link';

  @override
  String get passportSlugHint => 'letters, numbers and dashes';

  @override
  String get slugTaken => 'This link is already taken.';

  @override
  String get slugInvalid => 'Use 3–40 lowercase letters, numbers or dashes.';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get publishPassport => 'Publish passport';

  @override
  String get unpublishPassport => 'Unpublish';

  @override
  String get passportPublished => 'Your Music Passport is live!';

  @override
  String get passportSaved => 'Passport saved';

  @override
  String get passportDraft => 'Draft – not public yet';

  @override
  String get passportLive => 'Published';

  @override
  String get previewPublic => 'Preview public profile';

  @override
  String get sharePassport => 'Share passport';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get collaborate => 'Collaborate';

  @override
  String get contact => 'Contact';

  @override
  String get viewPortfolio => 'View portfolio';

  @override
  String get viewPassport => 'View Music Passport';

  @override
  String get passportNotFound =>
      'This Music Passport doesn\'t exist or isn\'t public.';

  @override
  String yearsExperienceValue(int count) {
    return '$count years of experience';
  }

  @override
  String get noContactPublic =>
      'This member shares contact details only through SplitSure. Sign in and apply to one of their opportunities to collaborate.';

  @override
  String openOpportunitiesBy(String name) {
    return 'Open opportunities by $name';
  }

  @override
  String noOpenOpportunitiesBy(String name) {
    return '$name has no open opportunities right now.';
  }

  @override
  String get signInToCollaborate => 'Sign in to collaborate';

  @override
  String get joinSplitSure => 'Join SplitSure';

  @override
  String get passportRequiredTitle => 'Music Passport needed';

  @override
  String get passportRequiredBody =>
      'Publish your Music Passport first – it\'s your professional identity for posting and applying.';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get photo => 'Photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get requiredField => 'Required';

  @override
  String get rolePassportSinger => 'Singer / Vocalist';

  @override
  String get rolePassportRapper => 'Rapper';

  @override
  String get rolePassportProducer => 'Music Producer';

  @override
  String get rolePassportSongwriter => 'Songwriter';

  @override
  String get rolePassportComposer => 'Composer';

  @override
  String get rolePassportSoundEngineer => 'Sound Engineer';

  @override
  String get rolePassportMixMaster => 'Mixing & Mastering Engineer';

  @override
  String get rolePassportInstrumentalist => 'Instrumentalist';

  @override
  String get rolePassportDj => 'DJ';

  @override
  String get rolePassportMusicManager => 'Music Manager';

  @override
  String get rolePassportArtistManager => 'Artist Manager';

  @override
  String get rolePassportLabel => 'Record Label';

  @override
  String get rolePassportPublisher => 'Music Publisher';

  @override
  String get rolePassportVideoDirector => 'Video Director';

  @override
  String get rolePassportPromoter => 'Music Promoter';

  @override
  String get rolePassportDesigner => 'Graphic Designer';

  @override
  String get rolePassportPhotographer => 'Photographer';

  @override
  String get rolePassportBusiness => 'Music Business Professional';

  @override
  String get rolePassportOther => 'Other';

  @override
  String get arrangementPaid => 'Paid collaboration';

  @override
  String get arrangementRevenueShare => 'Revenue sharing';

  @override
  String get arrangementRoyaltyShare => 'Royalty sharing';

  @override
  String get arrangementPercentage => 'Percentage-based partnership';

  @override
  String get arrangementVoluntary => 'Voluntary collaboration';

  @override
  String get arrangementNegotiable => 'Negotiable arrangement';

  @override
  String get opportunityHub => 'Opportunity Hub';

  @override
  String get navHub => 'Hub';

  @override
  String get hubTagline => 'Find collaborators and music projects';

  @override
  String get hubDiscover => 'Discover';

  @override
  String get hubMyPosts => 'My posts';

  @override
  String get hubMyApplications => 'My applications';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String get allOpportunities => 'All opportunities';

  @override
  String get searchOpportunities => 'Search opportunities';

  @override
  String get filters => 'Filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filterRole => 'Role';

  @override
  String get filterGenre => 'Genre';

  @override
  String get filterLocation => 'Location';

  @override
  String get filterCompensation => 'Compensation';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterDate => 'Posted';

  @override
  String get anyTime => 'Any time';

  @override
  String get last24h => 'Last 24 hours';

  @override
  String get lastWeek => 'Last 7 days';

  @override
  String get lastMonth => 'Last 30 days';

  @override
  String get remoteOk => 'Remote OK';

  @override
  String get noOpportunities => 'No opportunities match yet.';

  @override
  String get noOpportunitiesHint =>
      'Try other filters, or post your own opportunity.';

  @override
  String get postOpportunity => 'Post an opportunity';

  @override
  String get editOpportunity => 'Edit opportunity';

  @override
  String get opportunityTitle => 'Opportunity title';

  @override
  String get opportunityTitleHint =>
      'e.g. Looking for a vocalist for an Afrobeats single';

  @override
  String get projectDescription => 'Project description';

  @override
  String get projectCategory => 'Project category';

  @override
  String get categoryRecording => 'Recording';

  @override
  String get categorySongwriting => 'Songwriting';

  @override
  String get categoryProduction => 'Production';

  @override
  String get categoryPerformance => 'Performance';

  @override
  String get categoryVideo => 'Music video';

  @override
  String get categoryLive => 'Live / events';

  @override
  String get categoryMarketing => 'Marketing & promotion';

  @override
  String get categoryBusiness => 'Business & management';

  @override
  String get categoryOther => 'Other';

  @override
  String get requiredRoles => 'Required role(s)';

  @override
  String get requiredSkills => 'Required skills';

  @override
  String get projectLocation => 'Project location';

  @override
  String get remoteCollaboration => 'Remote collaboration possible';

  @override
  String get collaborationType => 'Collaboration type';

  @override
  String get compensationArrangement => 'Compensation arrangement';

  @override
  String get compensationHint => 'e.g. 50,000 FCFA, or 20% of master royalties';

  @override
  String get expectedDeliverables => 'Expected deliverables';

  @override
  String get projectDeadline => 'Project deadline';

  @override
  String get applicationDeadline => 'Application deadline';

  @override
  String get positionsNeeded => 'Number of collaborators needed';

  @override
  String get referenceLinks => 'Reference files or links';

  @override
  String get additionalRequirements => 'Additional requirements';

  @override
  String get restrictToRoles => 'Only show to people with these roles';

  @override
  String get restrictToRolesHint =>
      'Recommended: your opportunity reaches the right people and stays private from others.';

  @override
  String get publishOpportunity => 'Publish opportunity';

  @override
  String get opportunityPublished => 'Opportunity published';

  @override
  String get opportunityUpdated => 'Opportunity updated';

  @override
  String get freePostUsedTitle => 'Free post used';

  @override
  String get freePostUsedBody =>
      'Free accounts include one opportunity post. Upgrade to Pro for unlimited posts.';

  @override
  String freePostsRemaining(int count) {
    return 'Basic plan: $count post left';
  }

  @override
  String get statusOpen => 'Open';

  @override
  String get statusClosed => 'Closed';

  @override
  String get closeOpportunity => 'Close';

  @override
  String get reopenOpportunity => 'Reopen';

  @override
  String get deleteOpportunity => 'Delete opportunity';

  @override
  String get deleteOpportunityConfirm =>
      'Delete this opportunity and its applications? This can\'t be undone, and your free post allowance isn\'t restored.';

  @override
  String get postedBy => 'Posted by';

  @override
  String publishedOn(String date) {
    return 'Published $date';
  }

  @override
  String deadlineOn(String date) {
    return 'Deadline $date';
  }

  @override
  String applyBy(String date) {
    return 'Apply by $date';
  }

  @override
  String positionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count positions',
      one: '1 position',
    );
    return '$_temp0';
  }

  @override
  String applicationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applications',
      one: '1 application',
      zero: 'No applications yet',
    );
    return '$_temp0';
  }

  @override
  String get applyNow => 'Apply now';

  @override
  String get shareOpportunity => 'Share';

  @override
  String get alreadyApplied => 'You applied';

  @override
  String get applyTitle => 'Apply with your Music Passport';

  @override
  String get applicationMessage => 'Short message to the owner';

  @override
  String get applicationMessageHint => 'Why are you a good fit?';

  @override
  String get supportingLinks => 'Portfolio links or supporting material';

  @override
  String get submitApplication => 'Submit application';

  @override
  String get applicationSent => 'Application sent';

  @override
  String get opportunityClosedNotice => 'This opportunity is closed.';

  @override
  String get yourOwnOpportunity => 'This is your opportunity.';

  @override
  String get applicationsTitle => 'Applications';

  @override
  String get noApplicationsYet => 'No applications yet.';

  @override
  String get appStatusPending => 'Pending';

  @override
  String get appStatusUnderReview => 'Under review';

  @override
  String get appStatusShortlisted => 'Shortlisted';

  @override
  String get appStatusAccepted => 'Accepted';

  @override
  String get appStatusRejected => 'Rejected';

  @override
  String get appStatusWithdrawn => 'Withdrawn';

  @override
  String get markUnderReview => 'Review';

  @override
  String get shortlist => 'Shortlist';

  @override
  String get reject => 'Reject';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get withdrawConfirm => 'Withdraw your application?';

  @override
  String appliedOn(String date) {
    return 'Applied $date';
  }

  @override
  String get noMyApplications => 'You haven\'t applied to any opportunity yet.';

  @override
  String get noMyPosts => 'You haven\'t posted any opportunity yet.';

  @override
  String get startWorkspace => 'Open DealFlow workspace';

  @override
  String get dealflow => 'DealFlow';

  @override
  String get dealflowTagline => 'Agree on roles and splits, then protect it';

  @override
  String get workspaces => 'Workspaces';

  @override
  String get noWorkspaces =>
      'Accept an applicant to start a DealFlow workspace.';

  @override
  String get wsStatusNegotiating => 'Negotiating';

  @override
  String get wsStatusAgreed => 'Terms agreed';

  @override
  String get wsStatusInProtect => 'In Protect';

  @override
  String get wsStatusActive => 'Active';

  @override
  String get wsStatusCompleted => 'Completed';

  @override
  String get wsStatusCancelled => 'Cancelled';

  @override
  String get projectOwner => 'Project owner';

  @override
  String get participants => 'Participants';

  @override
  String get responsibilities => 'Responsibilities';

  @override
  String get contributionPercent => 'Contribution %';

  @override
  String get proposeTerms => 'Propose terms';

  @override
  String get editTerms => 'Edit terms';

  @override
  String get paymentArrangement => 'Payment arrangement';

  @override
  String get importantDates => 'Important dates';

  @override
  String get discussion => 'Discussion';

  @override
  String get writeMessage => 'Write a message…';

  @override
  String get iAgree => 'I agree to these terms';

  @override
  String get withdrawAgreement => 'Withdraw my agreement';

  @override
  String get agreedBadge => 'Agreed';

  @override
  String get notAgreedYet => 'Not agreed yet';

  @override
  String totalPercent(String percent) {
    return 'Total: $percent%';
  }

  @override
  String get totalMustBe100 =>
      'Contributions must add up to 100% before everyone can agree.';

  @override
  String get continueInProtect => 'Continue in Protect';

  @override
  String get continueInProtectHint =>
      'Everyone agreed. Create the agreement in Protect – it\'s pre-filled with these terms.';

  @override
  String get markActive => 'Mark active';

  @override
  String get cancelWorkspace => 'Cancel collaboration';

  @override
  String get termsLocked =>
      'Terms are locked because the agreement is in Protect.';

  @override
  String get workspaceOpened => 'Workspace ready';

  @override
  String get done => 'Done';

  @override
  String get more => 'More';

  @override
  String currentPlanName(String plan) {
    return 'Current plan: $plan';
  }

  @override
  String get pdfPreviewWatermark => 'PREVIEW – NOT FINAL';

  @override
  String get previewPdf => 'Preview PDF';

  @override
  String get previewPdfSubtitle => 'Free draft copy (not the final agreement)';

  @override
  String get generateFinalAgreement => 'Generate final agreement';

  @override
  String get finalAgreementFree => 'Included in Pro';

  @override
  String finalAgreementFee(String amount) {
    return '$amount one-time for this agreement';
  }

  @override
  String get finalAgreementNeedsAcceptance =>
      'Available once every party has accepted.';

  @override
  String get downloadFinalAgreement => 'Download final agreement';

  @override
  String get finalAgreementReady => 'Final agreement – saved for every party';

  @override
  String get finalAgreementUnlockedTitle => 'Final agreement unlocked';

  @override
  String get reachProOnlyTitle => 'Reach is a Pro feature';

  @override
  String get reachProOnlyBody =>
      'Turn every release into ready-to-post content for Instagram, TikTok, Facebook and WhatsApp.';

  @override
  String get reachBenefitCampaigns => 'Promotion campaigns for every release';

  @override
  String get reachBenefitVideo => '9:16 promo videos from your track and cover';

  @override
  String get reachBenefitCaptions =>
      'Captions, hashtags and announcements in EN/FR';

  @override
  String get reachBenefitBio => 'Artist bios written from your Music Passport';

  @override
  String upgradeNowFor(String amount) {
    return 'Upgrade now – $amount';
  }

  @override
  String get contentStudio => 'Content Studio';

  @override
  String get contentStudioSubtitle =>
      'Captions, announcements and bios from your projects and Passport';

  @override
  String get contentType => 'What do you want to write?';

  @override
  String get contentCaption => 'Promo caption';

  @override
  String get contentAnnouncement => 'Release announcement';

  @override
  String get contentBio => 'Artist biography';

  @override
  String get contentProjectPromo => 'Project promotion';

  @override
  String get platform => 'Platform';

  @override
  String get sourceProject => 'Project or campaign';

  @override
  String get noSourceSelected => 'No project – use my Passport only';

  @override
  String get generate => 'Generate';

  @override
  String get regenerate => 'Another version';

  @override
  String get copyText => 'Copy';

  @override
  String get textCopied => 'Copied – paste it in your app';

  @override
  String get shareText => 'Share';

  @override
  String get needPassportForBio =>
      'Create your Music Passport to generate a biography.';

  @override
  String get directPublishNote =>
      'Direct publishing needs each platform\'s official app approval. For now, copy or share the text and post it from the platform.';

  @override
  String genCaption1(String title, String artist, String link) {
    return 'New music alert! \"$title\" by $artist is out now. $link';
  }

  @override
  String genCaption2(String title, String artist, String link) {
    return '$artist just dropped \"$title\" – press play and tell me what you think. $link';
  }

  @override
  String genCaption3(String title, String link) {
    return '\"$title\" is here. Made with love, made for you. Stream it now. $link';
  }

  @override
  String genAnnouncement1(String kind, String title, String date, String link) {
    return 'Big news: my new $kind \"$title\" drops $date. Mark the date and get ready! $link';
  }

  @override
  String genAnnouncement2(
      String title, String artist, String date, String link) {
    return 'It\'s official – \"$title\" by $artist arrives $date. Turn on notifications so you don\'t miss it. $link';
  }

  @override
  String genAnnouncementNoDate(String title, String artist, String link) {
    return 'Coming soon: \"$title\" by $artist. Stay tuned – the countdown starts now. $link';
  }

  @override
  String get kindSingle => 'single';

  @override
  String genBioIntro(String name, String roles, String location) {
    return '$name is a $roles$location.';
  }

  @override
  String genBioBasedIn(String place) {
    return ', based in $place';
  }

  @override
  String genBioExperience(String years, String name, String genres) {
    return 'With $years years of experience, $name works across $genres.';
  }

  @override
  String genBioGenres(String name, String genres) {
    return '$name\'s sound blends $genres.';
  }

  @override
  String genBioCredits(String credits) {
    return 'Selected work: $credits.';
  }

  @override
  String genBioInstruments(String instruments) {
    return 'Plays $instruments.';
  }

  @override
  String get genBioOpen => 'Open to collaborations – reach out via SplitSure.';

  @override
  String genProjectPromo(String title, String genre, String description) {
    return 'Working on \"$title\"$genre. $description Follow the journey!';
  }

  @override
  String get andWord => 'and';

  @override
  String get notifOppRecommendedTitle => 'New opportunity for you';

  @override
  String notifOppRecommendedBody(String title) {
    return '\"$title\" matches your Music Passport.';
  }

  @override
  String get notifAppReceivedTitle => 'New application';

  @override
  String notifAppReceivedBody(String name, String title) {
    return '$name applied to \"$title\".';
  }

  @override
  String get notifAppUnderReviewTitle => 'Application under review';

  @override
  String get notifAppShortlistedTitle => 'You\'ve been shortlisted!';

  @override
  String get notifAppAcceptedTitle => 'Application accepted';

  @override
  String get notifAppRejectedTitle => 'Application update';

  @override
  String notifAppStatusBody(String title) {
    return '\"$title\"';
  }

  @override
  String notifAppRejectedBody(String title) {
    return 'Your application to \"$title\" wasn\'t selected this time.';
  }

  @override
  String get notifWorkspaceTitle => 'DealFlow workspace ready';

  @override
  String notifWorkspaceBody(String title) {
    return 'Agree on roles and splits for \"$title\".';
  }

  @override
  String get notifMemberAddedTitle => 'You were added to a collaboration';

  @override
  String get notifTermsUpdatedTitle => 'Terms updated';

  @override
  String notifTermsUpdatedBody(String title) {
    return 'New terms were proposed for \"$title\". Review and agree.';
  }

  @override
  String get notifPaymentSuccessTitle => 'Payment successful';

  @override
  String notifPaymentSuccessBody(String amount) {
    return '$amount FCFA received. Thank you!';
  }

  @override
  String get notifPaymentFailedTitle => 'Payment failed';

  @override
  String notifPaymentFailedBody(String amount) {
    return 'Your $amount FCFA payment didn\'t go through. Nothing was charged – you can try again.';
  }

  @override
  String get notifProActivatedTitle => 'Pro activated';

  @override
  String get notifProActivatedBody =>
      'Unlimited posts, agreements and Reach are now unlocked.';

  @override
  String get receiptTitle => 'PAYMENT RECEIPT';

  @override
  String receiptNumber(String number) {
    return 'Receipt no. $number';
  }

  @override
  String get receiptPaid => 'PAID';

  @override
  String get receiptBilledTo => 'Billed to';

  @override
  String get receiptPaymentDetails => 'Payment details';

  @override
  String get receiptReason => 'Reason for payment';

  @override
  String get receiptAmount => 'Amount';

  @override
  String get receiptTotalPaid => 'Total paid';

  @override
  String get receiptTransactionId => 'Transaction ID';

  @override
  String get receiptReference => 'SplitSure reference';

  @override
  String get receiptDate => 'Date of transaction';

  @override
  String get receiptPaymentMethod => 'Payment method';

  @override
  String get receiptPhoneUsed => 'Phone number used';

  @override
  String get receiptAccountType => 'Current account type';

  @override
  String get receiptCustomerName => 'Name';

  @override
  String get receiptDescPro => 'SplitSure Pro upgrade (one-time)';

  @override
  String get receiptDescAgreement => 'Final agreement generation';

  @override
  String get receiptThanks => 'Thank you for using SplitSure.';

  @override
  String get receiptFooterNote =>
      'This receipt was generated electronically and is valid without a signature.';

  @override
  String receiptIssuedOn(String date) {
    return 'Issued $date';
  }

  @override
  String get downloadReceipt => 'Download receipt';

  @override
  String receiptError(String error) {
    return 'Could not create the receipt: $error';
  }

  @override
  String sentForReviewEmailed(int count) {
    return 'Agreement sent for review. $count collaborator(s) were e-mailed.';
  }

  @override
  String newVersionSentEmailed(int count) {
    return 'New version sent. $count collaborator(s) were e-mailed.';
  }

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get orDivider => 'or';

  @override
  String get googleSignInUnavailable =>
      'Google sign-in isn\'t available yet. Please use your e-mail and password for now.';

  @override
  String googleSignInFailed(String error) {
    return 'Google sign-in failed: $error';
  }

  @override
  String get acceptTermsFirst =>
      'Please accept the terms and conditions first.';

  @override
  String get planBadgeBasic => 'BASIC';

  @override
  String get planBadgeTooltipBasic => 'Basic plan – tap to see Pro';

  @override
  String get planBadgeTooltipPro => 'Pro plan active';

  @override
  String reachHeadlineBy(String title, String artist) {
    return '🎵 \"$title\" by $artist is out now!';
  }

  @override
  String get reachLinkInBio => 'Link in bio';

  @override
  String get reachPostTitle => 'Post to your socials';

  @override
  String get reachPostHint =>
      'Each platform gets its own caption. On a phone, Share opens the app with the video and caption ready; on a computer the caption is copied, the video downloaded and the upload page opened.';

  @override
  String get reachShare => 'Share';

  @override
  String get reachCopyCaption => 'Copy caption';

  @override
  String get reachLinked => 'Linked';

  @override
  String get reachOpenMyPage => 'Open my page';

  @override
  String get reachSharedToApp => 'Caption copied – finish posting in the app.';

  @override
  String get reachOpenedWeb =>
      'Caption copied. Paste it on the page that just opened (the video was downloaded if needed).';

  @override
  String reachNeedsVideo(String platform) {
    return 'Create the promo video above first – $platform posts need a video.';
  }

  @override
  String get reachContentPack => 'Download content pack';

  @override
  String get reachContentPackHint =>
      'Video + a text file with every caption, to post by hand.';

  @override
  String get reachContentPackDone => 'Content pack downloaded.';

  @override
  String get reachRegenerate => 'Regenerate';

  @override
  String get reachPreviewCaption => 'Preview caption';

  @override
  String get forgotTitle => 'Forgot your password?';

  @override
  String get forgotSubtitle =>
      'Enter the email you use for SplitSure. We\'ll send you a reset code and a secure link.';

  @override
  String get forgotSend => 'Send reset code';

  @override
  String get forgotRemembered => 'Remembered it?';

  @override
  String get codeTitle => 'Check your email';

  @override
  String codeSubtitle(String email) {
    return 'We sent a reset code to $email. Enter it below, or simply tap the link in that email.';
  }

  @override
  String get codeLabel => 'Reset code';

  @override
  String get codeVerify => 'Verify code';

  @override
  String get codeResend => 'Resend code';

  @override
  String codeResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get codeSent => 'A new code is on its way.';

  @override
  String get codeInvalid =>
      'That code is wrong or has expired. Use the latest email, or resend a new code.';

  @override
  String get codeChangeEmail => 'Use a different email';

  @override
  String get codeSpamHint => 'Can\'t find it? Check your spam folder.';

  @override
  String get newPassTitle => 'Create a new password';

  @override
  String get newPassSubtitle =>
      'Choose a strong password you haven\'t used before.';

  @override
  String get newPassLabel => 'New password';

  @override
  String get newPassConfirm => 'Confirm new password';

  @override
  String get newPassSave => 'Update password';

  @override
  String get passMismatch => 'Passwords don\'t match';

  @override
  String get passTooShort => 'Use at least 8 characters';

  @override
  String passStrength(String level) {
    return 'Strength: $level';
  }

  @override
  String get passWeak => 'Weak';

  @override
  String get passFair => 'Fair';

  @override
  String get passStrong => 'Strong';

  @override
  String get passwordUpdatedTitle => 'Password updated';

  @override
  String get passwordUpdatedBody =>
      'Your password has been changed. Use it the next time you sign in.';

  @override
  String get continueToApp => 'Continue to SplitSure';

  @override
  String get tooManyRequests =>
      'Please wait a moment before requesting another code.';

  @override
  String get termsTitle => 'Terms & Conditions';

  @override
  String termsLastUpdated(String date) {
    return 'Last updated $date';
  }

  @override
  String get termsIntro =>
      'Please read these terms carefully. They explain your rights and responsibilities when you use SplitSure.';

  @override
  String get termsContents => 'Contents';

  @override
  String get termsAgree => 'I agree to the terms';

  @override
  String get termsReadLink => 'Read the Terms & Conditions';

  @override
  String get termsBackToTop => 'Back to top';

  @override
  String get approveTitle => 'Review & sign the agreement';

  @override
  String approveIntro(String owner, String song) {
    return '$owner invites you to approve the split agreement for “$song”.';
  }

  @override
  String get approveYourShare => 'Your share';

  @override
  String get approveYourRole => 'Your role';

  @override
  String get approveParties => 'All parties';

  @override
  String get approveLegal =>
      'By tapping “Approve & sign” you accept these terms. Your electronic signature code is recorded with the date and printed on the agreement document.';

  @override
  String get approveButton => 'Approve & sign';

  @override
  String get approveChanges => 'Request changes or decline';

  @override
  String get approveSignedTitle => 'Signed!';

  @override
  String get approveSignedBody =>
      'Your approval is recorded. This signature code now appears on the agreement document. We also e-mailed you a copy.';

  @override
  String get approveAlreadySigned => 'You already signed this agreement.';

  @override
  String get approveAllSigned =>
      'Every party has approved – the agreement is complete.';

  @override
  String get approveWaitingOthers =>
      'Waiting for the other parties to approve.';

  @override
  String get approveInvalid =>
      'This approval link is not valid. Open the latest e-mail from SplitSure.';

  @override
  String get approveExpired =>
      'This approval link has expired. Ask the creator to send the agreement again.';

  @override
  String get approveNewerVersion =>
      'This agreement has been updated since this e-mail. Use the link in the newest e-mail.';

  @override
  String get approveClosed => 'This agreement is no longer open for approval.';

  @override
  String get approveOpenApp => 'Open SplitSure';

  @override
  String get signatureCode => 'Signature code';

  @override
  String get signedViaEmail => 'Signed electronically by e-mail';

  @override
  String get signedViaApp => 'Signed electronically in SplitSure';

  @override
  String pdfSignedOn(String date) {
    return 'Signed $date';
  }

  @override
  String get planAgreementLimitBody =>
      'On the Basic plan your first agreement document is free; each extra one costs 50 FCFA to preview and download. Pro includes them all.';

  @override
  String get verifyTitle => 'Confirm your email';

  @override
  String verifySubtitle(String email) {
    return 'We\'ve sent a 6-digit code to $email. Enter it below to confirm your email and activate your SplitSure account.';
  }

  @override
  String get verifyButton => 'Activate my account';

  @override
  String get verifyFrom => 'The email comes from SplitSure.';

  @override
  String get verifySuccessTitle => 'Email confirmed!';

  @override
  String get verifySuccessBody =>
      'Your account is active. Let\'s pick your plan.';

  @override
  String get verifyWrongEmail => 'Wrong email? Sign up again';

  @override
  String get verifyStepAccount => 'Account';

  @override
  String get verifyStepVerify => 'Verify';

  @override
  String get verifyStepPlan => 'Plan';

  @override
  String get verifyNotConfirmed =>
      'Please confirm your email first. We\'ve sent you a new code.';

  @override
  String get verifyAlreadyConfirmed =>
      'This email is already confirmed. Please sign in.';

  @override
  String passportGateTitle(String name) {
    return 'View $name\'s Music Passport';
  }

  @override
  String passportGateBody(String name) {
    return '$name shared their Music Passport with you on SplitSure. Create a free account (or sign in) to see their full profile, portfolio and contact details.';
  }

  @override
  String get passportGateCreate => 'Create a free account';

  @override
  String get passportGateSignIn => 'I already have an account';

  @override
  String get passportGateBack => 'You\'ll come straight back to this passport.';

  @override
  String get passportGatePerk1 => 'Full profile, skills and genres';

  @override
  String get passportGatePerk2 => 'Portfolio and released work';

  @override
  String get passportGatePerk3 => 'Contact and collaborate safely';

  @override
  String get passportGateLocked => 'Members only';

  @override
  String uploadingPercent(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get videoPreparing => 'Getting your song and artwork ready…';

  @override
  String videoUploading(int percent) {
    return 'Saving your video… $percent%';
  }

  @override
  String get videoSavedLocallyHint =>
      'You can watch it now – it is being saved in the background.';

  @override
  String get audienceAndRelease => 'Audience & release';

  @override
  String get witnessConfirmed => 'Witness confirmed';

  @override
  String get witnessDeclined => 'Witness declined';

  @override
  String get witnessWaiting => 'Waiting for the witness to confirm';

  @override
  String get witnessCode => 'Witness code';

  @override
  String get witnessResponseNeeded => 'You are the witness of this agreement';

  @override
  String get witnessResponseIntro =>
      'Confirm that you witnessed this agreement between the collaborators below, or decline if you did not.';

  @override
  String get witnessConfirmButton => 'Confirm as witness';

  @override
  String get witnessConfirmQuestion =>
      'Confirm that you witnessed this agreement? Your witness code will be printed on the document.';

  @override
  String get witnessConfirmedToast => 'You confirmed as witness.';

  @override
  String get witnessDeclinedToast => 'You declined to witness this agreement.';

  @override
  String get witnessDeclineTitle => 'Decline as witness?';

  @override
  String get witnessDeclineQuestion =>
      'The creator will be told that you did not witness this agreement.';

  @override
  String get witnessApproveTitle => 'Confirm as witness';

  @override
  String witnessApproveIntro(String owner, String song) {
    return '$owner named you as the witness of the agreement for \"$song\".';
  }

  @override
  String get witnessApproveLegal =>
      'By confirming, you attest that you witnessed this agreement between the parties listed above. No account is needed.';

  @override
  String get witnessSignedTitle => 'Witness confirmation recorded';

  @override
  String get witnessSignedBody =>
      'Thank you. Your witness code below is printed on the agreement document.';

  @override
  String get witnessDeclinedTitle => 'You declined to witness this agreement';

  @override
  String get witnessDeclinedBody =>
      'The creator of the agreement has been notified.';

  @override
  String get witnessEmailHint =>
      'The witness receives an e-mail to confirm or decline the agreement, even without a SplitSure account.';

  @override
  String get notifWitnessInvitedTitle => 'You are asked to be a witness';

  @override
  String notifWitnessInvitedBody(String song) {
    return 'Confirm or decline the agreement for \"$song\".';
  }

  @override
  String get notifWitnessConfirmedTitle => 'Witness confirmed';

  @override
  String notifWitnessConfirmedBody(String name, String song) {
    return '$name confirmed as witness of \"$song\".';
  }

  @override
  String get notifWitnessDeclinedTitle => 'Witness declined';

  @override
  String notifWitnessDeclinedBody(String name, String song) {
    return '$name declined to witness \"$song\".';
  }

  @override
  String get successfulCollaborations => 'Successful collaborations';

  @override
  String get successfulCollaborationsHint =>
      'Agreements approved by every party';

  @override
  String get noSuccessfulCollaborations =>
      'No successful collaborations yet. They appear here once every party has approved an agreement.';

  @override
  String get acceptedCollaborations => 'Accepted collaborations';

  @override
  String get acceptedCollaborationsHint =>
      'Opportunities where your application was accepted';

  @override
  String get noAcceptedCollaborations =>
      'None yet. When you apply to an opportunity in the Hub and are accepted, it shows here.';

  @override
  String get supportChatTooltip => 'Chat with SplitSure support on WhatsApp';

  @override
  String get supportChatTitle => 'Need help?';

  @override
  String get supportChatSubtitle => 'Chat with support';

  @override
  String get logoutTitle => 'Log out of SplitSure?';

  @override
  String get stayLoggedIn => 'Stay';

  @override
  String get welcomeBackPlain => 'Welcome back!';

  @override
  String get greatToSeeYou => 'Great to see you again!';

  @override
  String get witnessNotAskedYet =>
      'The witness hasn\'t been asked to confirm this agreement yet.';

  @override
  String get askWitnessButton => 'Ask the witness to confirm';

  @override
  String get askWitnessConfirm =>
      'The witness will be asked to confirm or decline this agreement. It will only be fully accepted once they confirm.';

  @override
  String get witnessAskedEmailed =>
      'The witness has been e-mailed and notified.';

  @override
  String get witnessAskedInApp =>
      'The witness has been asked. They\'ll be e-mailed once e-mail sending is set up.';

  @override
  String get verifySendFailed =>
      'We couldn\'t send the code right now. Tap \"Resend code\" in a moment.';

  @override
  String get aboutTitle => 'About SplitSure';

  @override
  String get aboutTagline => 'Protect your music. Promote your sound.';

  @override
  String get aboutWhatTitle => 'What is SplitSure?';

  @override
  String get aboutWhatBody =>
      'SplitSure is the home of music collaboration. Agree on who did what and who earns what, sign it together, and keep a clear record for every song – then promote your release and grow your network.';

  @override
  String get aboutCameroonTitle => 'Made for Cameroon';

  @override
  String get aboutCameroonBody =>
      'SplitSure is built first and foremost for Cameroonian artists, producers, songwriters and music professionals – from Douala to Yaoundé, Bamenda, Bafoussam and beyond – so that every collaboration is fair, documented and respected.';

  @override
  String get aboutCameroonPay => 'MTN Mobile Money & Orange Money';

  @override
  String get aboutCameroonLang => 'English & Français';

  @override
  String get aboutCameroonPrice => 'Prices in FCFA';

  @override
  String get aboutFeaturesTitle => 'What you can do';

  @override
  String get aboutFeatProtect => 'Split agreements every collaborator signs';

  @override
  String get aboutFeatPassport => 'Your professional music identity';

  @override
  String get aboutFeatHub => 'Find and post collaborations';

  @override
  String get aboutFeatReach => 'Promo videos and captions for your release';

  @override
  String get aboutFeatDealflow => 'Agree on terms before you sign';

  @override
  String get aboutPromiseTitle => 'Our promise';

  @override
  String get aboutPromiseBody =>
      'Your music stays yours. Every signature is recorded with a unique code, every version is kept, and nothing is shared publicly unless you choose to.';

  @override
  String get aboutSupportTitle => 'Contact support';

  @override
  String get aboutSupportBody =>
      'A question, a problem or an idea? Write to us by e-mail – we usually reply within 24 hours.';

  @override
  String get aboutSupportCopied => 'E-mail address copied';

  @override
  String get aboutMadeWithLove => 'Made with love in Cameroon';

  @override
  String previewPdfFeeSubtitle(String amount) {
    return '$amount to preview and download this agreement';
  }

  @override
  String get previewPdfFirstFree => 'Your first agreement is free';

  @override
  String get previewPdfUnlocked => 'Paid – preview and download unlocked';

  @override
  String get finalAgreementFirstFree => 'Free – your first agreement';

  @override
  String get payToPreviewTitle => 'Unlock this agreement document';
}
