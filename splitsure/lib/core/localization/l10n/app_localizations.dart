import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SplitSure'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Protect your music.\nPromote your sound.'**
  String get tagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Protect Your Collaboration'**
  String get onboarding1Title;

  /// No description provided for @onboarding1TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get onboarding1TitleAccent;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create secure agreements: define collaboration terms, ownership percentages and each contributor\'s responsibilities.'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Promote Your Music'**
  String get onboarding2Title;

  /// No description provided for @onboarding2TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get onboarding2TitleAccent;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create promotional videos, captions and content for your releases, ready to share on TikTok, Instagram, Facebook and YouTube.'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Manage Your Projects'**
  String get onboarding3Title;

  /// No description provided for @onboarding3TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get onboarding3TitleAccent;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep all your collaborations and music projects organised in one place.'**
  String get onboarding3Subtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get username;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login;

  /// No description provided for @termsAccept.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get termsAccept;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms to continue'**
  String get mustAcceptTerms;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @myProjects.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjects;

  /// No description provided for @protect.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get protect;

  /// No description provided for @reach.
  ///
  /// In en, this message translates to:
  /// **'Reach'**
  String get reach;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcome;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Music Project'**
  String get createProject;

  /// No description provided for @recentProjects.
  ///
  /// In en, this message translates to:
  /// **'Recent Projects'**
  String get recentProjects;

  /// No description provided for @pendingAgreements.
  ///
  /// In en, this message translates to:
  /// **'Pending Agreements'**
  String get pendingAgreements;

  /// No description provided for @subscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionStatus;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Basic Plan'**
  String get freePlan;

  /// No description provided for @monthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get monthlyPlan;

  /// No description provided for @quarterlyPlan.
  ///
  /// In en, this message translates to:
  /// **'3-Month Plan'**
  String get quarterlyPlan;

  /// No description provided for @annualPlan.
  ///
  /// In en, this message translates to:
  /// **'Annual Plan'**
  String get annualPlan;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your language'**
  String get selectLanguage;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @onboarding1TitleRest.
  ///
  /// In en, this message translates to:
  /// **' Your\nCollaboration'**
  String get onboarding1TitleRest;

  /// No description provided for @onboarding2TitleRest.
  ///
  /// In en, this message translates to:
  /// **' Your\nMusic'**
  String get onboarding2TitleRest;

  /// No description provided for @onboarding3TitleRest.
  ///
  /// In en, this message translates to:
  /// **' Your\nProjects'**
  String get onboarding3TitleRest;

  /// No description provided for @chooseLanguageBilingual.
  ///
  /// In en, this message translates to:
  /// **'Choose your language / Choisissez votre langue'**
  String get chooseLanguageBilingual;

  /// No description provided for @welcomeFooter.
  ///
  /// In en, this message translates to:
  /// **'Join a growing community of artists and creators'**
  String get welcomeFooter;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a reset link.'**
  String get resetPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String errorWithDetails(String details);

  /// No description provided for @accountCreatedCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please check your email to confirm.'**
  String get accountCreatedCheckEmail;

  /// No description provided for @countryCameroon.
  ///
  /// In en, this message translates to:
  /// **'Cameroon'**
  String get countryCameroon;

  /// No description provided for @countryNigeria.
  ///
  /// In en, this message translates to:
  /// **'Nigeria'**
  String get countryNigeria;

  /// No description provided for @countryGhana.
  ///
  /// In en, this message translates to:
  /// **'Ghana'**
  String get countryGhana;

  /// No description provided for @countrySouthAfrica.
  ///
  /// In en, this message translates to:
  /// **'South Africa'**
  String get countrySouthAfrica;

  /// No description provided for @countryKenya.
  ///
  /// In en, this message translates to:
  /// **'Kenya'**
  String get countryKenya;

  /// No description provided for @countryFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get countryFrance;

  /// No description provided for @countryUnitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get countryUnitedStates;

  /// No description provided for @countryUnitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get countryUnitedKingdom;

  /// No description provided for @countryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get countryOther;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending acceptance'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get statusChangesRequested;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @statusContentGenerated.
  ///
  /// In en, this message translates to:
  /// **'Content generated'**
  String get statusContentGenerated;

  /// No description provided for @statusReadyToShare.
  ///
  /// In en, this message translates to:
  /// **'Ready to share'**
  String get statusReadyToShare;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @roleArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get roleArtist;

  /// No description provided for @roleProducer.
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get roleProducer;

  /// No description provided for @roleSongwriter.
  ///
  /// In en, this message translates to:
  /// **'Songwriter'**
  String get roleSongwriter;

  /// No description provided for @roleBeatmaker.
  ///
  /// In en, this message translates to:
  /// **'Beatmaker'**
  String get roleBeatmaker;

  /// No description provided for @roleFeaturedArtist.
  ///
  /// In en, this message translates to:
  /// **'Featured artist'**
  String get roleFeaturedArtist;

  /// No description provided for @roleComposer.
  ///
  /// In en, this message translates to:
  /// **'Composer'**
  String get roleComposer;

  /// No description provided for @roleSoundEngineer.
  ///
  /// In en, this message translates to:
  /// **'Sound engineer'**
  String get roleSoundEngineer;

  /// No description provided for @roleMusicManager.
  ///
  /// In en, this message translates to:
  /// **'Music manager'**
  String get roleMusicManager;

  /// No description provided for @roleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get roleOther;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingWithComma.
  ///
  /// In en, this message translates to:
  /// **'{greeting},'**
  String greetingWithComma(String greeting);

  /// No description provided for @defaultArtistName.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get defaultArtistName;

  /// No description provided for @agreementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Agreements'**
  String get agreementsLabel;

  /// No description provided for @campaignsLabel.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaignsLabel;

  /// No description provided for @agreementCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No agreements} =1{1 agreement} other{{count} agreements}}'**
  String agreementCount(int count);

  /// No description provided for @campaignCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No campaigns} =1{1 campaign} other{{count} campaigns}}'**
  String campaignCount(int count);

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @protectModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'SplitSure Protect'**
  String get protectModuleTitle;

  /// No description provided for @protectModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your collaborations with split agreements.'**
  String get protectModuleSubtitle;

  /// No description provided for @reachModuleTitle.
  ///
  /// In en, this message translates to:
  /// **'SplitSure Reach'**
  String get reachModuleTitle;

  /// No description provided for @reachModuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create promotional content for your releases.'**
  String get reachModuleSubtitle;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @activityAgreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement · {status}'**
  String activityAgreement(String status);

  /// No description provided for @activityCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign · {status}'**
  String activityCampaign(String status);

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @newAgreement.
  ///
  /// In en, this message translates to:
  /// **'New Agreement'**
  String get newAgreement;

  /// No description provided for @newCampaign.
  ///
  /// In en, this message translates to:
  /// **'New Campaign'**
  String get newCampaign;

  /// No description provided for @fullAccessActive.
  ///
  /// In en, this message translates to:
  /// **'Full access active'**
  String get fullAccessActive;

  /// No description provided for @upgradeForFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock all features'**
  String get upgradeForFullAccess;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @collaborationAgreements.
  ///
  /// In en, this message translates to:
  /// **'Collaboration agreements'**
  String get collaborationAgreements;

  /// No description provided for @newShort.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newShort;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noAgreementsYet.
  ///
  /// In en, this message translates to:
  /// **'No agreements yet'**
  String get noAgreementsYet;

  /// No description provided for @noAgreementsHint.
  ///
  /// In en, this message translates to:
  /// **'Protect your music collaborations by creating split agreements.'**
  String get noAgreementsHint;

  /// No description provided for @splitsMustTotal100.
  ///
  /// In en, this message translates to:
  /// **'Split percentages must total 100%'**
  String get splitsMustTotal100;

  /// No description provided for @createAgreement.
  ///
  /// In en, this message translates to:
  /// **'Create Agreement'**
  String get createAgreement;

  /// No description provided for @songInformation.
  ///
  /// In en, this message translates to:
  /// **'Song Information'**
  String get songInformation;

  /// No description provided for @stepOf3.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 3'**
  String stepOf3(String step);

  /// No description provided for @step3Optional.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3 (Optional)'**
  String get step3Optional;

  /// No description provided for @songTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Song Title *'**
  String get songTitleRequired;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @musicGenre.
  ///
  /// In en, this message translates to:
  /// **'Music Genre'**
  String get musicGenre;

  /// No description provided for @musicGenreHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Afrobeats, Hip-Hop'**
  String get musicGenreHint;

  /// No description provided for @songDescription.
  ///
  /// In en, this message translates to:
  /// **'Song Description'**
  String get songDescription;

  /// No description provided for @scopeOfRights.
  ///
  /// In en, this message translates to:
  /// **'Scope of Rights'**
  String get scopeOfRights;

  /// No description provided for @scopeOfRightsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Master recording, composition, lyrics...'**
  String get scopeOfRightsHint;

  /// No description provided for @additionalTermsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Terms (optional)'**
  String get additionalTermsOptional;

  /// No description provided for @recordingDate.
  ///
  /// In en, this message translates to:
  /// **'Recording Date'**
  String get recordingDate;

  /// No description provided for @expectedReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Release Date'**
  String get expectedReleaseDate;

  /// No description provided for @effectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective Date'**
  String get effectiveDate;

  /// No description provided for @uploadCoverArtOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload Cover Art (optional)'**
  String get uploadCoverArtOptional;

  /// No description provided for @legalInfoNotice.
  ///
  /// In en, this message translates to:
  /// **'This agreement is for informational purposes. Obtain independent legal advice for binding contracts.'**
  String get legalInfoNotice;

  /// No description provided for @collaboratorsAndSplits.
  ///
  /// In en, this message translates to:
  /// **'Collaborators & Splits'**
  String get collaboratorsAndSplits;

  /// No description provided for @collaborators.
  ///
  /// In en, this message translates to:
  /// **'Collaborators'**
  String get collaborators;

  /// No description provided for @splitTotalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}% · Remaining: {remaining}%'**
  String splitTotalRemaining(String total, String remaining);

  /// No description provided for @addCollaborator.
  ///
  /// In en, this message translates to:
  /// **'Add Collaborator'**
  String get addCollaborator;

  /// No description provided for @noCollaboratorsHint.
  ///
  /// In en, this message translates to:
  /// **'You can create the agreement without collaborators and add them later.'**
  String get noCollaboratorsHint;

  /// No description provided for @witnessLegalRep.
  ///
  /// In en, this message translates to:
  /// **'Witness / Legal Representative'**
  String get witnessLegalRep;

  /// No description provided for @addWitness.
  ///
  /// In en, this message translates to:
  /// **'Add Witness'**
  String get addWitness;

  /// No description provided for @addWitnessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — a person who witnesses the agreement'**
  String get addWitnessSubtitle;

  /// No description provided for @addLegalRep.
  ///
  /// In en, this message translates to:
  /// **'Add Legal Representative'**
  String get addLegalRep;

  /// No description provided for @addLegalRepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — a lawyer or legal advisor'**
  String get addLegalRepSubtitle;

  /// No description provided for @witnessLawyerDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer: Adding a witness or lawyer here does not constitute their legal approval. SplitSure does not replace qualified legal counsel. Parties should seek independent legal advice.'**
  String get witnessLawyerDisclaimer;

  /// No description provided for @witnessFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Witness Full Name *'**
  String get witnessFullNameRequired;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @roleRelationshipOptional.
  ///
  /// In en, this message translates to:
  /// **'Role / Relationship (optional)'**
  String get roleRelationshipOptional;

  /// No description provided for @lawyerFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Lawyer Full Name *'**
  String get lawyerFullNameRequired;

  /// No description provided for @lawFirmOptional.
  ///
  /// In en, this message translates to:
  /// **'Law Firm (optional)'**
  String get lawFirmOptional;

  /// No description provided for @professionalRegistrationOptional.
  ///
  /// In en, this message translates to:
  /// **'Professional Registration (optional)'**
  String get professionalRegistrationOptional;

  /// No description provided for @collaboratorNumber.
  ///
  /// In en, this message translates to:
  /// **'Collaborator {number}'**
  String collaboratorNumber(String number);

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameRequired;

  /// No description provided for @percentRequired.
  ///
  /// In en, this message translates to:
  /// **'% *'**
  String get percentRequired;

  /// No description provided for @requiredShort.
  ///
  /// In en, this message translates to:
  /// **'Req.'**
  String get requiredShort;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @collaboratorRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'Role (e.g. Producer, Vocalist) *'**
  String get collaboratorRoleRequired;

  /// No description provided for @contributionDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Contribution description (optional)'**
  String get contributionDescriptionOptional;

  /// No description provided for @responseRecorded.
  ///
  /// In en, this message translates to:
  /// **'Response recorded: {response}'**
  String responseRecorded(String response);

  /// No description provided for @statusUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Status updated to {status}'**
  String statusUpdatedTo(String status);

  /// No description provided for @pdfError.
  ///
  /// In en, this message translates to:
  /// **'PDF error: {details}'**
  String pdfError(String details);

  /// No description provided for @agreementActions.
  ///
  /// In en, this message translates to:
  /// **'Agreement Actions'**
  String get agreementActions;

  /// No description provided for @sendForReview.
  ///
  /// In en, this message translates to:
  /// **'Send for Review'**
  String get sendForReview;

  /// No description provided for @markAccepted.
  ///
  /// In en, this message translates to:
  /// **'Mark Accepted'**
  String get markAccepted;

  /// No description provided for @respondToAgreement.
  ///
  /// In en, this message translates to:
  /// **'Respond to Agreement'**
  String get respondToAgreement;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @requestChanges.
  ///
  /// In en, this message translates to:
  /// **'Request Changes'**
  String get requestChanges;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @songDetails.
  ///
  /// In en, this message translates to:
  /// **'Song Details'**
  String get songDetails;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @additionalTerms.
  ///
  /// In en, this message translates to:
  /// **'Additional Terms'**
  String get additionalTerms;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @witness.
  ///
  /// In en, this message translates to:
  /// **'Witness'**
  String get witness;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @emailShort.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailShort;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @legalRepresentative.
  ///
  /// In en, this message translates to:
  /// **'Legal Representative'**
  String get legalRepresentative;

  /// No description provided for @firm.
  ///
  /// In en, this message translates to:
  /// **'Firm'**
  String get firm;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @exportAndShare.
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get exportAndShare;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @downloadPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a PDF copy of this agreement'**
  String get downloadPdfSubtitle;

  /// No description provided for @copyAgreementId.
  ///
  /// In en, this message translates to:
  /// **'Copy Agreement ID'**
  String get copyAgreementId;

  /// No description provided for @agreementIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Agreement ID copied'**
  String get agreementIdCopied;

  /// No description provided for @recordKeepingDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer: This agreement is for record-keeping purposes. SplitSure does not provide legal advice. Consult a qualified legal professional for binding agreements.'**
  String get recordKeepingDisclaimer;

  /// No description provided for @songProjectInformation.
  ///
  /// In en, this message translates to:
  /// **'Song / Project Information'**
  String get songProjectInformation;

  /// No description provided for @songTitle.
  ///
  /// In en, this message translates to:
  /// **'Song Title'**
  String get songTitle;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @agreementStatus.
  ///
  /// In en, this message translates to:
  /// **'Agreement Status'**
  String get agreementStatus;

  /// No description provided for @collaboratorsRevenueShares.
  ///
  /// In en, this message translates to:
  /// **'Collaborators & Revenue Shares'**
  String get collaboratorsRevenueShares;

  /// No description provided for @roleRelationship.
  ///
  /// In en, this message translates to:
  /// **'Role / Relationship'**
  String get roleRelationship;

  /// No description provided for @lawFirm.
  ///
  /// In en, this message translates to:
  /// **'Law Firm'**
  String get lawFirm;

  /// No description provided for @pdfTaglineOneLine.
  ///
  /// In en, this message translates to:
  /// **'Protect your music. Promote your sound.'**
  String get pdfTaglineOneLine;

  /// No description provided for @collaborationAgreementCaps.
  ///
  /// In en, this message translates to:
  /// **'COLLABORATION AGREEMENT'**
  String get collaborationAgreementCaps;

  /// No description provided for @contribution.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get contribution;

  /// No description provided for @sharePercent.
  ///
  /// In en, this message translates to:
  /// **'Share %'**
  String get sharePercent;

  /// No description provided for @acceptanceSignatures.
  ///
  /// In en, this message translates to:
  /// **'Acceptance & Signatures'**
  String get acceptanceSignatures;

  /// No description provided for @pdfAcceptanceIntro.
  ///
  /// In en, this message translates to:
  /// **'The acceptance status of each party is recorded below.'**
  String get pdfAcceptanceIntro;

  /// No description provided for @signatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Signature:'**
  String get signatureLabel;

  /// No description provided for @dateBlank.
  ///
  /// In en, this message translates to:
  /// **'Date: ___________'**
  String get dateBlank;

  /// No description provided for @pdfReference.
  ///
  /// In en, this message translates to:
  /// **'Ref: {ref}'**
  String pdfReference(String ref);

  /// No description provided for @pdfPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pdfPageOf(String page, String total);

  /// No description provided for @pdfTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}%'**
  String pdfTotal(String total);

  /// No description provided for @pdfPartyStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String pdfPartyStatus(String status);

  /// No description provided for @pdfAwaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get pdfAwaitingResponse;

  /// No description provided for @pdfAcceptedOn.
  ///
  /// In en, this message translates to:
  /// **'Accepted: {date}'**
  String pdfAcceptedOn(String date);

  /// No description provided for @pdfDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'DISCLAIMER: This document is generated by SplitSure for record-keeping purposes only. It does not constitute legal advice. The parties are encouraged to seek independent legal counsel before relying on this agreement as a binding contract. SplitSure does not guarantee the legal enforceability of this document in any jurisdiction.'**
  String get pdfDisclaimer;

  /// No description provided for @promotionCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Promotion campaigns'**
  String get promotionCampaigns;

  /// No description provided for @noCampaignsYet.
  ///
  /// In en, this message translates to:
  /// **'No campaigns yet'**
  String get noCampaignsYet;

  /// No description provided for @noCampaignsHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first campaign to turn a release into promotional content.'**
  String get noCampaignsHint;

  /// No description provided for @contentGeneratedLabel.
  ///
  /// In en, this message translates to:
  /// **'Content generated'**
  String get contentGeneratedLabel;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error: {details}'**
  String uploadError(String details);

  /// No description provided for @editCampaign.
  ///
  /// In en, this message translates to:
  /// **'Edit Campaign'**
  String get editCampaign;

  /// No description provided for @campaignInfo.
  ///
  /// In en, this message translates to:
  /// **'Campaign Info'**
  String get campaignInfo;

  /// No description provided for @campaignNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Campaign Name (optional)'**
  String get campaignNameOptional;

  /// No description provided for @musicDescription.
  ///
  /// In en, this message translates to:
  /// **'Music Description'**
  String get musicDescription;

  /// No description provided for @promotionalMessage.
  ///
  /// In en, this message translates to:
  /// **'Promotional Message'**
  String get promotionalMessage;

  /// No description provided for @promotionalMessageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My new single is out now!'**
  String get promotionalMessageHint;

  /// No description provided for @streamingLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Streaming Link (optional)'**
  String get streamingLinkOptional;

  /// No description provided for @mediaAssets.
  ///
  /// In en, this message translates to:
  /// **'Media Assets'**
  String get mediaAssets;

  /// No description provided for @coverArt.
  ///
  /// In en, this message translates to:
  /// **'Cover Art'**
  String get coverArt;

  /// No description provided for @musicFileFormats.
  ///
  /// In en, this message translates to:
  /// **'Music File (MP3 / WAV)'**
  String get musicFileFormats;

  /// No description provided for @audienceAndBudget.
  ///
  /// In en, this message translates to:
  /// **'Audience & Budget'**
  String get audienceAndBudget;

  /// No description provided for @targetAudienceOptional.
  ///
  /// In en, this message translates to:
  /// **'Target Audience (optional)'**
  String get targetAudienceOptional;

  /// No description provided for @targetAudienceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Afrobeats fans, 18-35'**
  String get targetAudienceHint;

  /// No description provided for @budgetFcfa.
  ///
  /// In en, this message translates to:
  /// **'Budget (FCFA)'**
  String get budgetFcfa;

  /// No description provided for @releaseOn.
  ///
  /// In en, this message translates to:
  /// **'Release: {date}'**
  String releaseOn(String date);

  /// No description provided for @releaseDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Release Date (optional)'**
  String get releaseDateOptional;

  /// No description provided for @platforms.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get platforms;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @createCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create Campaign'**
  String get createCampaign;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUpload;

  /// No description provided for @snippetSaved.
  ///
  /// In en, this message translates to:
  /// **'Snippet saved!'**
  String get snippetSaved;

  /// No description provided for @contentGeneratedSnack.
  ///
  /// In en, this message translates to:
  /// **'Content generated!'**
  String get contentGeneratedSnack;

  /// No description provided for @copiedLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} copied!'**
  String copiedLabel(String label);

  /// No description provided for @campaignDetails.
  ///
  /// In en, this message translates to:
  /// **'Campaign Details'**
  String get campaignDetails;

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// No description provided for @streamingLink.
  ///
  /// In en, this message translates to:
  /// **'Streaming Link'**
  String get streamingLink;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @amountFcfa.
  ///
  /// In en, this message translates to:
  /// **'{amount} FCFA'**
  String amountFcfa(String amount);

  /// No description provided for @songSnippet.
  ///
  /// In en, this message translates to:
  /// **'Song Snippet'**
  String get songSnippet;

  /// No description provided for @loadingAudio.
  ///
  /// In en, this message translates to:
  /// **'Loading audio...'**
  String get loadingAudio;

  /// No description provided for @generatePromoContent.
  ///
  /// In en, this message translates to:
  /// **'Generate Promotional Content'**
  String get generatePromoContent;

  /// No description provided for @generatePromoContentHint.
  ///
  /// In en, this message translates to:
  /// **'Generate captions, hashtags and a promotional announcement for your campaign.'**
  String get generatePromoContentHint;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @generateContent.
  ///
  /// In en, this message translates to:
  /// **'Generate Content'**
  String get generateContent;

  /// No description provided for @generatedCaption.
  ///
  /// In en, this message translates to:
  /// **'Generated Caption'**
  String get generatedCaption;

  /// No description provided for @caption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get caption;

  /// No description provided for @hashtags.
  ///
  /// In en, this message translates to:
  /// **'Hashtags'**
  String get hashtags;

  /// No description provided for @promotionalVideo.
  ///
  /// In en, this message translates to:
  /// **'Promotional Video'**
  String get promotionalVideo;

  /// No description provided for @videoBackendNotice.
  ///
  /// In en, this message translates to:
  /// **'Video generation requires a backend service. Download your cover art and use a tool like CapCut or Canva to create a 9:16 promo video with your snippet.'**
  String get videoBackendNotice;

  /// No description provided for @coverArtUrl.
  ///
  /// In en, this message translates to:
  /// **'Cover art URL'**
  String get coverArtUrl;

  /// No description provided for @copyCoverArtUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy Cover Art URL'**
  String get copyCoverArtUrl;

  /// No description provided for @shareOn.
  ///
  /// In en, this message translates to:
  /// **'Share On'**
  String get shareOn;

  /// No description provided for @shareManuallyHint.
  ///
  /// In en, this message translates to:
  /// **'Download your content and share manually on these platforms.'**
  String get shareManuallyHint;

  /// No description provided for @markReadyToShare.
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready to Share'**
  String get markReadyToShare;

  /// No description provided for @selectSnippet.
  ///
  /// In en, this message translates to:
  /// **'Select Snippet'**
  String get selectSnippet;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String secondsShort(String seconds);

  /// No description provided for @snippetStart.
  ///
  /// In en, this message translates to:
  /// **'Start: {time}'**
  String snippetStart(String time);

  /// No description provided for @snippetEnd.
  ///
  /// In en, this message translates to:
  /// **'End: {time}'**
  String snippetEnd(String time);

  /// No description provided for @snippetRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommended: 15–30 seconds for social media.'**
  String get snippetRecommendation;

  /// No description provided for @saveSnippetTimes.
  ///
  /// In en, this message translates to:
  /// **'Save Snippet Times'**
  String get saveSnippetTimes;

  /// No description provided for @captionOutNow.
  ///
  /// In en, this message translates to:
  /// **'🎵 \"{title}\" is out now!'**
  String captionOutNow(String title);

  /// No description provided for @defaultPromoMessage.
  ///
  /// In en, this message translates to:
  /// **'New music out now!'**
  String get defaultPromoMessage;

  /// No description provided for @streamItNow.
  ///
  /// In en, this message translates to:
  /// **'Stream it now'**
  String get streamItNow;

  /// No description provided for @streamItNowAt.
  ///
  /// In en, this message translates to:
  /// **'Stream it now: {link}'**
  String streamItNowAt(String link);

  /// No description provided for @manageYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage your account'**
  String get manageYourAccount;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @notificationsAndSubscription.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Subscription'**
  String get notificationsAndSubscription;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'SplitSure collects only the data necessary to provide its services. Your data is stored securely on Supabase and is never sold to third parties.'**
  String get privacyPolicyBody;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'By using SplitSure, you agree to use the platform responsibly. Agreements created on SplitSure are for record-keeping purposes. Seek independent legal advice for binding contracts.'**
  String get termsBody;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'For support, contact us at support@splitsure.app. We aim to respond within 24 hours.'**
  String get helpBody;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated!'**
  String get passwordUpdated;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified about agreements and campaigns here.'**
  String get noNotificationsHint;

  /// No description provided for @chooseAPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a Plan'**
  String get chooseAPlan;

  /// No description provided for @unlockFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlock full access to SplitSure'**
  String get unlockFullAccess;

  /// No description provided for @durationForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get durationForever;

  /// No description provided for @durationPerMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get durationPerMonth;

  /// No description provided for @durationThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get durationThreeMonths;

  /// No description provided for @durationPerYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get durationPerYear;

  /// No description provided for @saveVsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Save {amount} FCFA vs monthly'**
  String saveVsMonthly(String amount);

  /// No description provided for @featureUpTo2Agreements.
  ///
  /// In en, this message translates to:
  /// **'Create up to 2 agreements'**
  String get featureUpTo2Agreements;

  /// No description provided for @featureUpTo2Campaigns.
  ///
  /// In en, this message translates to:
  /// **'Create up to 2 campaigns'**
  String get featureUpTo2Campaigns;

  /// No description provided for @featureBasicContent.
  ///
  /// In en, this message translates to:
  /// **'Basic content generation'**
  String get featureBasicContent;

  /// No description provided for @featureCommunitySupport.
  ///
  /// In en, this message translates to:
  /// **'Community support'**
  String get featureCommunitySupport;

  /// No description provided for @featureUnlimitedAgreements.
  ///
  /// In en, this message translates to:
  /// **'Unlimited agreements'**
  String get featureUnlimitedAgreements;

  /// No description provided for @featureUnlimitedCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Unlimited campaigns'**
  String get featureUnlimitedCampaigns;

  /// No description provided for @featureFullContent.
  ///
  /// In en, this message translates to:
  /// **'Full content generation'**
  String get featureFullContent;

  /// No description provided for @featurePdfExport.
  ///
  /// In en, this message translates to:
  /// **'PDF agreement export'**
  String get featurePdfExport;

  /// No description provided for @featurePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get featurePrioritySupport;

  /// No description provided for @featureEverythingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Everything in Monthly'**
  String get featureEverythingMonthly;

  /// No description provided for @featureSave17.
  ///
  /// In en, this message translates to:
  /// **'Save 17% vs monthly'**
  String get featureSave17;

  /// No description provided for @featureEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Early access to new features'**
  String get featureEarlyAccess;

  /// No description provided for @featureSave58.
  ///
  /// In en, this message translates to:
  /// **'Save 58% vs monthly'**
  String get featureSave58;

  /// No description provided for @featurePriorityRequests.
  ///
  /// In en, this message translates to:
  /// **'Priority feature requests'**
  String get featurePriorityRequests;

  /// No description provided for @featureDedicatedSupport.
  ///
  /// In en, this message translates to:
  /// **'Dedicated support'**
  String get featureDedicatedSupport;

  /// No description provided for @mobileMoneyNotice.
  ///
  /// In en, this message translates to:
  /// **'Payment integration with Mobile Money (MTN, Orange) will be available in the full release. Use the demo flow for testing.'**
  String get mobileMoneyNotice;

  /// No description provided for @demoSubscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Demo subscription activated: {plan}'**
  String demoSubscriptionActivated(String plan);

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current: {plan}'**
  String currentPlan(String plan);

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expiresOn(String date);

  /// No description provided for @noExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get noExpiry;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @subscribeFor.
  ///
  /// In en, this message translates to:
  /// **'Subscribe – {price}'**
  String subscribeFor(String price);

  /// No description provided for @demoModeNotice.
  ///
  /// In en, this message translates to:
  /// **'DEMO MODE — No real payment is processed. This simulates a subscription for testing.'**
  String get demoModeNotice;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @confirmDemoSubscription.
  ///
  /// In en, this message translates to:
  /// **'Confirm Demo Subscription'**
  String get confirmDemoSubscription;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get connectedAccounts;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @aboutSplitSure.
  ///
  /// In en, this message translates to:
  /// **'About SplitSure'**
  String get aboutSplitSure;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'SplitSure helps independent artists, producers and songwriters manage collaboration agreements and promote their music releases.'**
  String get aboutDescription;

  /// No description provided for @aboutCommunity.
  ///
  /// In en, this message translates to:
  /// **'Built for the music community in Cameroon and beyond.'**
  String get aboutCommunity;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @noSocialAccounts.
  ///
  /// In en, this message translates to:
  /// **'No social accounts connected.'**
  String get noSocialAccounts;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactionsYet;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @firstNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name *'**
  String get firstNameRequiredLabel;

  /// No description provided for @lastNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name *'**
  String get lastNameRequiredLabel;

  /// No description provided for @musicRoles.
  ///
  /// In en, this message translates to:
  /// **'Music Roles'**
  String get musicRoles;

  /// No description provided for @socialMediaLinks.
  ///
  /// In en, this message translates to:
  /// **'Social Media Links'**
  String get socialMediaLinks;

  /// No description provided for @whatsappUrl.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number or Link'**
  String get whatsappUrl;

  /// No description provided for @tiktokUrl.
  ///
  /// In en, this message translates to:
  /// **'TikTok URL'**
  String get tiktokUrl;

  /// No description provided for @youtubeUrl.
  ///
  /// In en, this message translates to:
  /// **'YouTube URL'**
  String get youtubeUrl;

  /// No description provided for @facebookUrl.
  ///
  /// In en, this message translates to:
  /// **'Facebook URL'**
  String get facebookUrl;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Sign in to continue.'**
  String get signInSubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join SplitSure in less than a minute.'**
  String get registerSubtitle;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @welcomeBackName.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBackName(String name);

  /// No description provided for @welcomeNewName.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SplitSure, {name}!'**
  String welcomeNewName(String name);

  /// No description provided for @welcomeBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Good to see you again. Your music is in safe hands.'**
  String get welcomeBackSubtitle;

  /// No description provided for @welcomeNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Let\'s protect and promote your music.'**
  String get welcomeNewSubtitle;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account created!'**
  String get accountCreatedTitle;

  /// No description provided for @continueToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue to sign in'**
  String get continueToSignIn;

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All caught up} =1{1 unread} other{{count} unread}}'**
  String unreadCount(int count);

  /// No description provided for @acceptConfirm.
  ///
  /// In en, this message translates to:
  /// **'By accepting, you confirm you have read this agreement and agree to your share and role. Your acceptance will be recorded with the date and your account.'**
  String get acceptConfirm;

  /// No description provided for @acceptedExplain.
  ///
  /// In en, this message translates to:
  /// **'Every required party has accepted this version. It is now locked and kept in the history.'**
  String get acceptedExplain;

  /// No description provided for @acceptedLocked.
  ///
  /// In en, this message translates to:
  /// **'Accepted agreements cannot be edited. Create a new agreement for any further changes.'**
  String get acceptedLocked;

  /// No description provided for @acceptedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{accepted}/{total} accepted'**
  String acceptedOfTotal(int accepted, int total);

  /// No description provided for @addAtLeastOneCollaborator.
  ///
  /// In en, this message translates to:
  /// **'Add at least one collaborator.'**
  String get addAtLeastOneCollaborator;

  /// No description provided for @additionalTermsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. deductions, credits, how disputes are handled…'**
  String get additionalTermsHint;

  /// No description provided for @agreementReference.
  ///
  /// In en, this message translates to:
  /// **'Agreement reference'**
  String get agreementReference;

  /// No description provided for @agreementSavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Agreement saved as a draft. Review it, then send it to your collaborators.'**
  String get agreementSavedDraft;

  /// No description provided for @agreementTitleFor.
  ///
  /// In en, this message translates to:
  /// **'Music Collaboration Agreement – “{song}”'**
  String agreementTitleFor(String song);

  /// No description provided for @artistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist name *'**
  String get artistNameLabel;

  /// No description provided for @awaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get awaitingResponse;

  /// No description provided for @changeNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'What changed? (optional)'**
  String get changeNoteOptional;

  /// No description provided for @changeRequests.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get changeRequests;

  /// No description provided for @changeRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Edit the agreement to address these requests; a new version will be sent to everyone.'**
  String get changeRequestsHint;

  /// No description provided for @changesRequestedExplain.
  ///
  /// In en, this message translates to:
  /// **'A collaborator asked for changes. The creator can edit the agreement and send a new version.'**
  String get changesRequestedExplain;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get changesSaved;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmRights.
  ///
  /// In en, this message translates to:
  /// **'I confirm I own this content or have permission to use it.'**
  String get confirmRights;

  /// No description provided for @confirmRightsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm you own or have permission to use the uploaded content.'**
  String get confirmRightsRequired;

  /// No description provided for @copyInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Copy invite link'**
  String get copyInviteLink;

  /// No description provided for @declineReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get declineReasonOptional;

  /// No description provided for @declinedExplain.
  ///
  /// In en, this message translates to:
  /// **'A collaborator declined. The creator can revise the agreement and send a new version, or delete it.'**
  String get declinedExplain;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAgreementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this agreement? This cannot be undone.'**
  String get deleteAgreementConfirm;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this project? Its agreements and campaigns are kept but no longer linked to it.'**
  String get deleteProjectConfirm;

  /// No description provided for @describeChanges.
  ///
  /// In en, this message translates to:
  /// **'Describe the changes you need'**
  String get describeChanges;

  /// No description provided for @draftExplain.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this draft. When the shares total 100%, send it to your collaborators for review.'**
  String get draftExplain;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editAgreement.
  ///
  /// In en, this message translates to:
  /// **'Edit agreement'**
  String get editAgreement;

  /// No description provided for @editAndResend.
  ///
  /// In en, this message translates to:
  /// **'Edit & send new version'**
  String get editAndResend;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @emailForInvite.
  ///
  /// In en, this message translates to:
  /// **'Email (to invite)'**
  String get emailForInvite;

  /// No description provided for @featureNotInPlan.
  ///
  /// In en, this message translates to:
  /// **'This feature is not included in your current plan.'**
  String get featureNotInPlan;

  /// No description provided for @finalizedOn.
  ///
  /// In en, this message translates to:
  /// **'Accepted by all on'**
  String get finalizedOn;

  /// No description provided for @inviteExplain.
  ///
  /// In en, this message translates to:
  /// **'Collaborators with an email receive the agreement in their SplitSure account (registered or not yet). You can also copy a secure invite link for each person once the agreement is saved.'**
  String get inviteExplain;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link for {name} copied. Share it privately.'**
  String inviteLinkCopied(String name);

  /// No description provided for @inviteOpening.
  ///
  /// In en, this message translates to:
  /// **'Linking this invitation to your account…'**
  String get inviteOpening;

  /// No description provided for @inviteSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited to review a music collaboration agreement. Create a free account or sign in to view it.'**
  String get inviteSignInPrompt;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited to collaborate'**
  String get inviteTitle;

  /// No description provided for @musicProjectOptional.
  ///
  /// In en, this message translates to:
  /// **'Music project (optional)'**
  String get musicProjectOptional;

  /// No description provided for @newVersionExplain.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be sent as a new version. Previous answers are kept in the history and everyone will be asked to review again.'**
  String get newVersionExplain;

  /// No description provided for @newVersionSent.
  ///
  /// In en, this message translates to:
  /// **'New version sent to your collaborators.'**
  String get newVersionSent;

  /// No description provided for @newVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a new version?'**
  String get newVersionTitle;

  /// No description provided for @noProject.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get noProject;

  /// No description provided for @noProjectsHint.
  ///
  /// In en, this message translates to:
  /// **'Group a song\'s agreements and campaigns in one place.'**
  String get noProjectsHint;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// No description provided for @noResponsesYet.
  ///
  /// In en, this message translates to:
  /// **'No responses yet'**
  String get noResponsesYet;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @openAgreement.
  ///
  /// In en, this message translates to:
  /// **'Open agreement'**
  String get openAgreement;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment / revenue-sharing terms'**
  String get paymentTerms;

  /// No description provided for @paymentTermsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. how and when income is shared, who collects, reporting…'**
  String get paymentTermsHint;

  /// No description provided for @pendingExplain.
  ///
  /// In en, this message translates to:
  /// **'Waiting for collaborators: {accepted} of {total} have accepted.'**
  String pendingExplain(int accepted, int total);

  /// No description provided for @planLimitReachedBody.
  ///
  /// In en, this message translates to:
  /// **'Your current plan allows up to {max}. Upgrade to create more.'**
  String planLimitReachedBody(int max);

  /// No description provided for @planLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan limit reached'**
  String get planLimitReachedTitle;

  /// No description provided for @projectCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No projects} =1{1 project} other{{count} projects}}'**
  String projectCount(int count);

  /// No description provided for @projectSaved.
  ///
  /// In en, this message translates to:
  /// **'Project saved.'**
  String get projectSaved;

  /// No description provided for @projectStatus.
  ///
  /// In en, this message translates to:
  /// **'Project status'**
  String get projectStatus;

  /// No description provided for @projectStatusIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get projectStatusIdea;

  /// No description provided for @projectStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get projectStatusInProgress;

  /// No description provided for @projectStatusRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get projectStatusRecorded;

  /// No description provided for @projectStatusReleased.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get projectStatusReleased;

  /// No description provided for @responseSentAccepted.
  ///
  /// In en, this message translates to:
  /// **'You accepted the agreement.'**
  String get responseSentAccepted;

  /// No description provided for @responseSentChanges.
  ///
  /// In en, this message translates to:
  /// **'Your change request was sent.'**
  String get responseSentChanges;

  /// No description provided for @responseSentDeclined.
  ///
  /// In en, this message translates to:
  /// **'You declined the agreement.'**
  String get responseSentDeclined;

  /// No description provided for @saveAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get saveAsDraft;

  /// No description provided for @saveProject.
  ///
  /// In en, this message translates to:
  /// **'Save project'**
  String get saveProject;

  /// No description provided for @scopeAndTerms.
  ///
  /// In en, this message translates to:
  /// **'Scope & terms'**
  String get scopeAndTerms;

  /// No description provided for @scopeComposition.
  ///
  /// In en, this message translates to:
  /// **'Musical composition'**
  String get scopeComposition;

  /// No description provided for @scopeDetails.
  ///
  /// In en, this message translates to:
  /// **'Scope details (optional)'**
  String get scopeDetails;

  /// No description provided for @scopeHelp.
  ///
  /// In en, this message translates to:
  /// **'The percentages do not automatically apply to every right or income. Select what this agreement covers.'**
  String get scopeHelp;

  /// No description provided for @scopeLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get scopeLyrics;

  /// No description provided for @scopeMaster.
  ///
  /// In en, this message translates to:
  /// **'Sound recording / master'**
  String get scopeMaster;

  /// No description provided for @scopeOther.
  ///
  /// In en, this message translates to:
  /// **'Other rights or revenue'**
  String get scopeOther;

  /// No description provided for @scopeProduction.
  ///
  /// In en, this message translates to:
  /// **'Production contribution'**
  String get scopeProduction;

  /// No description provided for @scopeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What does this agreement cover?'**
  String get scopeQuestion;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @seePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get seePlans;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendForReviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send this agreement to all collaborators for review? They will be able to accept, request changes or decline.'**
  String get sendForReviewConfirm;

  /// No description provided for @sendNewVersion.
  ///
  /// In en, this message translates to:
  /// **'Send new version'**
  String get sendNewVersion;

  /// No description provided for @sentForReview.
  ///
  /// In en, this message translates to:
  /// **'Agreement sent for review.'**
  String get sentForReview;

  /// No description provided for @splitsExceed100.
  ///
  /// In en, this message translates to:
  /// **'The total cannot exceed 100%.'**
  String get splitsExceed100;

  /// No description provided for @splitsMustReach100.
  ///
  /// In en, this message translates to:
  /// **'Shares must total exactly 100% before the agreement can be sent.'**
  String get splitsMustReach100;

  /// No description provided for @splitsReady.
  ///
  /// In en, this message translates to:
  /// **'Shares total 100%.'**
  String get splitsReady;

  /// No description provided for @stepOfN.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOfN(String step, String total);

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @versionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get versionHistory;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @versionSentOn.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · {date}'**
  String versionSentOn(int version, String date);

  /// No description provided for @versionShort.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String versionShort(int version);

  /// No description provided for @witnessOptionalIntro.
  ///
  /// In en, this message translates to:
  /// **'Both sections are optional. A witness or lawyer listed here has not approved the agreement unless they review it themselves.'**
  String get witnessOptionalIntro;

  /// No description provided for @yourResponse.
  ///
  /// In en, this message translates to:
  /// **'Your response'**
  String get yourResponse;

  /// No description provided for @yourResponseNeeded.
  ///
  /// In en, this message translates to:
  /// **'Your response is needed'**
  String get yourResponseNeeded;

  /// No description provided for @yourShareIs.
  ///
  /// In en, this message translates to:
  /// **'Your share: {percent} as {role}'**
  String yourShareIs(String percent, String role);

  /// No description provided for @updatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedOn(String date);

  /// No description provided for @sharedWithYou.
  ///
  /// In en, this message translates to:
  /// **'Shared with you'**
  String get sharedWithYou;

  /// No description provided for @deleteCampaignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this campaign and its generated content?'**
  String get deleteCampaignConfirm;

  /// No description provided for @downloadVideo.
  ///
  /// In en, this message translates to:
  /// **'Download video'**
  String get downloadVideo;

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String durationDays(int days);

  /// No description provided for @enablePush.
  ///
  /// In en, this message translates to:
  /// **'Enable push notifications on this device'**
  String get enablePush;

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Expires today} =1{Expires tomorrow} other{Expires in {days} days}}'**
  String expiresInDays(int days);

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @featureCollaboratorInvites.
  ///
  /// In en, this message translates to:
  /// **'Collaborator invitations & acceptance tracking'**
  String get featureCollaboratorInvites;

  /// No description provided for @featurePromoVideo.
  ///
  /// In en, this message translates to:
  /// **'9:16 promotional videos'**
  String get featurePromoVideo;

  /// No description provided for @featureUnlimitedProjects.
  ///
  /// In en, this message translates to:
  /// **'Unlimited music projects'**
  String get featureUnlimitedProjects;

  /// No description provided for @featureUpToAgreements.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} agreements'**
  String featureUpToAgreements(int count);

  /// No description provided for @featureUpToCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} campaigns'**
  String featureUpToCampaigns(int count);

  /// No description provided for @featureUpToProjects.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} music projects'**
  String featureUpToProjects(int count);

  /// No description provided for @freePlanExplain.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the Basic plan. Upgrade any time for unlimited agreements, campaigns and projects.'**
  String get freePlanExplain;

  /// No description provided for @generateVideo.
  ///
  /// In en, this message translates to:
  /// **'Generate promo video'**
  String get generateVideo;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get markCompleted;

  /// No description provided for @notifAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted “{song}”.'**
  String notifAcceptedBody(String name, String song);

  /// No description provided for @notifAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement accepted'**
  String get notifAcceptedTitle;

  /// No description provided for @notifCampaignBody.
  ///
  /// In en, this message translates to:
  /// **'“{campaign}” is complete.'**
  String notifCampaignBody(String campaign);

  /// No description provided for @notifCampaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign completed'**
  String get notifCampaignTitle;

  /// No description provided for @notifCatAgreements.
  ///
  /// In en, this message translates to:
  /// **'Agreements'**
  String get notifCatAgreements;

  /// No description provided for @notifCatAgreementsHint.
  ///
  /// In en, this message translates to:
  /// **'Invitations, responses and new versions'**
  String get notifCatAgreementsHint;

  /// No description provided for @notifCatCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get notifCatCampaigns;

  /// No description provided for @notifCatCampaignsHint.
  ///
  /// In en, this message translates to:
  /// **'When a campaign is completed'**
  String get notifCatCampaignsHint;

  /// No description provided for @notifCatSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get notifCatSubscription;

  /// No description provided for @notifCatSubscriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get notifCatSubscriptionHint;

  /// No description provided for @notifChangesBody.
  ///
  /// In en, this message translates to:
  /// **'{name} requested changes to “{song}”.'**
  String notifChangesBody(String name, String song);

  /// No description provided for @notifChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get notifChangesTitle;

  /// No description provided for @notifDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} declined “{song}”.'**
  String notifDeclinedBody(String name, String song);

  /// No description provided for @notifDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement declined'**
  String get notifDeclinedTitle;

  /// No description provided for @notifExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Renew to keep full access to SplitSure.'**
  String get notifExpiredBody;

  /// No description provided for @notifExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription expired'**
  String get notifExpiredTitle;

  /// No description provided for @notifExpiringBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan expires on {date}.'**
  String notifExpiringBody(String date);

  /// No description provided for @notifExpiringTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription expiring soon'**
  String get notifExpiringTitle;

  /// No description provided for @notifFinalBody.
  ///
  /// In en, this message translates to:
  /// **'All parties accepted “{song}”.'**
  String notifFinalBody(String song);

  /// No description provided for @notifFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement finalised'**
  String get notifFinalTitle;

  /// No description provided for @notifInvitedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited to review “{song}”.'**
  String notifInvitedBody(String song);

  /// No description provided for @notifInvitedTitle.
  ///
  /// In en, this message translates to:
  /// **'New collaboration agreement'**
  String get notifInvitedTitle;

  /// No description provided for @notifNewVersionBody.
  ///
  /// In en, this message translates to:
  /// **'Version {version} of “{song}” is ready for review.'**
  String notifNewVersionBody(String version, String song);

  /// No description provided for @notifNewVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement updated'**
  String get notifNewVersionTitle;

  /// No description provided for @outNowBadge.
  ///
  /// In en, this message translates to:
  /// **'OUT NOW'**
  String get outNowBadge;

  /// No description provided for @paymentDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo (not paid)'**
  String get paymentDemo;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentFailed;

  /// No description provided for @paymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentPaid;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get paymentPending;

  /// No description provided for @paymentRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentRefunded;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatus;

  /// No description provided for @pushEnabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications enabled on this device.'**
  String get pushEnabled;

  /// No description provided for @pushExplain.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your browser to be alerted about agreements even when SplitSure is closed.'**
  String get pushExplain;

  /// No description provided for @pushUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Push notifications are not available in this browser or were blocked.'**
  String get pushUnavailable;

  /// No description provided for @regenerateVideo.
  ///
  /// In en, this message translates to:
  /// **'Generate a new video'**
  String get regenerateVideo;

  /// No description provided for @renewExtends.
  ///
  /// In en, this message translates to:
  /// **'Renewing adds the new period after your current expiry date.'**
  String get renewExtends;

  /// No description provided for @renewPlan.
  ///
  /// In en, this message translates to:
  /// **'Renew – {price}'**
  String renewPlan(String price);

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @subscriptionHistory.
  ///
  /// In en, this message translates to:
  /// **'Subscription history'**
  String get subscriptionHistory;

  /// No description provided for @templatePulse.
  ///
  /// In en, this message translates to:
  /// **'Cover pulse'**
  String get templatePulse;

  /// No description provided for @templatePulseHint.
  ///
  /// In en, this message translates to:
  /// **'Artwork that moves with the beat'**
  String get templatePulseHint;

  /// No description provided for @templateWaveform.
  ///
  /// In en, this message translates to:
  /// **'Waveform teaser'**
  String get templateWaveform;

  /// No description provided for @templateWaveformHint.
  ///
  /// In en, this message translates to:
  /// **'Live sound bars + progress'**
  String get templateWaveformHint;

  /// No description provided for @videoFailed.
  ///
  /// In en, this message translates to:
  /// **'Video could not be created: {details}'**
  String videoFailed(String details);

  /// No description provided for @videoIntro.
  ///
  /// In en, this message translates to:
  /// **'Creates a real vertical 9:16 video with your artwork, title, artist name, message and the selected snippet. It records in real time, so keep this tab open.'**
  String get videoIntro;

  /// No description provided for @videoNeedsMusic.
  ///
  /// In en, this message translates to:
  /// **'Upload a music file to the campaign first.'**
  String get videoNeedsMusic;

  /// No description provided for @videoReady.
  ///
  /// In en, this message translates to:
  /// **'Your promo video is ready!'**
  String get videoReady;

  /// No description provided for @videoRendering.
  ///
  /// In en, this message translates to:
  /// **'Recording your video… {percent}%'**
  String videoRendering(int percent);

  /// No description provided for @videoUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This browser cannot record video. Use a recent Chrome, Edge or Safari.'**
  String get videoUnsupported;

  /// No description provided for @videoWebmNote.
  ///
  /// In en, this message translates to:
  /// **'Your browser saved this video as WebM. For an MP4 file, generate it in Chrome, Edge or Safari.'**
  String get videoWebmNote;

  /// No description provided for @noRolesYet.
  ///
  /// In en, this message translates to:
  /// **'No music roles added yet.'**
  String get noRolesYet;

  /// No description provided for @proPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proPlan;

  /// No description provided for @choosePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get choosePlanTitle;

  /// No description provided for @choosePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start free and upgrade whenever you\'re ready.'**
  String get choosePlanSubtitle;

  /// No description provided for @continueWithFree.
  ///
  /// In en, this message translates to:
  /// **'Continue with Basic'**
  String get continueWithFree;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @upgradeForAmount.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for {amount}'**
  String upgradeForAmount(String amount);

  /// No description provided for @oneTimePayment.
  ///
  /// In en, this message translates to:
  /// **'One-time payment'**
  String get oneTimePayment;

  /// No description provided for @freeForever.
  ///
  /// In en, this message translates to:
  /// **'Free forever'**
  String get freeForever;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro active'**
  String get proActive;

  /// No description provided for @proActiveSince.
  ///
  /// In en, this message translates to:
  /// **'Pro since {date}'**
  String proActiveSince(String date);

  /// No description provided for @youAreOnFree.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the Free plan'**
  String get youAreOnFree;

  /// No description provided for @youAreOnPro.
  ///
  /// In en, this message translates to:
  /// **'You\'re on Pro'**
  String get youAreOnPro;

  /// No description provided for @proUnlocksBody.
  ///
  /// In en, this message translates to:
  /// **'Unlimited opportunity posts, unlimited final agreements, Reach promotion tools and more.'**
  String get proUnlocksBody;

  /// No description provided for @freeFeatureProtectDrafts.
  ///
  /// In en, this message translates to:
  /// **'1 free agreement document'**
  String get freeFeatureProtectDrafts;

  /// No description provided for @freeFeatureAgreementFee.
  ///
  /// In en, this message translates to:
  /// **'Each extra agreement: {amount} to preview & download'**
  String freeFeatureAgreementFee(String amount);

  /// No description provided for @freeFeatureOnePost.
  ///
  /// In en, this message translates to:
  /// **'1 opportunity post'**
  String get freeFeatureOnePost;

  /// No description provided for @freeFeaturePassport.
  ///
  /// In en, this message translates to:
  /// **'Music Passport & applications'**
  String get freeFeaturePassport;

  /// No description provided for @freeFeatureProjects.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} projects'**
  String freeFeatureProjects(int count);

  /// No description provided for @proFeatureUnlimitedPosts.
  ///
  /// In en, this message translates to:
  /// **'Unlimited opportunity posts'**
  String get proFeatureUnlimitedPosts;

  /// No description provided for @proFeatureUnlimitedAgreements.
  ///
  /// In en, this message translates to:
  /// **'Unlimited agreements'**
  String get proFeatureUnlimitedAgreements;

  /// No description provided for @proFeatureReach.
  ///
  /// In en, this message translates to:
  /// **'Reach: campaigns, captions & promo videos'**
  String get proFeatureReach;

  /// No description provided for @proFeatureUnlimitedProjects.
  ///
  /// In en, this message translates to:
  /// **'Unlimited projects'**
  String get proFeatureUnlimitedProjects;

  /// No description provided for @proFeaturePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority visibility in the Opportunity Hub'**
  String get proFeaturePriority;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @noPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get noPayments;

  /// No description provided for @paymentTypePro.
  ///
  /// In en, this message translates to:
  /// **'Pro upgrade'**
  String get paymentTypePro;

  /// No description provided for @paymentTypeAgreement.
  ///
  /// In en, this message translates to:
  /// **'Final agreement'**
  String get paymentTypeAgreement;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get paymentSuccess;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get paymentCancelled;

  /// No description provided for @payWithMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Pay with Mobile Money'**
  String get payWithMobileMoney;

  /// No description provided for @mtnMomo.
  ///
  /// In en, this message translates to:
  /// **'MTN Mobile Money'**
  String get mtnMomo;

  /// No description provided for @orangeMoney.
  ///
  /// In en, this message translates to:
  /// **'Orange Money'**
  String get orangeMoney;

  /// No description provided for @mobileMoneyNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money number'**
  String get mobileMoneyNumber;

  /// No description provided for @mobileMoneyNumberHint.
  ///
  /// In en, this message translates to:
  /// **'6XX XXX XXX'**
  String get mobileMoneyNumberHint;

  /// No description provided for @invalidCameroonPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Cameroon number (9 digits starting with 6).'**
  String get invalidCameroonPhone;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @waitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your approval'**
  String get waitingForApproval;

  /// No description provided for @approveOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Check your phone and approve the {amount} payment with your PIN.'**
  String approveOnPhone(String amount);

  /// No description provided for @dialToApprove.
  ///
  /// In en, this message translates to:
  /// **'No prompt? Dial *126# (MTN) or #150*50# (Orange) to approve pending payments.'**
  String get dialToApprove;

  /// No description provided for @checkingPayment.
  ///
  /// In en, this message translates to:
  /// **'Checking payment…'**
  String get checkingPayment;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get paymentConfirmed;

  /// No description provided for @paymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment not completed'**
  String get paymentNotCompleted;

  /// No description provided for @paymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The payment was declined or cancelled. Nothing was charged. You can try again.'**
  String get paymentFailedBody;

  /// No description provided for @paymentStillPending.
  ///
  /// In en, this message translates to:
  /// **'We haven\'t received confirmation yet. If you approved it, it will be applied automatically – check again in a moment.'**
  String get paymentStillPending;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @paymentsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Payments are temporarily unavailable. Please try again later.'**
  String get paymentsUnavailable;

  /// No description provided for @alreadyPro.
  ///
  /// In en, this message translates to:
  /// **'You already have Pro.'**
  String get alreadyPro;

  /// No description provided for @proWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pro!'**
  String get proWelcomeTitle;

  /// No description provided for @proWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Everything is unlocked. Enjoy unlimited posts, agreements and Reach.'**
  String get proWelcomeBody;

  /// No description provided for @securePaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Payments are processed securely by MeSomb. SplitSure never sees your PIN.'**
  String get securePaymentNote;

  /// No description provided for @planBadgeFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get planBadgeFree;

  /// No description provided for @planBadgePro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get planBadgePro;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @musicPassport.
  ///
  /// In en, this message translates to:
  /// **'Music Passport'**
  String get musicPassport;

  /// No description provided for @passportTagline.
  ///
  /// In en, this message translates to:
  /// **'Your professional music identity'**
  String get passportTagline;

  /// No description provided for @createPassport.
  ///
  /// In en, this message translates to:
  /// **'Create my Music Passport'**
  String get createPassport;

  /// No description provided for @createPassportIntro.
  ///
  /// In en, this message translates to:
  /// **'One professional profile used across SplitSure: showcase your roles, skills and work, apply to opportunities and get discovered.'**
  String get createPassportIntro;

  /// No description provided for @editPassport.
  ///
  /// In en, this message translates to:
  /// **'Edit passport'**
  String get editPassport;

  /// No description provided for @passportStepIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get passportStepIdentity;

  /// No description provided for @passportStepProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get passportStepProfessional;

  /// No description provided for @passportStepPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get passportStepPortfolio;

  /// No description provided for @passportStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get passportStepReview;

  /// No description provided for @stageName.
  ///
  /// In en, this message translates to:
  /// **'Professional / stage name'**
  String get stageName;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @primaryRole.
  ///
  /// In en, this message translates to:
  /// **'Primary role'**
  String get primaryRole;

  /// No description provided for @secondaryRoles.
  ///
  /// In en, this message translates to:
  /// **'Secondary roles (optional)'**
  String get secondaryRoles;

  /// No description provided for @professionalBio.
  ///
  /// In en, this message translates to:
  /// **'Short professional biography'**
  String get professionalBio;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email'**
  String get contactEmail;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get contactPhone;

  /// No description provided for @preferredContact.
  ///
  /// In en, this message translates to:
  /// **'Preferred contact method'**
  String get preferredContact;

  /// No description provided for @contactEmailMethod.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmailMethod;

  /// No description provided for @contactPhoneMethod.
  ///
  /// In en, this message translates to:
  /// **'Phone call'**
  String get contactPhoneMethod;

  /// No description provided for @contactWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsapp;

  /// No description provided for @contactInApp.
  ///
  /// In en, this message translates to:
  /// **'Through SplitSure'**
  String get contactInApp;

  /// No description provided for @skillsSpecialisations.
  ///
  /// In en, this message translates to:
  /// **'Skills & specialisations'**
  String get skillsSpecialisations;

  /// No description provided for @yearsExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get yearsExperience;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @instruments.
  ///
  /// In en, this message translates to:
  /// **'Instruments played'**
  String get instruments;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability for collaboration'**
  String get availability;

  /// No description provided for @availabilityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availabilityAvailable;

  /// No description provided for @availabilityLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited availability'**
  String get availabilityLimited;

  /// No description provided for @availabilityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get availabilityUnavailable;

  /// No description provided for @preferredArrangements.
  ///
  /// In en, this message translates to:
  /// **'Preferred collaboration arrangements'**
  String get preferredArrangements;

  /// No description provided for @operatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Location of operation'**
  String get operatingLocation;

  /// No description provided for @operatingLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Douala, Yaoundé, remote'**
  String get operatingLocationHint;

  /// No description provided for @typeAndEnter.
  ///
  /// In en, this message translates to:
  /// **'Type and press Enter'**
  String get typeAndEnter;

  /// No description provided for @externalLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get externalLinks;

  /// No description provided for @personalWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get personalWebsite;

  /// No description provided for @portfolioItems.
  ///
  /// In en, this message translates to:
  /// **'Portfolio & experience'**
  String get portfolioItems;

  /// No description provided for @addPortfolioItem.
  ///
  /// In en, this message translates to:
  /// **'Add to portfolio'**
  String get addPortfolioItem;

  /// No description provided for @editPortfolioItem.
  ///
  /// In en, this message translates to:
  /// **'Edit portfolio item'**
  String get editPortfolioItem;

  /// No description provided for @noPortfolioItems.
  ///
  /// In en, this message translates to:
  /// **'Add your projects, releases, credits, videos and awards.'**
  String get noPortfolioItems;

  /// No description provided for @portfolioKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get portfolioKind;

  /// No description provided for @kindProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get kindProject;

  /// No description provided for @kindRelease.
  ///
  /// In en, this message translates to:
  /// **'Released song'**
  String get kindRelease;

  /// No description provided for @kindAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album / EP'**
  String get kindAlbum;

  /// No description provided for @kindProductionCredit.
  ///
  /// In en, this message translates to:
  /// **'Production credit'**
  String get kindProductionCredit;

  /// No description provided for @kindWritingCredit.
  ///
  /// In en, this message translates to:
  /// **'Writing credit'**
  String get kindWritingCredit;

  /// No description provided for @kindCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get kindCollaboration;

  /// No description provided for @kindVideo.
  ///
  /// In en, this message translates to:
  /// **'Music video'**
  String get kindVideo;

  /// No description provided for @kindAward.
  ///
  /// In en, this message translates to:
  /// **'Achievement / award'**
  String get kindAward;

  /// No description provided for @kindExperience.
  ///
  /// In en, this message translates to:
  /// **'Professional experience'**
  String get kindExperience;

  /// No description provided for @itemTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get itemTitle;

  /// No description provided for @itemRoleOptional.
  ///
  /// In en, this message translates to:
  /// **'Your role (optional)'**
  String get itemRoleOptional;

  /// No description provided for @itemYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get itemYear;

  /// No description provided for @itemLink.
  ///
  /// In en, this message translates to:
  /// **'Link (Spotify, YouTube…)'**
  String get itemLink;

  /// No description provided for @itemDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get itemDescription;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @showOnPublicPassport.
  ///
  /// In en, this message translates to:
  /// **'Show on my public passport'**
  String get showOnPublicPassport;

  /// No description provided for @visibilitySettings.
  ///
  /// In en, this message translates to:
  /// **'Public visibility'**
  String get visibilitySettings;

  /// No description provided for @visibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Choose what visitors of your public passport can see.'**
  String get visibilityHint;

  /// No description provided for @visibilityContact.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get visibilityContact;

  /// No description provided for @visibilityLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get visibilityLocation;

  /// No description provided for @visibilityPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get visibilityPortfolio;

  /// No description provided for @visibilityLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get visibilityLinks;

  /// No description provided for @visibilityExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get visibilityExperience;

  /// No description provided for @passportUrl.
  ///
  /// In en, this message translates to:
  /// **'Public link'**
  String get passportUrl;

  /// No description provided for @passportSlugHint.
  ///
  /// In en, this message translates to:
  /// **'letters, numbers and dashes'**
  String get passportSlugHint;

  /// No description provided for @slugTaken.
  ///
  /// In en, this message translates to:
  /// **'This link is already taken.'**
  String get slugTaken;

  /// No description provided for @slugInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 3–40 lowercase letters, numbers or dashes.'**
  String get slugInvalid;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @publishPassport.
  ///
  /// In en, this message translates to:
  /// **'Publish passport'**
  String get publishPassport;

  /// No description provided for @unpublishPassport.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublishPassport;

  /// No description provided for @passportPublished.
  ///
  /// In en, this message translates to:
  /// **'Your Music Passport is live!'**
  String get passportPublished;

  /// No description provided for @passportSaved.
  ///
  /// In en, this message translates to:
  /// **'Passport saved'**
  String get passportSaved;

  /// No description provided for @passportDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft – not public yet'**
  String get passportDraft;

  /// No description provided for @passportLive.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get passportLive;

  /// No description provided for @previewPublic.
  ///
  /// In en, this message translates to:
  /// **'Preview public profile'**
  String get previewPublic;

  /// No description provided for @sharePassport.
  ///
  /// In en, this message translates to:
  /// **'Share passport'**
  String get sharePassport;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @collaborate.
  ///
  /// In en, this message translates to:
  /// **'Collaborate'**
  String get collaborate;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @viewPortfolio.
  ///
  /// In en, this message translates to:
  /// **'View portfolio'**
  String get viewPortfolio;

  /// No description provided for @viewPassport.
  ///
  /// In en, this message translates to:
  /// **'View Music Passport'**
  String get viewPassport;

  /// No description provided for @passportNotFound.
  ///
  /// In en, this message translates to:
  /// **'This Music Passport doesn\'t exist or isn\'t public.'**
  String get passportNotFound;

  /// No description provided for @yearsExperienceValue.
  ///
  /// In en, this message translates to:
  /// **'{count} years of experience'**
  String yearsExperienceValue(int count);

  /// No description provided for @noContactPublic.
  ///
  /// In en, this message translates to:
  /// **'This member shares contact details only through SplitSure. Sign in and apply to one of their opportunities to collaborate.'**
  String get noContactPublic;

  /// No description provided for @openOpportunitiesBy.
  ///
  /// In en, this message translates to:
  /// **'Open opportunities by {name}'**
  String openOpportunitiesBy(String name);

  /// No description provided for @noOpenOpportunitiesBy.
  ///
  /// In en, this message translates to:
  /// **'{name} has no open opportunities right now.'**
  String noOpenOpportunitiesBy(String name);

  /// No description provided for @signInToCollaborate.
  ///
  /// In en, this message translates to:
  /// **'Sign in to collaborate'**
  String get signInToCollaborate;

  /// No description provided for @joinSplitSure.
  ///
  /// In en, this message translates to:
  /// **'Join SplitSure'**
  String get joinSplitSure;

  /// No description provided for @passportRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Music Passport needed'**
  String get passportRequiredTitle;

  /// No description provided for @passportRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Publish your Music Passport first – it\'s your professional identity for posting and applying.'**
  String get passportRequiredBody;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @rolePassportSinger.
  ///
  /// In en, this message translates to:
  /// **'Singer / Vocalist'**
  String get rolePassportSinger;

  /// No description provided for @rolePassportRapper.
  ///
  /// In en, this message translates to:
  /// **'Rapper'**
  String get rolePassportRapper;

  /// No description provided for @rolePassportProducer.
  ///
  /// In en, this message translates to:
  /// **'Music Producer'**
  String get rolePassportProducer;

  /// No description provided for @rolePassportSongwriter.
  ///
  /// In en, this message translates to:
  /// **'Songwriter'**
  String get rolePassportSongwriter;

  /// No description provided for @rolePassportComposer.
  ///
  /// In en, this message translates to:
  /// **'Composer'**
  String get rolePassportComposer;

  /// No description provided for @rolePassportSoundEngineer.
  ///
  /// In en, this message translates to:
  /// **'Sound Engineer'**
  String get rolePassportSoundEngineer;

  /// No description provided for @rolePassportMixMaster.
  ///
  /// In en, this message translates to:
  /// **'Mixing & Mastering Engineer'**
  String get rolePassportMixMaster;

  /// No description provided for @rolePassportInstrumentalist.
  ///
  /// In en, this message translates to:
  /// **'Instrumentalist'**
  String get rolePassportInstrumentalist;

  /// No description provided for @rolePassportDj.
  ///
  /// In en, this message translates to:
  /// **'DJ'**
  String get rolePassportDj;

  /// No description provided for @rolePassportMusicManager.
  ///
  /// In en, this message translates to:
  /// **'Music Manager'**
  String get rolePassportMusicManager;

  /// No description provided for @rolePassportArtistManager.
  ///
  /// In en, this message translates to:
  /// **'Artist Manager'**
  String get rolePassportArtistManager;

  /// No description provided for @rolePassportLabel.
  ///
  /// In en, this message translates to:
  /// **'Record Label'**
  String get rolePassportLabel;

  /// No description provided for @rolePassportPublisher.
  ///
  /// In en, this message translates to:
  /// **'Music Publisher'**
  String get rolePassportPublisher;

  /// No description provided for @rolePassportVideoDirector.
  ///
  /// In en, this message translates to:
  /// **'Video Director'**
  String get rolePassportVideoDirector;

  /// No description provided for @rolePassportPromoter.
  ///
  /// In en, this message translates to:
  /// **'Music Promoter'**
  String get rolePassportPromoter;

  /// No description provided for @rolePassportDesigner.
  ///
  /// In en, this message translates to:
  /// **'Graphic Designer'**
  String get rolePassportDesigner;

  /// No description provided for @rolePassportPhotographer.
  ///
  /// In en, this message translates to:
  /// **'Photographer'**
  String get rolePassportPhotographer;

  /// No description provided for @rolePassportBusiness.
  ///
  /// In en, this message translates to:
  /// **'Music Business Professional'**
  String get rolePassportBusiness;

  /// No description provided for @rolePassportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get rolePassportOther;

  /// No description provided for @arrangementPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid collaboration'**
  String get arrangementPaid;

  /// No description provided for @arrangementRevenueShare.
  ///
  /// In en, this message translates to:
  /// **'Revenue sharing'**
  String get arrangementRevenueShare;

  /// No description provided for @arrangementRoyaltyShare.
  ///
  /// In en, this message translates to:
  /// **'Royalty sharing'**
  String get arrangementRoyaltyShare;

  /// No description provided for @arrangementPercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage-based partnership'**
  String get arrangementPercentage;

  /// No description provided for @arrangementVoluntary.
  ///
  /// In en, this message translates to:
  /// **'Voluntary collaboration'**
  String get arrangementVoluntary;

  /// No description provided for @arrangementNegotiable.
  ///
  /// In en, this message translates to:
  /// **'Negotiable arrangement'**
  String get arrangementNegotiable;

  /// No description provided for @opportunityHub.
  ///
  /// In en, this message translates to:
  /// **'Opportunity Hub'**
  String get opportunityHub;

  /// No description provided for @navHub.
  ///
  /// In en, this message translates to:
  /// **'Hub'**
  String get navHub;

  /// No description provided for @hubTagline.
  ///
  /// In en, this message translates to:
  /// **'Find collaborators and music projects'**
  String get hubTagline;

  /// No description provided for @hubDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get hubDiscover;

  /// No description provided for @hubMyPosts.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get hubMyPosts;

  /// No description provided for @hubMyApplications.
  ///
  /// In en, this message translates to:
  /// **'My applications'**
  String get hubMyApplications;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @allOpportunities.
  ///
  /// In en, this message translates to:
  /// **'All opportunities'**
  String get allOpportunities;

  /// No description provided for @searchOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Search opportunities'**
  String get searchOpportunities;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @filterRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get filterRole;

  /// No description provided for @filterGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get filterGenre;

  /// No description provided for @filterLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get filterLocation;

  /// No description provided for @filterCompensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get filterCompensation;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get filterDate;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get anyTime;

  /// No description provided for @last24h.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get last24h;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lastWeek;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get lastMonth;

  /// No description provided for @remoteOk.
  ///
  /// In en, this message translates to:
  /// **'Remote OK'**
  String get remoteOk;

  /// No description provided for @noOpportunities.
  ///
  /// In en, this message translates to:
  /// **'No opportunities match yet.'**
  String get noOpportunities;

  /// No description provided for @noOpportunitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Try other filters, or post your own opportunity.'**
  String get noOpportunitiesHint;

  /// No description provided for @postOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Post an opportunity'**
  String get postOpportunity;

  /// No description provided for @editOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Edit opportunity'**
  String get editOpportunity;

  /// No description provided for @opportunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Opportunity title'**
  String get opportunityTitle;

  /// No description provided for @opportunityTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Looking for a vocalist for an Afrobeats single'**
  String get opportunityTitleHint;

  /// No description provided for @projectDescription.
  ///
  /// In en, this message translates to:
  /// **'Project description'**
  String get projectDescription;

  /// No description provided for @projectCategory.
  ///
  /// In en, this message translates to:
  /// **'Project category'**
  String get projectCategory;

  /// No description provided for @categoryRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get categoryRecording;

  /// No description provided for @categorySongwriting.
  ///
  /// In en, this message translates to:
  /// **'Songwriting'**
  String get categorySongwriting;

  /// No description provided for @categoryProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get categoryProduction;

  /// No description provided for @categoryPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get categoryPerformance;

  /// No description provided for @categoryVideo.
  ///
  /// In en, this message translates to:
  /// **'Music video'**
  String get categoryVideo;

  /// No description provided for @categoryLive.
  ///
  /// In en, this message translates to:
  /// **'Live / events'**
  String get categoryLive;

  /// No description provided for @categoryMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing & promotion'**
  String get categoryMarketing;

  /// No description provided for @categoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business & management'**
  String get categoryBusiness;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @requiredRoles.
  ///
  /// In en, this message translates to:
  /// **'Required role(s)'**
  String get requiredRoles;

  /// No description provided for @requiredSkills.
  ///
  /// In en, this message translates to:
  /// **'Required skills'**
  String get requiredSkills;

  /// No description provided for @projectLocation.
  ///
  /// In en, this message translates to:
  /// **'Project location'**
  String get projectLocation;

  /// No description provided for @remoteCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Remote collaboration possible'**
  String get remoteCollaboration;

  /// No description provided for @collaborationType.
  ///
  /// In en, this message translates to:
  /// **'Collaboration type'**
  String get collaborationType;

  /// No description provided for @compensationArrangement.
  ///
  /// In en, this message translates to:
  /// **'Compensation arrangement'**
  String get compensationArrangement;

  /// No description provided for @compensationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50,000 FCFA, or 20% of master royalties'**
  String get compensationHint;

  /// No description provided for @expectedDeliverables.
  ///
  /// In en, this message translates to:
  /// **'Expected deliverables'**
  String get expectedDeliverables;

  /// No description provided for @projectDeadline.
  ///
  /// In en, this message translates to:
  /// **'Project deadline'**
  String get projectDeadline;

  /// No description provided for @applicationDeadline.
  ///
  /// In en, this message translates to:
  /// **'Application deadline'**
  String get applicationDeadline;

  /// No description provided for @positionsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Number of collaborators needed'**
  String get positionsNeeded;

  /// No description provided for @referenceLinks.
  ///
  /// In en, this message translates to:
  /// **'Reference files or links'**
  String get referenceLinks;

  /// No description provided for @additionalRequirements.
  ///
  /// In en, this message translates to:
  /// **'Additional requirements'**
  String get additionalRequirements;

  /// No description provided for @restrictToRoles.
  ///
  /// In en, this message translates to:
  /// **'Only show to people with these roles'**
  String get restrictToRoles;

  /// No description provided for @restrictToRolesHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended: your opportunity reaches the right people and stays private from others.'**
  String get restrictToRolesHint;

  /// No description provided for @publishOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Publish opportunity'**
  String get publishOpportunity;

  /// No description provided for @opportunityPublished.
  ///
  /// In en, this message translates to:
  /// **'Opportunity published'**
  String get opportunityPublished;

  /// No description provided for @opportunityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Opportunity updated'**
  String get opportunityUpdated;

  /// No description provided for @freePostUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Free post used'**
  String get freePostUsedTitle;

  /// No description provided for @freePostUsedBody.
  ///
  /// In en, this message translates to:
  /// **'Free accounts include one opportunity post. Upgrade to Pro for unlimited posts.'**
  String get freePostUsedBody;

  /// No description provided for @freePostsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Basic plan: {count} post left'**
  String freePostsRemaining(int count);

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @closeOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeOpportunity;

  /// No description provided for @reopenOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopenOpportunity;

  /// No description provided for @deleteOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Delete opportunity'**
  String get deleteOpportunity;

  /// No description provided for @deleteOpportunityConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this opportunity and its applications? This can\'t be undone, and your free post allowance isn\'t restored.'**
  String get deleteOpportunityConfirm;

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get postedBy;

  /// No description provided for @publishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String publishedOn(String date);

  /// No description provided for @deadlineOn.
  ///
  /// In en, this message translates to:
  /// **'Deadline {date}'**
  String deadlineOn(String date);

  /// No description provided for @applyBy.
  ///
  /// In en, this message translates to:
  /// **'Apply by {date}'**
  String applyBy(String date);

  /// No description provided for @positionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 position} other{{count} positions}}'**
  String positionsCount(int count);

  /// No description provided for @applicationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No applications yet} =1{1 application} other{{count} applications}}'**
  String applicationsCount(int count);

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply now'**
  String get applyNow;

  /// No description provided for @shareOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareOpportunity;

  /// No description provided for @alreadyApplied.
  ///
  /// In en, this message translates to:
  /// **'You applied'**
  String get alreadyApplied;

  /// No description provided for @applyTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply with your Music Passport'**
  String get applyTitle;

  /// No description provided for @applicationMessage.
  ///
  /// In en, this message translates to:
  /// **'Short message to the owner'**
  String get applicationMessage;

  /// No description provided for @applicationMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Why are you a good fit?'**
  String get applicationMessageHint;

  /// No description provided for @supportingLinks.
  ///
  /// In en, this message translates to:
  /// **'Portfolio links or supporting material'**
  String get supportingLinks;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get submitApplication;

  /// No description provided for @applicationSent.
  ///
  /// In en, this message translates to:
  /// **'Application sent'**
  String get applicationSent;

  /// No description provided for @opportunityClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This opportunity is closed.'**
  String get opportunityClosedNotice;

  /// No description provided for @yourOwnOpportunity.
  ///
  /// In en, this message translates to:
  /// **'This is your opportunity.'**
  String get yourOwnOpportunity;

  /// No description provided for @applicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applicationsTitle;

  /// No description provided for @noApplicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No applications yet.'**
  String get noApplicationsYet;

  /// No description provided for @appStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get appStatusPending;

  /// No description provided for @appStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get appStatusUnderReview;

  /// No description provided for @appStatusShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get appStatusShortlisted;

  /// No description provided for @appStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get appStatusAccepted;

  /// No description provided for @appStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get appStatusRejected;

  /// No description provided for @appStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get appStatusWithdrawn;

  /// No description provided for @markUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get markUnderReview;

  /// No description provided for @shortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get shortlist;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @withdrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your application?'**
  String get withdrawConfirm;

  /// No description provided for @appliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied {date}'**
  String appliedOn(String date);

  /// No description provided for @noMyApplications.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t applied to any opportunity yet.'**
  String get noMyApplications;

  /// No description provided for @noMyPosts.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted any opportunity yet.'**
  String get noMyPosts;

  /// No description provided for @startWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open DealFlow workspace'**
  String get startWorkspace;

  /// No description provided for @dealflow.
  ///
  /// In en, this message translates to:
  /// **'DealFlow'**
  String get dealflow;

  /// No description provided for @dealflowTagline.
  ///
  /// In en, this message translates to:
  /// **'Agree on roles and splits, then protect it'**
  String get dealflowTagline;

  /// No description provided for @workspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaces;

  /// No description provided for @noWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Accept an applicant to start a DealFlow workspace.'**
  String get noWorkspaces;

  /// No description provided for @wsStatusNegotiating.
  ///
  /// In en, this message translates to:
  /// **'Negotiating'**
  String get wsStatusNegotiating;

  /// No description provided for @wsStatusAgreed.
  ///
  /// In en, this message translates to:
  /// **'Terms agreed'**
  String get wsStatusAgreed;

  /// No description provided for @wsStatusInProtect.
  ///
  /// In en, this message translates to:
  /// **'In Protect'**
  String get wsStatusInProtect;

  /// No description provided for @wsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get wsStatusActive;

  /// No description provided for @wsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get wsStatusCompleted;

  /// No description provided for @wsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get wsStatusCancelled;

  /// No description provided for @projectOwner.
  ///
  /// In en, this message translates to:
  /// **'Project owner'**
  String get projectOwner;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @responsibilities.
  ///
  /// In en, this message translates to:
  /// **'Responsibilities'**
  String get responsibilities;

  /// No description provided for @contributionPercent.
  ///
  /// In en, this message translates to:
  /// **'Contribution %'**
  String get contributionPercent;

  /// No description provided for @proposeTerms.
  ///
  /// In en, this message translates to:
  /// **'Propose terms'**
  String get proposeTerms;

  /// No description provided for @editTerms.
  ///
  /// In en, this message translates to:
  /// **'Edit terms'**
  String get editTerms;

  /// No description provided for @paymentArrangement.
  ///
  /// In en, this message translates to:
  /// **'Payment arrangement'**
  String get paymentArrangement;

  /// No description provided for @importantDates.
  ///
  /// In en, this message translates to:
  /// **'Important dates'**
  String get importantDates;

  /// No description provided for @discussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussion;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get writeMessage;

  /// No description provided for @iAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to these terms'**
  String get iAgree;

  /// No description provided for @withdrawAgreement.
  ///
  /// In en, this message translates to:
  /// **'Withdraw my agreement'**
  String get withdrawAgreement;

  /// No description provided for @agreedBadge.
  ///
  /// In en, this message translates to:
  /// **'Agreed'**
  String get agreedBadge;

  /// No description provided for @notAgreedYet.
  ///
  /// In en, this message translates to:
  /// **'Not agreed yet'**
  String get notAgreedYet;

  /// No description provided for @totalPercent.
  ///
  /// In en, this message translates to:
  /// **'Total: {percent}%'**
  String totalPercent(String percent);

  /// No description provided for @totalMustBe100.
  ///
  /// In en, this message translates to:
  /// **'Contributions must add up to 100% before everyone can agree.'**
  String get totalMustBe100;

  /// No description provided for @continueInProtect.
  ///
  /// In en, this message translates to:
  /// **'Continue in Protect'**
  String get continueInProtect;

  /// No description provided for @continueInProtectHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone agreed. Create the agreement in Protect – it\'s pre-filled with these terms.'**
  String get continueInProtectHint;

  /// No description provided for @markActive.
  ///
  /// In en, this message translates to:
  /// **'Mark active'**
  String get markActive;

  /// No description provided for @cancelWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Cancel collaboration'**
  String get cancelWorkspace;

  /// No description provided for @termsLocked.
  ///
  /// In en, this message translates to:
  /// **'Terms are locked because the agreement is in Protect.'**
  String get termsLocked;

  /// No description provided for @workspaceOpened.
  ///
  /// In en, this message translates to:
  /// **'Workspace ready'**
  String get workspaceOpened;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @currentPlanName.
  ///
  /// In en, this message translates to:
  /// **'Current plan: {plan}'**
  String currentPlanName(String plan);

  /// No description provided for @pdfPreviewWatermark.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW – NOT FINAL'**
  String get pdfPreviewWatermark;

  /// No description provided for @previewPdf.
  ///
  /// In en, this message translates to:
  /// **'Preview PDF'**
  String get previewPdf;

  /// No description provided for @previewPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free draft copy (not the final agreement)'**
  String get previewPdfSubtitle;

  /// No description provided for @generateFinalAgreement.
  ///
  /// In en, this message translates to:
  /// **'Generate final agreement'**
  String get generateFinalAgreement;

  /// No description provided for @finalAgreementFree.
  ///
  /// In en, this message translates to:
  /// **'Included in Pro'**
  String get finalAgreementFree;

  /// No description provided for @finalAgreementFee.
  ///
  /// In en, this message translates to:
  /// **'{amount} one-time for this agreement'**
  String finalAgreementFee(String amount);

  /// No description provided for @finalAgreementNeedsAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Available once every party has accepted.'**
  String get finalAgreementNeedsAcceptance;

  /// No description provided for @downloadFinalAgreement.
  ///
  /// In en, this message translates to:
  /// **'Download final agreement'**
  String get downloadFinalAgreement;

  /// No description provided for @finalAgreementReady.
  ///
  /// In en, this message translates to:
  /// **'Final agreement – saved for every party'**
  String get finalAgreementReady;

  /// No description provided for @finalAgreementUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Final agreement unlocked'**
  String get finalAgreementUnlockedTitle;

  /// No description provided for @reachProOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach is a Pro feature'**
  String get reachProOnlyTitle;

  /// No description provided for @reachProOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Turn every release into ready-to-post content for Instagram, TikTok, Facebook and WhatsApp.'**
  String get reachProOnlyBody;

  /// No description provided for @reachBenefitCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Promotion campaigns for every release'**
  String get reachBenefitCampaigns;

  /// No description provided for @reachBenefitVideo.
  ///
  /// In en, this message translates to:
  /// **'9:16 promo videos from your track and cover'**
  String get reachBenefitVideo;

  /// No description provided for @reachBenefitCaptions.
  ///
  /// In en, this message translates to:
  /// **'Captions, hashtags and announcements in EN/FR'**
  String get reachBenefitCaptions;

  /// No description provided for @reachBenefitBio.
  ///
  /// In en, this message translates to:
  /// **'Artist bios written from your Music Passport'**
  String get reachBenefitBio;

  /// No description provided for @upgradeNowFor.
  ///
  /// In en, this message translates to:
  /// **'Upgrade now – {amount}'**
  String upgradeNowFor(String amount);

  /// No description provided for @contentStudio.
  ///
  /// In en, this message translates to:
  /// **'Content Studio'**
  String get contentStudio;

  /// No description provided for @contentStudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Captions, announcements and bios from your projects and Passport'**
  String get contentStudioSubtitle;

  /// No description provided for @contentType.
  ///
  /// In en, this message translates to:
  /// **'What do you want to write?'**
  String get contentType;

  /// No description provided for @contentCaption.
  ///
  /// In en, this message translates to:
  /// **'Promo caption'**
  String get contentCaption;

  /// No description provided for @contentAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Release announcement'**
  String get contentAnnouncement;

  /// No description provided for @contentBio.
  ///
  /// In en, this message translates to:
  /// **'Artist biography'**
  String get contentBio;

  /// No description provided for @contentProjectPromo.
  ///
  /// In en, this message translates to:
  /// **'Project promotion'**
  String get contentProjectPromo;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @sourceProject.
  ///
  /// In en, this message translates to:
  /// **'Project or campaign'**
  String get sourceProject;

  /// No description provided for @noSourceSelected.
  ///
  /// In en, this message translates to:
  /// **'No project – use my Passport only'**
  String get noSourceSelected;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Another version'**
  String get regenerate;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyText;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied – paste it in your app'**
  String get textCopied;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareText;

  /// No description provided for @needPassportForBio.
  ///
  /// In en, this message translates to:
  /// **'Create your Music Passport to generate a biography.'**
  String get needPassportForBio;

  /// No description provided for @directPublishNote.
  ///
  /// In en, this message translates to:
  /// **'Direct publishing needs each platform\'s official app approval. For now, copy or share the text and post it from the platform.'**
  String get directPublishNote;

  /// No description provided for @genCaption1.
  ///
  /// In en, this message translates to:
  /// **'New music alert! \"{title}\" by {artist} is out now. {link}'**
  String genCaption1(String title, String artist, String link);

  /// No description provided for @genCaption2.
  ///
  /// In en, this message translates to:
  /// **'{artist} just dropped \"{title}\" – press play and tell me what you think. {link}'**
  String genCaption2(String title, String artist, String link);

  /// No description provided for @genCaption3.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is here. Made with love, made for you. Stream it now. {link}'**
  String genCaption3(String title, String link);

  /// No description provided for @genAnnouncement1.
  ///
  /// In en, this message translates to:
  /// **'Big news: my new {kind} \"{title}\" drops {date}. Mark the date and get ready! {link}'**
  String genAnnouncement1(String kind, String title, String date, String link);

  /// No description provided for @genAnnouncement2.
  ///
  /// In en, this message translates to:
  /// **'It\'s official – \"{title}\" by {artist} arrives {date}. Turn on notifications so you don\'t miss it. {link}'**
  String genAnnouncement2(
      String title, String artist, String date, String link);

  /// No description provided for @genAnnouncementNoDate.
  ///
  /// In en, this message translates to:
  /// **'Coming soon: \"{title}\" by {artist}. Stay tuned – the countdown starts now. {link}'**
  String genAnnouncementNoDate(String title, String artist, String link);

  /// No description provided for @kindSingle.
  ///
  /// In en, this message translates to:
  /// **'single'**
  String get kindSingle;

  /// No description provided for @genBioIntro.
  ///
  /// In en, this message translates to:
  /// **'{name} is a {roles}{location}.'**
  String genBioIntro(String name, String roles, String location);

  /// No description provided for @genBioBasedIn.
  ///
  /// In en, this message translates to:
  /// **', based in {place}'**
  String genBioBasedIn(String place);

  /// No description provided for @genBioExperience.
  ///
  /// In en, this message translates to:
  /// **'With {years} years of experience, {name} works across {genres}.'**
  String genBioExperience(String years, String name, String genres);

  /// No description provided for @genBioGenres.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s sound blends {genres}.'**
  String genBioGenres(String name, String genres);

  /// No description provided for @genBioCredits.
  ///
  /// In en, this message translates to:
  /// **'Selected work: {credits}.'**
  String genBioCredits(String credits);

  /// No description provided for @genBioInstruments.
  ///
  /// In en, this message translates to:
  /// **'Plays {instruments}.'**
  String genBioInstruments(String instruments);

  /// No description provided for @genBioOpen.
  ///
  /// In en, this message translates to:
  /// **'Open to collaborations – reach out via SplitSure.'**
  String get genBioOpen;

  /// No description provided for @genProjectPromo.
  ///
  /// In en, this message translates to:
  /// **'Working on \"{title}\"{genre}. {description} Follow the journey!'**
  String genProjectPromo(String title, String genre, String description);

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get andWord;

  /// No description provided for @notifOppRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'New opportunity for you'**
  String get notifOppRecommendedTitle;

  /// No description provided for @notifOppRecommendedBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" matches your Music Passport.'**
  String notifOppRecommendedBody(String title);

  /// No description provided for @notifAppReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'New application'**
  String get notifAppReceivedTitle;

  /// No description provided for @notifAppReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} applied to \"{title}\".'**
  String notifAppReceivedBody(String name, String title);

  /// No description provided for @notifAppUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Application under review'**
  String get notifAppUnderReviewTitle;

  /// No description provided for @notifAppShortlistedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been shortlisted!'**
  String get notifAppShortlistedTitle;

  /// No description provided for @notifAppAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application accepted'**
  String get notifAppAcceptedTitle;

  /// No description provided for @notifAppRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application update'**
  String get notifAppRejectedTitle;

  /// No description provided for @notifAppStatusBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\"'**
  String notifAppStatusBody(String title);

  /// No description provided for @notifAppRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your application to \"{title}\" wasn\'t selected this time.'**
  String notifAppRejectedBody(String title);

  /// No description provided for @notifWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'DealFlow workspace ready'**
  String get notifWorkspaceTitle;

  /// No description provided for @notifWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'Agree on roles and splits for \"{title}\".'**
  String notifWorkspaceBody(String title);

  /// No description provided for @notifMemberAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'You were added to a collaboration'**
  String get notifMemberAddedTitle;

  /// No description provided for @notifTermsUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms updated'**
  String get notifTermsUpdatedTitle;

  /// No description provided for @notifTermsUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'New terms were proposed for \"{title}\". Review and agree.'**
  String notifTermsUpdatedBody(String title);

  /// No description provided for @notifPaymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get notifPaymentSuccessTitle;

  /// No description provided for @notifPaymentSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} FCFA received. Thank you!'**
  String notifPaymentSuccessBody(String amount);

  /// No description provided for @notifPaymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get notifPaymentFailedTitle;

  /// No description provided for @notifPaymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your {amount} FCFA payment didn\'t go through. Nothing was charged – you can try again.'**
  String notifPaymentFailedBody(String amount);

  /// No description provided for @notifProActivatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro activated'**
  String get notifProActivatedTitle;

  /// No description provided for @notifProActivatedBody.
  ///
  /// In en, this message translates to:
  /// **'Unlimited posts, agreements and Reach are now unlocked.'**
  String get notifProActivatedBody;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT RECEIPT'**
  String get receiptTitle;

  /// No description provided for @receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt no. {number}'**
  String receiptNumber(String number);

  /// No description provided for @receiptPaid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get receiptPaid;

  /// No description provided for @receiptBilledTo.
  ///
  /// In en, this message translates to:
  /// **'Billed to'**
  String get receiptBilledTo;

  /// No description provided for @receiptPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get receiptPaymentDetails;

  /// No description provided for @receiptReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for payment'**
  String get receiptReason;

  /// No description provided for @receiptAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get receiptAmount;

  /// No description provided for @receiptTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get receiptTotalPaid;

  /// No description provided for @receiptTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get receiptTransactionId;

  /// No description provided for @receiptReference.
  ///
  /// In en, this message translates to:
  /// **'SplitSure reference'**
  String get receiptReference;

  /// No description provided for @receiptDate.
  ///
  /// In en, this message translates to:
  /// **'Date of transaction'**
  String get receiptDate;

  /// No description provided for @receiptPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get receiptPaymentMethod;

  /// No description provided for @receiptPhoneUsed.
  ///
  /// In en, this message translates to:
  /// **'Phone number used'**
  String get receiptPhoneUsed;

  /// No description provided for @receiptAccountType.
  ///
  /// In en, this message translates to:
  /// **'Current account type'**
  String get receiptAccountType;

  /// No description provided for @receiptCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get receiptCustomerName;

  /// No description provided for @receiptDescPro.
  ///
  /// In en, this message translates to:
  /// **'SplitSure Pro upgrade (one-time)'**
  String get receiptDescPro;

  /// No description provided for @receiptDescAgreement.
  ///
  /// In en, this message translates to:
  /// **'Final agreement generation'**
  String get receiptDescAgreement;

  /// No description provided for @receiptThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using SplitSure.'**
  String get receiptThanks;

  /// No description provided for @receiptFooterNote.
  ///
  /// In en, this message translates to:
  /// **'This receipt was generated electronically and is valid without a signature.'**
  String get receiptFooterNote;

  /// No description provided for @receiptIssuedOn.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String receiptIssuedOn(String date);

  /// No description provided for @downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download receipt'**
  String get downloadReceipt;

  /// No description provided for @receiptError.
  ///
  /// In en, this message translates to:
  /// **'Could not create the receipt: {error}'**
  String receiptError(String error);

  /// No description provided for @sentForReviewEmailed.
  ///
  /// In en, this message translates to:
  /// **'Agreement sent for review. {count} collaborator(s) were e-mailed.'**
  String sentForReviewEmailed(int count);

  /// No description provided for @newVersionSentEmailed.
  ///
  /// In en, this message translates to:
  /// **'New version sent. {count} collaborator(s) were e-mailed.'**
  String newVersionSentEmailed(int count);

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @googleSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in isn\'t available yet. Please use your e-mail and password for now.'**
  String get googleSignInUnavailable;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {error}'**
  String googleSignInFailed(String error);

  /// No description provided for @acceptTermsFirst.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions first.'**
  String get acceptTermsFirst;

  /// No description provided for @planBadgeBasic.
  ///
  /// In en, this message translates to:
  /// **'BASIC'**
  String get planBadgeBasic;

  /// No description provided for @planBadgeTooltipBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic plan – tap to see Pro'**
  String get planBadgeTooltipBasic;

  /// No description provided for @planBadgeTooltipPro.
  ///
  /// In en, this message translates to:
  /// **'Pro plan active'**
  String get planBadgeTooltipPro;

  /// No description provided for @reachHeadlineBy.
  ///
  /// In en, this message translates to:
  /// **'🎵 \"{title}\" by {artist} is out now!'**
  String reachHeadlineBy(String title, String artist);

  /// No description provided for @reachLinkInBio.
  ///
  /// In en, this message translates to:
  /// **'Link in bio'**
  String get reachLinkInBio;

  /// No description provided for @reachPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Post to your socials'**
  String get reachPostTitle;

  /// No description provided for @reachPostHint.
  ///
  /// In en, this message translates to:
  /// **'Each platform gets its own caption. On a phone, Share opens the app with the video and caption ready; on a computer the caption is copied, the video downloaded and the upload page opened.'**
  String get reachPostHint;

  /// No description provided for @reachShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get reachShare;

  /// No description provided for @reachCopyCaption.
  ///
  /// In en, this message translates to:
  /// **'Copy caption'**
  String get reachCopyCaption;

  /// No description provided for @reachLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get reachLinked;

  /// No description provided for @reachOpenMyPage.
  ///
  /// In en, this message translates to:
  /// **'Open my page'**
  String get reachOpenMyPage;

  /// No description provided for @reachSharedToApp.
  ///
  /// In en, this message translates to:
  /// **'Caption copied – finish posting in the app.'**
  String get reachSharedToApp;

  /// No description provided for @reachOpenedWeb.
  ///
  /// In en, this message translates to:
  /// **'Caption copied. Paste it on the page that just opened (the video was downloaded if needed).'**
  String get reachOpenedWeb;

  /// No description provided for @reachNeedsVideo.
  ///
  /// In en, this message translates to:
  /// **'Create the promo video above first – {platform} posts need a video.'**
  String reachNeedsVideo(String platform);

  /// No description provided for @reachContentPack.
  ///
  /// In en, this message translates to:
  /// **'Download content pack'**
  String get reachContentPack;

  /// No description provided for @reachContentPackHint.
  ///
  /// In en, this message translates to:
  /// **'Video + a text file with every caption, to post by hand.'**
  String get reachContentPackHint;

  /// No description provided for @reachContentPackDone.
  ///
  /// In en, this message translates to:
  /// **'Content pack downloaded.'**
  String get reachContentPackDone;

  /// No description provided for @reachRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get reachRegenerate;

  /// No description provided for @reachPreviewCaption.
  ///
  /// In en, this message translates to:
  /// **'Preview caption'**
  String get reachPreviewCaption;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you use for SplitSure. We\'ll send you a reset code and a secure link.'**
  String get forgotSubtitle;

  /// No description provided for @forgotSend.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get forgotSend;

  /// No description provided for @forgotRemembered.
  ///
  /// In en, this message translates to:
  /// **'Remembered it?'**
  String get forgotRemembered;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get codeTitle;

  /// No description provided for @codeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a reset code to {email}. Enter it below, or simply tap the link in that email.'**
  String codeSubtitle(String email);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get codeLabel;

  /// No description provided for @codeVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get codeVerify;

  /// No description provided for @codeResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get codeResend;

  /// No description provided for @codeResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String codeResendIn(int seconds);

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get codeSent;

  /// No description provided for @codeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired. Use the latest email, or resend a new code.'**
  String get codeInvalid;

  /// No description provided for @codeChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get codeChangeEmail;

  /// No description provided for @codeSpamHint.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Check your spam folder.'**
  String get codeSpamHint;

  /// No description provided for @newPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get newPassTitle;

  /// No description provided for @newPassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password you haven\'t used before.'**
  String get newPassSubtitle;

  /// No description provided for @newPassLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassLabel;

  /// No description provided for @newPassConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get newPassConfirm;

  /// No description provided for @newPassSave.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get newPassSave;

  /// No description provided for @passMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passMismatch;

  /// No description provided for @passTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passTooShort;

  /// No description provided for @passStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength: {level}'**
  String passStrength(String level);

  /// No description provided for @passWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passWeak;

  /// No description provided for @passFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passFair;

  /// No description provided for @passStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passStrong;

  /// No description provided for @passwordUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdatedTitle;

  /// No description provided for @passwordUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed. Use it the next time you sign in.'**
  String get passwordUpdatedBody;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue to SplitSure'**
  String get continueToApp;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment before requesting another code.'**
  String get tooManyRequests;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsTitle;

  /// No description provided for @termsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String termsLastUpdated(String date);

  /// No description provided for @termsIntro.
  ///
  /// In en, this message translates to:
  /// **'Please read these terms carefully. They explain your rights and responsibilities when you use SplitSure.'**
  String get termsIntro;

  /// No description provided for @termsContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get termsContents;

  /// No description provided for @termsAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms'**
  String get termsAgree;

  /// No description provided for @termsReadLink.
  ///
  /// In en, this message translates to:
  /// **'Read the Terms & Conditions'**
  String get termsReadLink;

  /// No description provided for @termsBackToTop.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get termsBackToTop;

  /// No description provided for @approveTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & sign the agreement'**
  String get approveTitle;

  /// No description provided for @approveIntro.
  ///
  /// In en, this message translates to:
  /// **'{owner} invites you to approve the split agreement for “{song}”.'**
  String approveIntro(String owner, String song);

  /// No description provided for @approveYourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share'**
  String get approveYourShare;

  /// No description provided for @approveYourRole.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get approveYourRole;

  /// No description provided for @approveParties.
  ///
  /// In en, this message translates to:
  /// **'All parties'**
  String get approveParties;

  /// No description provided for @approveLegal.
  ///
  /// In en, this message translates to:
  /// **'By tapping “Approve & sign” you accept these terms. Your electronic signature code is recorded with the date and printed on the agreement document.'**
  String get approveLegal;

  /// No description provided for @approveButton.
  ///
  /// In en, this message translates to:
  /// **'Approve & sign'**
  String get approveButton;

  /// No description provided for @approveChanges.
  ///
  /// In en, this message translates to:
  /// **'Request changes or decline'**
  String get approveChanges;

  /// No description provided for @approveSignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Signed!'**
  String get approveSignedTitle;

  /// No description provided for @approveSignedBody.
  ///
  /// In en, this message translates to:
  /// **'Your approval is recorded. This signature code now appears on the agreement document. We also e-mailed you a copy.'**
  String get approveSignedBody;

  /// No description provided for @approveAlreadySigned.
  ///
  /// In en, this message translates to:
  /// **'You already signed this agreement.'**
  String get approveAlreadySigned;

  /// No description provided for @approveAllSigned.
  ///
  /// In en, this message translates to:
  /// **'Every party has approved – the agreement is complete.'**
  String get approveAllSigned;

  /// No description provided for @approveWaitingOthers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other parties to approve.'**
  String get approveWaitingOthers;

  /// No description provided for @approveInvalid.
  ///
  /// In en, this message translates to:
  /// **'This approval link is not valid. Open the latest e-mail from SplitSure.'**
  String get approveInvalid;

  /// No description provided for @approveExpired.
  ///
  /// In en, this message translates to:
  /// **'This approval link has expired. Ask the creator to send the agreement again.'**
  String get approveExpired;

  /// No description provided for @approveNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This agreement has been updated since this e-mail. Use the link in the newest e-mail.'**
  String get approveNewerVersion;

  /// No description provided for @approveClosed.
  ///
  /// In en, this message translates to:
  /// **'This agreement is no longer open for approval.'**
  String get approveClosed;

  /// No description provided for @approveOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open SplitSure'**
  String get approveOpenApp;

  /// No description provided for @signatureCode.
  ///
  /// In en, this message translates to:
  /// **'Signature code'**
  String get signatureCode;

  /// No description provided for @signedViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Signed electronically by e-mail'**
  String get signedViaEmail;

  /// No description provided for @signedViaApp.
  ///
  /// In en, this message translates to:
  /// **'Signed electronically in SplitSure'**
  String get signedViaApp;

  /// No description provided for @pdfSignedOn.
  ///
  /// In en, this message translates to:
  /// **'Signed {date}'**
  String pdfSignedOn(String date);

  /// No description provided for @planAgreementLimitBody.
  ///
  /// In en, this message translates to:
  /// **'On the Basic plan your first agreement document is free; each extra one costs 50 FCFA to preview and download. Pro includes them all.'**
  String get planAgreementLimitBody;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get verifyTitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit code to {email}. Enter it below to confirm your email and activate your SplitSure account.'**
  String verifySubtitle(String email);

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Activate my account'**
  String get verifyButton;

  /// No description provided for @verifyFrom.
  ///
  /// In en, this message translates to:
  /// **'The email comes from SplitSure.'**
  String get verifyFrom;

  /// No description provided for @verifySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed!'**
  String get verifySuccessTitle;

  /// No description provided for @verifySuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is active. Let\'s pick your plan.'**
  String get verifySuccessBody;

  /// No description provided for @verifyWrongEmail.
  ///
  /// In en, this message translates to:
  /// **'Wrong email? Sign up again'**
  String get verifyWrongEmail;

  /// No description provided for @verifyStepAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get verifyStepAccount;

  /// No description provided for @verifyStepVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyStepVerify;

  /// No description provided for @verifyStepPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get verifyStepPlan;

  /// No description provided for @verifyNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email first. We\'ve sent you a new code.'**
  String get verifyNotConfirmed;

  /// No description provided for @verifyAlreadyConfirmed.
  ///
  /// In en, this message translates to:
  /// **'This email is already confirmed. Please sign in.'**
  String get verifyAlreadyConfirmed;

  /// No description provided for @passportGateTitle.
  ///
  /// In en, this message translates to:
  /// **'View {name}\'s Music Passport'**
  String passportGateTitle(String name);

  /// No description provided for @passportGateBody.
  ///
  /// In en, this message translates to:
  /// **'{name} shared their Music Passport with you on SplitSure. Create a free account (or sign in) to see their full profile, portfolio and contact details.'**
  String passportGateBody(String name);

  /// No description provided for @passportGateCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a free account'**
  String get passportGateCreate;

  /// No description provided for @passportGateSignIn.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get passportGateSignIn;

  /// No description provided for @passportGateBack.
  ///
  /// In en, this message translates to:
  /// **'You\'ll come straight back to this passport.'**
  String get passportGateBack;

  /// No description provided for @passportGatePerk1.
  ///
  /// In en, this message translates to:
  /// **'Full profile, skills and genres'**
  String get passportGatePerk1;

  /// No description provided for @passportGatePerk2.
  ///
  /// In en, this message translates to:
  /// **'Portfolio and released work'**
  String get passportGatePerk2;

  /// No description provided for @passportGatePerk3.
  ///
  /// In en, this message translates to:
  /// **'Contact and collaborate safely'**
  String get passportGatePerk3;

  /// No description provided for @passportGateLocked.
  ///
  /// In en, this message translates to:
  /// **'Members only'**
  String get passportGateLocked;

  /// No description provided for @uploadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String uploadingPercent(int percent);

  /// No description provided for @videoPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting your song and artwork ready…'**
  String get videoPreparing;

  /// No description provided for @videoUploading.
  ///
  /// In en, this message translates to:
  /// **'Saving your video… {percent}%'**
  String videoUploading(int percent);

  /// No description provided for @videoSavedLocallyHint.
  ///
  /// In en, this message translates to:
  /// **'You can watch it now – it is being saved in the background.'**
  String get videoSavedLocallyHint;

  /// No description provided for @audienceAndRelease.
  ///
  /// In en, this message translates to:
  /// **'Audience & release'**
  String get audienceAndRelease;

  /// No description provided for @witnessConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Witness confirmed'**
  String get witnessConfirmed;

  /// No description provided for @witnessDeclined.
  ///
  /// In en, this message translates to:
  /// **'Witness declined'**
  String get witnessDeclined;

  /// No description provided for @witnessWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the witness to confirm'**
  String get witnessWaiting;

  /// No description provided for @witnessCode.
  ///
  /// In en, this message translates to:
  /// **'Witness code'**
  String get witnessCode;

  /// No description provided for @witnessResponseNeeded.
  ///
  /// In en, this message translates to:
  /// **'You are the witness of this agreement'**
  String get witnessResponseNeeded;

  /// No description provided for @witnessResponseIntro.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you witnessed this agreement between the collaborators below, or decline if you did not.'**
  String get witnessResponseIntro;

  /// No description provided for @witnessConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm as witness'**
  String get witnessConfirmButton;

  /// No description provided for @witnessConfirmQuestion.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you witnessed this agreement? Your witness code will be printed on the document.'**
  String get witnessConfirmQuestion;

  /// No description provided for @witnessConfirmedToast.
  ///
  /// In en, this message translates to:
  /// **'You confirmed as witness.'**
  String get witnessConfirmedToast;

  /// No description provided for @witnessDeclinedToast.
  ///
  /// In en, this message translates to:
  /// **'You declined to witness this agreement.'**
  String get witnessDeclinedToast;

  /// No description provided for @witnessDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline as witness?'**
  String get witnessDeclineTitle;

  /// No description provided for @witnessDeclineQuestion.
  ///
  /// In en, this message translates to:
  /// **'The creator will be told that you did not witness this agreement.'**
  String get witnessDeclineQuestion;

  /// No description provided for @witnessApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm as witness'**
  String get witnessApproveTitle;

  /// No description provided for @witnessApproveIntro.
  ///
  /// In en, this message translates to:
  /// **'{owner} named you as the witness of the agreement for \"{song}\".'**
  String witnessApproveIntro(String owner, String song);

  /// No description provided for @witnessApproveLegal.
  ///
  /// In en, this message translates to:
  /// **'By confirming, you attest that you witnessed this agreement between the parties listed above. No account is needed.'**
  String get witnessApproveLegal;

  /// No description provided for @witnessSignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Witness confirmation recorded'**
  String get witnessSignedTitle;

  /// No description provided for @witnessSignedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your witness code below is printed on the agreement document.'**
  String get witnessSignedBody;

  /// No description provided for @witnessDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'You declined to witness this agreement'**
  String get witnessDeclinedTitle;

  /// No description provided for @witnessDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'The creator of the agreement has been notified.'**
  String get witnessDeclinedBody;

  /// No description provided for @witnessEmailHint.
  ///
  /// In en, this message translates to:
  /// **'The witness receives an e-mail to confirm or decline the agreement, even without a SplitSure account.'**
  String get witnessEmailHint;

  /// No description provided for @notifWitnessInvitedTitle.
  ///
  /// In en, this message translates to:
  /// **'You are asked to be a witness'**
  String get notifWitnessInvitedTitle;

  /// No description provided for @notifWitnessInvitedBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm or decline the agreement for \"{song}\".'**
  String notifWitnessInvitedBody(String song);

  /// No description provided for @notifWitnessConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Witness confirmed'**
  String get notifWitnessConfirmedTitle;

  /// No description provided for @notifWitnessConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} confirmed as witness of \"{song}\".'**
  String notifWitnessConfirmedBody(String name, String song);

  /// No description provided for @notifWitnessDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Witness declined'**
  String get notifWitnessDeclinedTitle;

  /// No description provided for @notifWitnessDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} declined to witness \"{song}\".'**
  String notifWitnessDeclinedBody(String name, String song);

  /// No description provided for @successfulCollaborations.
  ///
  /// In en, this message translates to:
  /// **'Successful collaborations'**
  String get successfulCollaborations;

  /// No description provided for @successfulCollaborationsHint.
  ///
  /// In en, this message translates to:
  /// **'Agreements approved by every party'**
  String get successfulCollaborationsHint;

  /// No description provided for @noSuccessfulCollaborations.
  ///
  /// In en, this message translates to:
  /// **'No successful collaborations yet. They appear here once every party has approved an agreement.'**
  String get noSuccessfulCollaborations;

  /// No description provided for @acceptedCollaborations.
  ///
  /// In en, this message translates to:
  /// **'Accepted collaborations'**
  String get acceptedCollaborations;

  /// No description provided for @acceptedCollaborationsHint.
  ///
  /// In en, this message translates to:
  /// **'Opportunities where your application was accepted'**
  String get acceptedCollaborationsHint;

  /// No description provided for @noAcceptedCollaborations.
  ///
  /// In en, this message translates to:
  /// **'None yet. When you apply to an opportunity in the Hub and are accepted, it shows here.'**
  String get noAcceptedCollaborations;

  /// No description provided for @supportChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chat with SplitSure support on WhatsApp'**
  String get supportChatTooltip;

  /// No description provided for @supportChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get supportChatTitle;

  /// No description provided for @supportChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with support'**
  String get supportChatSubtitle;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of SplitSure?'**
  String get logoutTitle;

  /// No description provided for @stayLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stayLoggedIn;

  /// No description provided for @welcomeBackPlain.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBackPlain;

  /// No description provided for @greatToSeeYou.
  ///
  /// In en, this message translates to:
  /// **'Great to see you again!'**
  String get greatToSeeYou;

  /// No description provided for @witnessNotAskedYet.
  ///
  /// In en, this message translates to:
  /// **'The witness hasn\'t been asked to confirm this agreement yet.'**
  String get witnessNotAskedYet;

  /// No description provided for @askWitnessButton.
  ///
  /// In en, this message translates to:
  /// **'Ask the witness to confirm'**
  String get askWitnessButton;

  /// No description provided for @askWitnessConfirm.
  ///
  /// In en, this message translates to:
  /// **'The witness will be asked to confirm or decline this agreement. It will only be fully accepted once they confirm.'**
  String get askWitnessConfirm;

  /// No description provided for @witnessAskedEmailed.
  ///
  /// In en, this message translates to:
  /// **'The witness has been e-mailed and notified.'**
  String get witnessAskedEmailed;

  /// No description provided for @witnessAskedInApp.
  ///
  /// In en, this message translates to:
  /// **'The witness has been asked. They\'ll be e-mailed once e-mail sending is set up.'**
  String get witnessAskedInApp;

  /// No description provided for @verifySendFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the code right now. Tap \"Resend code\" in a moment.'**
  String get verifySendFailed;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About SplitSure'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Protect your music. Promote your sound.'**
  String get aboutTagline;

  /// No description provided for @aboutWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'What is SplitSure?'**
  String get aboutWhatTitle;

  /// No description provided for @aboutWhatBody.
  ///
  /// In en, this message translates to:
  /// **'SplitSure is the home of music collaboration. Agree on who did what and who earns what, sign it together, and keep a clear record for every song – then promote your release and grow your network.'**
  String get aboutWhatBody;

  /// No description provided for @aboutCameroonTitle.
  ///
  /// In en, this message translates to:
  /// **'Made for Cameroon'**
  String get aboutCameroonTitle;

  /// No description provided for @aboutCameroonBody.
  ///
  /// In en, this message translates to:
  /// **'SplitSure is built first and foremost for Cameroonian artists, producers, songwriters and music professionals – from Douala to Yaoundé, Bamenda, Bafoussam and beyond – so that every collaboration is fair, documented and respected.'**
  String get aboutCameroonBody;

  /// No description provided for @aboutCameroonPay.
  ///
  /// In en, this message translates to:
  /// **'MTN Mobile Money & Orange Money'**
  String get aboutCameroonPay;

  /// No description provided for @aboutCameroonLang.
  ///
  /// In en, this message translates to:
  /// **'English & Français'**
  String get aboutCameroonLang;

  /// No description provided for @aboutCameroonPrice.
  ///
  /// In en, this message translates to:
  /// **'Prices in FCFA'**
  String get aboutCameroonPrice;

  /// No description provided for @aboutFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get aboutFeaturesTitle;

  /// No description provided for @aboutFeatProtect.
  ///
  /// In en, this message translates to:
  /// **'Split agreements every collaborator signs'**
  String get aboutFeatProtect;

  /// No description provided for @aboutFeatPassport.
  ///
  /// In en, this message translates to:
  /// **'Your professional music identity'**
  String get aboutFeatPassport;

  /// No description provided for @aboutFeatHub.
  ///
  /// In en, this message translates to:
  /// **'Find and post collaborations'**
  String get aboutFeatHub;

  /// No description provided for @aboutFeatReach.
  ///
  /// In en, this message translates to:
  /// **'Promo videos and captions for your release'**
  String get aboutFeatReach;

  /// No description provided for @aboutFeatDealflow.
  ///
  /// In en, this message translates to:
  /// **'Agree on terms before you sign'**
  String get aboutFeatDealflow;

  /// No description provided for @aboutPromiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Our promise'**
  String get aboutPromiseTitle;

  /// No description provided for @aboutPromiseBody.
  ///
  /// In en, this message translates to:
  /// **'Your music stays yours. Every signature is recorded with a unique code, every version is kept, and nothing is shared publicly unless you choose to.'**
  String get aboutPromiseBody;

  /// No description provided for @aboutSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get aboutSupportTitle;

  /// No description provided for @aboutSupportBody.
  ///
  /// In en, this message translates to:
  /// **'A question, a problem or an idea? Write to us by e-mail – we usually reply within 24 hours.'**
  String get aboutSupportBody;

  /// No description provided for @aboutSupportCopied.
  ///
  /// In en, this message translates to:
  /// **'E-mail address copied'**
  String get aboutSupportCopied;

  /// No description provided for @aboutMadeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with love in Cameroon'**
  String get aboutMadeWithLove;

  /// No description provided for @previewPdfFeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{amount} to preview and download this agreement'**
  String previewPdfFeeSubtitle(String amount);

  /// No description provided for @previewPdfFirstFree.
  ///
  /// In en, this message translates to:
  /// **'Your first agreement is free'**
  String get previewPdfFirstFree;

  /// No description provided for @previewPdfUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Paid – preview and download unlocked'**
  String get previewPdfUnlocked;

  /// No description provided for @finalAgreementFirstFree.
  ///
  /// In en, this message translates to:
  /// **'Free – your first agreement'**
  String get finalAgreementFirstFree;

  /// No description provided for @payToPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock this agreement document'**
  String get payToPreviewTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
